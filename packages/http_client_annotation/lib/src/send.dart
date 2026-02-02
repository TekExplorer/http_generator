import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

@internal
Future<http.StreamedResponse> $$send(http.BaseRequest request) async {
  final client = http.Client();
  try {
    return await client.send(request);
  } finally {
    client.close();
  }
}
