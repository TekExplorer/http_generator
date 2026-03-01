import 'package:analyzer/dart/element/element.dart' hide Fragment;
import 'package:analyzer/dart/element/type.dart';
import 'package:http_generator/src/generator.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader, TypeChecker;
import 'package:source_helper/source_helper.dart';

extension Checker on TypeChecker {
  static TypeChecker annotation(String type) =>
      TypeChecker.typeNamedLiterally(type, inPackage: 'http_annotation');

  static TypeChecker from(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme == 'dart') return TypeChecker.fromUrl(url);
    return TypeChecker.typeNamedLiterally(
      uri.fragment,
      inPackage: uri.pathSegments.first,
    );
  }

  static TypeChecker any(Iterable<TypeChecker> checkers) =>
      TypeChecker.any(checkers);

  static final method = annotation('Method');

  static final path = annotation('Path');

  static final query = annotation('Query');
  static final queryAll = annotation('QueryAll');

  static final fragment = annotation('Fragment');

  static final body = annotation('Body');

  static final filePart = annotation('FilePart');

  static final field = annotation('Field');
  static final fields = annotation('Fields');

  static final headers = annotation('Headers');
  static final header = annotation('Header');

  static final custom = annotation('Custom');
  // static final filePart = TypeChecker.typeNamed(FilePart);

  static final cancel = annotation('Cancel');

  static final jsonConverter = from('json_serializer_annotation#JsonConverter');

  static final cancelToken = from('dio#CancelToken');

  static final response = from('http#Response');
  static final streamedResponse = from('http#StreamedResponse');

  static final uint8List = from('dart:typed_data#Uint8List');

  static final future = from('dart:async#Future');

  static final stream = from('dart:async#Stream');

  static final map = from('dart:core#Map');

  static final list = from('dart:core#List');
  static final iterable = from('dart:core#Iterable');

  static final string = from('dart:core#String');

  static final protoGeneratedMessage = from('protobuf#GeneratedMessage');
}

extension TypeHelpers on DartType {
  bool get isAMapStringString =>
      isA(Checker.map, [Checker.string, Checker.string]);

  bool get isAStreamListInt {
    if (!isA(Checker.stream)) return false;
    final arg = typeArgumentsOf(Checker.stream)?.single;
    if (arg == null) return false;
    return arg.isAListInt;
  }

  bool get isAListInt => isA(Checker.list, [Checker.from('dart:core#int')]);
}

extension AnnotatedOf on TypeChecker {
  Iterable<({ConstantReader annotation, T element})>
  annotatedOf<T extends Element>(Iterable<T> elements) {
    return elements.where((e) => hasAnnotationOf(e)).map((e) {
      return (annotation: ConstantReader(firstAnnotationOf(e)!), element: e);
    });
  }
}
