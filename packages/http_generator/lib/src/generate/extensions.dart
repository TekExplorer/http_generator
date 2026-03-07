part of '../generator.dart';

extension on Iterable<FormalParameterElement> {
  String toCode([Formal? formal]) {
    final required = where(
      (p) => p.isRequiredPositional,
    ).map((p) => '${p.toCode(formal)},').join(' ');
    final optional = where(
      (p) => p.isOptionalPositional,
    ).map((p) => p.toCode(formal)).join(', ');
    final named = where(
      (p) => p.isNamed,
    ).map((p) => p.toCode(formal)).join(', ');

    final buffer = StringBuffer();
    buffer.write(required);
    if (optional.isNotEmpty) {
      buffer.write('[$optional]');
    }
    if (named.isNotEmpty) {
      buffer.write('{$named}');
    }
    return buffer.toString();
  }

  String toCallCode() {
    final positional = where(
      (p) => p.isPositional,
    ).map((p) => p.name).join(', ');
    final named = where(
      (p) => p.isNamed,
    ).map((p) => '${p.name}: ${p.name}').join(', ');

    final buffer = StringBuffer();
    buffer.write(positional);
    if (named.isNotEmpty) {
      if (positional.isNotEmpty) buffer.write(', ');
      buffer.write(named);
    }
    return buffer.toString();
  }
}

enum Formal { superFormal, initializingFormal, existing, none }

extension on FormalParameterElement {
  String toCode([Formal? formal]) {
    final buffer = StringBuffer();
    if (isRequiredNamed) buffer.write('required ');
    if (isCovariant) buffer.write('covariant ');
    buffer.write('${type.toCode()} ');

    // switch (formal) {
    //     case Formal.superFormal when isSuperFormal:
    //     case Formal.initializingFormal when isInitializingFormal:
    //       break;
    //     case Formal.existing when !isSuperFormal && !isInitializingFormal:
    //       break;
    //     case null, Formal.none:
    //       break;
    //     default:
    //       throw InvalidGenerationSourceError(
    //         'Formal parameter `${name}` does not match the expected formal type `$formal`.',
    //         element: this,
    //       );
    //   }

    if (formal == Formal.superFormal || (formal == null && isSuperFormal)) {
      buffer.write('super.');
    } else if (formal == Formal.initializingFormal ||
        (formal == null && isInitializingFormal)) {
      buffer.write('this.');
    }

    buffer.write('$name');
    if (defaultValueCode case final defaultValue?) {
      buffer.write(' = $defaultValue');
    }
    return buffer.toString();
  }
}

extension type MethodAnnotation(ConstantReader reader)
    implements ConstantReader, HeadersAnnotation {
  String get method => read('method').stringValue;
  String get path => read('path').stringValue;

  bool? get multipart => read('multipart').nullOr?.boolValue;

  // Map<String, String>? get headers {
  //   final headersReader = read('headers');
  //   if (headersReader.isNull) return null;
  //   return headersReader.mapValue.map(
  //     (key, value) => MapEntry(
  //       ConstantReader(key).stringValue,
  //       ConstantReader(value).stringValue,
  //     ),
  //   );
  // }

  // /// returns like `const {'content': 'value'}`
  // String? get headersCode =>
  //     read('headers').nullOr?.objectValue.toCode(addLeadingConst: false);
}

extension type HeadersAnnotation(ConstantReader reader)
    implements ConstantReader {
  Map<DartObject, DartObject> get headers =>
      read('headers').nullOr?.objectValue.toMapValue()?.cast() ?? {};
}

extension type HeaderAnnotation(ConstantReader reader)
    implements ConstantReader {
  String? get key => read('key').nullOr?.stringValue;
}

extension on ConstantReader {
  ConstantReader? get nullOr => isNull ? null : this;
}

extension on InterfaceType {
  Iterable<MethodElement> get allMethods sync* {
    yield* methods;
    for (var type in allSupertypes) {
      yield* type.methods;
    }
  }
}

String typeParametersToCode(List<TypeParameterElement> typeParameters) {
  if (typeParameters.isEmpty) return '';
  return '<${typeParameters.map((tp) {
    final bound = tp.bound != null ? ' extends ${tp.bound!.toCode()}' : '';
    return '${tp.name}$bound';
  }).join(', ')}>';
}

