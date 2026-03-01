part of '../generator.dart';

class RequestBody {
  RequestBody(this.method, this.methodAnnotation, this.addMember);
  final MethodElement method;

  final MethodAnnotation methodAnnotation;

  bool get isMultipart {
    if (Checker.annotation('_Multipart').hasAnnotationOf(method)) return true;
    if (methodAnnotation.multipart == true) return true;
    return false;
  }

  final void Function(String method) addMember;

  static const encoded = '#{{http_annotation|BodyEncoded}}';

  @protected
  RequestType get _requestType {
    if (isMultipart) return RequestType.multipart;

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

  String? buildEncoded() => switch (_requestType) {
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
      'await #{{http_annotation|EncodedMultipart}}.build(${_defineMultipartBuilder()})';

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
      addMember(
        '@#{{meta|protected}} #{{dart:async|FutureOr}}<$encoded> $methodName(${type.toCode()} $name);',
      );
      return 'await $methodName($name)';
    }

    if (Checker.custom.hasAnnotationOf(param.element)) return buildCustom();

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
  String? _defineMultipartBuilder() {
    final lines = <String>[];
    const request = r'$request';

    final field = Checker.field.annotatedOf(method.formalParameters);

    final customParameters = <FormalParameterElement>[];

    for (final param in field) {
      final paramName = param.element.name!;
      final fieldName =
          param.annotation.read('name').nullOr?.stringValue ?? paramName;

      final paramType = param.element.type;

      final useCustom = Checker.custom.hasAnnotationOf(param.element);

      if (useCustom) {
        customParameters.add(param.element);
        continue;
      } else if (paramType.isA(Checker.string)) {
        lines.add(
          '$request.fields[${escapeDartString(fieldName)}] = $paramName;',
        );
      } else if (paramType.isA(
        .any([
          // .fromUrl('dart:io#File'),
          .fromUrl('dart:core#num'),
          .fromUrl('dart:core#bool'),
        ]),
      )) {
        final q = paramType.nullabilitySuffix == .question ? '?' : '';
        lines.add(
          '$request.fields[${escapeDartString(fieldName)}] = $paramName$q.toString();',
        );
      } else if (paramType.isA(Checker.filePart)) {
        lines.add(
          '$request.files[${escapeDartString(fieldName)}] = $paramName;',
        );
      } else if (paramType.isA(Checker.from('http#MultipartFile'))) {
        lines.add(
          '$request.files[${escapeDartString(fieldName)}] = .fromMultipartFile($paramName);',
        );
      } else {
        log.warning(
          'Parameter `${param.element.name}` has unsupported type `${paramType.getDisplayString()}` for multipart encoding. Please either change the parameter type to `String`, `num`, `bool`, `FilePart`, or `http.MultipartFile`, or specify a custom encoder with `@Field(custom: true)` and implement the encoding logic yourself.',
        );
        customParameters.add(param.element);
      }
    }

    final fields = Checker.fields.annotatedOf(method.formalParameters);

    for (final param in fields) {
      final paramName = param.element.name!;
      final paramType = param.element.type;

      final useCustom = Checker.custom.hasAnnotationOf(param.element);

      if (useCustom) {
        customParameters.add(param.element);
        continue;
      }

      if (paramType.isA(Checker.map)) {
        final [keyType, valueType] = paramType.typeArgumentsOf(Checker.map)!;
        if (!keyType.isA(Checker.string)) {
          throw InvalidGenerationSourceError(
            'Parameter `${param.element.name}` annotated with `@Fields()` must be of type `Map<String, String>`.',
            element: param.element,
          );
        }
        if (valueType.isA(Checker.string)) {
          // its a Map<String, String>
          lines.add('$request.fields.addAll($paramName);');
          continue;
        } else {
          lines.add('''
    for (final entry in $paramName.entries) {
      if (entry.value is null) continue;
      $request.fields[entry.key] = entry.value.toString();
    }
''');
          continue;
        }
      } else if (paramType is InterfaceType) {
        final toMapMethod =
            paramType.getMethod('toMap') ?? paramType.getMethod('toJson');

        if (toMapMethod == null) {
          throw InvalidGenerationSourceError(
            'Parameter `${param.element.name}` annotated with `@Fields()` must be of type `Map<String, String>` or provide a `toJson` or `toMap` method that returns a `Map<String, String>` without arguments.',
            element: param.element,
          );
        }

        final mapSource = '$paramName.${toMapMethod.name}()';

        if (toMapMethod.returnType.isA(Checker.map)) {
          final [keyType, valueType] = toMapMethod.returnType.typeArgumentsOf(
            Checker.map,
          )!;
          if (!keyType.isA(Checker.string) || !valueType.isA(Checker.string)) {
            throw InvalidGenerationSourceError(
              'The `toMap` or `toJson` method of parameter `${param.element.name}` annotated with `@Fields()` must return a `Map<String, String>`.',
              element: param.element,
            );
          }
          lines.add('$request.fields.addAll($mapSource);');
          continue;
        }

        // TODO: see if we want more types to work
        lines.add('''
    for (final entry in $mapSource.entries) {
      switch (entry.value) {
        case null:
          continue;
        case #{{http_annotation|FilePart}} value:
          $request.files[entry.key] = value;
        default:
          $request.fields[entry.key] = entry.value.toString();
      }
    }
''');
      }
    }

    if (customParameters.isNotEmpty) {
      final methodName = '_${method.name}BuildMultipart';

      addMember('''
@#{{meta|protected}} #{{dart:async|FutureOr}}<void> $methodName(#{{http_annotation|MultipartBuilder}} \$builder, ${customParameters.toCode()});
''');
      lines.add(
        'await $methodName($request, ${customParameters.toCallCode()});',
      );
    }

    return '($request) async {\n${lines.join('\n')}\n}';
  }

  @protected
  /// returns a `Map<String, String>`
  MapLiteral? _defineFieldsMap() {
    final formFieldParameters = Checker.field.annotatedOf(
      method.formalParameters,
    );
    final formFieldsParameters = Checker.fields.annotatedOf(
      method.formalParameters,
    );

    if (formFieldParameters.isEmpty && formFieldsParameters.isEmpty) {
      return null;
    }
    final map = MapLiteral();

    final customFields = <FormalParameterElement>[];

    for (final param in formFieldParameters) {
      final paramName = param.element.name!;

      String encoded;
      if (Checker.custom.hasAnnotationOf(param.element)) {
        customFields.add(param.element);
        continue;
      } else if (param.element.type.isA(Checker.string)) {
        encoded = paramName;
      } else {
        try {
          encoded = callToJson('$paramName?', param.element);
        } catch (e, s) {
          log.warning(
            'Failed to generate encoding for parameter `${param.element.name}` of type `${param.element.type.getDisplayString()}`. Falling back to custom encoding.',
            e,
            s,
          );
          encoded = '$paramName?.toString()';
        }
      }

      final fieldName =
          param.annotation.read('name').nullOr?.stringValue ?? paramName;
      map.add(fieldName, encoded);
    }
    for (final param in formFieldsParameters) {
      if (Checker.custom.hasAnnotationOf(param.element)) {
        customFields.add(param.element);
        continue;
      }
      map.addAll(Coding.encodeToMapStringString(param.element));
    }

    if (customFields.isNotEmpty) {
      final methodName = '_${method.name}EncodeFields';
      addMember(
        '@#{{meta|protected}} #{{dart:async|FutureOr}}<Map<String, String>> $methodName(${customFields.toCode()});',
      );
      map.addSpread('$methodName(${customFields.toCallCode()})');
    }

    return map;
  }
}
