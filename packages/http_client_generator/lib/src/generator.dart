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

    final buffer = AnalyzerBuffer.part2(
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

    final methodReader = ConstantReader(methodAnnotation);
    final httpMethod = methodReader.peek('method')?.stringValue;
    final path = methodReader.peek('path')?.stringValue;
    if (httpMethod == null || path == null) {
      throw InvalidGenerationSourceError(
        'Method `${method.name}` has invalid `@Method` annotation.',
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

    return '''
  ${methodSignature(method)} {
    ${[
      'Uri \$uri = baseUri.resolve(${modifyPath(path, method.formalParameters)});',
      if (hasQuery || fragment != null) [
          '\$uri = \$uri.replace(', //
          if (hasQuery) 'queryParameters: ${createQuery('\$uri', method.formalParameters)},', //
          if (fragment != null) 'fragment: ${fragment.element.name},',
          ');',
        ].join('\n'),
    ].join('\n')}
    // final \$request = #{{http_client_annotation|createRequest}}('$httpMethod', \$uri,${abortTrigger(method)});
    final \$request = #{{http|AbortableRequest}}('$httpMethod', \$uri,${abortTrigger(method)});
    ${ModifyRequest.apply(r'$request', method)}
    return \$send(\$request).then(#{{http|Response}}.fromStream).then((response) {
      return ${Coding.decodeResponse('response', futureType, decodingFactories(method))};
    });
  }
''';
  }

  String abortTrigger(MethodElement method) {
    final cancels = Checker.cancel.annotatedOf(method.formalParameters);
    if (cancels.isEmpty) return '';

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

    if (futures.length == 1) return 'abortTrigger: ${futures.single}';
    return 'abortTrigger: #{{dart:async|Future}}.any([${futures.join(', ')}].whereType<Future<void>>())';
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

class ModifyRequest {
  static String apply(String request, MethodElement method) {
    return ModifyRequest(request, method).modifyRequest();
  }

  ModifyRequest(this.request, this.method);
  final String request;
  final MethodElement method;

  // bool validate() {
  //   final bodyParameters = Checker.body.annotatedOf(method.formalParameters);

  //   final formFieldParameters = Checker.field.annotatedOf(
  //     method.formalParameters,
  //   );
  //   final formFieldsParameters = Checker.fields.annotatedOf(
  //     method.formalParameters,
  //   );

  //   if (bodyParameters.isNotEmpty &&
  //       (formFieldParameters.isNotEmpty || formFieldsParameters.isNotEmpty)) {
  //     throw InvalidGenerationSourceError(
  //       'Method `${method.name}` cannot have parameters annotated with both `@Body` and `@FormField`/`@FormFields`.',
  //       element: method,
  //     );
  //   }

  //   return true;
  // }

  String modifyRequest() =>
      multipartRequestFields() ?? formFieldsBody() ?? requestBody();

  String requestBody() {
    final bodyParameters = Checker.body.annotatedOf(method.formalParameters);
    if (bodyParameters.isEmpty) return '';

    if (bodyParameters.length > 1) {
      throw InvalidGenerationSourceError(
        'Method `${method.name}` has multiple parameters annotated with `@Body`. '
        'Only one `@Body` parameter is allowed per method.',
        element: method,
      );
    }

    final param = bodyParameters.single;

    final bool raw = param.annotation.read('raw').boolValue;
    if (raw) return '$request.body = ${param.element.name}.toString();';

    final bodyEncodable = Coding.bodyEncodable(
      param.element.type,
      ConverterContext(param.element.name!, {
        for (final tp in method.typeParameters)
          tp: (context) {
            // myFunc<@TConverter() T>()
            final converterAnnotation = Checker.jsonConverter
                .firstAnnotationOfExact(tp);
            if (converterAnnotation != null) {
              return '$request.body = #{{dart:convert|jsonEncode}}(${converterAnnotation.toCode()}.toJson(${context.varName}));';
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
    return '$request.body = #{{dart:convert|jsonEncode}}($bodyEncodable);';
  }

  String? formFieldsBody() {
    return '$request.bodyFields = ${defineFields(method)};';
  }

  /// Only for multipart requests, adds fields and files to the request body.
  String? multipartRequestFields() {
    var fields = defineFields(method);
    if (fields == null) return null;
    return '''
  final \$fields = $fields;
  $request.fields.addAll(\$fields.fields);
  $request.files.addAll(\$fields.files.entries.map((e) => e.value.toMultipartFile(e.key)));
''';
  }
}

/// returns a `({Map<String, String> fields, Map<String, FilePart> files})`
String? defineFields(MethodElement method) {
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
    lines.add('${escapeDartString(fieldName)}: $encoded,');
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
      lines.add(paramName);
    } else if (param.element.type case InterfaceType type) {
      final encoding = Coding.bodyEncodable(
        type,
        ConverterContext(paramName, decodingFactories(method)),
        Checker.jsonConverter.firstAnnotationOf(param.element),
      );
      lines.add(encoding);
    } else {
      throw InvalidGenerationSourceError(
        'Parameter `${param.element.name}` annotated with `@FormFields` must be of type `Map<String, String>` or provide a `toJson` or `toMap` method that returns a `Map<String, String>` without arguments.',
        element: param.element,
      );
    }
  }
  return '#{{http_client_annotation|mapToFields}}({${lines.map((line) => '...$line,').join('\n')}})';
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
    if (type is VoidType) return '';
    if (Checker.responseType.isExactlyType(type)) return response;
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
