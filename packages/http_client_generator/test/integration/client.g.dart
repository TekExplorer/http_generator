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

  Future<http.Response> getResponse() async {
    Uri $uri = baseUri.resolve('/response');
    final $request = await createRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream);
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

  Future<http.Response> getResponse() async {
    Uri $uri = baseUri.resolve('/response');
    final $request = await createRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream);
  }

  Future<Data> getThing() async {
    Uri $uri = baseUri.resolve('/thing');
    final $request = await createRequest('GET', $uri);

    return $send($request)
        .then(http.Response.fromStream)
        .then(
          (response) =>
              Data.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        );
  }

  Future<String> getRawThing() async {
    Uri $uri = baseUri.resolve('/raw-thing');
    final $request = await createRequest('GET', $uri);

    return $send(
      $request,
    ).then(http.Response.fromStream).then((response) => response.body);
  }

  Future<Gen<Data>> getGenericThing() async {
    Uri $uri = baseUri.resolve('/generic-thing');
    final $request = await createRequest('GET', $uri);

    return $send($request)
        .then(http.Response.fromStream)
        .then(
          (response) => Gen<Data>.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
            (object) => Data.fromJson(object as Map<String, dynamic>),
          ),
        );
  }

  Future<void> withBody(String body) async {
    Uri $uri = baseUri.resolve('/body');
    final $request = await createRequest('POST', $uri, body: jsonEncode(body));

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody2(Map<String, dynamic> body) async {
    Uri $uri = baseUri.resolve('/body2');
    final $request = await createRequest('POST', $uri, body: jsonEncode(body));

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody3(Data body) async {
    Uri $uri = baseUri.resolve('/body3');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode(body.toJson()),
    );

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody4(Gen<Data> body) async {
    Uri $uri = baseUri.resolve('/body4');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode(body.toJson((object) => object.toJson())),
    );

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody5(List<Data> body) async {
    Uri $uri = baseUri.resolve('/body5');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode(body.map((e) => e.toJson()).toList()),
    );

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody6(String body) async {
    Uri $uri = baseUri.resolve('/body6');
    final $request = await createRequest('POST', $uri, body: body.toString());

    return $send($request).then(http.Response.fromStream);
  }

  Future<()> getRecord0() async {
    Uri $uri = baseUri.resolve('/record0');
    final $request = await createRequest('GET', $uri);

    return $send(
      $request,
    ).then(http.Response.fromStream).then((response) => ());
  }

  Future<(int, String)> getRecord2() async {
    Uri $uri = baseUri.resolve('/record2');
    final $request = await createRequest('GET', $uri);

    return $send($request)
        .then(http.Response.fromStream)
        .then(
          (response) => () {
            final $map = jsonDecode(response.body) as Map;
            return ($map[0] as int, $map[1] as String);
          }(),
        );
  }

  Future<({int id, String name})> getRecordNamed() async {
    Uri $uri = baseUri.resolve('/record_named');
    final $request = await createRequest('GET', $uri);

    return $send($request)
        .then(http.Response.fromStream)
        .then(
          (response) => () {
            final $map = jsonDecode(response.body) as Map;
            return (id: $map['id'] as int, name: $map['name'] as String);
          }(),
        );
  }

  Future<void> withRecordNamedBody(({int id, String name}) body) async {
    Uri $uri = baseUri.resolve('/record_named_body');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode({'id': body.id, 'name': body.name}),
    );

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> withRecord2Body((int, String) body) async {
    Uri $uri = baseUri.resolve('/record2_body');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode([body.$1, body.$2]),
    );

    return $send($request).then(http.Response.fromStream);
  }

  Future<http.Response> getWithQuery(
    String search,
    Map<String, dynamic> filters,
  ) async {
    Uri $uri = baseUri.resolve('/query');
    $uri = $uri.replace(
      queryParameters: {
        ...$uri.queryParametersAll,
        ...filters,
        'search': search,
      },
    );
    final $request = await createRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream);
  }

  Future<http.Response> getWithPath(String id, String detailId) async {
    Uri $uri = baseUri.resolve('/path/${id}/detail/${detailId}');
    final $request = await createRequest('GET', $uri);

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> cancelable(Future<void> abortTrigger) async {
    Uri $uri = baseUri.resolve('/cancelable');
    final $request = await createRequest(
      'GET',
      $uri,
      abortTrigger: abortTrigger,
    );

    return $send($request).then(http.Response.fromStream);
  }

  Future<List<Map<String, Gen<Data>>>> everything(
    String id,
    String search,
    String fragment,
    Gen<Map<String, Data>> body,
    Future<void> abortTrigger,
  ) async {
    Uri $uri = baseUri.resolve('/everything/${id}');
    $uri = $uri.replace(
      queryParameters: {...$uri.queryParametersAll, 'search': search},
      fragment: fragment,
    );
    final $request = await createRequest(
      'POST',
      $uri,
      abortTrigger: abortTrigger,
      body: jsonEncode(
        body.toJson((object) => object.map((k, v) => MapEntry(k, v.toJson()))),
      ),
    );

    return $send($request)
        .then(http.Response.fromStream)
        .then(
          (response) => (jsonDecode(response.body) as List)
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
              .toList(),
        );
  }

  Future<void> withFields(Map<String, String> fields) async {
    Uri $uri = baseUri.resolve('/fields');
    final $request = await createRequest('POST', $uri, fields: {...fields});

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> withFields2(Fields fields) async {
    Uri $uri = baseUri.resolve('/fields/object');
    final $request = await createRequest(
      'POST',
      $uri,
      fields: {...fields.toJson()},
    );

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> withFields3(GenFields<Stringy> fields) async {
    Uri $uri = baseUri.resolve('/fields/generic');
    final $request = await createRequest(
      'POST',
      $uri,
      fields: {...fields.toJson((object) => object.toJson())},
    );

    return $send($request).then(http.Response.fromStream);
  }

  Future<void> withFields4(
    String field1,
    String field2,
    int field3,
    String? field4,
    Data? field5,
    Fields grouped,
    Map<String, String> rest,
  ) async {
    Uri $uri = baseUri.resolve('/fields');
    final $request = await createRequest(
      'POST',
      $uri,
      fields: {
        'f1': field1,
        'f2': field2,
        'f3': field3,
        'f4': field4,
        'f5': field5?.toJson(),
        ...grouped.toJson(),
        ...rest,
      },
    );

    return $send($request).then(http.Response.fromStream);
  }

  Future<http.StreamedResponse> streamed(Stream<List<int>> body) async {
    Uri $uri = baseUri.resolve('/stream');
    final $request = await createRequest('PUT', $uri, bodyStream: body);

    return $send($request);
  }

  Future<http.StreamedResponse> streamed2(Stream<Uint8List> body) async {
    Uri $uri = baseUri.resolve('/stream');
    final $request = await createRequest('PUT', $uri, bodyStream: body);

    return $send($request);
  }

  Future<http.StreamedResponse> streamed3(http.ByteStream body) async {
    Uri $uri = baseUri.resolve('/stream');
    final $request = await createRequest('PUT', $uri, bodyStream: body);

    return $send($request);
  }
}
