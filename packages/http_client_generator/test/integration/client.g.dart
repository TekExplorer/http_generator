// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// HttpClientGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

mixin _$NoBaseUrl {
  @protected
  Future<http.StreamedResponse> $send(http.BaseRequest request) {
    return request.send();
  }

  String get baseUrl;
  Uri get baseUri => Uri.parse(baseUrl);

  Future<http.Response> getResponse() {
    Uri uri = baseUri.resolve('/response');

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return response;
    });
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

mixin _$A {
  @protected
  Future<http.StreamedResponse> $send(http.BaseRequest request) {
    return request.send();
  }

  String get baseUrl => 'http://example.com';
  Uri get baseUri => Uri.parse(baseUrl);

  Future<http.Response> getResponse() {
    Uri uri = baseUri.resolve('/response');

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return response;
    });
  }

  Future<Data> getThing() {
    Uri uri = baseUri.resolve('/thing');

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return Data.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    });
  }

  Future<String> getRawThing() {
    Uri uri = baseUri.resolve('/raw-thing');

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return response.body;
    });
  }

  Future<Gen<Data>> getGenericThing() {
    Uri uri = baseUri.resolve('/generic-thing');

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return Gen<Data>.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        (object) => Data.fromJson(object as Map<String, dynamic>),
      );
    });
  }

  Future<void> withBody(String body) {
    Uri uri = baseUri.resolve('/body');

    final request = http.AbortableRequest('POST', uri);
    request.body = jsonEncode(body);
    return $send(request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody2(Map<String, dynamic> body) {
    Uri uri = baseUri.resolve('/body2');

    final request = http.AbortableRequest('POST', uri);
    request.body = jsonEncode(body);
    return $send(request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody3(Data body) {
    Uri uri = baseUri.resolve('/body3');

    final request = http.AbortableRequest('POST', uri);
    request.body = jsonEncode(body);
    return $send(request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody4(Gen<Data> body) {
    Uri uri = baseUri.resolve('/body4');

    final request = http.AbortableRequest('POST', uri);
    request.body = jsonEncode(body.toJson((object) => object));
    return $send(request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody5(List<Data> body) {
    Uri uri = baseUri.resolve('/body5');

    final request = http.AbortableRequest('POST', uri);
    request.body = jsonEncode(body);
    return $send(request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody6(String body) {
    Uri uri = baseUri.resolve('/body6');

    final request = http.AbortableRequest('POST', uri);
    request.body = body.toString();
    return $send(request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<()> getRecord0() {
    Uri uri = baseUri.resolve('/record0');

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return ();
    });
  }

  Future<(int, String)> getRecord2() {
    Uri uri = baseUri.resolve('/record2');

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return () {
        final map = jsonDecode(response.body) as Map;
        return (map[0] as int, map[1] as String);
      }();
    });
  }

  Future<({int id, String name})> getRecordNamed() {
    Uri uri = baseUri.resolve('/record_named');

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return () {
        final map = jsonDecode(response.body) as Map;
        return (id: map['id'] as int, name: map['name'] as String);
      }();
    });
  }

  Future<void> withRecordNamedBody(({int id, String name}) body) {
    Uri uri = baseUri.resolve('/record_named_body');

    final request = http.AbortableRequest('POST', uri);
    request.body = jsonEncode({'id': body.id, 'name': body.name});
    return $send(request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withRecord2Body((int, String) body) {
    Uri uri = baseUri.resolve('/record2_body');

    final request = http.AbortableRequest('POST', uri);
    request.body = jsonEncode([body.$1, body.$2]);
    return $send(request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<http.Response> getWithQuery(
    String search,
    Map<String, dynamic> filters,
  ) {
    Uri uri = baseUri.resolve('/query');
    uri = uri.replace(
      queryParameters: {
        ...uri.queryParametersAll,
        ...filters,
        'search': search,
      },
    );

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return response;
    });
  }

  Future<http.Response> getWithPath(String id, String detailId) {
    Uri uri = baseUri.resolve('/path/${id}/detail/${detailId}');

    final request = http.AbortableRequest('GET', uri);

    return $send(request).then(http.Response.fromStream).then((response) {
      return response;
    });
  }

  Future<void> cancelable(Future<void> abortTrigger) {
    Uri uri = baseUri.resolve('/cancelable');

    final request = http.AbortableRequest(
      'GET',
      uri,
      abortTrigger: abortTrigger,
    );

    return $send(request).then(http.Response.fromStream).then((response) {
      return;
    });
  }
}
