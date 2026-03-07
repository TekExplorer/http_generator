import 'dart:async';

import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer_buffer/analyzer_buffer.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:http_annotation/http_annotation.dart' show BodyType, ExtraType;
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'coders/coder_shared.dart';
import 'coders/json_decoder_visitor.dart';
import 'coders/json_encoder_visitor.dart';
import 'generate/map_literal.dart';
import 'generate/sealed_dart_type.dart';
import 'type_checker/checkers.dart';

part 'coders/coding.dart';
part 'generate/abort_trigger.dart';
part 'generate/extensions.dart';
part 'generate/generate_method.dart';
part 'generate/modify_path.dart';
part 'generate/query_parameters.dart';
part 'generate/request_body.dart';

extension type RestClientAnnotation(ConstantReader reader)
    implements ConstantReader {
  String? get baseUrl => read('baseUrl').nullOr?.stringValue;
  String? get mixinName => read('mixinName').nullOr?.stringValue;
  bool get implementSelf => read('implementSelf').boolValue;
  String? get renameSend => read('renameSend').nullOr?.stringValue;
  bool get autoSelectClient => read('autoSelectClient').boolValue;
  ExtraType get extraType =>
      ExtraType.values[read('extraType').read('index').intValue];
}

class HttpClientGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    final elements = library.annotatedWith(
      TypeChecker.typeNamedLiterally(
        'RestClient',
        inPackage: 'http_annotation',
      ),
    );

    final items = <Future<String>>[];
    for (final annotatedElement in elements) {
      final element = annotatedElement.element;
      final annotation = RestClientAnnotation(annotatedElement.annotation);

      items.add(
        generateForAnnotatedElement(library, element, annotation, buildStep),
      );
    }
    return items.wait.then((generated) => generated.join('\n\n'));
  }

  Future<String> generateForAnnotatedElement(
    LibraryReader library,
    Element element,
    RestClientAnnotation annotation,
    BuildStep buildStep,
  ) async {
    if (element is! InstanceElement) {
      throw InvalidGenerationSourceError(
        'Generator cannot target `${element.name}`. '
        '`@RestClient` can only be applied to classes.',
        element: element,
      );
    }

    final context = GeneratorContext(element: element, annotation: annotation);

    final baseUrl = annotation.baseUrl;
    final mixinName = annotation.mixinName ?? '_\$${element.name!}';
    final implementSelf = annotation.implementSelf == true;

    writeSend(element, context);

    assert(
      context.args.containsKey('send'),
      'send method is not defined in the context',
    );

    context.args['baseUrl'] = (buffer) => buffer.write('baseUrl');

    buildMethods(element.methods, context);

    if (context._additionalMethods.isNotEmpty) {
      switch (annotation.extraType) {
        case .inline:
          context.args['extra'] = (buffer) => buffer.write('_');

          context.members.addAll(
            context._additionalMethods.map((e) {
              final returnType = e.returnType;
              final name = e.name;
              final parameters = '(${e.parameters.toCode()})';

              return '@#{{meta|protected}} $returnType _$name$parameters;';
            }),
          );
        case .mixin:
          context.args['extra'] = (buffer) => buffer.write('_extra.');

          final extraClassName = '_\$${element.name}Extra';
          context.members.add(
            '@#{{meta|protected}} $extraClassName get _extra;',
          );
          final methods = context._additionalMethods.map((e) {
            final returnType = e.returnType;
            final name = e.name;
            final parameters = '(${e.parameters.toCode()})';
            return '$returnType $name$parameters;';
          });
          context.libraryBuffer.add('''
            mixin $extraClassName { ${methods.join('\n')} }
          ''');
        case .factory:
          context.args['extra'] = (buffer) => buffer.write('_extra.');

          final extraClassName = '_\$${element.name}Extra';
          context.members.add(
            '@#{{meta|protected}} $extraClassName get _extra;',
          );
          final methods = context._additionalMethods.map((e) {
            final returnType = e.returnType;
            final name = e.name;
            return '$returnType Function(${e.parameters.toCode()}) $name;';
          });

          final fields = context._additionalMethods.map((e) {
            return 'required this.${e.name}';
          });
          context.libraryBuffer.add('''
            final class $extraClassName {
              $extraClassName({${fields.join(', ')}});
              ${methods.join('\n')}
            }
          ''');
      }
    }

    context.libraryBuffer.add('''
abstract mixin class $mixinName ${implementSelf ? 'implements ${element.name}' : ''} {

  Uri get #{{baseUrl}}${baseUrl != null ? " => Uri.parse(${baseUrl.literal})" : ''};

${context.members.join('\n')}
}
''');

    return resolve(context);
  }

  String resolve(GeneratorContext context) {
    final buffer = AnalyzerBuffer.part(
      context.library,
      header: '// ignore_for_file: type=lint, type=warning\n',
    );

    buffer.write(
      args: context._$args(buffer),
      context.libraryBuffer.join('\n\n'),
    );

    return buffer.toString();
  }

  void writeSend(InstanceElement element, GeneratorContext context) {
    if (element.thisType.isA(Checker.client)) {
      context.args['send'] = (buffer) => buffer.write('this.send()');
      return;
    }

    final sendName = context.annotation.renameSend ?? r'$send';
    final doSend = _doSend(element, context);

    context.args['send'] = (buffer) => buffer.write(sendName);
    context.members.add('''
      @#{{meta|protected}}
      Future<#{{http|StreamedResponse}}> $sendName(#{{http|BaseRequest}} request) {
        return $doSend;
      }
    ''');
  }

  String _doSend(InstanceElement element, GeneratorContext context) {
    final client = element.getters
        .where((g) => g.returnType.isA(Checker.client))
        .firstOrNull;

    if (client != null) {
      log.info(
        'Using `${client.name}` as the http.Client for `${element.name}`.',
      );

      context.members.add('''
  ${client.returnType.toCode()} get client;
''');
      if (!client.returnType.isNullableType) {
        return '${client.name!}.send(request)';
      }
      return '${client.name!}?.send(request) ?? request.send()';
    }

    return 'request.send()';
  }

  void buildMethods(List<MethodElement> methods, GeneratorContext context) {
    for (final method in methods) {
      GenerateForMethod(method, context).build();
    }
  }
}

