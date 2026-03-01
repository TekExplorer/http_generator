import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

class ConverterContext {
  ConverterContext(this.varName, this.library, this.otherFields);

  final String varName;
  final LibraryElement library;
  final Iterable<VariableElement> otherFields;

  VariableElement? getFactory(TypeParameterType type, String prefix) {
    return otherFields.firstWhereOrNull((f) {
      return f.name == '$prefix${type.element.name}';
    });
  }

  ConverterContext withVar(String newVarName) {
    return ConverterContext(newVarName, library, otherFields);
  }
}
