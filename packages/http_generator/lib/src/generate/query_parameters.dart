part of '../generator.dart';

// bool hasQueryParameters(List<FormalParameterElement> formalParameters) {
//   final queryParameters = Checker.query.annotatedOf(formalParameters);
//   final queryAllParameters = Checker.queryAll.annotatedOf(formalParameters);
//   return queryParameters.isNotEmpty || queryAllParameters.isNotEmpty;
// }

String? createQuery(String uri, List<FormalParameterElement> formalParameters) {
  final queryParameters = Checker.query.annotatedOf(formalParameters);
  final queryAllParameters = Checker.queryAll.annotatedOf(formalParameters);

  if (queryParameters.isEmpty && queryAllParameters.isEmpty) {
    return null;
  }

  return '''{
    ...$uri.queryParametersAll,
    ${queryAllParameters.map((param) {
    if (param.element.type.isDartCoreMap) return '...${param.element.name!},';
    if (param.element.type case InterfaceType type) {
      // TODO: more robust query serialization
      final encode = type.allMethods.where((m) => m.name == 'toJson' || m.name == 'toMap');
      for (final m in encode) {
        if (m.returnType.isDartCoreMap && m.formalParameters.isEmpty) {
          return '...${param.element.name!}.${m.name}(),';
        }
      }
      // TODO: possibly allow arguments later
      throw InvalidGenerationSourceError('Parameter `${param.element.name}` annotated with `@QueryAll` must be of type `Map<String, dynamic>` or provide a `toJson` or `toMap` method that returns a `Map<String, dynamic>` without arguments.', element: param.element);
    }
  }).join('\n')}
    ${queryParameters.map((param) {
    final queryKey = param.annotation.read('name').stringValue;
    final paramName = param.element.name!;
    return '${escapeDartString(queryKey)}: $paramName,';
  }).join('\n')}
  }''';
}
