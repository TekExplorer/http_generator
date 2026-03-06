part of '../generator.dart';

class Coding {
  static String decodeResponse(String response, MethodElement method) {
    final library = method.library;
    final type = method.returnType.typeArgumentsOf(Checker.future)!.single;
    if (type is VoidType) return '';
    if (type is DynamicType) return response;

    if (Checker.uint8List.isExactlyType(type)) return '$response.bodyBytes';
    if (type.isDartCoreString) return '$response.body';

    final json = '#{{dart:convert|jsonDecode}}($response.body)';

    final jsonConverter = Checker.jsonConverter.firstAnnotationOf(method);
    if (jsonConverter != null) {
      return '${jsonConverter.toCode()}.fromJson($json)';
    }

    return type.acceptWithArgument(
      JsonDecoderVisitor(),
      ConverterContext(json, library, method.formalParameters),
    );
  }

  // // TODO: simplify
  // static String bodyEncodable(
  //   DartType type,
  //   ConverterContext context,
  //   DartObject? jsonConverter,
  // ) {
  //   if (jsonConverter != null) {
  //     return '${jsonConverter.toCode()}.toJson(${context.varName})';
  //   }
  //   return type.acceptWithArgument(JsonEncoderVisitor(), context);
  // }

  static String encodeToJson(FormalParameterElement element) {
    final jsonConverter = Checker.jsonConverter.firstAnnotationOf(element);
    if (jsonConverter != null) {
      return '${jsonConverter.toCode()}.toJson(${element.name!})';
    }
    final type = element.type;
    if (type.isA(Checker.string)) return element.name!;

    return type.acceptWithArgument(
      JsonEncoderVisitor(),
      ConverterContext(
        element.name!,
        element.library!,
        (element.enclosingElement as FunctionTypedElement).formalParameters,
      ),
    );
  }

  static MapLiteral encodeToMapStringString(
    FormalParameterElement element, {
    bool allowDynamic = false,
  }) {
    final jsonConverter = Checker.jsonConverter.firstAnnotationOf(element);
    if (jsonConverter != null) {
      return MapLiteral()
        ..addSpread('${jsonConverter.toCode()}.toJson(${element.name!})');
    }
    final type = element.type;

    if (type.isA(Checker.map, [Checker.string, Checker.string])) {
      return MapLiteral()..addSpread(element.name!);
    }

    return type.acceptWithArgument(
      MapStringStringEncoderVisitor(allowDynamic: allowDynamic),
      element,
    );
  }

  static String encodeToString(FormalParameterElement element) {
    final type = element.type;
    if (type.isA(Checker.string)) return element.name!;

    final jsonConverter = Checker.jsonConverter.firstAnnotationOf(element);
    if (jsonConverter != null) {
      return '${jsonConverter.toCode()}.toJson(${element.name!})';
    }

    return encodeTypeToString(
      type,
      element.name!,
      element.library!,
      (element.enclosingElement as FunctionTypedElement).formalParameters,
    );
  }

  static String encodeTypeToString(
    DartType type,
    String varName,
    LibraryElement library,
    Iterable<VariableElement> otherFields,
  ) {
    if (type.isA(Checker.string)) return varName;

    try {
      return type.acceptWithArgument(
        JsonEncoderVisitor(),
        ConverterContext(varName, library, otherFields),
      );
    } on InvalidGenerationSourceError {
      final q = type.nullabilitySuffix == .question ? '?' : '';
      return '$varName$q.toString()';
    }
  }
}

