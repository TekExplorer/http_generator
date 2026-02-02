import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
final class Method {
  const Method(this.method, this.path);
  final String method;
  final String path;
}

@Target({TargetKind.method})
final class Get extends Method {
  const Get(String path) : super('GET', path);
}

@Target({TargetKind.method})
final class Post extends Method {
  const Post(String path) : super('POST', path);
}

@Target({TargetKind.method})
final class Put extends Method {
  const Put(String path) : super('PUT', path);
}

@Target({TargetKind.method})
final class Delete extends Method {
  const Delete(String path) : super('DELETE', path);
}

@Target({TargetKind.method})
final class Patch extends Method {
  const Patch(String path) : super('PATCH', path);
}

@Target({TargetKind.method})
final class Head extends Method {
  const Head(String path) : super('HEAD', path);
}
