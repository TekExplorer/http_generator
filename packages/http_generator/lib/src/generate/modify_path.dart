part of '../generator.dart';

String modifyPath(String path, List<FormalParameterElement> formalParameters) {
  final pathParameters = PathAnnotation.annotatedOf(formalParameters);

  final map = {
    for (final (:annotation, :element) in pathParameters)
      annotation.value ?? element.name!: element.name!,
  };

  return escapeDartString(path).replaceAllMapped(RegExp(r'\{([^\}]+)\}'), (
    match,
  ) {
    final key = match.group(1)!;
    final name = map[key];
    if (name == null) return match.group(0)!;
    return '\${$name}';
  });
}

extension type PathAnnotation(ConstantReader reader) implements ConstantReader {
  static Iterable<({PathAnnotation annotation, FormalParameterElement element})>
  annotatedOf(List<FormalParameterElement> formalParameters) => Checker.path
      .annotatedOf(formalParameters)
      .map(
        (e) => (annotation: PathAnnotation(e.annotation), element: e.element),
      );

  String? get value => read('value').nullOr?.stringValue;
}
