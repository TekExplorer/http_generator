import 'package:analyzer/dart/element/element.dart' hide Fragment;
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader, TypeChecker;
import 'package:source_helper/source_helper.dart';

final class Checker {
  static TypeChecker annotation(String type) =>
      TypeChecker.typeNamedLiterally(type, inPackage: 'http_annotation');

  static TypeChecker fromUrl(String url) {
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
  static final _filePart = annotation('FilePart');
  static final _multipartFile = fromUrl('http#MultipartFile');
  static final validFile = any([_filePart, _multipartFile]);
  //

  static final field = annotation('Field');
  static final fields = annotation('Fields');

  // static final filePart = TypeChecker.typeNamed(FilePart);

  static final cancel = annotation('Cancel');

  static final jsonConverter = fromUrl(
    'json_serializer_annotation#JsonConverter',
  );

  static final cancelToken = fromUrl('dio#CancelToken');

  static final response = fromUrl('http#Response');
  static final streamedResponse = fromUrl('http#StreamedResponse');

  static final uint8List = fromUrl('dart:typed_data#Uint8List');

  static bool implementsListInt(DartType type) {
    final listArg = type.typeArgumentsOf(fromUrl('dart:core#List'))?.single;
    if (listArg == null) return false;
    return listArg.isDartCoreInt;
  }

  static final future = fromUrl('dart:async#Future');

  static final stream = fromUrl('dart:async#Stream');
  static bool implementsStreamListInt(DartType type) {
    final streamArgs = type.typeArgumentsOf(stream);
    if (streamArgs == null) return false;
    return implementsListInt(streamArgs.single);
  }

  static final map = fromUrl('dart:core#Map');

  static final string = fromUrl('dart:core#String');

  static bool implementsMapStringString(DartType type) {
    final mapArgs = type.typeArgumentsOf(map);
    if (mapArgs == null) return false;
    final [key, value] = mapArgs;
    return key.isDartCoreString && value.isDartCoreString;
  }

  static final protoGeneratedMessage = fromUrl('protobuf#GeneratedMessage');
}

extension AnnotatedOf on TypeChecker {
  Iterable<({ConstantReader annotation, T element})>
  annotatedOf<T extends Element>(Iterable<T> elements) {
    return elements.where((e) => hasAnnotationOf(e)).map((e) {
      return (annotation: ConstantReader(firstAnnotationOf(e)!), element: e);
    });
  }
}
