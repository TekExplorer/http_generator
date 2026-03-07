part of '../generator.dart';

class GenerateForMethod {
  GenerateForMethod(this.method, this.context);
  final MethodElement method;

  final GeneratorContext context;

  void build() {
    final impl = buildMethod();
    if (impl != null) context.members.add(impl);
  }

  late final methodAnnotation = MethodAnnotation(
    ConstantReader(Checker.method.firstAnnotationOf(method)),
  );

  @protected
  String? buildMethod() {
    if (methodAnnotation.isNull) return null;

    final returnType = method.returnType;
    if (!returnType.isA(Checker.future)) {
      throw InvalidGenerationSourceError(
        'Return type of `${method.name}` must be a Future.',
        element: method,
      );
    }

    final httpMethod = methodAnnotation.method;

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

    final body = RequestBody(method, methodAnnotation, context).buildEncoded();
    final trigger = abortTrigger(method);

    return '''
  ${methodSignature(method)} async {
    ${_buildUri()}
    final \$request = #{{http_annotation|\$createRequest}}(${[
      httpMethod.literal,
      '\$uri',
      if (trigger != null) 'abortTrigger: $trigger', //
      if (body != null) 'body: $body', //
    ].join(',\n')});
    
    ${[if (allHeaders() case final headers?) '\$request.headers.addAll($headers);'].join()}
    
    ${_processRequest(futureType).join('\n')}
  }
''';
  }

  String _buildUri() {
    final fragments = Checker.fragment.annotatedOf(method.formalParameters);
    if (fragments.length > 1) {
      throw InvalidGenerationSourceError(
        'Method `${method.name}` has multiple parameters annotated with `@Fragment`. '
        'Only one `@Fragment` parameter is allowed per method.',
        element: method,
      );
    }

    final fragment = fragments.firstOrNull?.element;

    final path = methodAnnotation.path;
    final query = createQuery(r'$uri', method, context);

    return [
      'Uri \$uri = #{{baseUrl}}.resolve(${modifyPath(path, method.formalParameters)});',
      if (query != null || fragment != null) ...[
        r'$uri = $uri.replace(', //
        if (query != null) 'queryParameters: $query,', //
        if (fragment != null) 'fragment: ${fragment.name},',
        ');',
      ],
    ].join('\n');
  }

  Iterable<String> _processRequest(DartType futureType) sync* {
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
      final name = context.addMethod(
        '#{{dart:async|FutureOr}}<${futureType.toCode()}>',
        '${method.name}Decode',
        [Parameter('#{{http|Response}}', 'response')],
      );
      yield 'return $name(\$response);';
    }
  }

  MapLiteral? allHeaders() {
    return MapLiteral()
      ..addLiteral(staticHeaders())
      ..addLiteral(parameterHeaders());
  }

  @protected
  MapLiteral? staticHeaders() {
    final readers = [
      ...Checker.headers.annotationsOf(method.enclosingElement!),
      ...Checker.headers.annotationsOf(method),
    ].map(ConstantReader.new).map(HeadersAnnotation.new);

    final staticValues = <DartObject, DartObject>{
      for (final reader in readers) ...reader.headers,
      ...methodAnnotation.headers,
    }.nonNulls;

    if (staticValues.isEmpty) return null;
    final literal = MapLiteral();

    for (final entry in staticValues.entries) {
      literal.addRaw(
        entry.key.toCode(addLeadingConst: false),
        entry.value.toCode(addLeadingConst: false),
      );
    }

    return literal;
  }

  @protected
  MapLiteral? parameterHeaders() {
    final headers = MapLiteral();

    final customHeaders = <FormalParameterElement>[];

    for (final (:annotation, :element) in Checker.header.annotatedOf(
      method.formalParameters,
    )) {
      if (!element.type.isA(Checker.string)) {
        customHeaders.add(element);
        continue;
      }
      final key = HeaderAnnotation(annotation).key ?? element.name!;
      final q = element.type.isNullableType ? '?' : '';
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

      final methodName = context.addMethod(
        '#{{dart:async|FutureOr}}<Map<String, String>>',
        '${method.name}Headers',
        customHeaders.map(Parameter.fromElement),
      );

      final call = customHeaders.map(
        (e) => e.isNamed ? '${e.name}: ${e.name}' : e.name!,
      );

      headers.addSpread('await $methodName(${call.join(', ')})');
    }

    return headers;
  }

  @protected
  String methodSignature(MethodElement method) {
    return '${method.returnType.toCode()} ${method.name}${typeParametersToCode(method.typeParameters)}(${method.formalParameters.toCode()})';
  }
}
