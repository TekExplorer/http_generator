part of '../generator.dart';

class Coding {
  static String decodeResponse(
    String response,
    DartType type,
    LibraryElement library,
    GenericFactories factories, [
    DartObject? jsonConverter,
  ]) {
    if (type is VoidType) return '';
    if (type is DynamicType) return response;

    if (Checker.uint8List.isExactlyType(type)) return '$response.bodyBytes';
    if (type.isDartCoreString) return '$response.body';

    final json = '#{{dart:convert|jsonDecode}}($response.body)';

    if (jsonConverter != null) {
      return '${jsonConverter.toCode()}.fromJson($json)';
    }

    return type.acceptWithArgument(
      JsonDecoderVisitor(),
      ConverterContext(json, factories, library),
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

  static Iterable<MapLiteralEntry> encodeToMapStringString(
    VariableElement variable, {
    bool allowDynamic = false,
  }) {
    final jsonConverter = Checker.jsonConverter.firstAnnotationOf(variable);
    if (jsonConverter != null) {
      return [.spread('${jsonConverter.toCode()}.toJson(${variable.name!})')];
    }
    final type = variable.type;

    if (type.isA(Checker.map, [Checker.string, Checker.string])) {
      return [.spread(variable.name!)];
    }

    return type.acceptWithArgument(
      MapStringStringEncoderVisitor(allowDynamic: allowDynamic),
      variable,
    );
  }
}

class MapStringStringEncoderVisitor
        //         A list of entries to be added to the map literal
        extends
        TypeVisitorWithArgument<Iterable<MapLiteralEntry>, VariableElement> {
  MapStringStringEncoderVisitor({this.allowDynamic = false});
  final bool allowDynamic;

  @override
  visitInterfaceType(InterfaceType type, element) sync* {
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
        yield .spread('${element.name!}?.${m.name}($arguments)');
        return;
      }

      if (m.returnType.isA(Checker.map, [Checker.string, null])) {
        final [_, valueType] = m.returnType.typeArgumentsOf(Checker.map)!;

        if (valueType.isA(Checker.string) || allowDynamic) {
          yield .spread('${element.name!}?.${m.name}($arguments)');
          return;
        }

        yield .spread(
          '${element.name!}?.${m.name}($arguments)?.map((k, v) => MapEntry(k, v.toString()))',
        );
        return;
      }
    }

    throw InvalidGenerationSourceError(
      'Type `$type` cannot be converted to `Map<String, String>`. Please provide a `toJson` or `toMap` method that returns a `Map<String, String>` or `Map<String, dynamic>` without arguments, or mark it with @custom for custom serialization.',
      element: element,
    );
  }

  @override
  visitRecordType(RecordType type, element) sync* {
    if (type.positionalFields.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Records with positional fields cannot be converted to `Map<String, String>`. Please convert it to a named record or a class, or mark it with @custom for custom serialization.',
        element: element,
      );
    }
    for (final field in type.namedFields) {
      final fieldName = field.name;
      if (field.type.isA(Checker.string) || allowDynamic) {
        yield .kv(fieldName, '${element.name!}?.$fieldName');
      } else {
        yield .kv(fieldName, '${element.name!}?.$fieldName?.toString()');
      }
    }
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

String callToJsonOf(String name, FunctionType toJsonT) {
  final argument = toJsonT.formalParameters.singleOrNull;
  if (argument == null) {
    throw InvalidGenerationSourceError(
      'The `toJson` or `toMap` method used for encoding query parameters must have exactly one parameter. Found ${toJsonT.formalParameters.length} parameters.',
      element: toJsonT.element,
    );
  }
  final returnType = toJsonT.returnType;

  return callToJson(name, argument, returnType);
}

String callToJson(
  String name,
  FormalParameterElement argument, [
  DartType? returnType,
]) {
  final argumentType = argument.type;

  if (returnType != null && argumentType.isAssignableTo(returnType)) {
    return name;
  }

  // see if other things work
  if (argumentType is! InterfaceType) {
    throw InvalidGenerationSourceError(
      'The `toJson` or `toMap` method used for encoding query parameters must have a parameter that is assignable to its return type. Found parameter of type `$argumentType` and return type `$returnType`.',
      element: argument,
    );
  }

  final toJson = argumentType.allMethods
      .where((c) => c.name == 'toJson' || c.name == 'toMap')
      .firstOrNull;
  if (toJson == null) {
    throw InvalidGenerationSourceError(
      'Type `${argument.name}` cannot be converted to `Map<String, String>`. Please provide a `toJson` method that returns a `Map<String, String>` or `Map<String, dynamic>`, or mark it with @custom for custom serialization.',
      element: argument,
    );
  }

  if (toJson.formalParameters.where((p) => p.isRequired).isEmpty) {
    return '$name.${toJson.name!}()';
  }

  final args = <String>[];

  for (final p in toJson.formalParameters) {
    final type = p.type;
    if (type is! FunctionType) {
      throw InvalidGenerationSourceError(
        'Only function parameters are supported in `toJson` methods used for encoding query parameters. Parameter `${p.name}` in `${type.element?.name}.${toJson.name}` is of type `$type`.',
        element: p,
      );
    }

    args.add('(obj) => ${callToJsonOf('obj', type)}');
  }

  return '$name.${toJson.name!}(${args.join(', ')})';
}
