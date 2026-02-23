part of '../generator.dart';

String modifyPath(String path, List<FormalParameterElement> formalParameters) {
  final pathParameters = Checker.path
      .annotatedOf(formalParameters)
      .map(
        (param) => (
          path: PathAnnotation(param.annotation).value,
          paramName: param.element.name!,
        ),
      );

  final map = {
    for (final (:path, :paramName) in pathParameters)
      path ?? paramName: paramName,
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
  String? get value => read('value').nullOr?.stringValue;
}
