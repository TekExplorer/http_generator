/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'package:meta/meta.dart' show protected;

// ignore: invalid_export_of_internal_element
export 'src/annotations.dart';
export 'src/file_part.dart';
export 'src/method.dart';
export 'src/utils.dart';

// class Response<T> implements http.BaseResponse {
//   Response(this.data, this.response);

//   final T data;
//   final http.Response response;

//   @override
//   int? get contentLength => response.contentLength;

//   @override
//   Map<String, String> get headers => response.headers;

//   @override
//   bool get isRedirect => response.isRedirect;

//   @override
//   bool get persistentConnection => response.persistentConnection;

//   @override
//   String? get reasonPhrase => response.reasonPhrase;

//   @override
//   http.BaseRequest? get request => response.request;

//   @override
//   int get statusCode => response.statusCode;
// }
