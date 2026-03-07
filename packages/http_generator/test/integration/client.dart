import 'dart:core';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_annotation/http_annotation.dart';

part 'client.g.dart';

class SpecialClass {}

class NoBaseUrlImpl extends NoBaseUrl with _$NoBaseUrl {
  NoBaseUrlImpl({required super.baseUrl, required super.client}) : super._();

  @override
  final _extra = .new(
    getResponseHeaders: (Fields fields, {SpecialClass? specialHeader}) {
      return {
        ...fields.toJson().cast<String, String>(),
        if (specialHeader != null)
          'special-header': 'special-${specialHeader.hashCode}',
      };
    },
    updateThing2Encode: (SpecialClass body) {
      return .fields({'custom': 'custom-encoded-${body.hashCode}'});
    },
    updateThing2Decode: (Response response) {
      return SpecialClass();
    },
    updateThingEncode: (SpecialClass body) {
      return .string('custom-encoded-${body.hashCode}');
    },
    multipartBuildMultipart: (MultipartBuilder $builder, Object unknown) async {
      $builder.fields['unknown'] = unknown.toString();
    },
  );
}

@Headers({'x-class-header': 'class-header-value'})
@RestClient(implementSelf: true, extraType: .factory)
abstract class NoBaseUrl {
  factory NoBaseUrl({required Uri baseUrl, required http.Client client}) =
      NoBaseUrlImpl;

  NoBaseUrl._({required this.baseUrl, required this.client});
  final http.Client client;

  final Uri baseUrl;

  @Method('GET', '/response', headers: {'x-header': 'value'})
  @Headers({'x-method-header': 'method-header-value'})
  Future<Response> getResponse(
    @Headers() Map<String, String> headers,
    @Header('x-param-header') String? paramHeader,
    @Headers() Fields fields, {
    @Header() SpecialClass? specialHeader,
  });

  @Post('/special')
  Future<StreamedResponse> updateThing(@Body() SpecialClass body);

  @Post('/special')
  Future<SpecialClass> updateThing2(@Body() @custom SpecialClass body);

  @Post('/multipart', multipart: true)
  Future<void> multipart(
    @Field('file') FilePart file,
    @Field('name') String name,
    @Field('age') int? age,
    @Field() http.MultipartFile file2,
    @Field() io.File fileIo,
    @Field() @custom Object unknown,
  );

  @Post('/weird')
  Future<R> weird<T, R>(
    @Body.json() T body,
    Object? Function(T value) toJsonT,
    R Function(Object? json) fromJsonR,
  );

  // final _getResponse = (
  //   request: (
  //     headers: (Fields fields, {SpecialClass? specialHeader}) {
  //       return {
  //         ...fields.toJson().cast<String, String>(),
  //         if (specialHeader != null)
  //           'special-header': 'special-${specialHeader.hashCode}',
  //       };
  //     },
  //     intercept: (http.AbortableRequest request) {
  //       // do something with response
  //     },
  //     encode: (SpecialClass body) {
  //       return .fields({'value': 'encoded-${body.hashCode}'});
  //     },
  //   ),
  //   response: (
  //     intercept: (http.Response response) {
  //       // do something with response
  //     },
  //   ),
  // );

  //
  // get $coding => (
  //   decodeSpecialClass: (response) => SpecialClass(),
  //   encodeSpecialClass: (body) => .string('custom-encoded-${body.hashCode}'),
  // );

  //
  // final $coding = .new(
  //   encodeSpecialClass: (body) {
  //     return .fields({'value': 'encoded-${body.hashCode}'});
  //   },
  //   decodeSpecialClass: (response) {
  //     return SpecialClass();
  //   },
  // );

  @Method('GET', '/response')
  Future<Response> getResponse2();

  @Method('GET', '/thing')
  Future<Data> getThing();

  @Method('GET', '/raw-thing')
  Future<String> getRawThing();

  @Get('/generic-thing')
  Future<Gen<Data>> getGenericThing();

  @Post('/body')
  Future<void> withBody(@Body() String body);

  @Post('/body2')
  Future<void> withBody2(@Body() Map<String, dynamic> body);

  @Post('/body3')
  Future<void> withBody3(@Body() Data body);

  @Post('/body4')
  Future<void> withBody4(@Body() Gen<Data> body);

  @Post('/body5')
  Future<void> withBody5(@Body() List<Data> body);

  @Post('/body6')
  Future<void> withBody6(@Body.string() String body);

  @Get('/record0')
  Future<()> getRecord0();

  // @Get('/record1')
  // Future<(int i,)> getRecord1();

  @Get('/record2')
  Future<(int i, String name)> getRecord2();

  @Get('/record_named')
  Future<({int id, String name})> getRecordNamed();

  @Post('/record_named_body')
  Future<void> withRecordNamedBody(@Body() ({int id, String name}) body);

  @Post('/record2_body')
  Future<void> withRecord2Body(@Body() (int i, String name) body);

  @Get('/query')
  Future<Response> getWithQuery(
    @Query('search') String search,
    @Queries() Map<String, dynamic> filters,
  );

  @Get('/path/{id}/detail/{detailId}')
  Future<Response> getWithPath(
    @Path('id') String id,
    @Path('detailId') String detailId,
  );

  @Get('/cancelable')
  Future<void> cancelable(@Cancel() Future<void> abortTrigger);

  @Post('/everything/{id}')
  Future<List<Map<String, Gen<Data>>>> everything(
    @Path('id') String id,
    @Query('search') String search,
    @Fragment() String fragment,
    @Body() Gen<Map<String, Data>> body,
    @Cancel() Future<void> abortTrigger,
  );

  @Post('/fields')
  Future<void> withFields(@fields Map<String, String> fields);

  @Post('/fields/object')
  Future<void> withFields2(@fields Fields fields);

  @Post('/fields/generic')
  Future<void> withFields3(@fields GenFields<Stringy> fields);

  @Post('/fields')
  Future<void> withFields4(
    @Field('f1') String field1,
    @Field('f2') String field2,
    @Field('f3') int field3,
    @Field('f4') String? field4,
    @Field('f5') Data? field5,
    @fields Fields grouped,
    @fields Map<String, String> rest,
  );

  @Put('/stream')
  Future<StreamedResponse> streamed(@Body() Stream<List<int>> body);

  @Put('/stream')
  Future<StreamedResponse> streamed2(@Body() Stream<Uint8List> body);

  @Put('/stream')
  Future<StreamedResponse> streamed3(@Body() http.ByteStream body);
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
  Map<String, String> toJson() => {};
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
