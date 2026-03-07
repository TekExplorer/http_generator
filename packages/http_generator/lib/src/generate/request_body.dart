part of '../generator.dart';

class RequestBody {
  RequestBody(this.method, this.methodAnnotation, this.context);
  final MethodElement method;
  final MethodAnnotation methodAnnotation;
  final GeneratorContext context;

  bool get isMultipart {
    if (Checker.annotation('_Multipart').hasAnnotationOf(method)) return true;
    if (methodAnnotation.multipart == true) return true;
    return false;
  }

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

  static const encoded = '#{{http_annotation|BodyEncoded}}';

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

    // short-circuit for already encoded bodies
    if (type.isA(Checker.annotation('Encoded'))) return name;

    final bodyAnnotation = BodyAnnotation(param.annotation);
    final bodyType = bodyAnnotation.bodyType;

    String? buildCustom() {
      final methodName = context.addMethod(
        '#{{dart:async|FutureOr}}<String>',
        '${method.name}Encode',
        [Parameter(type.toCode(), name)],
      );

      return 'await $methodName($name)';
    }

    if (Checker.custom.hasAnnotationOf(param.element)) return buildCustom();

    switch (bodyType) {
      stream:
      case BodyType.stream:
        if (!type.isAStreamListInt) {
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
        if (type.isA(Checker.protoGeneratedMessage)) {
          return '$encoded.bytes($name.writeToBuffer())';
        }
        if (!type.isAListInt) {
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
        if (type.isA(Checker.string)) {
          return '$encoded.string($name)';
        }
        if (type.isA(Checker.protoGeneratedMessage)) {
          log.warning(
            'Parameter `$name` is of type `${type.getDisplayString()}`, which is a protobuf message. '
            'Inferring string body encoding using `toTextFormat()`. If this is not what you intended, please specify the body type explicitly with `@Body.bytes()` or `@Body.json()` or implement a custom encoder with `@Body.custom()`.',
          );
          return '$encoded.string($name.toTextFormat())';
        }
        return '$encoded.string($name.toString())';
      json:
      case BodyType.json:
        if (type.isA(Checker.protoGeneratedMessage)) {
          return '$encoded.string($name.writeToJson())';
        }
        try {
          final bodyEncodable = Coding.encodeToJson(param.element);
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
        if (type.isA(Checker.string)) continue string;
        if (type.isAStreamListInt) continue stream;
        if (type.isAListInt) continue bytes;
        if (type.isA(Checker.protoGeneratedMessage)) {
          log.info(
            'Parameter `$name` is of type `${type.getDisplayString()}`, which is a protobuf message. '
            'Inferring body type as Bytes. If this is not what you intended, please specify the body type explicitly with `@Body.json()` or implement a custom encoder with `@Body.custom()`.',
          );
          continue bytes;
        }

        if (type is InterfaceType) {
          final toJson =
              type.lookUpMethod('toJson', context.library) ??
              type.lookUpMethod('toMap', context.library);

          if (toJson != null) continue json;
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

    final customFieldParameters = <FormalParameterElement>[];

    for (final param in field) {
      final paramName = param.element.name!;
      final fieldName =
          param.annotation.read('name').nullOr?.stringValue ?? paramName;

      final paramType = param.element.type;

      final useCustom = Checker.custom.hasAnnotationOf(param.element);

      if (useCustom) {
        customFieldParameters.add(param.element);
        continue;
      }

      String? line;

      final fieldNameLiteral = fieldName.literal;

      if (paramType.isA(Checker.string)) {
        lines.add('$request.fields[$fieldNameLiteral] = $paramName;');
      } else if (paramType.isA(
        .any([.fromUrl('dart:core#num'), .fromUrl('dart:core#bool')]),
      )) {
        line = '$request.fields[$fieldNameLiteral] = $paramName.toString();';
      } else if (paramType.isA(Checker.filePart)) {
        line = '$request.files[$fieldNameLiteral] = $paramName;';
      } else if (paramType.isA(Checker.from('dart:io#File'))) {
        line =
            '$request.files[$fieldNameLiteral] = await .fromPath($paramName.path);';
      } else if (paramType.isA(Checker.from('http#MultipartFile'))) {
        line =
            '$request.files[$fieldNameLiteral] = .fromMultipartFile($paramName);';
      } else {
        log.warning(
          'Parameter `${param.element.name}` has unsupported type `${paramType.getDisplayString()}` for multipart encoding. Please either change the parameter type to `String`, `num`, `bool`, `FilePart`, or `http.MultipartFile`, or specify a custom encoder with `@Field(custom: true)` and implement the encoding logic yourself.',
        );
        customFieldParameters.add(param.element);
      }
      if (line != null) {
        if (paramType.isNullableType) {
          line = 'if ($paramName != null) {$line}';
        }
        lines.add(line);
      }
    }

    final fields = Checker.fields.annotatedOf(method.formalParameters);
    final customFieldsParameters = <FormalParameterElement>[];

    for (final param in fields) {
      final paramName = param.element.name!;
      final paramType = param.element.type;

      final useCustom = Checker.custom.hasAnnotationOf(param.element);

      if (useCustom) {
        customFieldsParameters.add(param.element);
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
            paramType.lookUpMethod('toMap', context.library) ??
            paramType.lookUpMethod('toJson', context.library);

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

    final customParameters = customFieldParameters.followedBy(
      customFieldsParameters,
    );
    // for (final param in customParameters) {
    //   final methodName = '${method.name}_${param.name}';
    //   context.requestMethod(
    //     '#{{dart:async|FutureOr}}<void>',
    //     methodName,
    //     '(${param.type.toCode()} ${param.name})',
    //   );
    //   lines.add('await #{{extra}}$methodName(${param.name});');
    // }

    if (customParameters.isNotEmpty) {
      final methodName = context.addMethod(
        '#{{dart:async|FutureOr}}<void>',
        '${method.name}BuildMultipart',
        [
          Parameter('#{{http_annotation|MultipartBuilder}}', r'$builder'),
          ...customParameters.map(Parameter.fromElement),
        ],
      );
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
      if (Checker.custom.hasAnnotationOf(param.element)) {
        customFields.add(param.element);
        continue;
      }

      final paramName = param.element.name!;
      final fieldName =
          param.annotation.read('name').nullOr?.stringValue ?? paramName;

      map.add(fieldName, Coding.encodeToString(param.element));
    }
    for (final param in formFieldsParameters) {
      if (Checker.custom.hasAnnotationOf(param.element)) {
        customFields.add(param.element);
        continue;
      }
      map.addLiteral(Coding.encodeToMapStringString(param.element));
    }

    if (customFields.isNotEmpty) {
      final methodName = context.addMethod(
        '#{{dart:async|FutureOr}}<Map<String, String>>',
        '${method.name}EncodeFields',
        customFields.map(Parameter.fromElement),
      );

      map.addSpread('$methodName(${customFields.toCallCode()})');
    }

    return map;
  }
}
