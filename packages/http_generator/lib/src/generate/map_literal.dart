import 'package:source_helper/source_helper.dart';

// leave the dot-shorthands alone

// sealed class Literal {}

sealed class CollectionLiteral {
  CollectionLiteral({this.nullAware = true});
  final bool nullAware;

  final elements = <CollectionEntry>[];
  bool get isEmpty => elements.isEmpty;

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

sealed class IterableLiteral extends CollectionLiteral {
  IterableLiteral();
  IterableLiteral.of(Iterable<CollectionEntry> elements) {
    addAll(elements);
  }

  void add(String element) => addEntry(.entry(element));
}

final class ListLiteral extends IterableLiteral {
  @override
  (String, String) get _delimiters => ('[', ']');
}

final class SetLiteral extends IterableLiteral {}

final class MapLiteral extends CollectionLiteral {
  void add(String key, String expression) =>
      addEntry(.mapEntry(key, expression));
}

sealed class CollectionEntry {
  factory CollectionEntry.spread(String expression) = _CollectionEntrySpread;
  factory CollectionEntry.entry(String expression) = _CollectionEntryElement;
  factory CollectionEntry.mapEntry(String key, String expression) =>
      .entry('${escapeDartString(key)}: $expression');

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
  CollectionEntry get nullAware => .entry('?${nullUnaware.expression}');

  @override
  CollectionEntry get nullUnaware => .entry(expression.replaceAll('?', ''));
}

final class _CollectionEntrySpread implements CollectionEntry {
  @override
  final String expression;

  _CollectionEntrySpread(this.expression);

  @override
  String toString() => '...$expression';

  @override
  CollectionEntry get nullAware =>
      .entry('?${nullUnaware.expression.replaceAll(':', ':?')}');

  @override
  CollectionEntry get nullUnaware => .entry(expression.replaceAll('?', ''));
}
