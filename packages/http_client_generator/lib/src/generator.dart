import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_buffer/analyzer_buffer.dart';
import 'package:build/build.dart';
import 'package:http_client_annotation/http_client_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'coders/coder_shared.dart';
import 'coders/json_decoder_visitor.dart';
import 'coders/json_encoder_visitor.dart';
import 'type_checker/checkers.dart';

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

    final buffer = AnalyzerBuffer.part(
      element.library,
      header: '// ignore_for_file: type=lint, type=warning\n',
    );
    final baseUrl = annotation.peek('baseUrl')?.stringValue;

    buffer.write('''
mixin _\$${element.name} {
  @#{{meta|protected}}
  Future<#{{http|StreamedResponse}}> \$send(#{{http|BaseRequest}} request) {
    return request.send();
  }
  String get baseUrl${baseUrl != null ? " => ${escapeDartString(baseUrl)}" : ''};
  Uri get baseUri => Uri.parse(baseUrl);

${element.methods.map(methodImpl).join('\n')}
}
''');

    return buffer.toString();
  }

  String methodImpl(MethodElement method) {
    final methodAnnotation = Checker.method.firstAnnotationOf(method);
    if (methodAnnotation == null) return '';

    final returnType = method.returnType;
    if (!returnType.isDartAsyncFuture) {
      throw InvalidGenerationSourceError(
        'Return type of `${method.name}` must be a Future.',
        element: method,
      );
    }

    final methodReader = MethodAnnotation(ConstantReader(methodAnnotation));
    final httpMethod = methodReader.method;
    final path = methodReader.path;

    final futureType = (returnType as InterfaceType).typeArguments.first;

    if (futureType is! InterfaceType &&
        futureType is! RecordType &&
        futureType is! DynamicType &&
        futureType is! VoidType) {
      throw InvalidGenerationSourceError(
        'Return type of `${method.name}` must be a Future<void|dynamic|interface|record>',
        element: method,
      );
    }
    final hasQuery = hasQueryParameters(method.formalParameters);

    final fragments = Checker.fragment.annotatedOf(method.formalParameters);
    if (fragments.isNotEmpty && fragments.length > 1) {
      throw InvalidGenerationSourceError(
        'Method `${method.name}` has multiple parameters annotated with `@Fragment`. '
        'Only one `@Fragment` parameter is allowed per method.',
        element: method,
      );
    }
    final fragment = fragments.firstOrNull;

    final fields = defineFieldsMap(method);

    final isMultipart =
        methodReader.multipart == true ||
        Checker.field.annotatedOf(method.formalParameters).any((param) {
          final type = param.element.type;
          if (Checker.validFile.isAssignableFromType(type)) return true;
          return false;
        });

    return '''
  ${methodSignature(method)} async {
    ${[
      'Uri \$uri = baseUri.resolve(${modifyPath(path, method.formalParameters)});',
      if (hasQuery || fragment != null) [
          '\$uri = \$uri.replace(', //
          if (hasQuery) 'queryParameters: ${createQuery('\$uri', method.formalParameters)},', //
          if (fragment != null) 'fragment: ${fragment.element.name},',
          ');',
        ].join('\n'),
    ].join('\n')}
    final \$request = await #{{http_client_annotation|createRequest}}(${[
      (escapeDartString(httpMethod)),
      r'$uri',
      if (abortTrigger(method) case final trigger?) 'abortTrigger: $trigger',
      if (isMultipart) 'multipart: true',
      if (fields != null) 'fields: $fields',
      if (requestBody(method) case (final body, final kind)) switch (kind) {
          BodyKind.body => 'body: $body',
          BodyKind.bodyBytes => 'bodyBytes: $body',
          BodyKind.stream => 'bodyStream: $body',
        },
      // consider additional headers
      if (methodReader.headersCode case final headers?) 'headers: $headers',
      //
    ].join(',\n')});

    return ${() sync* {
      yield r'$send($request)';
      if (Checker.streamedResponse.isExactlyType(futureType)) return;
      yield '.then(#{{http|Response}}.fromStream)';
      if (Checker.response.isAssignableFromType(futureType) || futureType is VoidType) return;
      yield '.then((response) => ${Coding.decodeResponse('response', futureType, decodingFactories(method))})';
    }().join('\n')};
  }
''';
  }

  String? abortTrigger(MethodElement method) {
    final cancels = Checker.cancel.annotatedOf(method.formalParameters);
    if (cancels.isEmpty) return null;

    final futures = <String>[];
    for (final cancel in cancels) {
      final type = cancel.element.type;
      final name = cancel.element.name!;
      if (Checker.cancelToken.isAssignableFromType(type)) {
        futures.add('$name.whenCancel');
      } else if (Checker.future.isAssignableFromType(type)) {
        futures.add(name);
      } else {
        throw InvalidGenerationSourceError(
          'Parameter `$name` annotated with `@Cancel` must be of type `CancelToken` or `Future<void>`.',
          element: cancel.element,
        );
      }
    }

    if (futures.length == 1) return futures.single;
    return '#{{dart:async|Future}}.any([${futures.join(', ')}].whereType<Future<void>>())';
  }

  String modifyPath(
    String path,
    List<FormalParameterElement> formalParameters,
  ) {
    final pathParameters = Checker.path.annotatedOf(formalParameters);
    final map = {
      for (final param in pathParameters)
        param.annotation.read('value').stringValue: param,
    };

    return escapeDartString(path).replaceAllMapped(RegExp(r'\{([^\}]+)\}'), (
      match,
    ) {
      final key = match.group(1)!;
      final param = map[key];
      if (param == null) return match.group(0)!;
      return '\${${param.element.name}}';
    });
  }

  //==========================//
  bool hasQueryParameters(List<FormalParameterElement> formalParameters) {
    final queryParameters = Checker.query.annotatedOf(formalParameters);
    final queryAllParameters = Checker.queryAll.annotatedOf(formalParameters);
    return queryParameters.isNotEmpty || queryAllParameters.isNotEmpty;
  }

  String createQuery(
    String uri,
    List<FormalParameterElement> formalParameters,
  ) {
    final queryParameters = Checker.query.annotatedOf(formalParameters);
    final queryAllParameters = Checker.queryAll.annotatedOf(formalParameters);

    return '''{
    ...$uri.queryParametersAll,
    ${queryAllParameters.map((param) {
      if (param.element.type.isDartCoreMap) return '...${param.element.name!},';
      if (param.element.type case InterfaceType type) {
        // TODO: more robust query serialization
        final encode = type.methods.where((m) => m.name == 'toJson' || m.name == 'toMap');
        for (final m in encode) {
          if (m.returnType.isDartCoreMap && m.formalParameters.isEmpty) {
            return '...${param.element.name!}.${m.name}(),';
          }
        }
        // TODO: possibly allow arguments later
        throw InvalidGenerationSourceError('Parameter `${param.element.name}` annotated with `@QueryAll` must be of type `Map<String, dynamic>` or provide a `toJson` or `toMap` method that returns a `Map<String, dynamic>` without arguments.', element: param.element);
      }
    }).join('\n')}
    ${queryParameters.map((param) {
      final queryKey = param.annotation.read('name').stringValue;
      final paramName = param.element.name!;
      return '${escapeDartString(queryKey)}: $paramName,';
    }).join('\n')}
  }''';
  }
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

