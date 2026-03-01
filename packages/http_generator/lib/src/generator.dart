import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer_buffer/analyzer_buffer.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:http_annotation/http_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'coders/coder_shared.dart';
import 'coders/json_decoder_visitor.dart';
import 'coders/json_encoder_visitor.dart';
import 'generate/map_literal.dart';
import 'type_checker/checkers.dart';

part 'coders/coding.dart';
part 'generate/abort_trigger.dart';
part 'generate/extensions.dart';
part 'generate/generate_method.dart';
part 'generate/modify_path.dart';
part 'generate/query_parameters.dart';
part 'generate/request_body.dart';

class HttpClientGenerator extends GeneratorForAnnotation<RestClient> {
  HttpClientGenerator() : super(inPackage: 'http_annotation');

  RestClient getAnnotation(ConstantReader annotation) => RestClient(
    baseUrl: annotation.read('baseUrl').nullOr?.stringValue,
    mixinName: annotation.read('mixinName').nullOr?.stringValue,
    mixinClass: annotation.read('mixinClass').nullOr?.boolValue,
    implementSelf: annotation.read('implementSelf').nullOr?.boolValue,
  );

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

    final annotationValue = getAnnotation(annotation);
    final baseUrl = annotationValue.baseUrl;
    final mixinName = annotationValue.mixinName ?? '_\$${element.name}';
    final mixinClass = annotationValue.mixinClass == true;
    final implementSelf = annotationValue.implementSelf == true;
    buffer.write('''
${mixinClass ? 'abstract mixin class' : 'mixin'} $mixinName implements #{{http_annotation|\$GeneratedClient}}${implementSelf ? ', ${element.name}' : ''} {
  @#{{meta|protected}}
  Future<#{{http|StreamedResponse}}> \$send(#{{http|BaseRequest}} request) {
    return request.send();
  }
  
  Uri get baseUrl${baseUrl != null ? " => Uri.parse(${escapeDartString(baseUrl)})" : ''};

  Uri \$buildUrl(String path) => baseUrl.resolve(path);

${buildMethods(element.methods).join('\n')}
}
''');

    return buffer.toString();
  }

  List<String> buildMethods(List<MethodElement> methods) {
    final generatedMethods = <String>[];

    final builders = methods.map(
      (method) => GenerateForMethod(method, generatedMethods.add),
    );
    for (final impl in builders) {
      impl.build();
    }

    return generatedMethods;
  }
}
