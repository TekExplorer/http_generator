import 'dart:async';

import 'package:http/http.dart' as http;

import 'coding/coding.dart';

Future<http.Abortable> $createRequest(
  String method,
  Uri url, {
  Future<void>? abortTrigger,
  FutureOr<Encoded?>? body,
}) async =>
    (await body)?.createRequest(method, url, abortTrigger: abortTrigger) ??
    http.AbortableRequest(method, url, abortTrigger: abortTrigger);

// http.AbortableRequest $createRequest(
//   String method,
//   Uri url, {
//   Future<void>? abortTrigger,
//   SimpleEncoded? body,
// }) =>
//     body?.createRequest(method, url, abortTrigger: abortTrigger) ??
//     http.AbortableRequest(method, url, abortTrigger: abortTrigger);

// http.AbortableStreamedRequest $createStreamedRequest(
//   String method,
//   Uri url, {
//   Future<void>? abortTrigger,
//   required EncodedStream body,
// }) => body.createRequest(method, url, abortTrigger: abortTrigger);

// Future<http.AbortableMultipartRequest> $createMultipartRequest(
//   String method,
//   Uri url, {
//   Future<void>? abortTrigger,
//   required EncodedMultipart body,
// }) async => body.createRequest(method, url, abortTrigger: abortTrigger);

// final class $AbortContext {
//   $AbortContext([this._abortTrigger]) {
//     _abortTrigger?.then((_) => _aborted = true);
//   }
//   final Future<void>? _abortTrigger;
//   bool _aborted = false;

//   bool get aborted => _aborted;

//   void checkAborted() {
//     if (_aborted) throw http.RequestAbortedException();
//   }
// }
