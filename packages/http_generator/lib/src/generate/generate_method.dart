part of '../generator.dart';

class GenerateForMethod {
  GenerateForMethod(this.method, this.addMember);
  final MethodElement method;

  final void Function(String method) addMember;

  void build() {
    final impl = methodImpl();
    if (impl != null) addMember(impl);
  }

  @protected
  String? methodImpl() {
    final methodAnnotation = Checker.method.firstAnnotationOf(method);
    if (methodAnnotation == null) return null;

    final returnType = method.returnType;
    if (!returnType.isA(Checker.future)) {
      throw InvalidGenerationSourceError(
        'Return type of `${method.name}` must be a Future.',
        element: method,
      );
    }

    final methodReader = MethodAnnotation(ConstantReader(methodAnnotation));
    final httpMethod = methodReader.method;
    final path = methodReader.path;

    final futureType = returnType.typeArgumentsOf(Checker.future)!.single;

    switch (futureType.sealed) {
      case NeverTy():
        throw InvalidGenerationSourceError(
          'Return type of `${method.name}` cannot be Future<Never>.',
          element: method,
        );
      case InvalidTy():
        throw InvalidGenerationSourceError(
          'Return type of `${method.name}` is invalid.',
          element: method,
        );
      case FunctionTy():
        throw InvalidGenerationSourceError(
          'Return type of `${method.name}` cannot be a function.',
          element: method,
        );
      case InterfaceTy():
      case RecordTy():
      case DynamicTy():
      case VoidTy():
      case TypeParameterTy():
      // good
    }

    final fragments = Checker.fragment.annotatedOf(method.formalParameters);
    if (fragments.length > 1) {
      throw InvalidGenerationSourceError(
        'Method `${method.name}` has multiple parameters annotated with `@Fragment`. '
        'Only one `@Fragment` parameter is allowed per method.',
        element: method,
      );
    }

    final fragment = fragments.firstOrNull;
    final query = createQuery(r'$uri', method);

    final body = RequestBody(method, methodReader, addMember);

    return '''
  ${methodSignature(method)} async {
    ${[
      'Uri \$uri = \$buildUrl(${modifyPath(path, method.formalParameters)});',
      if (query != null || fragment != null) ...[
        r'$uri = $uri.replace(', //
        if (query != null) 'queryParameters: $query,', //
        if (fragment != null) 'fragment: ${fragment.element.name},',
        ');',
      ],
    ].join('\n')}
    final \$request = await #{{http_annotation|\$createRequest}}(${[
      httpMethod.literal,
      '\$uri',
      if (abortTrigger(method) case final trigger?) 'abortTrigger: $trigger', //
      if (body.buildEncoded() case final body?) 'body: $body', //
    ].join(',\n')});
    
    ${[
      if (staticHeaders(methodReader) case final headers?) '\$request.headers.addAll($headers);',
      if (parameterHeaders(methodReader) case final headers?) '\$request.headers.addAll($headers);',
      //
    ].join('\n')}
    
    ${() sync* {
      if (Checker.streamedResponse.isExactlyType(futureType)) {
        yield r'return await #{{send}}($request);';
        return;
      }

      if (futureType is VoidType) {
        // wait for the stream to complete. configurable?
        yield r'await #{{send}}($request).then(#{{http|Response}}.fromStream);';
        return;
      }

      if (futureType.isA(Checker.response)) {
        yield r'return await #{{send}}($request).then(#{{http|Response}}.fromStream);';
        return;
      }

      //TODO: figure out how to support direct stream returns
      if (Checker.stream.isExactlyType(futureType)) {
        yield r'final $response = await #{{send}}($request);';
        yield r'return $response.stream;';
        return;
      }

      yield r'final $response = await #{{send}}($request).then(#{{http|Response}}.fromStream);';

      try {
        yield 'return ${Coding.decodeResponse(r'$response', method)};';
      } catch (e) {
        final decodeMethodName = '_${method.name}Decode';
        addMember('@#{{meta|protected}} #{{dart:async|FutureOr}}<${futureType.toCode()}> $decodeMethodName(#{{http|Response}} response);');
        yield 'return $decodeMethodName(\$response);';
      }
    }().join('\n')}
  }
''';
  }

  @protected
  String? staticHeaders(MethodAnnotation annotation) {
    final readers = [
      ...Checker.annotation(
        'Headers',
      ).annotationsOf(method.enclosingElement!).map(ConstantReader.new),
      ...Checker.annotation(
        'Headers',
      ).annotationsOf(method).map(ConstantReader.new),
      annotation,
    ];

    final staticValues = <DartObject?, DartObject?>{
      for (var reader in readers)
        ...?reader.read('headers').nullOr?.objectValue.toMapValue(),
    }.nonNulls;

    if (staticValues.isEmpty) return null;

    final code = [
      for (var entry in staticValues.entries)
        '${entry.key.toCode(addLeadingConst: false)}: ${entry.value.toCode(addLeadingConst: false)}',
    ];

    return 'const {${code.join(', ')}}';
  }

  @protected
  MapLiteral? parameterHeaders(MethodAnnotation annotation) {
    final headers = MapLiteral();

    final customHeaders = <FormalParameterElement>[];

    for (final (:annotation, :element) in Checker.header.annotatedOf(
      method.formalParameters,
    )) {
      if (!element.type.isA(Checker.string)) {
        customHeaders.add(element);
        continue;
      }
      final key = annotation.read('key').nullOr?.stringValue ?? element.name!;
      final q = element.type.nullabilitySuffix == .question ? '?' : '';
      headers.add(key, '$q${element.name!}');
    }

    for (final (annotation: _, :element) in Checker.headers.annotatedOf(
      method.formalParameters,
    )) {
      // if (!Checker.implementsMapStringString(element.type)) {
      if (!element.type.isA(Checker.map, [Checker.string, Checker.string])) {
        customHeaders.add(element);
        continue;
      }
      headers.addLiteral(Coding.encodeToMapStringString(element));
    }

    if (headers.isEmpty && customHeaders.isEmpty) return null;

    if (customHeaders.isNotEmpty) {
      // sort by original order
      // TODO: do the above better so this isnt necessary
      customHeaders.sort(
        (a, b) => method.formalParameters
            .indexOf(a)
            .compareTo(method.formalParameters.indexOf(b)),
      );

      final methodName = '_${method.name}Headers';
      addMember(
        '@#{{meta|protected}} Map<String, String> $methodName(${customHeaders.toCode()});',
      );

      final call = customHeaders.map(
        (e) => e.isNamed ? '${e.name}: ${e.name}' : e.name!,
      );

      headers.addSpread('$methodName(${call.join(', ')})');
    }

    return headers;
  }

  @protected
  String methodSignature(MethodElement method) {
    return '${method.returnType.toCode()} ${method.name}${typeParametersToCode(method.typeParameters)}(${method.formalParameters.toCode()})';
  }
}
