import 'package:build_test/build_test.dart';
import 'package:http_generator/http_generator.dart';
import 'package:test/test.dart';

void main() {
  test('http client generator test', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'test_package');
    await readerWriter.testing.loadIsolateSources();

    await testBuilder(
      httpClientBuilder(),
      rootPackage: 'test_package',
      readerWriter: readerWriter,
      {
        'test_package|lib/a.dart': r'''
import 'package:http_annotation/http_annotation.dart';
import 'dart:convert';
part 'a.g.dart';

@RestClient('http://example.com')
abstract class A with _$A {
  @Method('GET', '/response')
  Future<Response> getResponse();

  @Method('GET', '/thing')
  Future<Data> getThing();

  @Method('GET', '/raw-thing')
  Future<String> getRawThing();
}

class Data {
  Data(this.value);
  final String value;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(json['value'] as String);
  }

  Map<String, dynamic> toJson() => {
        'value': value,
      };
}
''',
      },
      outputs: {
        'test_package|lib/a.http_client.g.part': decodedMatches(
          predicate<String>((value) {
            print(value);
            return value.contains(r'mixin _$A') &&
                value.contains("String get baseUrl => 'http://example.com';");
          }),
        ),
      },
    );
  });
}
