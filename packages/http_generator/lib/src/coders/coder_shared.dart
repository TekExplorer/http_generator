import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

typedef GenericFactories =
    Map<TypeParameterElement, String Function(ConverterContext)>;
typedef Factories = Map<DartType, String Function(ConverterContext)>;

class ConverterContext {
  ConverterContext(this.varName, this.factories, this.library);

  final String varName;
  final GenericFactories factories;
  final LibraryElement library;
  ConverterContext withVar(String newVarName) {
    return ConverterContext(newVarName, factories, library);
  }
}
