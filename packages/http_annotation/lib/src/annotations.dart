import 'dart:async';

import 'package:meta/meta_meta.dart';

// TODO: support any interface like mixins, extensions, extension types etc once augmentations are released
@Target({TargetKind.classType})
class RestClient {
  const RestClient([this.baseUrl, this.mixinName, this.mixinClass]);

  final String? baseUrl;
  final String? mixinName;
  final bool? mixinClass;
}

@Target({TargetKind.parameter})
class Path {
  const Path([this.value]);
  final String? value;
}

enum BodyType {
  stream,
  bytes,
  string,
  json,

  /// ```dart
  /// @Get('/my-endpoint')
  /// myMethod(@Body.custom() MyCustomType body);
  /// FutureOr<String | List<int> | Stream<List<int>>> $myMethodEncode(MyCustomType body) {
  ///   // custom encoding logic here
  /// }
  /// ```
  custom,
}

@Target({TargetKind.parameter})
final class Body {
  const Body() : bodyType = null;
  const Body.stream() : bodyType = BodyType.bytes;
  const Body.bytes() : bodyType = BodyType.bytes;
  const Body.string() : bodyType = BodyType.string;
  const Body.json() : bodyType = BodyType.json;
  const Body.custom() : bodyType = BodyType.custom;

  /// [bodyType] indicates how the body should be serialized and sent.
  /// if [:null:], we try to infer the body type from the parameter type.
  /// if [bodyType] is provided, it will be used to serialize the body, regardless of the parameter type.
  ///
  /// Inference Examples:
  /// - [String] -> BodyType.string
  /// - [List<int>] or Uint8List -> BodyType.bytes
  /// - [Map] or custom objects -> BodyType.json
  /// - Protobuf messages -> BodyType.proto
  /// - If the parameter type is not recognized, defaults to BodyType.custom,
  /// which generates a custom encoder method for you to implement.

  final BodyType? bodyType;
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
const query = Queries();

@Target({TargetKind.parameter})
final class Queries {
  const Queries();
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
