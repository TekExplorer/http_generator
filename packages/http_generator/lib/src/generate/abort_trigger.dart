part of '../generator.dart';

String? abortTrigger(MethodElement method) {
  final cancels = Checker.cancel.annotatedOf(method.formalParameters);
  if (cancels.isEmpty) return null;

  final futures = <String>[];
  for (final cancel in cancels) {
    final type = cancel.element.type;
    final name = cancel.element.name!;
    if (Checker.cancelToken.isAssignableFromType(type)) {
      final q = type.nullabilitySuffix == .question ? '?' : '';
      futures.add('$name$q.whenCancel');
    } else if (Checker.future.isAssignableFromType(type)) {
      futures.add(name);
    } else {
      throw InvalidGenerationSourceError(
        'Parameter `$name` annotated with `@Cancel` must be of type `CancelToken` or `Future<void>`.',
        element: cancel.element,
      );
    }
  }

  if (futures.length == 1) return futures.single;
  return '#{{dart:async|Future}}.any([${futures.join(', ')}].whereType<#{{dart:async|Future}}<void>>())';
}
