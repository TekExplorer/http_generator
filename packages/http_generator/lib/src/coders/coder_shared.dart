import 'package:analyzer/dart/element/element.dart';

class ConverterContext {
  ConverterContext(this.varName, this.library);

  final String varName;
  final LibraryElement library;
  ConverterContext withVar(String newVarName) {
    return ConverterContext(newVarName, library);
  }
}
