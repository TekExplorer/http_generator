import 'package:analyzer/dart/element/element.dart';

import 'type_checker.dart';

class PackageChecker extends TypeChecker {
  PackageChecker(this.package, this.name);

  final String package;
  final String name;

  @override
  bool isExactly(Element element) {
    final uri = element.library!.uri;
    final pkg = uri.pathSegments.first;
    return element.name == name && pkg == package;
  }
}
