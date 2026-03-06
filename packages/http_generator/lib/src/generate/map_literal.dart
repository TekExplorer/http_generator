// leave the dot-shorthands alone

// sealed class Literal {}

import 'package:source_helper/source_helper.dart';

extension StringLiteralExt on String {
  String get literal => escapeDartString(this);
}

sealed class CollectionLiteral {
  CollectionLiteral({this.nullAware = true});
  final bool nullAware;

  final elements = <CollectionEntry>[];
  bool get isEmpty => elements.isEmpty;
  bool get isNotEmpty => elements.isNotEmpty;

  void addLiteral(CollectionLiteral literal) => addAll(literal.elements);

  void addAll(Iterable<CollectionEntry> newElements) =>
      elements.addAll(newElements);

  void addEntry(CollectionEntry entry) => elements.add(entry);

  void addSpread(String expression) => addEntry(.spread(expression));

  (String, String) get _delimiters => ('{', '}');

  @override
  String toString() {
    final elements = this.elements.map(
      (e) => nullAware ? e.nullAware : e.nullUnaware,
    );

    final (l, r) = _delimiters;
    return '$l${elements.join(', ')}$r';
  }
}

// sealed class IterableLiteral extends CollectionLiteral {
//   IterableLiteral();
//   IterableLiteral.of(Iterable<CollectionEntry> elements) {
//     addAll(elements);
//   }

//   void add(String element) => addEntry(.element(element));
// }

// final class ListLiteral extends IterableLiteral {
//   @override
//   (String, String) get _delimiters => ('[', ']');
// }

// final class SetLiteral extends IterableLiteral {}

final class MapLiteral extends CollectionLiteral {
  void add(String key, String expression) =>
      addEntry(.mapEntry(key, expression));
}

abstract final class CollectionEntry {
  factory CollectionEntry.spread(String expression) = _CollectionEntrySpread;
  factory CollectionEntry.element(String expression) = _CollectionEntryElement;
  factory CollectionEntry.mapEntry(String key, String expression) =
      _CollectionMapEntry;

  String get expression;

  CollectionEntry get nullAware;
  CollectionEntry get nullUnaware;

  @override
  String toString();
}

final class _CollectionEntryElement implements CollectionEntry {
  @override
  final String expression;

  _CollectionEntryElement(this.expression);

  @override
  String toString() => expression;

  @override
  _CollectionEntryElement get nullAware => .new('?${nullUnaware.expression}');

  @override
  _CollectionEntryElement get nullUnaware {
    final expression = this.expression.trim();
    if (expression.startsWith('?')) return .new(expression.substring(1));
    return .new(expression);
  }
}

final class _CollectionEntrySpread implements CollectionEntry {
  @override
  final String expression;

  _CollectionEntrySpread(this.expression);

  @override
  String toString() => '...$expression';

  @override
  _CollectionEntrySpread get nullAware => .new('?${nullUnaware.expression}');

  @override
  _CollectionEntrySpread get nullUnaware {
    final expression = this.expression.trim();
    if (expression.startsWith('?')) return .new(expression.substring(1));
    return .new(expression);
  }
}

final class _CollectionMapEntry implements _CollectionEntryElement {
  final String key;

  final String value;

  @override
  String get expression => '${key.literal}: $value';

  _CollectionMapEntry(this.key, this.value);

  @override
  String toString() => '$key: $expression';

  @override
  _CollectionMapEntry get nullAware => .new(key, '?${nullUnaware.expression}');

  @override
  _CollectionMapEntry get nullUnaware {
    final value = this.value.trim();
    if (value.startsWith('?')) return .new(key, value.substring(1));
    return .new(key, value);
  }
}
