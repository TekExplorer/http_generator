part of '../generator.dart';

class Coding {
  static String decodeResponse(
    String response,
    DartType type,
    LibraryElement library,
    GenericFactories factories, [
    DartObject? jsonConverter,
  ]) {
    if (Checker.uint8List.isExactlyType(type)) return '$response.bodyBytes';
    if (type.isDartCoreString) return '$response.body';

    final json = '#{{dart:convert|jsonDecode}}($response.body)';
    return Coding().jsonDecoding(
      type,
      ConverterContext(json, factories, library),
      jsonConverter,
    );
  }

  // TODO: simplify
  static String bodyEncodable(
    DartType type,
    ConverterContext context,
    DartObject? jsonConverter,
  ) {
    if (jsonConverter != null) {
      return '${jsonConverter.toCode()}.toJson(${context.varName})';
    }
    return type.acceptWithArgument(JsonEncoderVisitor(), context);
  }

  String jsonDecoding(
    DartType type,
    ConverterContext context,
    DartObject? converter,
  ) {
    if (converter != null) {
      return '${converter.toCode()}.fromJson(${context.varName})';
    }
    return type.acceptWithArgument(JsonDecoderVisitor(), context);
  }

  String jsonEncoding(
    DartType type,
    ConverterContext context,
    DartObject? converter,
  ) {
    if (converter != null) {
      return '${converter.toCode()}.toJson(${context.varName})';
    }
    return type.acceptWithArgument(JsonEncoderVisitor(), context);
  }
}

Map<TypeParameterElement, String Function(ConverterContext)> decodingFactories(
  MethodElement method,
) {
  return <TypeParameterElement, String Function(ConverterContext)>{
    for (final tp in method.typeParameters)
      tp: (context) {
        // myFunc<@TConverter() T>()
        final converterAnnotation = Checker.jsonConverter.firstAnnotationOf(tp);
        if (converterAnnotation != null) {
          return '${converterAnnotation.toCode()}.fromJson(${context.varName})';
        }
        throw InvalidGenerationSourceError(
          'Generic type parameter `${tp.name}` must have a factory for deserialization. '
          'Either provide a `@JsonConverter` annotation or avoid using generic types.',
          element: tp,
        );
      },
  };
}
