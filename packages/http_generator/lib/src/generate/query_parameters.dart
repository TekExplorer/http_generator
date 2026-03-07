part of '../generator.dart';

// bool hasQueryParameters(List<FormalParameterElement> formalParameters) {
//   final queryParameters = Checker.query.annotatedOf(formalParameters);
//   final queryAllParameters = Checker.queryAll.annotatedOf(formalParameters);
//   return queryParameters.isNotEmpty || queryAllParameters.isNotEmpty;
// }

MapLiteral? createQuery(
  String uri,
  FunctionTypedElement function,
  GeneratorContext context,
) {
  List<FormalParameterElement> formalParameters = function.formalParameters;

  final queryParameters = Checker.query.annotatedOf(formalParameters);
  final queryAllParameters = Checker.queryAll.annotatedOf(formalParameters);

  if (queryParameters.isEmpty && queryAllParameters.isEmpty) return null;

  final mapLiteral = MapLiteral();

  mapLiteral.addSpread('$uri.queryParametersAll');

  for (final param in queryAllParameters) {
    final paramName = param.element.name!;

    final isCustom = Checker.custom.hasAnnotationOf(param.element);

    if (isCustom) {
      throw UnimplementedError(
        'Custom query parameter serialization is not yet implemented. Parameter: `$paramName`',
      );
    }

    final encoded = Coding.encodeToMapStringString(
      param.element,
      allowDynamic: true,
    );

    if (encoded.isNotEmpty) {
      mapLiteral.addLiteral(encoded);
      continue;
    }

    throw InvalidGenerationSourceError(
      'Parameter `$paramName` annotated with `@Queries` must be of type `Map<String, dynamic>`, a record, or provide a `toJson` or `toMap` method that returns a `Map<String, dynamic>` without arguments, or mark it with @custom for custom serialization.',
      element: param.element,
    );
  }

  for (final param in queryParameters) {
    final paramName = param.element.name!;
    final type = param.element.type;

    final queryKey =
        param.annotation.read('name').nullOr?.stringValue ?? paramName;

    if (Checker.custom.hasAnnotationOf(param.element)) {
      final methodName = '${function.name}_${paramName}_encode';
      context.requestMethod(
        '#{{dart:async|FutureOr}}<String>',
        methodName,
        '${type.toCode()} $paramName',
      );
      mapLiteral.add(queryKey, 'await #{{extra}}$methodName($paramName)');
      continue;
    }

    if (type is DynamicType ||
        type.isA(Checker.string) ||
        type.isA(Checker.iterable, [Checker.string])) {
      mapLiteral.add(queryKey, paramName);
    } else if (type.isA(Checker.iterable)) {
      final elementType = type.typeArgumentsOf(Checker.iterable)!.single;
      final encode = Coding.encodeTypeToString(
        elementType,
        'e',
        param.element.library!,
        function.formalParameters,
      );
      final q = elementType.isNullableType ? '?' : '';
      mapLiteral.add(queryKey, '$paramName$q.map((e) => $encode)');
    } else {
      mapLiteral.add(queryKey, Coding.encodeToString(param.element));
    }
  }

  return mapLiteral;
}
