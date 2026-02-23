// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// HttpClientGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

mixin _$NoBaseUrl implements $GeneratedClient {
  @protected
  Future<StreamedResponse> $send(BaseRequest request) {
    return request.send();
  }

  Uri get baseUrl;

  Uri $buildUrl(String path) => baseUrl.resolve(path);

  Future<Response> getResponse() async {
    Uri $uri = $buildUrl('/response');
    final $request = await createRequest('GET', $uri);

    return $send($request).then(Response.fromStream);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

mixin _$A implements $GeneratedClient {
  @protected
  Future<StreamedResponse> $send(BaseRequest request) {
    return request.send();
  }

  Uri get baseUrl => Uri.parse('http://example.com');

  Uri $buildUrl(String path) => baseUrl.resolve(path);

  Future<Response> getResponse() async {
    Uri $uri = $buildUrl('/response');
    final $request = await createRequest('GET', $uri);

    return $send($request).then(Response.fromStream);
  }

  Future<Data> getThing() async {
    Uri $uri = $buildUrl('/thing');
    final $request = await createRequest('GET', $uri);

    return $send($request)
        .then(Response.fromStream)
        .then(
          (response) =>
              Data.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        );
  }

  Future<String> getRawThing() async {
    Uri $uri = $buildUrl('/raw-thing');
    final $request = await createRequest('GET', $uri);

    return $send(
      $request,
    ).then(Response.fromStream).then((response) => response.body);
  }

  Future<Gen<Data>> getGenericThing() async {
    Uri $uri = $buildUrl('/generic-thing');
    final $request = await createRequest('GET', $uri);

    return $send($request)
        .then(Response.fromStream)
        .then(
          (response) => Gen<Data>.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
            (object) => Data.fromJson(object as Map<String, dynamic>),
          ),
        );
  }

  Future<void> withBody(String body) async {
    Uri $uri = $buildUrl('/body');
    final $request = await createRequest('POST', $uri, body: jsonEncode(body));

    return $send($request).then(Response.fromStream);
  }

  Future<void> withBody2(Map<String, dynamic> body) async {
    Uri $uri = $buildUrl('/body2');
    final $request = await createRequest('POST', $uri, body: jsonEncode(body));

    return $send($request).then(Response.fromStream);
  }

  Future<void> withBody3(Data body) async {
    Uri $uri = $buildUrl('/body3');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode(body.toJson()),
    );

    return $send($request).then(Response.fromStream);
  }

  Future<void> withBody4(Gen<Data> body) async {
    Uri $uri = $buildUrl('/body4');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode(body.toJson((object) => object.toJson())),
    );

    return $send($request).then(Response.fromStream);
  }

  Future<void> withBody5(List<Data> body) async {
    Uri $uri = $buildUrl('/body5');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode(body.map((e) => e.toJson()).toList()),
    );

    return $send($request).then(Response.fromStream);
  }

  Future<void> withBody6(String body) async {
    Uri $uri = $buildUrl('/body6');
    final $request = await createRequest('POST', $uri, body: body.toString());

    return $send($request).then(Response.fromStream);
  }

  Future<()> getRecord0() async {
    Uri $uri = $buildUrl('/record0');
    final $request = await createRequest('GET', $uri);

    return $send($request).then(Response.fromStream).then((response) => ());
  }

  Future<(int, String)> getRecord2() async {
    Uri $uri = $buildUrl('/record2');
    final $request = await createRequest('GET', $uri);

    return $send($request)
        .then(Response.fromStream)
        .then(
          (response) => () {
            final $map = jsonDecode(response.body) as Map;
            return ($map[0] as int, $map[1] as String);
          }(),
        );
  }

  Future<({int id, String name})> getRecordNamed() async {
    Uri $uri = $buildUrl('/record_named');
    final $request = await createRequest('GET', $uri);

    return $send($request)
        .then(Response.fromStream)
        .then(
          (response) => () {
            final $map = jsonDecode(response.body) as Map;
            return (id: $map['id'] as int, name: $map['name'] as String);
          }(),
        );
  }

  Future<void> withRecordNamedBody(({int id, String name}) body) async {
    Uri $uri = $buildUrl('/record_named_body');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode({'id': body.id, 'name': body.name}),
    );

    return $send($request).then(Response.fromStream);
  }

  Future<void> withRecord2Body((int, String) body) async {
    Uri $uri = $buildUrl('/record2_body');
    final $request = await createRequest(
      'POST',
      $uri,
      body: jsonEncode([body.$1, body.$2]),
    );

    return $send($request).then(Response.fromStream);
  }

  Future<Response> getWithQuery(
    String search,
    Map<String, dynamic> filters,
  ) async {
    Uri $uri = $buildUrl('/query');
    $uri = $uri.replace(
      queryParameters: {...$uri.queryParametersAll, 'search': search}
        ..removeWhere((_, value) => value == null),
    );
    final $request = await createRequest('GET', $uri);

    return $send($request).then(Response.fromStream);
  }

  Future<Response> getWithPath(String id, String detailId) async {
    Uri $uri = $buildUrl('/path/${id}/detail/${detailId}');
    final $request = await createRequest('GET', $uri);

    return $send($request).then(Response.fromStream);
  }

  Future<void> cancelable(Future<void> abortTrigger) async {
    Uri $uri = $buildUrl('/cancelable');
    final $request = await createRequest(
      'GET',
      $uri,
      abortTrigger: abortTrigger,
    );

    return $send($request).then(Response.fromStream);
  }

  Future<List<Map<String, Gen<Data>>>> everything(
    String id,
    String search,
    String fragment,
    Gen<Map<String, Data>> body,
    Future<void> abortTrigger,
  ) async {
    Uri $uri = $buildUrl('/everything/${id}');
    $uri = $uri.replace(
      queryParameters: {...$uri.queryParametersAll, 'search': search}
        ..removeWhere((_, value) => value == null),
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

    final $request2 = await createRequest2(
      'POST',
      $uri,
      abortTrigger: abortTrigger,
      body: Encoded.string(
        jsonEncode(
          body.toJson(
            (object) => object.map((k, v) => MapEntry(k, v.toJson())),
          ),
        ),
      ),
    );

    return $send($request)
        .then(Response.fromStream)
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
    Uri $uri = $buildUrl('/fields');
    final $request = await createRequest('POST', $uri, fields: {...fields});

    return $send($request).then(Response.fromStream);
  }

  Future<void> withFields2(Fields fields) async {
    Uri $uri = $buildUrl('/fields/object');
    final $request = await createRequest(
      'POST',
      $uri,
      fields: {...fields.toJson()},
    );

    return $send($request).then(Response.fromStream);
  }

  Future<void> withFields3(GenFields<Stringy> fields) async {
    Uri $uri = $buildUrl('/fields/generic');
    final $request = await createRequest(
      'POST',
      $uri,
      fields: {...fields.toJson((object) => object.toJson())},
    );

    return $send($request).then(Response.fromStream);
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
    Uri $uri = $buildUrl('/fields');
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

    return $send($request).then(Response.fromStream);
  }

  Future<StreamedResponse> streamed(Stream<List<int>> body) async {
    Uri $uri = $buildUrl('/stream');
    final $request = await createRequest('PUT', $uri, bodyStream: body);

    return $send($request);
  }

  Future<StreamedResponse> streamed2(Stream<Uint8List> body) async {
    Uri $uri = $buildUrl('/stream');
    final $request = await createRequest('PUT', $uri, bodyStream: body);

    return $send($request);
  }

  Future<StreamedResponse> streamed3(http.ByteStream body) async {
    Uri $uri = $buildUrl('/stream');
    final $request = await createRequest('PUT', $uri, bodyStream: body);

    return $send($request);
  }
}
