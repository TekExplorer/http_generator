// ignore: unused_import
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;
import 'package:http_client_annotation/http_client_annotation.dart';

part 'client.g.dart';

@RestClient()
class NoBaseUrl with _$NoBaseUrl {
  NoBaseUrl({required this.baseUrl});

  @override
  final String baseUrl;

  @override
  @Method('GET', '/response')
  Future<http.Response> getResponse();
}

@RestClient('http://example.com')
abstract class A with _$A {
  A(this.client);

  final http.Client client;

  @override
  Future<http.StreamedResponse> $send(http.BaseRequest request) {
    return client.send(request);
  }

  @override
  @Method('GET', '/response')
  Future<http.Response> getResponse();

  @override
  @Method('GET', '/thing')
  Future<Data> getThing();

  @override
  @Method('GET', '/raw-thing')
  Future<String> getRawThing();

  @override
  @Get('/generic-thing')
  Future<Gen<Data>> getGenericThing();

  @override
  @Post('/body')
  Future<void> withBody(@Body() String body);

  @override
  @Post('/body2')
  Future<void> withBody2(@Body() Map<String, dynamic> body);

  @override
  @Post('/body3')
  Future<void> withBody3(@Body() Data body);

  @override
  @Post('/body4')
  Future<void> withBody4(@Body() Gen<Data> body);

  @override
  @Post('/body5')
  Future<void> withBody5(@Body() List<Data> body);

  @override
  @Post('/body6')
  Future<void> withBody6(@Body(raw: true) String body);

  @override
  @Get('/record0')
  Future<()> getRecord0();

  // @Get('/record1')
  // Future<(int i,)> getRecord1();

  @override
  @Get('/record2')
  Future<(int i, String name)> getRecord2();

  @override
  @Get('/record_named')
  Future<({int id, String name})> getRecordNamed();

  @override
  @Post('/record_named_body')
  Future<void> withRecordNamedBody(@Body() ({int id, String name}) body);

  @override
  @Post('/record2_body')
  Future<void> withRecord2Body(@Body() (int i, String name) body);

  @override
  @Get('/query')
  Future<http.Response> getWithQuery(
    @Query('search') String search,
    @QueryAll() Map<String, dynamic> filters,
  );

  @override
  @Get('/path/{id}/detail/{detailId}')
  Future<http.Response> getWithPath(
    @Path('id') String id,
    @Path('detailId') String detailId,
  );

  @override
  @Get('/cancelable')
  Future<void> cancelable(@Cancel() Future<void> abortTrigger);

  @override
  @Post('/everything/{id}')
  Future<List<Map<String, Gen<Data>>>> everything(
    @Path('id') String id,
    @Query('search') String search,
    @Fragment() String fragment,
    @Body() Gen<Map<String, Data>> body,
    @Cancel() Future<void> abortTrigger,
  );

  @override
  @Post('/fields')
  Future<void> withFields(@formFields Map<String, String> fields);

  @override
  @Post('/fields/object')
  Future<void> withFields2(@formFields Fields fields);

  @override
  @Post('/fields/generic')
  Future<void> withFields3(@formFields GenFields<Stringy> fields);

  @override
  @Post('/fields')
  Future<void> withFields4(
    @Field('f1') String field1,
    @Field('f2') String field2,
    @Field('f3') int field3,
    @Field('f4') String? field4,
    @Field('f5') Data? field5,
    @formFields Fields grouped,
    @formFields Map<String, String> rest,
  );
}

void x() {
  http.AbortableRequest('method', Uri());
  http.AbortableMultipartRequest('method', Uri());
  http.AbortableStreamedRequest('method', Uri());
}

class Data {
  Data(this.value);
  final String value;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(json['value'] as String);
  }

  Map<String, dynamic> toJson() => {'value': value};
}

class Gen<T> {
  Gen(this.value);
  final T value;

  factory Gen.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => Gen<T>(fromJsonT(json['value']));

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
    'value': toJsonT(value),
  };
}

class Fields {
  Map<String, dynamic> toJson() => {};
}

class GenFields<T> {
  GenFields(this.value);
  final T value;

  Map<String, String> toJson(String Function(T value) toJsonT) => {
    'value': toJsonT(value),
  };
}

extension type Stringy(String value) implements String {
  String toJson() => value;
}
