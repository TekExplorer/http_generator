import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer_buffer/analyzer_buffer.dart' show CodeFor2;
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../generate/map_literal.dart';
import 'coder_shared.dart';

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
      final listType = type.typeArguments.single;
      return '($varName as #{{dart:core|List}}).map((e) => ${nest(listType, 'e', argument)}).toList()';
    } else if (type.isDartCoreMap) {
      final [keyType, valueType] = type.typeArguments;
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
      final genericArgumentFactories = <String>[];
      if (type.typeArguments.isNotEmpty &&
          fromJson.formalParameters.length > 1) {
        final genericParams = fromJson.formalParameters.skip(1).toList();
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
      return '${type.toCode()}.${fromJson.name}($varName as ${fromJson.formalParameters.first.type.toCode()}, ${genericArgumentFactories.join(', ')})';
    }
  }

  @override
  String visitRecordType(RecordType type, ConverterContext argument) {
    if (type.positionalFields.isEmpty && type.namedFields.isEmpty) return '()';

    if (type.positionalFields.isNotEmpty && type.namedFields.isNotEmpty) {
      // TODO: deserialize maps that have numbers as keys into a mixed record?
      throw InvalidGenerationSourceError(
        'Records with both positional and named fields are not supported. Use a custom decoder instead.',
        element: type.element,
      );
    }
    final buffer = StringBuffer();
    for (final (index, field) in type.positionalFields.indexed) {
      buffer.write(
        // TODO: index may need adjusting by 1
        '${nest(field.type, '\$map[$index]', argument)}, ',
      );
    }
    for (final field in type.namedFields) {
      final fieldName = '\$map[${field.name.literal}]';
      buffer.write('${field.name}: ${nest(field.type, fieldName, argument)}, ');
    }

    return '''(){
      final \$map = ${argument.varName} as #{{dart:core|Map}};
      return ($buffer);
    }()''';
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
    final fromJsonT = argument.getFactory(type, 'fromJson');
    if (fromJsonT != null) {
      final nullable = type.nullabilitySuffix == .question;
      if (!nullable) return '${fromJsonT.name}(${argument.varName})';
      return '${argument.varName}?.call${fromJsonT.name}(${argument.varName}!)';
    }
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
