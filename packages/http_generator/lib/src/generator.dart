import 'dart:async';

import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer_buffer/analyzer_buffer.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:http_annotation/http_annotation.dart' show BodyType;
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
  bool? get implementSelf => read('implementSelf').nullOr?.boolValue;
  String? get renameSend => read('renameSend').nullOr?.stringValue;
  bool? get autoSelectClient => read('autoSelectClient').nullOr?.boolValue;
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

    context.args['baseUrl'] = (buffer) {
      buffer.write('baseUrl');
    };

    buildMethods(element.methods, context);

    context.libraryBuffer.add('''
abstract mixin class $mixinName ${implementSelf ? 'implements ${element.name}' : ''} {

  Uri get #{{baseUrl}}${baseUrl != null ? " => Uri.parse(${baseUrl.literal})" : ''};

${context.classBuffer.join('\n')}

${context.customMethodBuffer.join('\n')}
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
    final autoSelectSend =
        context.annotation.autoSelectClient != false &&
        context.annotation.renameSend == null;

    final sendName = context.annotation.renameSend ?? r'$send';

    final sendMethods = element.methods.where((m) {
      if (m.isStatic) return false;
      if (m.name != sendName) return false;
      if (m.formalParameters.length != 1) return false;

      final baseRequest = Checker.from('http#BaseRequest');
      if (!m.formalParameters.single.type.isExactly(baseRequest)) return false;
      if (!m.returnType.isExactly(Checker.future, [Checker.streamedResponse])) {
        return false;
      }
      return true;
    });
    if (autoSelectSend && sendMethods.length == 1) {
      final sendMethod = sendMethods.single;
      log.info(
        'Using `${sendMethod.name}` as the send method for `${element.name}`.',
      );
      context.args['send'] = (buffer) => buffer.write(sendMethod.name!);
      return;
    }

    if (autoSelectSend && element.thisType.isA(Checker.client)) {
      context.args['send'] = (buffer) => buffer.write('send');
      return;
    }

    {
      final clientGetters = element.getters.where(
        (g) => g.returnType.isA(Checker.client),
      );

      if (autoSelectSend && clientGetters.length == 1) {
        final client = clientGetters.single;
        log.info(
          'Using `${client.name}` as the http.Client for `${element.name}`.',
        );
        context.args['send'] = (buffer) => buffer.write('${client.name!}.send');
        return;
      }
    }

    context.args['send'] = (buffer) => buffer.write(sendName);
    context.classBuffer.add('''
          @#{{meta|protected}}
          Future<#{{http|StreamedResponse}}> $sendName(#{{http|BaseRequest}} request) {
            return request.send();
          }
        ''');
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
  final classBuffer = <String>[];

  final customMethodBuffer = <String>[];

  Map<String, void Function()> _$args(AnalyzerBuffer buffer) => {
    for (final entry in args.entries)
      entry.key: () {
        entry.value(buffer);
      },
  };
}
