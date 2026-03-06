import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';

extension SealedDartTypeExtension on DartType {
  Ty get sealed => accept(_TypeToTyVisitor());
}

sealed class Ty {
  factory Ty(DartType type) => type.accept(_TypeToTyVisitor());

  DartType get type;
}

final class DynamicTy implements Ty {
  DynamicTy(this.type);
  @override
  final DynamicType type;
}

final class FunctionTy implements Ty {
  FunctionTy(this.type);
  @override
  final FunctionType type;
}

final class InterfaceTy implements Ty {
  InterfaceTy(this.type);
  @override
  final InterfaceType type;
}

final class InvalidTy implements Ty {
  InvalidTy(this.type);
  @override
  final InvalidType type;
}

final class NeverTy implements Ty {
  NeverTy(this.type);
  @override
  final NeverType type;
}

final class RecordTy implements Ty {
  RecordTy(this.type);
  @override
  final RecordType type;
}

final class TypeParameterTy implements Ty {
  TypeParameterTy(this.type);
  @override
  final TypeParameterType type;
}

final class VoidTy implements Ty {
  VoidTy(this.type);
  @override
  final VoidType type;
}

final class _TypeToTyVisitor implements TypeVisitor<Ty> {
  @override
  DynamicTy visitDynamicType(DynamicType type) {
    return DynamicTy(type);
  }

  @override
  FunctionTy visitFunctionType(FunctionType type) {
    return FunctionTy(type);
  }

  @override
  InterfaceTy visitInterfaceType(InterfaceType type) {
    return InterfaceTy(type);
  }

  @override
  InvalidTy visitInvalidType(InvalidType type) {
    return InvalidTy(type);
  }

  @override
  NeverTy visitNeverType(NeverType type) {
    return NeverTy(type);
  }

  @override
  RecordTy visitRecordType(RecordType type) {
    return RecordTy(type);
  }

  @override
  TypeParameterTy visitTypeParameterType(TypeParameterType type) {
    return TypeParameterTy(type);
  }

  @override
  VoidTy visitVoidType(VoidType type) {
    return VoidTy(type);
  }
}
