part of '../generator.dart';

class RequestBody {
  RequestBody(this.method, this.addMethod);
  final MethodElement method;
  final void Function(String method) addMethod;

  static const encoded = '#{{http_annotation|BodyEncoded}}';

  @protected
  RequestType _requestTypeOf() {
    if (Checker.field.annotatedOf(method.formalParameters).isNotEmpty) {
      return RequestType.fields;
    }
    if (Checker.fields.annotatedOf(method.formalParameters).isNotEmpty) {
      return RequestType.fields;
    }
    if (Checker.body.annotatedOf(method.formalParameters).isNotEmpty) {
      return RequestType.body;
    }
    return RequestType.none;
  }

  String? buildEncoded() => switch (_requestTypeOf()) {
    RequestType.fields => _buildFields(),
    RequestType.multipart => _buildMultipart(),
    RequestType.body => _buildBody(),
    RequestType.none => null,
  };

  @protected
  String? _buildFields() =>
      '#{{http_annotation|EncodedFields}}.from(${_defineFieldsMap()})';

  @protected
  String? _buildMultipart() =>
      '#{{http_annotation|Encoded}}.multipart(${_defineMultipartMap()})';

  @protected
  // must return an Encoded
  String? _buildBody() {
    final bodyParameters = Checker.body.annotatedOf(method.formalParameters);
    if (bodyParameters.isEmpty) return null;

    if (bodyParameters.length > 1) {
      throw InvalidGenerationSourceError(
        'Method `${method.name}` has multiple parameters annotated with `@Body`. '
        'Only one `@Body` parameter is allowed per method.',
        element: method,
      );
    }

    final param = bodyParameters.single;

    final type = param.element.type;
    final name = param.element.name!;

    final bodyAnnotation = BodyAnnotation(param.annotation);
    final bodyType = bodyAnnotation.bodyType;

    String? buildCustom() {
      final methodName = '_${method.name}Encode';
      addMethod(
        '@#{{meta|protected}} #{{dart:async|FutureOr}}<$encoded> $methodName(${type.toCode()} $name);',
      );
      return 'await $methodName($name)';
    }

    // final isInferred = bodyType == null;
    switch (bodyType) {
      stream:
      case BodyType.stream:
        if (!Checker.implementsStreamListInt(type)) {
          log.warning(
            [
              'Type of `$name` is `${type.getDisplayString()}`, which is not a `Stream<List<int>>`.',
              'Please either change the parameter type to `Stream<List<int>>` or `Stream<Uint8List>`,'
                  ' or specify a custom decoder with `@Body(custom: true)` and implement the encoding logic yourself.',
            ].join('\n'),
          );
          return buildCustom();
        }
        return '$encoded.stream($name)';
      bytes:
      case BodyType.bytes:
        if (Checker.protoGeneratedMessage.isAssignableFromType(type)) {
          return '$encoded.bytes($name.writeToBuffer())';
        }
        if (!Checker.implementsListInt(type)) {
          log.warning(
            [
              'Type of `$name` is `${type.getDisplayString()}`, which is not a `List<int>` or `Uint8List`.',
              'Please either change the parameter type to `List<int>` or `Uint8List`,'
                  ' or specify a custom decoder with `@Body(custom: true)` and implement the encoding logic yourself.',
            ].join('\n'),
          );
          return buildCustom();
        }
        return '$encoded.bytes($name)';
      string:
      case BodyType.string:
        if (type.isDartCoreString ||
            Checker.string.isAssignableFromType(type)) {
          return '$encoded.string($name)';
        }
        if (Checker.protoGeneratedMessage.isAssignableFromType(type)) {
          log.warning(
            'Parameter `$name` is of type `${type.getDisplayString()}`, which is a protobuf message. '
            'Inferring string body encoding using `toTextFormat()`. If this is not what you intended, please specify the body type explicitly with `@Body.bytes()` or `@Body.json()` or implement a custom encoder with `@Body.custom()`.',
          );
          return '$encoded.string($name.toTextFormat())';
        }
        return '$encoded.string($name.toString())';
      json:
      case BodyType.json:
        if (Checker.protoGeneratedMessage.isAssignableFromType(type)) {
          return '$encoded.string($name.writeToJson())';
        }
        try {
          final bodyEncodable = Coding.bodyEncodable(
            type,
            ConverterContext(name, {
              for (final tp in method.typeParameters)
                tp: (context) {
                  // myFunc<@TConverter() T>()
                  final converterAnnotation = Checker.jsonConverter
                      .firstAnnotationOfExact(tp);
                  if (converterAnnotation != null) {
                    return '#{{dart:convert|jsonEncode}}(${converterAnnotation.toCode()}.toJson(${context.varName}))';
                  }
                  throw InvalidGenerationSourceError(
                    'Generic type parameter `${tp.name}` must have a factory for serialization. '
                    'Either provide a `@JsonConverter` annotation or avoid using generic types.',
                    element: tp,
                  );
                },
            }, method.library),
            Checker.jsonConverter.firstAnnotationOf(param.element),
          );
          return '$encoded.string(#{{dart:convert|jsonEncode}}($bodyEncodable))';
        } catch (e, s) {
          log.warning(
            'Failed to generate JSON encoding for parameter `$name` of type `${type.getDisplayString()}`. Falling back to custom encoding.',
            e,
            s,
          );
          return buildCustom();
        }

      case null:
        // inference!
        if (Checker.string.isAssignableFromType(type)) continue string;
        if (Checker.implementsStreamListInt(type)) continue stream;
        if (Checker.implementsListInt(type)) continue bytes;
        if (Checker.protoGeneratedMessage.isAssignableFromType(type)) {
          log.info(
            'Parameter `$name` is of type `${type.getDisplayString()}`, which is a protobuf message. '
            'Inferring body type as Bytes. If this is not what you intended, please specify the body type explicitly with `@Body.json()` or implement a custom encoder with `@Body.custom()`.',
          );
          continue bytes;
        }

        if (type is InterfaceType) {
          if (type.getMethod('toJson') != null) continue json;
          if (type.getMethod('toMap') != null) continue json;
        }
        // log.warning(
        //   [
        //     'Could not infer body encoding for parameter `$name` of type `${type.getDisplayString()}`.',
        //     'Please specify the body type explicitly with `Body.json()`, `Body.bytes()`, etc, or implement a custom encoder with `@Body(custom: true)`.',
        //   ].join('\n'),
        // );
        // return buildCustom();
        continue json;
    }
  }

