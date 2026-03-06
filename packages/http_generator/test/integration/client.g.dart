// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// HttpClientGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

abstract mixin class _$NoBaseUrl implements NoBaseUrl {
  Uri get baseUrl;

  Future<http.Response> getResponse(
    Map<String, String> headers,
    String? paramHeader,
    Fields fields, {
    SpecialClass? specialHeader,
  }) async {
    Uri $uri = baseUrl.resolve('/response');
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {
      'x-class-header': 'class-header-value',
      'x-method-header': 'method-header-value',
      'x-header': 'value',
    });
    $request.headers.addAll({
      'x-param-header': ?paramHeader,
      ...headers,
      ...await _getResponseHeaders(fields, specialHeader: specialHeader),
    });

    return await $send($request).then(http.Response.fromStream);
  }

  Future<http.StreamedResponse> updateThing(SpecialClass body) async {
    Uri $uri = baseUrl.resolve('/special');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: await _updateThingEncode(body),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    return await $send($request);
  }

  Future<SpecialClass> updateThing2(SpecialClass body) async {
    Uri $uri = baseUrl.resolve('/special');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: await _updateThing2Encode(body),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    final $response = await $send($request).then(http.Response.fromStream);
    return _updateThing2Decode($response);
  }

  Future<void> multipart(
    FilePart file,
    String name,
    int? age,
    http.MultipartFile file2,
    io.File fileIo,
    Object unknown,
  ) async {
    Uri $uri = baseUrl.resolve('/multipart');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: await EncodedMultipart.build(($request) async {
        $request.files['file'] = file;
        $request.fields['name'] = name;
        $request.fields['age'] = age?.toString();
        $request.files['file2'] = .fromMultipartFile(file2);
        await _multipartBuildMultipart($request, fileIo, unknown);
      }),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<R> weird<T, R>(
    T body,
    Object? Function(T value) toJsonT,
    R Function(Object? json) fromJsonR,
  ) async {
    Uri $uri = baseUrl.resolve('/weird');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: BodyEncoded.string(jsonEncode(toJsonT(body))),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    final $response = await $send($request).then(http.Response.fromStream);
    return fromJsonR(jsonDecode($response.body));
  }

  Future<http.Response> getResponse2() async {
    Uri $uri = baseUrl.resolve('/response');
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    return await $send($request).then(http.Response.fromStream);
  }

  Future<Data> getThing() async {
    Uri $uri = baseUrl.resolve('/thing');
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    final $response = await $send($request).then(http.Response.fromStream);
    return Data.fromJson(jsonDecode($response.body) as Map<String, dynamic>);
  }

  Future<String> getRawThing() async {
    Uri $uri = baseUrl.resolve('/raw-thing');
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    final $response = await $send($request).then(http.Response.fromStream);
    return $response.body;
  }

  Future<Gen<Data>> getGenericThing() async {
    Uri $uri = baseUrl.resolve('/generic-thing');
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    final $response = await $send($request).then(http.Response.fromStream);
    return Gen<Data>.fromJson(
      jsonDecode($response.body) as Map<String, dynamic>,
      (object) => Data.fromJson(object as Map<String, dynamic>),
    );
  }

  Future<void> withBody(String body) async {
    Uri $uri = baseUrl.resolve('/body');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: BodyEncoded.string(body),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody2(Map<String, dynamic> body) async {
    Uri $uri = baseUrl.resolve('/body2');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: BodyEncoded.string(jsonEncode(body)),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody3(Data body) async {
    Uri $uri = baseUrl.resolve('/body3');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: BodyEncoded.string(jsonEncode(body.toJson())),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody4(Gen<Data> body) async {
    Uri $uri = baseUrl.resolve('/body4');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: BodyEncoded.string(
        jsonEncode(body.toJson((object) => object.toJson())),
      ),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody5(List<Data> body) async {
    Uri $uri = baseUrl.resolve('/body5');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: BodyEncoded.string(jsonEncode(body.map((e) => e.toJson()))),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<void> withBody6(String body) async {
    Uri $uri = baseUrl.resolve('/body6');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: BodyEncoded.string(body),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<()> getRecord0() async {
    Uri $uri = baseUrl.resolve('/record0');
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    final $response = await $send($request).then(http.Response.fromStream);
    return ();
  }

  Future<(int, String)> getRecord2() async {
    Uri $uri = baseUrl.resolve('/record2');
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    final $response = await $send($request).then(http.Response.fromStream);
    return () {
      final $map = jsonDecode($response.body) as Map;
      return ($map[0] as int, $map[1] as String);
    }();
  }

  Future<({int id, String name})> getRecordNamed() async {
    Uri $uri = baseUrl.resolve('/record_named');
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    final $response = await $send($request).then(http.Response.fromStream);
    return () {
      final $map = jsonDecode($response.body) as Map;
      return (id: $map['id'] as int, name: $map['name'] as String);
    }();
  }

  Future<void> withRecordNamedBody(({int id, String name}) body) async {
    Uri $uri = baseUrl.resolve('/record_named_body');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: BodyEncoded.string(jsonEncode({'id': body.id, 'name': body.name})),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<void> withRecord2Body((int, String) body) async {
    Uri $uri = baseUrl.resolve('/record2_body');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: BodyEncoded.string(jsonEncode([body.$1, body.$2])),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<http.Response> getWithQuery(
    String search,
    Map<String, dynamic> filters,
  ) async {
    Uri $uri = baseUrl.resolve('/query');
    $uri = $uri.replace(
      queryParameters: {...$uri.queryParametersAll, 'search': search},
    );
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    return await $send($request).then(http.Response.fromStream);
  }

  Future<http.Response> getWithPath(String id, String detailId) async {
    Uri $uri = baseUrl.resolve('/path/${id}/detail/${detailId}');
    final $request = await $createRequest('GET', $uri);

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    return await $send($request).then(http.Response.fromStream);
  }

  Future<void> cancelable(Future<void> abortTrigger) async {
    Uri $uri = baseUrl.resolve('/cancelable');
    final $request = await $createRequest(
      'GET',
      $uri,
      abortTrigger: abortTrigger,
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<List<Map<String, Gen<Data>>>> everything(
    String id,
    String search,
    String fragment,
    Gen<Map<String, Data>> body,
    Future<void> abortTrigger,
  ) async {
    Uri $uri = baseUrl.resolve('/everything/${id}');
    $uri = $uri.replace(
      queryParameters: {...$uri.queryParametersAll, 'search': search},
      fragment: fragment,
    );
    final $request = await $createRequest(
      'POST',
      $uri,
      abortTrigger: abortTrigger,
      body: BodyEncoded.string(
        jsonEncode(
          body.toJson(
            (object) => object.map((k, v) => MapEntry(k, v.toJson())),
          ),
        ),
      ),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    final $response = await $send($request).then(http.Response.fromStream);
    return (jsonDecode($response.body) as List)
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
  }

  Future<void> withFields(Map<String, String> fields) async {
    Uri $uri = baseUrl.resolve('/fields');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: EncodedFields.from({...fields}),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<void> withFields2(Fields fields) async {
    Uri $uri = baseUrl.resolve('/fields/object');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: EncodedFields.from({...fields.toJson()}),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<void> withFields3(GenFields<Stringy> fields) async {
    Uri $uri = baseUrl.resolve('/fields/generic');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: EncodedFields.from({...fields.toJson((obj) => obj)}),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
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
    Uri $uri = baseUrl.resolve('/fields');
    final $request = await $createRequest(
      'POST',
      $uri,
      body: EncodedFields.from({
        'f1': field1,
        'f2': field2,
        'f3': field3,
        'f4': field4,
        'f5': field5?.toJson(),
        ...grouped.toJson(),
        ...rest,
      }),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    await $send($request).then(http.Response.fromStream);
  }

  Future<http.StreamedResponse> streamed(Stream<List<int>> body) async {
    Uri $uri = baseUrl.resolve('/stream');
    final $request = await $createRequest(
      'PUT',
      $uri,
      body: BodyEncoded.stream(body),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    return await $send($request);
  }

  Future<http.StreamedResponse> streamed2(Stream<Uint8List> body) async {
    Uri $uri = baseUrl.resolve('/stream');
    final $request = await $createRequest(
      'PUT',
      $uri,
      body: BodyEncoded.stream(body),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    return await $send($request);
  }

  Future<http.StreamedResponse> streamed3(http.ByteStream body) async {
    Uri $uri = baseUrl.resolve('/stream');
    final $request = await $createRequest(
      'PUT',
      $uri,
      body: BodyEncoded.stream(body),
    );

    $request.headers.addAll(const {'x-class-header': 'class-header-value'});

    return await $send($request);
  }

  @protected
  FutureOr<Map<String, String>> _getResponseHeaders(
    Fields fields, {
    SpecialClass? specialHeader,
  });
  @protected
  FutureOr<BodyEncoded> _updateThingEncode(SpecialClass body);
  @protected
  FutureOr<BodyEncoded> _updateThing2Encode(SpecialClass body);
  @protected
  FutureOr<SpecialClass> _updateThing2Decode(http.Response response);
  @protected
  FutureOr<void> _multipartBuildMultipart(
    MultipartBuilder $builder,
    io.File fileIo,
    Object unknown,
  );
}
