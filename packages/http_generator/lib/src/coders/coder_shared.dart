import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

class ConverterContext {
  ConverterContext(this.varName, this.library, this.otherFields);
  ConverterContext.from(this.varName, MethodElement method)
    : library = method.library,
      otherFields = method.formalParameters;

  ConverterContext.from2(FormalParameterElement element)
    : varName = element.name!,
      library = element.library!,
      otherFields = switch (element.enclosingElement) {
        FunctionTypedElement(:final formalParameters) => formalParameters,
        _ => [],
      };

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
