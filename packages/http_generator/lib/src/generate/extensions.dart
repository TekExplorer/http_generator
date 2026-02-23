part of '../generator.dart';

extension on List<FormalParameterElement> {
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
}

enum Formal { superFormal, initializingFormal, none }

extension on FormalParameterElement {
  String toCode([Formal? formal]) {
    final buffer = StringBuffer();
    if (isRequiredNamed) buffer.write('required ');
    if (isCovariant) buffer.write('covariant ');
    buffer.write('${type.toCode()} ');

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