extension type BodyAnnotation(ConstantReader reader) implements ConstantReader {
  BodyType? get bodyType {
    final bodyTypeObj = read('bodyType').nullOr?.objectValue;
    if (bodyTypeObj == null) return null;
    final index = ConstantReader(bodyTypeObj).read('index').intValue;
    return BodyType.values[index];
  }
}

enum RequestType { fields, multipart, body, none }

extension NonNullMap<V extends Object, K extends Object> on Map<K?, V?> {
  Map<K, V> get nonNulls => {
    for (final entry in entries) ?entry.key: ?entry.value,
  };
}

extension DartTypeIsA on DartType {
  // bool isA(TypeChecker typeChecker) => typeChecker.isAssignableFromType(this);
  bool isExactly(
    TypeChecker typeChecker, [
    Iterable<TypeChecker?> typeArgumentCheckers = const [],
  ]) {
    if (!typeChecker.isExactlyType(this)) return false;

    final typeArguments = typeArgumentsOf(typeChecker);
    if (typeArguments == null) return true;

    if (typeArgumentCheckers.length > typeArguments.length) return false;
    for (var i = 0; i < typeArgumentCheckers.length; i++) {
      final arg = typeArguments.elementAt(i);
      final checker = typeArgumentCheckers.elementAt(i);
      if (checker == null) continue;
      if (!arg.isExactly(checker)) return false;
    }
    return true;
  }

  bool isA(
    TypeChecker typeChecker, [
    Iterable<TypeChecker?>? typeArgumentCheckers,
  ]) => isA2(
    TypeRef(
      typeChecker,
      typeArgumentCheckers?.map((c) => c == null ? null : TypeRef(c)).toList(),
    ),
  );

  bool isA2(TypeRef typeRef) {
    if (!typeRef.checker.isAssignableFromType(this)) return false;
    final typeArgumentsCheckers = typeRef.typeArguments;
    if (typeArgumentsCheckers == null) return true;

    final typeArguments = typeArgumentsOf(typeRef.checker);
    if (typeArguments == null) return true;

    if (typeArgumentsCheckers.length > typeArguments.length) return false;

    for (var i = 0; i < typeArgumentsCheckers.length; i++) {
      final arg = typeArguments.elementAt(i);
      final checker = typeArgumentsCheckers.elementAt(i);
      if (checker == null) continue;
      if (!arg.isA2(checker)) return false;
    }

    return true;
  }

  bool isA3(
    TypeChecker checker, [
    Iterable<Predicate> typeArgumentPredicates = const [],
  ]) {
    if (!checker.isAssignableFromType(this)) return false;
    final typeArguments = typeArgumentsOf(checker);
    if (typeArguments == null) return true;
    if (typeArgumentPredicates.isEmpty) return true;
    for (final (index, predicate) in typeArgumentPredicates.indexed) {
      if (index >= typeArguments.length) break;
      final arg = typeArguments.elementAt(index);
      if (!predicate(arg)) return false;
    }

    return true;
  }
}

typedef Predicate = bool Function(DartType type);

class TypeRef {
  TypeRef(this.checker, [this.typeArguments]);
  factory TypeRef.fromUrl(String url, [List<TypeRef?>? typeArguments]) {
    return TypeRef(Checker.from(url), typeArguments);
  }

  final TypeChecker checker;
  final List<TypeRef?>? typeArguments;
}

extension TypeCheckerRef on TypeChecker {
  TypeRef get asRef => TypeRef(this);
  TypeRef withTypeArguments(List<TypeRef?> typeArguments) =>
      TypeRef(this, typeArguments);
}

// abstract class TypeHelper {
//   bool isExactly(DartType type);
// }

// class _TypeCheckerHelper implements TypeHelper {
//   _TypeCheckerHelper(this.checker);
//   final TypeChecker checker;

//   @override
//   bool isExactly(DartType type) => checker.isExactlyType(type);
// }

// class _ExactTypeCheckerHelper implements TypeHelper {
//   _ExactTypeCheckerHelper(this.type);
//   final DartType type;

//   @override
//   bool isExactly(DartType other) => other == type;
// }
