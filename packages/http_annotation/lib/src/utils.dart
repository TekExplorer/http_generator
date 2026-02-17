import 'dart:async';
import 'dart:convert' show Encoding;

import 'package:http/http.dart' as http;

import 'file_part.dart';

Future<http.Abortable> createRequest(
  String method,
  Uri url, {
  Future<void>? abortTrigger,
  // Streamed request
  Stream<List<int>>? bodyStream,
  int? contentLength,
  Stream<int>? contentLengthUpdates,
  // text request
  http.MediaType? contentType,
  Encoding? encoding, // for [body]
  String? body,
  List<int>? bodyBytes,
  // form fields and multipart files

  // while we could assume files from [FilePart]s in fields,
  // we dont always know if a multipart request just doesn't have any,
  bool multipart = false,
  Map<String, Object?>? fields,
  Map<String, String? Function(Object?)>? convertOverrides,
  // headers
  Map<String, String>? headers,
  void Function(Map<String, String> headers)? modifyHeaders,
}) async {
  if (bodyStream != null) {
    assert(
      [body, bodyBytes, fields].nonNulls.isEmpty,
      'bodyStream requests cannot have a body, bodyBytes, or form fields.',
    );
    assert(
      encoding == null && contentType == null,
      'bodyStream requests cannot have encoding or contentType.',
    );
    return _createStreamedRequest(
      method,
      url,
      abortTrigger: abortTrigger,
      bodyStream: bodyStream,
      contentLength: contentLength,
      contentLengthUpdates: contentLengthUpdates,
    );
  }
  assert(
    contentLength == null && contentLengthUpdates == null,
    'contentLength and contentLengthUpdates can only be used with bodyStream requests.',
  );
  return await _createNonStreamRequest(
    method,
    url,
    abortTrigger: abortTrigger,
    bodyBytes: bodyBytes,
    contentType: contentType,
    body: body,
    encoding: encoding,
    multipart: multipart,
    fields: fields,
    convertOverrides: convertOverrides,
    headers: headers,
    modifyHeaders: modifyHeaders,
  );
}

http.AbortableStreamedRequest _createStreamedRequest(
  String method,
  Uri url, {
  Future<void>? abortTrigger,
  // the actual contents of the body
  required Stream<List<int>> bodyStream,
  // content length can be set initially
  int? contentLength,
  // or updated over time
  Stream<int>? contentLengthUpdates,
  //
  void Function(int bytesSent, int? totalBytes)? onSendProgress,
}) {
  final request = http.AbortableStreamedRequest(
    method,
    url,
    abortTrigger: abortTrigger,
  );

  request.contentLength = contentLength;

  final sub = contentLengthUpdates?.listen((length) {
    request.contentLength = length;
  });

  // request.sink.addStream(bodyStream).then((_) {
  //   sub?.cancel();
  //   request.sink.close();
  // });
  var bytesSent = 0;
  request.sink.addStream(
    bodyStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          bytesSent += data.length;
          onSendProgress?.call(bytesSent, request.contentLength);
          sink.add(data);
        },
        handleError: (error, stackTrace, sink) {
          sub?.cancel();
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) {
          sub?.cancel();
          sink.close();
        },
      ),
    ),
  );

  return request;
}

Future<http.Abortable> _createNonStreamRequest(
  String method,
  Uri url, {
  Future<void>? abortTrigger,
  // text request
  Encoding? encoding,
  String? body,
  // bytes request (encode the bytes of json)
  List<int>? bodyBytes,
  http.MediaType? contentType,
  // form fields and multipart files
  Map<String, Object?>? fields,
  Map<String, String? Function(Object?)>? convertOverrides,
  bool multipart = false,
  // headers
  Map<String, String>? headers,
  void Function(Map<String, String> headers)? modifyHeaders,
}) async {
  void adjustHeaders(Map<String, String> requestHeaders) {
    if (headers != null) requestHeaders.addAll(headers);
    modifyHeaders?.call(requestHeaders);
  }

  final form = _mapToFields(fields, convertOverrides);
  if (multipart) {
    final request = http.AbortableMultipartRequest(
      method,
      url,
      abortTrigger: abortTrigger,
    );
    adjustHeaders(request.headers);

    // huh. why make it multipart but provide nothing?
    if (form == null) return request;

    request.fields.addAll(form.fields);
    for (final entry in form.files.entries) {
      final file = entry.value;
      request.files.add(await file.toMultipartFile(entry.key));
    }
    return request;
  }
  assert(
    form == null || form.files.isEmpty,
    'Non-multipart requests cannot have files. Found: ${form.files.keys.join(', ')}',
  );

  final request = http.AbortableRequest(
    method,
    url,
    abortTrigger: abortTrigger,
  );

  final formFields = form?.fields;

  adjustHeaders(request.headers);

  if (contentType != null && formFields == null) {
    request.headers['content-type'] = contentType.toString();
  }

  assert(
    [body, bodyBytes, fields].nonNulls.length.isZeroOr1,
    'Only one of body, bodyBytes, or form fields can be provided.',
  );
  if (encoding != null) request.encoding = encoding;

  if (formFields != null) request.bodyFields = formFields;
  if (bodyBytes != null) request.bodyBytes = bodyBytes;
  if (body != null) request.body = body;

  return request;
}

extension on int {
  bool get isZeroOr1 => this == 0 || this == 1;
}

({Map<String, String> fields, Map<String, FilePart> files})? _mapToFields(
  Map<String, Object?>? map, [
  Map<String, String? Function(Object? object)>? convertOverrides,
]) {
  if (map == null) return null;

  final fileParts = <String, FilePart>{};
  final fields = <String, String>{};

  for (final entry in map.entries) {
    Object? value = entry.value;
    if (value is http.MultipartFile) {
      value = FilePart.fromMultipartFile(value);
    }

    if (value is FilePart) {
      fileParts[entry.key] = value;
    } else {
      final convert = convertOverrides?[entry.key] ?? (v) => v?.toString();
      if (convert(value) case final result?) fields[entry.key] = result;
    }
  }

  return (fields: fields, files: fileParts);
}
