part of '../generator.dart';

class GenerateForMethod {
  GenerateForMethod(this.method, this.addMethod);
  final MethodElement method;

  final void Function(String method) addMethod;

  void build() {
    final impl = methodImpl(method);
    if (impl != null) addMethod(impl);
  }

  @protected
  String? methodImpl(MethodElement method) {
    final methodAnnotation = Checker.method.firstAnnotationOf(method);
    if (methodAnnotation == null) return null;

    final returnType = method.returnType;
    if (!returnType.isDartAsyncFuture) {
      throw InvalidGenerationSourceError(
        'Return type of `${method.name}` must be a Future.',
        element: method,
      );
    }

    final methodReader = MethodAnnotation(ConstantReader(methodAnnotation));
    final httpMethod = methodReader.method;
    final path = methodReader.path;

    final futureType = (returnType as InterfaceType).typeArguments.first;

    if (futureType is! InterfaceType &&
        futureType is! RecordType &&
        futureType is! DynamicType &&
        futureType is! VoidType) {
      throw InvalidGenerationSourceError(
        'Return type of `${method.name}` must be a Future<void|dynamic|interface|record>',
        element: method,
      );
    }

    final fragments = Checker.fragment.annotatedOf(method.formalParameters);
    if (fragments.isNotEmpty && fragments.length > 1) {
      throw InvalidGenerationSourceError(
        'Method `${method.name}` has multiple parameters annotated with `@Fragment`. '
        'Only one `@Fragment` parameter is allowed per method.',
        element: method,
      );
    }
    final fragment = fragments.firstOrNull;
    final query = createQuery(r'$uri', method.formalParameters);

    final body = RequestBody(method, addMethod);

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
    final \$request = await #{{http_annotation|createRequest2}}(${[
      escapeDartString(httpMethod),
      '\$uri',
      if (abortTrigger(method) case final trigger?) 'abortTrigger: $trigger', //
      if (body.buildEncoded() case final body?) 'body: $body', //
      if (methodReader.headersCode case final headers?) 'headers: $headers',
    ].join(',\n')});

    return ${() sync* {
      yield r'$send($request)';
      if (Checker.streamedResponse.isExactlyType(futureType)) return;
      yield '.then(#{{http|Response}}.fromStream)';
      if (Checker.response.isAssignableFromType(futureType) || futureType is VoidType) return;
      yield '.then((response) => ${Coding.decodeResponse('response', futureType, method.library, decodingFactories(method))})';
    }().join('\n')};
  }
''';
  }

  @protected
  String methodSignature(MethodElement method) {
    return '${method.returnType.toCode()} ${method.name}${typeParametersToCode(method.typeParameters)}(${method.formalParameters.toCode()})';
  }
}
