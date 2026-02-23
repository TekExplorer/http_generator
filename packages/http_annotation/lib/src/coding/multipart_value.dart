part of 'coding.dart';

sealed class MultipartValue {
  factory MultipartValue(String value) = FieldValue;
  // factory MultipartValue.many(Iterable<String> value) = QueryValue.many;
}

final class FieldValue implements MultipartValue {
  FieldValue(this.value);
  final String value;
}
