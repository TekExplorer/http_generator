import 'package:analyzer/dart/element/element.dart' hide Fragment;
import 'package:http_client_annotation/http_client_annotation.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;

import 'path_checker.dart';
import 'type_checker.dart';

abstract final class Checker {
  static final method = TypeChecker.typeNamed(Method);
  static final body = TypeChecker.typeNamed(Body);
  static final query = TypeChecker.typeNamed(Query);
  static final queryAll = TypeChecker.typeNamed(QueryAll);
  static final fragment = TypeChecker.typeNamed(Fragment);

  static final path = TypeChecker.typeNamed(Path);

  static final cancel = TypeChecker.typeNamed(Cancel);

  static final jsonConverter = PackageChecker(
    'json_serializer_annotation',
    'JsonConverter',
  );

  static final cancelToken = PackageChecker('dio', 'CancelToken');

  static final responseType = PackageChecker('http', 'Response');

  static final uint8List = TypeChecker.fromUrl('dart:typed_data#Uint8List');
  static final future = TypeChecker.fromUrl('dart:async#Future');
  static final stream = TypeChecker.fromUrl('dart:async#Stream');
}

extension AnnotatedOf on TypeChecker {
  Iterable<({ConstantReader annotation, T element})>
  annotatedOf<T extends Element>(Iterable<T> elements) {
    return elements.where((e) => hasAnnotationOf(e)).map((e) {
      return (annotation: ConstantReader(firstAnnotationOf(e)!), element: e);
    });
  }
}
