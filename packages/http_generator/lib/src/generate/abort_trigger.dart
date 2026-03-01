part of '../generator.dart';

String? abortTrigger(MethodElement method) {
  final cancels = Checker.cancel.annotatedOf(method.formalParameters);
  if (cancels.isEmpty) return null;

  final futures = <String>[];
  for (final cancel in cancels) {
    final type = cancel.element.type;
    final name = cancel.element.name!;
    if (type.isA(Checker.cancelToken)) {
      final q = type.nullabilitySuffix == .question ? '?' : '';
      futures.add('$name$q.whenCancel');
    } else if (type.isA(Checker.future)) {
      futures.add(name);
    } else {
      throw InvalidGenerationSourceError(
        'Parameter `$name` annotated with `@Cancel` must be of type `CancelToken` (from Dio) or `Future<void>`.',
        element: cancel.element,
      );
    }
  }

  if (futures.length == 1) return futures.single;
  return '#{{dart:async|Future}}.any([${futures.join(', ')}].whereType<#{{dart:async|Future}}<void>>())';
}
