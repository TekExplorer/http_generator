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

// figure out dart docs templates
const fields = Fields();

/// Multiple form fields, e.g. `name=John&age=30`
///
/// Object must be or serialize to a [Map<String, Object?>], where the value can be a [String], a [FilePart], or a [http.MultipartFile].
///
/// Any other type will be converted to a string using [toString], unless a custom converter is provided.
///
/// Files are only supported for multipart requests, and will be ignored otherwise.
/// Multipart requests must be indicated with multipart: true
@Target({TargetKind.parameter})
final class Fields {
  const Fields();
}

/// A single form field, e.g. `name=John`
///
/// The value can be a [String], a [FilePart], or a [http.MultipartFile].
///
/// Any other type will be converted to a string using [toString], unless a custom converter is provided.
///
/// Files are only supported for multipart requests, and will be ignored otherwise.
/// Multipart requests must be indicated with the [multipart] annotation.
@Target({TargetKind.parameter})
final class Field {
  const Field(this.name);
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

/// Fragment part of the URL, e.g. `#section1`
const fragment = Fragment();

/// Fragment part of the URL, e.g. `#section1`
@Target({TargetKind.parameter})
final class Fragment {
  const Fragment();
}

/// Used to cancel an ongoing request.
///
/// Only valid on parameters of type [Future<void>] or CancelToken (from dio).
///
/// If canceled, the method will throw a [http.RequestAbortedException]
///
/// Consider using [Completer] or [Future.delayed] to trigger the cancellation at a later time.
///
/// Multiple cancel parameters will be combined with [Future.any], so the request will be canceled if any of them is triggered.
///
/// Prefer to have only one cancel parameter per method for clarity.
@Target({TargetKind.parameter})
final class Cancel {
  const Cancel();
}