class GeneratorContext {
  GeneratorContext({required this.element, required this.annotation});

  final InstanceElement element;
  LibraryElement get library => element.library;

  final RestClientAnnotation annotation;

  final args = <String, void Function(AnalyzerBuffer buffer)>{};

  /// for adding things to the library level, e.g. imports, helper functions, etc.
  final libraryBuffer = <String>[];

  /// for adding things to the class/mixin level, e.g. fields, helper methods, etc.
  final members = <String>[];

  final _additionalMethods = <Method>[];

  @useResult
  String addMethod(
    String returnType,
    String name,
    Iterable<Parameter> parameters,
  ) {
    _additionalMethods.add(Method(returnType, name, parameters));
    final index = _additionalMethods.length;
    final arg = '#{{method:$name:$index}}';

    final resolvedMethodName = '#{{extra}}$name';
    args[arg] = (buffer) => buffer.write(resolvedMethodName);
    return resolvedMethodName;
  }

  Map<String, void Function()> _$args(AnalyzerBuffer buffer) => {
    for (final entry in args.entries)
      entry.key: () {
        entry.value(buffer);
      },
  };
}

class Method {
  Method(this.returnType, this.name, this.parameters);

  Method.fromElement(MethodElement element)
    : returnType = element.returnType.toCode(),
      name = element.name!,
      parameters = element.formalParameters.map(Parameter.fromElement);

  final String returnType;
  final String name;
  final Iterable<Parameter> parameters;
}

extension on Iterable<Parameter> {
  String toCode() => map((p) => p.toCode()).join(', ');
}

class Parameter {
  Parameter(
    this.type,
    this.name, {
    this.isNamed = false,
    this.isRequired = false,
  });

  Parameter.fromElement(FormalParameterElement element)
    : type = element.type.toCode(),
      name = element.name!,
      isNamed = element.isNamed,
      isRequired = element.isRequired;

  /// As code
  final String type;
  final String name;
  final bool isNamed;
  final bool isRequired;

  String toCode() {
    final buffer = StringBuffer();
    if (isNamed && isRequired) {
      buffer.write('required ');
    }
    buffer.write('$type $name');
    return buffer.toString();
  }
}
