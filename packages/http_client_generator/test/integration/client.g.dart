// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// HttpClientGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

mixin _$A {
  @protected
  Future<http.StreamedResponse> $send(http.BaseRequest request) async {
    final client = http.Client();
    try {
      return await client.send(request);
    } finally {
      client.close();
    }
  }

  String get baseUrl => 'http://example.com';
  Uri get baseUri => Uri.parse(baseUrl);
}

class _A extends A {
  _A(String super.thing) : super._();

  Future<http.Response> getResponse() {
    final request = http.Request('GET', baseUri.resolve('/response'));
    return $send(request).then(http.Response.fromStream).then((response) {
      return response;
    });
  }

  Future<Data> getThing() {
    final request = http.Request('GET', baseUri.resolve('/thing'));
    return $send(request).then(http.Response.fromStream).then((response) {
      return Data.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    });
  }

  Future<String> getRawThing() {
    final request = http.Request('GET', baseUri.resolve('/raw-thing'));
    return $send(request).then(http.Response.fromStream).then((response) {
      return response.body;
    });
  }
}
