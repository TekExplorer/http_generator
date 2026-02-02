// ignore: unused_import
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_client_annotation/http_client_annotation.dart';

part 'client.g.dart';

@RestClient('http://example.com')
abstract class A with _$A {
  factory A(String thing) = _A;
  A._(this.thing);

  final String thing;

  @Method('GET', '/response')
  Future<http.Response> getResponse();

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

  Map<String, dynamic> toJson() => {'value': value};
}
