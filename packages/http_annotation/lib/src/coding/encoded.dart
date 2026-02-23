part of 'coding.dart';

/// This class is used to safely represent the encoded body of a request,
/// which can be a [_stream], [bytes], [string], query/form [fields], or [multipart] fields.
///
/// It is used when encoding the body of a request,
/// and allows the generator to handle different body types in a consistent way,
/// without having to worry about the specific type of the body.
///
/// The argument is a function which accepts a [FutureOr] value,
/// which allows for both synchronous and asynchronous encoding of the body.
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
}

sealed class SimpleEncoded extends Encoded {
  SimpleEncoded({this.encoding});
  final Encoding? encoding;
}

final class EncodedStream extends Encoded {
  EncodedStream(this._stream, {this.contentLength, this.contentLengthUpdates});

  Stream<List<int>> stream() async* {
    yield* await _stream;
  }

  final FutureOr<Stream<List<int>>> _stream;
  final FutureOr<int?>? contentLength;
  final Stream<int>? contentLengthUpdates;
}

final class EncodedBytes extends SimpleEncoded {
  EncodedBytes(this.bytes, {super.encoding});

  final FutureOr<List<int>> bytes;
}

final class EncodedString extends SimpleEncoded {
  EncodedString(this.string, {super.encoding});
  final FutureOr<String> string;
}

final class EncodedFields extends SimpleEncoded {
  EncodedFields(this.fields, {super.encoding});
  final FutureOr<Map<String, String?>> fields;
}

final class EncodedMultipart extends Encoded {
  EncodedMultipart(this.fields);
  final FutureOr<Map<String, MultipartValue>> fields;
}

@internal
extension SplitFields on Map<String, MultipartValue> {
  ({Map<String, FieldValue> fields, Map<String, FilePart> files}) get split {
    final fields = <String, FieldValue>{};
    final fileParts = <String, FilePart>{};

    for (final entry in entries) {
      switch (entry.value) {
        case FieldValue value:
          fields[entry.key] = value;
        case FilePart value:
          fileParts[entry.key] = value;
      }
    }

    return (fields: fields, files: fileParts);
  }
}
