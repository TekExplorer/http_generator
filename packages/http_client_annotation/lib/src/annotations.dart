import 'package:meta/meta_meta.dart';

// TODO: support any interface like mixins, extensions, extension types etc once augmentations are released
@Target({TargetKind.classType})
class RestClient {
  const RestClient([this.baseUrl]);

  final String? baseUrl;
}

@Target({TargetKind.parameter})
final class Body {
  const Body();
}

// A single query parameter, e.g. `?search=foo`
@Target({TargetKind.parameter})
final class Query {
  const Query(this.name);
  final String name;
}

// Multiple query parameters, e.g. `?filter=name&filter=age`
// serialized from an object
@Target({TargetKind.parameter})
final class QueryAll {
  const QueryAll();
}

//// @Post('/upload')
// @MultiPart()
// Future<void> uploadFile(@Part('file') Uint8List file, @Part('description') String description);
@Target({TargetKind.method})
final class MultiPart {
  const MultiPart();
}

/// valid for [File] and [Uint8List] and [String]
@Target({TargetKind.parameter})
final class FilePart extends Part {
  const FilePart(super.name);
}

@Target({TargetKind.parameter})
final class Part {
  const Part(this.name);
  final String name;
}