  @protected
  String? _defineMultipartMap() {
    final lines = <String>[];

    final field = Checker.field.annotatedOf(method.formalParameters);
    for (final param in field) {
      final paramName = param.element.name!;
      final fieldName =
          param.annotation.read('name').nullOr?.stringValue ?? paramName;
      final useCustom = param.annotation.read('custom').boolValue;

      if (useCustom) {
        lines.add(
          "${escapeDartString(fieldName)}: throw UnimplementedError('Custom multipart encoding is not implemented for parameter `$paramName`. Please implement the encoding logic manually.')",
        );
        continue;
      }

      lines.add('${escapeDartString(fieldName)}: $paramName');
    }

    final fields = Checker.fields.annotatedOf(method.formalParameters);

    for (final param in fields) {
      final paramName = param.element.name!;
      final useCustom = param.annotation.read('custom').boolValue;

      if (useCustom) {
        lines.add(
          "throw UnimplementedError('Custom multipart encoding is not implemented for parameter `$paramName`. Please implement the encoding logic manually.')",
        );
        continue;
      }

      if (Checker.map.isAssignableFromType(param.element.type)) {
        // we assume it's a Map<String, String>
        lines.add('...$paramName');
        continue;
      }

      final encoded = Coding.bodyEncodable(
        param.element.type,
        ConverterContext(paramName, decodingFactories(method), method.library),
        Checker.jsonConverter.firstAnnotationOf(param.element),
      );

      lines.add('...$encoded');
    }

    return '{${lines.join(',\n')}}';
  }

  @protected
  /// returns a `Map<String, String>`
  String? _defineFieldsMap() {
    final formFieldParameters = Checker.field.annotatedOf(
      method.formalParameters,
    );
    final formFieldsParameters = Checker.fields.annotatedOf(
      method.formalParameters,
    );

    if (formFieldParameters.isEmpty && formFieldsParameters.isEmpty) {
      return null;
    }
    final lines = <String>[];
    for (final param in formFieldParameters) {
      final paramName = param.element.name!;
      final encoded = Coding.bodyEncodable(
        param.element.type,
        ConverterContext(paramName, decodingFactories(method), method.library),
        Checker.jsonConverter.firstAnnotationOf(param.element),
      );
      final fieldName = param.annotation.read('name').stringValue;
      lines.add('${escapeDartString(fieldName)}: $encoded');
    }
    for (final param in formFieldsParameters) {
      final type = param.element.type;
      if (type is! InterfaceType) {
        throw InvalidGenerationSourceError(
          'Parameter `${param.element.name}` annotated with `@FormFields` must be of type `Map<String, String>` or provide a `toJson` or `toMap` method that returns a `Map<String, String>` without arguments.',
          element: param.element,
        );
      }
      final paramName = param.element.name!;

      if (Checker.map.isAssignableFromType(type)) {
        lines.add('...$paramName');
      } else if (param.element.type case InterfaceType type) {
        final encoding = Coding.bodyEncodable(
          type,
          ConverterContext(
            paramName,
            decodingFactories(method),
            method.library,
          ),
          Checker.jsonConverter.firstAnnotationOf(param.element),
        );
        lines.add('...$encoding');
      } else {
        throw InvalidGenerationSourceError(
          'Parameter `${param.element.name}` annotated with `@FormFields` must be of type `Map<String, String>` or provide a `toJson` or `toMap` method that returns a `Map<String, String>` without arguments.',
          element: param.element,
        );
      }
    }
    return '{${lines.join(',\n')}}';
  }
}
