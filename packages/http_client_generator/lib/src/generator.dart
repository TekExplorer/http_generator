import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_buffer/analyzer_buffer.dart';
import 'package:build/build.dart';
import 'package:http_client_annotation/http_client_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'json_decoder_visitor.dart';

class HttpClientGenerator extends GeneratorForAnnotation<RestClient> {
  HttpClientGenerator() : super(inPackage: 'http_client_annotation');
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Generator cannot target `${element.name}`. '
        '`@RestClient` can only be applied to classes.',
        element: element,
      );
    }

    final buffer = AnalyzerBuffer.part2(
      element.library,
      header: '// ignore_for_file: type=lint, type=warning\n',
    );
    final baseUrl = annotation.peek('baseUrl')?.stringValue;
    final className = '_${element.name}';
    String buildConstructor() {
      final constructor = element.getNamedConstructor('_');
      if (constructor == null || constructor.isFactory) return '$className()';

      final formals = constructor.formalParameters.toCode(Formal.superFormal);
      return '$className($formals) : super._()';
    }

    buffer.write('''
mixin _\$${element.name} {
  @#{{meta|protected}}
  Future<#{{http|StreamedResponse}}> \$send(#{{http|BaseRequest}} request) async {
    final client = #{{http|Client}}();
    try {
      return await client.send(request);
    } finally {
      client.close();
    }
  }
  String get baseUrl${baseUrl != null ? " => ${escapeDartString(baseUrl)}" : ''};
  Uri get baseUri => Uri.parse(baseUrl);
}

class $className extends ${element.name} {
  ${buildConstructor()};

${element.methods.map(methodImpl).join('\n')}
}
''');

    return buffer.toString();
  }

  static const methodTypeChecker = TypeChecker.typeNamed(Method);

  String methodImpl(MethodElement method) {
    final methodAnnotation = methodTypeChecker.firstAnnotationOfExact(method);
    if (methodAnnotation == null) {
      return '';
    }
    final returnType = method.returnType;
    if (!returnType.isDartAsyncFuture) {
      throw InvalidGenerationSourceError(
        'Return type of `${method.name}` must be a Future.',
        element: method,
      );
    }
    final futureType = (returnType as InterfaceType).typeArguments.first;
    assert(
      futureType is InterfaceType ||
          futureType is RecordType ||
          futureType is DynamicType ||
          futureType is VoidType,
    );

    final methodReader = ConstantReader(methodAnnotation);
    final httpMethod = methodReader.peek('method')?.stringValue;
    final path = methodReader.peek('path')?.stringValue;
    if (httpMethod == null || path == null) {
      throw InvalidGenerationSourceError(
        'Method `${method.name}` has invalid `@Method` annotation.',
        element: method,
      );
    }
    final jsonConverter = const TypeChecker.fromUrl(
      'package:json_serializer_annotation/json_serializer_annotation.dart#JsonConverter',
    );
    String factoryForTypeParameter(
      TypeParameterElement tp,
      ConverterContext context,
    ) {
      // myFunc<@TConverter() T>()
      final converterAnnotation = jsonConverter.firstAnnotationOfExact(tp);
      if (converterAnnotation != null) {
        return '${converterAnnotation.toCode()}.fromJson(${context.varName})';
      }
      throw InvalidGenerationSourceError(
        'Generic type parameter `${tp.name}` must have a factory for deserialization. '
        'Either provide a `@JsonConverter` annotation or avoid using generic types.',
        element: tp,
      );
    }

    final factories = <TypeParameterElement, String Function(ConverterContext)>{
      for (final tp in method.typeParameters)
        tp: (context) => factoryForTypeParameter(tp, context),
    };
    final converter = switch (futureType.element) {
      final element? => jsonConverter.firstAnnotationOf(element),
      null => null,
    };
    return '''
  ${methodSignature(method)} {
    final request = #{{http|Request}}('$httpMethod', baseUri.resolve(${escapeDartString(path)}));
    return \$send(request).then(#{{http|Response}}.fromStream).then((response) {
      ${futureType is VoidType ? 'return;' : 'return ${responseDecoding(futureType, factories, converter)};'}
    });
  }
''';
  }

  String methodSignature(MethodElement method) {
    return '${method.returnType.toCode()} ${method.name}${typeParametersToCode(method.typeParameters)}(${method.formalParameters.toCode()})';
  }

  String typeParametersToCode(List<TypeParameterElement> typeParameters) {
    if (typeParameters.isEmpty) return '';
    return '<${typeParameters.map((tp) {
      final bound = tp.bound != null ? ' extends ${tp.bound!.toCode()}' : '';
      return '${tp.name}$bound';
    }).join(', ')}>';
  }

  final responseTypeChecker = TypeChecker.fromUrl(
    'package:http/src/response.dart#Response',
  );
  final uint8ListTypeChecker = TypeChecker.fromUrl('dart:typed_data#Uint8List');
  String responseDecoding(
    DartType type,
    GenericFactories factories,
    DartObject? converter,
  ) {
    if (responseTypeChecker.isExactlyType(type)) return 'response';
    if (uint8ListTypeChecker.isExactlyType(type)) return 'response.bodyBytes';
    if (type.isDartCoreString) return 'response.body';

    final json = '#{{dart:convert|jsonDecode}}(response.body)';
    return jsonDecoding(type, ConverterContext(json, factories), converter);
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
}

extension on List<FormalParameterElement> {
  String toCode([Formal? formal]) {
    final required = where(
      (p) => p.isRequiredPositional,
    ).map((p) => '${p.toCode(formal)},').join(' ');
    final optional = where(
      (p) => p.isOptionalPositional,
    ).map((p) => p.toCode(formal)).join(', ');
    final named = where(
      (p) => p.isNamed,
    ).map((p) => p.toCode(formal)).join(', ');

    final buffer = StringBuffer();
    buffer.write(required);
    if (optional.isNotEmpty) {
      buffer.write('[$optional]');
    }
    if (named.isNotEmpty) {
      buffer.write('{$named}');
    }
    return buffer.toString();
  }
}

enum Formal { superFormal, initializingFormal, none }

extension on FormalParameterElement {
  String toCode([Formal? formal]) {
    final buffer = StringBuffer();
    if (isRequiredNamed) buffer.write('required ');
    if (isCovariant) buffer.write('covariant ');
    buffer.write('${type.toCode()} ');

    if (formal == Formal.superFormal || (formal == null && isSuperFormal)) {
      buffer.write('super.');
    } else if (formal == Formal.initializingFormal ||
        (formal == null && isInitializingFormal)) {
      buffer.write('this.');
    }

    buffer.write('$name');
    if (defaultValueCode case final defaultValue?) {
      buffer.write(' = $defaultValue');
    }
    return buffer.toString();
  }
}
