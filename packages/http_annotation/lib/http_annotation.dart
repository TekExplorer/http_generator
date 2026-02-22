/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'dart:convert' show jsonEncode, jsonDecode, utf8;

export 'package:http/http.dart' show StreamedResponse, Response, BaseRequest;
export 'package:meta/meta.dart' show protected;

// ignore: invalid_export_of_internal_element
export 'src/annotations.dart';
export 'src/file_part.dart';
export 'src/generated_client.dart';
export 'src/method.dart';
export 'src/utils.dart';
