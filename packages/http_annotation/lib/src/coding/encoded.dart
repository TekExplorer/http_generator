import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'file_part.dart';

typedef OnProgressCallback = void Function(int loaded, int total);

/// This class is used to safely represent the encoded body of a request,
/// which can be a [_stream], [bytes], [string], query/form [parts], or [multipart] fields.
///
/// It is used when encoding the body of a request,
/// and allows the generator to handle different body types in a consistent way,
/// without having to worry about the specific type of the body.
///
/// This can include processing the body in an isolate, which is useful for
/// expensive encoding operations like JSON encoding large objects
sealed class Encoded {
  /// This is a convenience factory for encoding stream bodies, such as streaming data
  static const stream = EncodedStream.new;

  /// This is a convenience factory for encoding byte bodies, such as files or binary data.
  static const bytes = EncodedBytes.new;

  /// This is a convenience factory for encoding string bodies,
  /// and can be used for plain text or pre-serialized JSON strings.
  static const string = EncodedString.new;

  /// This represents query parameters or form-data fields,
  /// where each field can have multiple values, but cannot include files.
  static const fields = EncodedFields.new;

  /// This represents the fields of a multipart request,
  /// where each field can have multiple values, and can also include files.
  static const multipart = EncodedMultipart.new;

  http.Abortable createRequest(
    String method,
    Uri url, {
    Future<void>? abortTrigger,
  });
}

sealed class BodyEncoded implements Encoded {
  /// This is a convenience factory for encoding stream bodies, such as streaming data
  static const stream = EncodedStream.new;

  /// This is a convenience factory for encoding byte bodies, such as files or binary data.
  static const bytes = EncodedBytes.new;

  /// This is a convenience factory for encoding string bodies,
  /// and can be used for plain text or pre-serialized JSON strings.
  static const string = EncodedString.new;

  /// This represents query parameters or form-data fields,
  /// where each field can have multiple values, but cannot include files.
  static const fields = EncodedFields.new;
}

sealed class SimpleEncoded implements Encoded, BodyEncoded {
  static const string = EncodedString.new;
  static const bytes = EncodedBytes.new;
  static const fields = EncodedFields.new;

  SimpleEncoded({this.encoding});
  final Encoding? encoding;

  @override
  http.AbortableRequest createRequest(
    String method,
    Uri url, {
    Future<void>? abortTrigger,
  });
}

final class EncodedStream implements BodyEncoded {
  EncodedStream(this._stream, {this.contentLength});

  Stream<List<int>> stream() async* {
    yield* _stream;
  }

  final Stream<List<int>> _stream;
  final int? contentLength;

  @override
  http.AbortableStreamedRequest createRequest(
    String method,
    Uri url, {
    Future<void>? abortTrigger,
  }) {
    final request = http.AbortableStreamedRequest(
      method,
      url,
      abortTrigger: abortTrigger,
    );

    if (contentLength != null) request.contentLength = contentLength;

    request.sink.addStream(stream());

    return request;
  }
}

final class EncodedBytes extends SimpleEncoded {
  EncodedBytes(this.bytes, {super.encoding});

  final List<int> bytes;

  @override
  http.AbortableRequest createRequest(
    String method,
    Uri url, {
    Future<void>? abortTrigger,
  }) {
    final request = http.AbortableRequest(
      method,
      url,
      abortTrigger: abortTrigger,
    );
    if (encoding case final encoding?) request.encoding = encoding;
    request.bodyBytes = bytes;
    return request;
  }
}

final class EncodedString extends SimpleEncoded {
  EncodedString(this.string, {super.encoding});
  final String string;

  @override
  http.AbortableRequest createRequest(
    String method,
    Uri url, {
    Future<void>? abortTrigger,
  }) {
    final request = http.AbortableRequest(
      method,
      url,
      abortTrigger: abortTrigger,
    );
    if (encoding case final encoding?) request.encoding = encoding;
    request.body = string;
    return request;
  }
}

final class EncodedFields extends SimpleEncoded {
  EncodedFields(this.parts, {super.encoding});
  EncodedFields.from(Map<String, Object?> fields, {super.encoding})
    : parts = {
        for (final entry in fields.entries) entry.key: ?entry.value?.toString(),
      };

  final Map<String, String> parts;

  @override
  http.AbortableRequest createRequest(
    String method,
    Uri url, {
    Future<void>? abortTrigger,
  }) {
    final request = http.AbortableRequest(
      method,
      url,
      abortTrigger: abortTrigger,
    );
    if (encoding case final encoding?) request.encoding = encoding;
    request.bodyFields = parts;
    return request;
  }
}

abstract final class MultipartBuilder {
  Map<String, String?> get fields;
  Map<String, FilePart?> get files;
}

final class EncodedMultipart implements Encoded, MultipartBuilder {
  EncodedMultipart({Map<String, String>? fields, Map<String, FilePart>? files})
    : fields = {...?fields},
      files = {...?files};

  static Future<EncodedMultipart> build(
    FutureOr<void> Function(MultipartBuilder builder) build,
  ) async {
    final multipart = EncodedMultipart();
    await build(multipart);
    return multipart;
  }

  @override
  final Map<String, String?> fields;

  @override
  final Map<String, FilePart?> files;

  @override
  http.AbortableMultipartRequest createRequest(
    String method,
    Uri url, {
    Future<void>? abortTrigger,
  }) {
    final request = http.AbortableMultipartRequest(
      method,
      url,
      abortTrigger: abortTrigger,
    );

    request.fields.addAll(fields.nonNulls);

    for (final entry in files.nonNulls.entries) {
      request.files.add(entry.value.toHttpMultipartFile(entry.key));
    }

    return request;
  }
}

extension<V extends Object, K extends Object> on Map<K?, V?> {
  Map<K, V> get nonNulls => {
    for (final entry in entries) ?entry.key: ?entry.value,
  };
}
