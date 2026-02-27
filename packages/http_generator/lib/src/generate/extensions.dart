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
    implements ConstantReader {
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

  Map<DartObject?, DartObject?>? get headers =>
      read('headers').nullOr?.objectValue.toMapValue();

  /// returns like `const {'content': 'value'}`
  String? get headersCode =>
      read('headers').nullOr?.objectValue.toCode(addLeadingConst: false);
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
  bool isA(TypeChecker typeChecker) => typeChecker.isAssignableFromType(this);
}