class MapStringStringEncoderVisitor
        //         A list of entries to be added to the map literal
        extends
        TypeVisitorWithArgument<MapLiteral, VariableElement> {
  MapStringStringEncoderVisitor({this.allowDynamic = false});
  final bool allowDynamic;

  @override
  visitInterfaceType(InterfaceType type, element) {
    final map = MapLiteral();

    final q = type.nullabilitySuffix == .question ? '?' : '';
    // Check for toJson or toMap method that returns Map<String, String>
    final encode = type.allMethods.where(
      (m) => {'toJson', 'toMap'}.contains(m.name),
    );

    for (final m in encode) {
      final args = <String>[];
      for (final p in m.formalParameters) {
        final type = p.type;
        if (type is! FunctionType) {
          throw InvalidGenerationSourceError(
            'Only function parameters are supported in `toJson` or `toMap` methods used for encoding query parameters. Parameter `${p.name}` in `${type.element?.name}.${m.name}` is of type `$type`.',
            element: p,
          );
        }
        args.add('(obj) => ${callToJsonOf('obj', type)}');
      }
      final arguments = args.join(', ');

      if (m.returnType.isA(Checker.map, [Checker.string, Checker.string])) {
        map.addSpread('${element.name!}$q.${m.name}($arguments)');
        return map;
      }

      if (m.returnType.isA(Checker.map, [Checker.string, null])) {
        final [_, valueType] = m.returnType.typeArgumentsOf(Checker.map)!;

        if (valueType.isA(Checker.string) || allowDynamic) {
          map.addSpread('${element.name!}$q.${m.name}($arguments)');
          return map;
        }

        final q2 = m.returnType.nullabilitySuffix == .question ? '?' : '';
        map.addSpread(
          '${element.name!}$q.${m.name}($arguments)$q2'
          '.map((k, v) => MapEntry(k, ${Coding.encodeTypeToString(valueType, 'v', element.library!, [])}))',
        );
        return map;
      }
    }

    throw InvalidGenerationSourceError(
      'Type `$type` cannot be converted to `Map<String, String>`. Please provide a `toJson` or `toMap` method that returns a `Map<String, String>` or `Map<String, dynamic>` without arguments, or mark it with @custom for custom serialization.',
      element: element,
    );
  }

  @override
  visitRecordType(RecordType type, element) {
    if (type.positionalFields.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Records with positional fields cannot be converted to `Map<String, String>`. Please convert it to a named record or a class, or mark it with @custom for custom serialization.',
        element: element,
      );
    }

    final map = MapLiteral();

    final q = type.nullabilitySuffix == .question ? '?' : '';
    for (final field in type.namedFields) {
      final fieldName = field.name;
      if (field.type.isA(Checker.string) || allowDynamic) {
        map.add(fieldName, '${element.name!}$q.$fieldName');
      } else {
        final q2 = field.type.nullabilitySuffix == .question ? '?' : '';
        map.add(fieldName, '${element.name!}$q.$fieldName$q2.toString()');
      }
    }

    return map;
  }

  @override
  visitTypeParameterType(TypeParameterType type, element) {
    try {
      if (type.bound case InterfaceType() || RecordType()) {
        return type.bound.acceptWithArgument(this, element);
      }
    } catch (e) {
      // If the bound cannot be resolved, we can't generate encoding logic for it.
    }

    throw InvalidGenerationSourceError(
      'Generic type parameters cannot be converted to `Map<String, String>` unless it has a bound that is an interface or record which trivially encodes. Please provide a bound with encoding logic, or mark it with @custom for custom serialization.',
      element: element,
    );
  }

  Never _throw(DartType type, VariableElement element) {
    throw InvalidGenerationSourceError(
      'Type `$type` cannot be used as a query parameter. Please provide a custom encoder by annotating the parameter with `@custom` and implementing the encoding logic yourself.',
      element: element,
    );
  }

  @override
  visitDynamicType(DynamicType type, element) {
    throw InvalidGenerationSourceError(
      'Dynamic type cannot be used as a query parameter without a custom encoder. Please provide a custom encoder by annotating the parameter with `@custom` and implementing the encoding logic yourself.',
      element: element,
    );
  }

  @override
  visitFunctionType(FunctionType type, element) => _throw(type, element);

  @override
  visitInvalidType(InvalidType type, element) => _throw(type, element);

  @override
  visitNeverType(NeverType type, element) => _throw(type, element);

  @override
  visitVoidType(VoidType type, element) => _throw(type, element);
}

String callToJsonOf(
  String name,
  FunctionType toJsonT, {
  String Function(String toJson, DartType returnType)? wrap,
}) {
  final object = toJsonT.formalParameters.singleOrNull;
  if (object == null) {
    throw InvalidGenerationSourceError(
      'The `toJson` or `toMap` method used for encoding query parameters must have exactly one parameter. Found ${toJsonT.formalParameters.length} parameters.',
      element: toJsonT.element,
    );
  }
  final returnType = toJsonT.returnType;

  return callToJson(name, object, returnType: returnType, wrap: wrap);
}

String callToJson(
  String name,
  FormalParameterElement object, {
  DartType? returnType,
  String Function(String toJson, DartType returnType)? wrap,
}) {
  String returns(String code, DartType returnType) {
    return wrap?.call(code, returnType) ?? code;
  }

  final objectType = object.type;

  if (returnType != null && objectType.isAssignableTo(returnType)) {
    return returns(name, returnType);
  }

  // see if other things work
  if (objectType is! InterfaceType) {
    throw InvalidGenerationSourceError(
      'The `toJson` or `toMap` method used for encoding query parameters must have a parameter that is assignable to its return type. Found parameter of type `$objectType` and return type `$returnType`.',
      element: object,
    );
  }

  final toJson = objectType.allMethods
      .where((c) => c.name == 'toJson' || c.name == 'toMap')
      .firstOrNull;
  if (toJson == null) {
    throw InvalidGenerationSourceError(
      'Type `${object.name}` cannot be converted to `Map<String, String>`. Please provide a `toJson` method that returns a `Map<String, String>` or `Map<String, dynamic>`, or mark it with @custom for custom serialization.',
      element: object,
    );
  }

  final args = <String>[];

  for (final p in toJson.formalParameters) {
    final type = p.type;
    if (type is! FunctionType) {
      throw InvalidGenerationSourceError(
        'Generic argument parameters in `toJson` or `toMap` methods used for encoding query parameters must be functions. Parameter `${p.name}` in `${object.name}.${toJson.name}` is of type `$type`.',
        element: p,
      );
    }

    // Dont wrap - this is an implementation detail of generic argument encoding
    args.add('(obj) => ${callToJsonOf('obj', type)}');
  }

  return returns(
    '$name.${toJson.name!}(${args.join(', ')})',
    toJson.returnType,
  );
}
