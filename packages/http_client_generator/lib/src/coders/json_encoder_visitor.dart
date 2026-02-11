import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'coder_shared.dart';

class JsonEncoderVisitor
    extends TypeVisitorWithArgument<String, ConverterContext> {
  String nest(DartType type, String varName, ConverterContext context) {
    return type.acceptWithArgument(this, context.withVar(varName));
  }

  @override
  String visitInterfaceType(InterfaceType type, ConverterContext argument) {
    final varName = argument.varName;
    // final factory = argument.factories[type]?.call(argument);
    // if (factory != null) return '$factory($varName)';
    if (type.isSerializableToJson) return varName;

    if (type.isDartCoreList) {
      final listType = type.typeArguments.first;
      // shortcut so we dont have unnecessary nesting
      if (listType is DynamicType) return varName;
      if (listType.isSerializableToJson) return varName;
      return '$varName.map((e) => ${nest(listType, 'e', argument)}).toList()';
    }
    if (type.isDartCoreMap) {
      final mapType = type.typeArguments;
      // final keyType = mapType[0];
      // if (!keyType.isDartCoreString) {
      //   throw InvalidGenerationSourceError('Only Map<String, V> is supported.');
      // }
      final valueType = mapType[1];
      // shortcut so we dont have unnecessary nesting
      if (valueType is DynamicType) return varName;
      if (valueType.isSerializableToJson) return varName;

      return '$varName.map((k, v) => MapEntry(k, ${nest(valueType, 'v', argument)}))';
    }

    final toJson = type.getMethod('toJson') ?? type.getMethod('toMap');

    if (toJson == null || toJson.isStatic) {
      throw InvalidGenerationSourceError(
        'Cannot generate code for type `${type.getDisplayString()}`. '
        'Provide a factory for serialization.',
        element: type.element,
      );
    }

    final genericArgumentFactories = <String>[];

    if (type.typeArguments.isNotEmpty && toJson.formalParameters.isNotEmpty) {
      final genericParams = toJson.formalParameters.toList();
      for (final (i, param) in genericParams.indexed) {
        final factoryType = param.type;
        if (factoryType is! FunctionType) {
          throw InvalidGenerationSourceError(
            'Generic argument factories must be function types.',
            element: param,
          );
        }
        genericArgumentFactories.add(
          '(object) => ${nest(type.typeArguments[i], 'object', argument)}',
        );
      }
    }
    return '$varName.${toJson.name}(${genericArgumentFactories.join(', ')})';
  }

  @override
  String visitRecordType(RecordType type, ConverterContext argument) {
    if (type.positionalFields.isEmpty && type.namedFields.isEmpty) {
      throw InvalidGenerationSourceError(
        'Empty records are not supported. Use a custom encoder instead.',
        element: type.element,
      );
      // return '()';
    }

    if (type.positionalFields.isNotEmpty && type.namedFields.isNotEmpty) {
      // TODO: serialize mixed records as a map?
      throw InvalidGenerationSourceError(
        'Records with both positional and named fields are not supported. Use a custom encoder instead.',
        element: type.element,
      );
    }

    final varName = argument.varName;
    if (type.positionalFields.isNotEmpty) {
      final buffer = <String>[];

      for (final (i, field) in type.positionalFields.indexed) {
        buffer.add(nest(field.type, '$varName.\$${i + 1}', argument));
      }
      return '[${buffer.join(', ')}]';
    }

    if (type.namedFields.isNotEmpty) {
      final buffer = <String>[];
      for (final field in type.namedFields) {
        buffer.add(
          '${escapeDartString(field.name)}: ${nest(field.type, '$varName.${field.name}', argument)}',
        );
      }
      return '{${buffer.join(', ')}}';
    }

    throw InvalidGenerationSourceError(
      'Unreachable code reached in record encoding.',
      element: type.element,
    );
  }

  @override
  String visitDynamicType(DynamicType type, ConverterContext argument) {
    return argument.varName;
  }

  @override
  String visitVoidType(VoidType type, ConverterContext argument) {
    return 'null';
  }

  @override
  String visitTypeParameterType(
    TypeParameterType type,
    ConverterContext argument,
  ) {
    final factory = argument.factories[type.element];
    if (factory != null) return factory(argument);

    throw InvalidGenerationSourceError(
      'Generic type parameter `${type.element.name}` must provide a factory for deserialization.',
      element: type.element,
    );
  }

  @override
  String visitFunctionType(FunctionType type, ConverterContext argument) {
    throw InvalidGenerationSourceError(
      'Function types are not supported.',
      element: type.element,
    );
  }

  @override
  String visitInvalidType(InvalidType type, ConverterContext argument) {
    throw InvalidGenerationSourceError(
      'Invalid type. Code generation cannot rely on generated code.',
      element: type.element,
    );
  }

  @override
  String visitNeverType(NeverType type, ConverterContext argument) {
    throw InvalidGenerationSourceError(
      'Never type is not supported.',
      element: type.element,
    );
  }
}

extension on DartType {
  bool get isSerializableToJson => _isSerializableToJson();

  bool _isSerializableToJson() =>
      isDartCoreString ||
      isDartCoreInt ||
      isDartCoreDouble ||
      isDartCoreBool ||
      isDartCoreNum ||
      _isObjectSerializableToJson();

  bool _isObjectSerializableToJson() {
    if (this is InterfaceType) {
      final type = this as InterfaceType;
      final toJson = type.getMethod('toJson');
      return toJson != null &&
          !toJson.isStatic &&
          toJson.formalParameters.isEmpty;
    }
    return false;
  }
}
