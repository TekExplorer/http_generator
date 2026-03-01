import 'dart:core';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_annotation/http_annotation.dart';

part 'client.g.dart';

class SpecialClass {}

@Headers({'x-class-header': 'class-header-value'})
@RestClient()
class NoBaseUrl with _$NoBaseUrl {
  NoBaseUrl({required this.baseUrl});

  @override
  final Uri baseUrl;
  @override
  Map<String, String> _getResponseHeaders(
    Fields fields, {
    SpecialClass? specialHeader,
  }) {
    return {
      ...fields.toJson().cast<String, String>(),
      if (specialHeader != null)
        'special-header': 'special-${specialHeader.hashCode}',
    };
  }

  @override
  @Method('GET', '/response', headers: {'x-header': 'value'})
  @Headers({'x-method-header': 'method-header-value'})
  Future<Response> getResponse(
    @Headers() Map<String, String> headers,
    @Header('x-param-header') String? paramHeader,
    @Headers() Fields fields, {
    @Header() SpecialClass? specialHeader,
  });

  @override
  BodyEncoded _updateThingEncode(SpecialClass body) {
    return .string('custom-encoded-${body.hashCode}');
  }

  @override
  @Post('/special')
  Future<StreamedResponse> updateThing(@Body() SpecialClass body);

  @override
  BodyEncoded _updateThing2Encode(SpecialClass body) {
    return .fields({'custom': 'custom-encoded-${body.hashCode}'});
  }

  @override
  SpecialClass _updateThing2Decode(Response response) {
    return SpecialClass();
  }

  @override
  @Post('/special')
  Future<SpecialClass> updateThing2(@Body() @custom SpecialClass body);

  @override
  FutureOr<void> _multipartBuildMultipart(
    MultipartBuilder $builder,
    io.File fileIo,
    Object unknown,
  ) async {
    $builder.files['file_io'] = .fromBytes(
      await fileIo.readAsBytes(),
      filename: fileIo.path.split('/').last,
    );
  }

  @override
  @Post('/multipart', multipart: true)
  Future<void> multipart(
    @Field('file') FilePart file,
    @Field('name') String name,
    @Field('age') int? age,
    // TODO: clearly we want an @custom
    @Field() http.MultipartFile file2,
    @Field() io.File fileIo,
    @Field() @custom Object unknown,
  );

  @override
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

  // @override
  // get $coding => (
  //   decodeSpecialClass: (response) => SpecialClass(),
  //   encodeSpecialClass: (body) => .string('custom-encoded-${body.hashCode}'),
  // );

  // @override
  // final $coding = .new(
  //   encodeSpecialClass: (body) {
  //     return .fields({'value': 'encoded-${body.hashCode}'});
  //   },
  //   decodeSpecialClass: (response) {
  //     return SpecialClass();
  //   },
  // );
}

@RestClient(
  baseUrl: 'http://example.com',
  mixinClass: true,
  mixinName: 'AClientMixin',
)
abstract class AClient extends AClientMixin {
  AClient(this.client);

  final http.Client client;

  @override
  Future<StreamedResponse> $send(BaseRequest request) {
    return client.send(request);
  }

  @override
  @Method('GET', '/response')
  Future<Response> getResponse();

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
  Future<void> withBody6(@Body.string() String body);

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
  Future<Response> getWithQuery(
    @Query('search') String search,
    @Queries() Map<String, dynamic> filters,
  );

  @override
  @Get('/path/{id}/detail/{detailId}')
  Future<Response> getWithPath(
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
  Future<void> withFields(@fields Map<String, String> fields);

  @override
  @Post('/fields/object')
  Future<void> withFields2(@fields Fields fields);

  @override
  @Post('/fields/generic')
  Future<void> withFields3(@fields GenFields<Stringy> fields);

  @override
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

  @override
  @Put('/stream')
  Future<StreamedResponse> streamed(@Body() Stream<List<int>> body);

  @override
  @Put('/stream')
  Future<StreamedResponse> streamed2(@Body() Stream<Uint8List> body);

  @override
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