enum BodyKind { body, bodyBytes, stream }

(String, BodyKind)? requestBody(MethodElement method) {
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

  if (Checker.implementsStreamListInt(type)) return (name, BodyKind.stream);
  if (Checker.stream.isAssignableFromType(type)) {
    // works with ByteStream and other such subtypes
    throw InvalidGenerationSourceError(
      'Parameter `$name` annotated with `@Body` is a Stream, but is not a Stream<List<int>>.'
      ' Found type: `${type.getDisplayString()}`.',
      element: param.element,
    );
  }

  if (Checker.implementsListInt(type)) return (name, BodyKind.bodyBytes);

  final bool raw = param.annotation.read('raw').boolValue;
  if (raw) return ('$name.toString()', BodyKind.body);

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
    }),
    Checker.jsonConverter.firstAnnotationOf(param.element),
  );
  return ('#{{dart:convert|jsonEncode}}($bodyEncodable)', BodyKind.body);
}

/// returns a `Map<String, Object?>`
String? defineFieldsMap(MethodElement method) {
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
      ConverterContext(paramName, decodingFactories(method)),
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
        ConverterContext(paramName, decodingFactories(method)),
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

class Coding {
  static String decodeResponse(
    String response,
    DartType type,
    GenericFactories factories, [
    DartObject? jsonConverter,
  ]) {
    if (Checker.uint8List.isExactlyType(type)) return '$response.bodyBytes';
    if (type.isDartCoreString) return '$response.body';

    final json = '#{{dart:convert|jsonDecode}}($response.body)';
    return Coding().jsonDecoding(
      type,
      ConverterContext(json, factories),
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

extension type MethodAnnotation(ConstantReader reader)
    implements ConstantReader {
  String get method => read('method').stringValue;
  String get path => read('path').stringValue;

  bool? get multipart => read('multipart').nullOr?.boolValue;

  // Map<String, String>? get headers {
  //   final headersReader = read('headers');
  //   if (headersReader.isNull) return null;
  //   return headersReader.mapValue.map(
  //     (key, value) => MapEntry(
  //       ConstantReader(key).stringValue,
  //       ConstantReader(value).stringValue,
  //     ),
  //   );
  // }

  /// returns like `const {'content': 'value'}`
  String? get headersCode =>
      read('headers').nullOr?.objectValue.toCode(addLeadingConst: false);
}

extension on ConstantReader {
  ConstantReader? get nullOr => isNull ? null : this;
}
