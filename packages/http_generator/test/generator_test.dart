import 'package:build/build.dart';
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

@RestClient(baseUrl: 'http://example.com')
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
      outputs: null,
      flattenOutput: true,
    );

    // You can read all of the generated assets like this...
    // for (final AssetId asset in result.outputs) {
    //   print('reading generated asset: $asset');
    //   print('  can read: ${await readerWriter.canRead(asset)}');
    //   print('  exists: ${readerWriter.testing.exists(asset)}');
    //   print('  content: \n${readerWriter.testing.readString(asset)}');
    // }
    final output = readerWriter.testing.readString(
      AssetId.parse('test_package|lib/a.http_client.g.part'),
    );
    print(output);
    expect(
      output,
      predicate<String>((value) {
        return value.contains(r'mixin _$A') &&
            value.contains(
              "Uri get baseUrl => Uri.parse('http://example.com');",
            );
      }),
    );
  });
}
