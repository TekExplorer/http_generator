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
    Uri $uri = baseUri.resolve('/response');

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
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
    Uri $uri = baseUri.resolve('/response');

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
      return response;
    });
  }

  Future<Data> getThing() {
    Uri $uri = baseUri.resolve('/thing');

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
      return Data.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    });
  }

  Future<String> getRawThing() {
    Uri $uri = baseUri.resolve('/raw-thing');

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
      return response.body;
    });
  }

  Future<Gen<Data>> getGenericThing() {
    Uri $uri = baseUri.resolve('/generic-thing');

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
      return Gen<Data>.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        (object) => Data.fromJson(object as Map<String, dynamic>),
      );
    });
  }

  Future<void> withBody(String body) {
    Uri $uri = baseUri.resolve('/body');

    final $request = http.AbortableRequest('POST', $uri);
    $request.body = jsonEncode(body);
    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody2(Map<String, dynamic> body) {
    Uri $uri = baseUri.resolve('/body2');

    final $request = http.AbortableRequest('POST', $uri);
    $request.body = jsonEncode(body);
    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody3(Data body) {
    Uri $uri = baseUri.resolve('/body3');

    final $request = http.AbortableRequest('POST', $uri);
    $request.body = jsonEncode(body.toJson());
    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody4(Gen<Data> body) {
    Uri $uri = baseUri.resolve('/body4');

    final $request = http.AbortableRequest('POST', $uri);
    $request.body = jsonEncode(body.toJson((object) => object.toJson()));
    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody5(List<Data> body) {
    Uri $uri = baseUri.resolve('/body5');

    final $request = http.AbortableRequest('POST', $uri);
    $request.body = jsonEncode(body.map((e) => e.toJson()).toList());
    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withBody6(String body) {
    Uri $uri = baseUri.resolve('/body6');

    final $request = http.AbortableRequest('POST', $uri);
    $request.body = body.toString();
    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<()> getRecord0() {
    Uri $uri = baseUri.resolve('/record0');

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
      return ();
    });
  }

  Future<(int, String)> getRecord2() {
    Uri $uri = baseUri.resolve('/record2');

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
      return () {
        final map = jsonDecode(response.body) as Map;
        return (map[0] as int, map[1] as String);
      }();
    });
  }

  Future<({int id, String name})> getRecordNamed() {
    Uri $uri = baseUri.resolve('/record_named');

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
      return () {
        final map = jsonDecode(response.body) as Map;
        return (id: map['id'] as int, name: map['name'] as String);
      }();
    });
  }

  Future<void> withRecordNamedBody(({int id, String name}) body) {
    Uri $uri = baseUri.resolve('/record_named_body');

    final $request = http.AbortableRequest('POST', $uri);
    $request.body = jsonEncode({'id': body.id, 'name': body.name});
    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withRecord2Body((int, String) body) {
    Uri $uri = baseUri.resolve('/record2_body');

    final $request = http.AbortableRequest('POST', $uri);
    $request.body = jsonEncode([body.$1, body.$2]);
    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<http.Response> getWithQuery(
    String search,
    Map<String, dynamic> filters,
  ) {
    Uri $uri = baseUri.resolve('/query');
    $uri = $uri.replace(
      queryParameters: {
        ...$uri.queryParametersAll,
        ...filters,
        'search': search,
      },
    );

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
      return response;
    });
  }

  Future<http.Response> getWithPath(String id, String detailId) {
    Uri $uri = baseUri.resolve('/path/${id}/detail/${detailId}');

    final $request = http.AbortableRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream).then((response) {
      return response;
    });
  }

  Future<void> cancelable(Future<void> abortTrigger) {
    Uri $uri = baseUri.resolve('/cancelable');

    final $request = http.AbortableRequest(
      'GET',
      $uri,
      abortTrigger: abortTrigger,
    );

    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<List<Map<String, Gen<Data>>>> everything(
    String id,
    String search,
    String fragment,
    Gen<Map<String, Data>> body,
    Future<void> abortTrigger,
  ) {
    Uri $uri = baseUri.resolve('/everything/${id}');
    $uri = $uri.replace(
      queryParameters: {...$uri.queryParametersAll, 'search': search},
      fragment: fragment,
    );

    final $request = http.AbortableRequest(
      'POST',
      $uri,
      abortTrigger: abortTrigger,
    );
    $request.body = jsonEncode(
      body.toJson((object) => object.map((k, v) => MapEntry(k, v.toJson()))),
    );
    return $send($request).then(http.Response.fromStream).then((response) {
      return (jsonDecode(response.body) as List)
          .map(
            (e) => (e as Map).map(
              (k, v) => MapEntry(
                k as String,
                Gen<Data>.fromJson(
                  v as Map<String, dynamic>,
                  (object) => Data.fromJson(object as Map<String, dynamic>),
                ),
              ),
            ),
          )
          .toList();
    });
  }

  Future<void> withFields(Map<String, String> fields) {
    Uri $uri = baseUri.resolve('/fields');

    final $request = http.AbortableRequest('POST', $uri);
    final $fields = <String, Object?>{...fields /* is a map */};
    $fields.removeWhere((_, v) => v == 'null');
    $request.bodyFields = $fields.map((k, v) => MapEntry(k, v.toString()));

    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withFields2(Fields fields) {
    Uri $uri = baseUri.resolve('/fields/object');

    final $request = http.AbortableRequest('POST', $uri);
    final $fields = <String, Object?>{...fields.toJson()};
    $fields.removeWhere((_, v) => v == 'null');
    $request.bodyFields = $fields.map((k, v) => MapEntry(k, v.toString()));

    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withFields3(GenFields<Stringy> fields) {
    Uri $uri = baseUri.resolve('/fields/generic');

    final $request = http.AbortableRequest('POST', $uri);
    final $fields = <String, Object?>{
      ...fields.toJson((object) => object.toJson()),
    };
    $fields.removeWhere((_, v) => v == 'null');
    $request.bodyFields = $fields.map((k, v) => MapEntry(k, v.toString()));

    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }

  Future<void> withFields4(
    String field1,
    String field2,
    int field3,
    String? field4,
    Data? field5,
    Fields grouped,
    Map<String, String> rest,
  ) {
    Uri $uri = baseUri.resolve('/fields');

    final $request = http.AbortableRequest('POST', $uri);
    final $fields = <String, Object?>{
      'f1': field1,
      'f2': field2,
      'f3': field3,
      'f4': field4,
      'f5': field5?.toJson(),
      ...grouped.toJson(),
      ...rest /* is a map */,
    };
    $fields.removeWhere((_, v) => v == 'null');
    $request.bodyFields = $fields.map((k, v) => MapEntry(k, v.toString()));

    return $send($request).then(http.Response.fromStream).then((response) {
      return;
    });
  }
}
