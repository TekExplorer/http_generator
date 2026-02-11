import 'package:meta/meta_meta.dart';

// TODO: support any interface like mixins, extensions, extension types etc once augmentations are released
@Target({TargetKind.classType})
class RestClient {
  const RestClient([this.baseUrl]);

  final String? baseUrl;
}

@Target({TargetKind.parameter})
class Path {
  const Path(this.value);
  final String value;
}

@Target({TargetKind.parameter})
final class Body {
  /// [raw] indicates that the body should be sent as is, without any serialization.
  ///
  /// This is useful for sending plain text or pre-serialized JSON strings.
  ///
  /// if [raw] = [true], will toString() the value instead of serializing.
  const Body({this.raw = false});

  /// if [raw] = [true], will toString() the value instead of serializing.
  final bool raw;
}

const formFields = FormFields();

@Target({TargetKind.parameter})
final class FormFields {
  const FormFields();
}

@Target({TargetKind.parameter})
final class FormField {
  const FormField(this.name);
  final String name;
}

// A single query parameter, e.g. `?search=foo`
@Target({TargetKind.parameter})
final class Query {
  const Query(this.name);
  final String name;
}

// Multiple query parameters, e.g. `?filter=name&filter=age`
// serialized from an object
const queryAll = QueryAll();

@Target({TargetKind.parameter})
final class QueryAll {
  const QueryAll();
}

// Fragment part of the URL, e.g. `#section1`
const fragment = Fragment();

@Target({TargetKind.parameter})
final class Fragment {
  const Fragment();
}

@Target({TargetKind.parameter})
final class Cancel {
  const Cancel();
}

//// @Post('/upload')
// @MultiPart()
// Future<void> uploadFile(@Part('file') Uint8List file, @Part('description') String description);
// @Target({TargetKind.method})
// final class MultiPart {
//   const MultiPart();
// }

// @Target({TargetKind.parameter})
// final class Part {
//   const Part(this.name);
//   const factory Part.file(String name) = _FilePart;
//   final String name;
// }

// /// valid for [File] and [Uint8List] and [String]
// @Target({TargetKind.parameter})
// final class _FilePart extends Part {
//   const _FilePart(super.name);
// }
