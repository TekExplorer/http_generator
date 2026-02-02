import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer_buffer/analyzer_buffer.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

typedef GenericFactories =
    Map<TypeParameterElement, String Function(ConverterContext)>;
typedef Factories = Map<DartType, String Function(ConverterContext)>;

class ConverterContext {
  ConverterContext(this.varName, this.factories);

  final String varName;
  final GenericFactories factories;
  ConverterContext withVar(String newVarName) {
    return ConverterContext(newVarName, factories);
  }
}

class JsonDecoderVisitor
    extends TypeVisitorWithArgument<String, ConverterContext> {
  String nest(DartType type, String varName, ConverterContext context) {
    return type.acceptWithArgument(this, context.withVar(varName));
  }

  @override
  String visitInterfaceType(InterfaceType type, ConverterContext argument) {
    final varName = argument.varName;
    // final factory = argument.factories[type]?.call(argument);
    // if (factory != null) return '$factory($varName)';

    if (type.isDartCoreString) {
      return '$varName as #{{dart:core|String}}';
    } else if (type.isDartCoreInt) {
      return '$varName as #{{dart:core|int}}';
    } else if (type.isDartCoreDouble) {
      return '$varName as #{{dart:core|double}}';
    } else if (type.isDartCoreBool) {
      return '$varName as #{{dart:core|bool}}';
    } else if (type.isDartCoreList) {
      final listType = type.typeArguments.first;
      return '($varName as #{{dart:core|List}}).map((e) => ${nest(listType, 'e', argument)}).toList()';
    } else if (type.isDartCoreMap) {
      final mapType = type.typeArguments;
      final keyType = mapType[0];
      final valueType = mapType[1];
      if (!keyType.isDartCoreString) {
        throw InvalidGenerationSourceError('Only Map<String, V> is supported.');
      }
      return '($varName as #{{dart:core|Map}}).map((k, v) => MapEntry(k as #{{dart:core|String}}, ${nest(valueType, 'v', argument)}))';
    } else {
      final fromJsonConstructor = type.element.constructors.firstWhereOrNull(
        (c) => c.name == 'fromJson' || c.name == 'fromMap',
      );
      final fromJsonMethod =
          type.getMethod('fromJson') ?? type.getMethod('fromMap');

      if (fromJsonConstructor == null &&
          (fromJsonMethod == null || !fromJsonMethod.isStatic)) {
        throw InvalidGenerationSourceError(
          'Cannot generate code for type `${type.getDisplayString()}`. '
          'Provide a factory for deserialization.',
          element: type.element,
        );
      }
      final fromJson = fromJsonConstructor ?? fromJsonMethod;
      if (fromJson == null) {
        throw InvalidGenerationSourceError(
          'Cannot generate code for type `${type.getDisplayString()}`. ',
          element: fromJson,
        );
      }
      final genericArgumentFactories = StringBuffer();
      if (type.typeArguments.isNotEmpty &&
          fromJson.formalParameters.length > 1) {
        final genericParams = fromJson.formalParameters.skip(1).toList();
        for (final param in genericParams) {
          final name = param.name;
          final factoryType = param.type;
          if (factoryType is! FunctionType) {
            throw InvalidGenerationSourceError(
              'Generic argument factories must be function types.',
              element: param,
            );
          }
          genericArgumentFactories.write(', $name($varName)');
        }
      }
      return '${type.toCode()}.${fromJson.name}($varName as ${fromJson.formalParameters.first.type.toCode()}$genericArgumentFactories)';
    }
  }

  @override
  String visitRecordType(RecordType type, ConverterContext argument) {
    if (type.positionalFields.isEmpty && type.namedFields.isEmpty) {
      return '()';
    } else if (type.positionalFields.isNotEmpty &&
        type.namedFields.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Records with both positional and named fields are not supported. Use a custom decoder instead.',
        element: type.element,
      );
    }
    final varName = argument.varName;
    final buffer = StringBuffer();
    for (final (index, field) in type.positionalFields.indexed) {
      buffer.write(
        // TODO: index may need adjusting by 1
        '${field.type.acceptWithArgument(this, '$varName[\$$index]')}, ',
      );
    }
    for (final field in type.namedFields) {
      buffer.write(
        '${field.name}: ${field.type.acceptWithArgument(this, "$varName['${field.name}']")}, ',
      );
    }
    return '($buffer)';
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
      'Generic type parameters must provide a factory for deserialization.',
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
