import 'package:source_helper/source_helper.dart';

final class MapLiteral {
  MapLiteral([List<MapLiteralEntry>? entries]) : entries = entries ?? [];
  final List<MapLiteralEntry> entries;

  void addAll(Iterable<MapLiteralEntry> newEntries) =>
      entries.addAll(newEntries);

  void addSpread(String expression) =>
      entries.add(MapLiteralEntry.spread(expression));

  void add(String key, String expression) =>
      entries.add(MapLiteralEntry.kv(key, expression));

  @override
  String toString() => '{${entries.join(',\n')}}';
}

sealed class MapLiteralEntry {
  factory MapLiteralEntry.spread(String expression) = _MapLiteralSpread;
  factory MapLiteralEntry.kv(String key, String value) =
      _MapLiteralEntryKeyValue;
}

final class _MapLiteralSpread implements MapLiteralEntry {
  final String expression;

  _MapLiteralSpread(this.expression);

  @override
  String toString() => '...?$expression';
}

final class _MapLiteralEntryKeyValue implements MapLiteralEntry {
  final String key;
  final String value;

  _MapLiteralEntryKeyValue(this.key, this.value);

  @override
  String toString() => '?${escapeDartString(key)}: ?$value';
}
