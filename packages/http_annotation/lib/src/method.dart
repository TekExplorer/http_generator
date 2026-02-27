import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
final class Method {
  const Method(this.method, this.path, {this.headers, this.multipart});
  final String method;
  final String path;
  final Map<String, String>? headers;
  final bool? multipart;
}

@Target({TargetKind.method})
final class Get extends Method {
  const Get(String path, {super.headers}) : super('GET', path);
}

@Target({TargetKind.method})
final class Post extends Method {
  const Post(String path, {super.headers, super.multipart})
    : super('POST', path);
}

@Target({TargetKind.method})
final class Put extends Method {
  const Put(String path, {super.headers, super.multipart}) : super('PUT', path);
}

@Target({TargetKind.method})
final class Delete extends Method {
  const Delete(String path, {super.headers, super.multipart})
    : super('DELETE', path);
}

@Target({TargetKind.method})
final class Patch extends Method {
  const Patch(String path, {super.headers, super.multipart})
    : super('PATCH', path);
}

@Target({TargetKind.method})
final class Head extends Method {
  const Head(String path, {super.headers}) : super('HEAD', path);
}
