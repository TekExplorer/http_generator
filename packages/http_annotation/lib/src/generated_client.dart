import 'dart:async';

import 'package:http_annotation/http_annotation.dart';

abstract class $GeneratedClient {
  Uri get baseUrl;

  @protected
  Uri $buildUrl(String path);

  @protected
  Future<StreamedResponse> $send(BaseRequest request);
}
