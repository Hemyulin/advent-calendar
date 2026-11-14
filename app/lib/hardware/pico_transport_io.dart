import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'pico_response.dart';

Future<PicoResponse> getResponse(Uri uri, Duration timeout) =>
    _response('GET', uri, timeout);
Future<PicoResponse> postResponse(Uri uri, Duration timeout) =>
    _response('POST', uri, timeout);

Future<PicoResponse> _response(String method, Uri uri, Duration timeout) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    return await (() async {
      final request = await client.openUrl(method, uri);
      if (method == 'POST') request.contentLength = 0;
      request.followRedirects = false;
      final response = await request.close();
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        if (bytes.length + chunk.length > 8192) {
          throw const FormatException('Pico response too large');
        }
        bytes.add(chunk);
      }
      return PicoResponse(response.statusCode, utf8.decode(bytes.takeBytes()));
    })().timeout(timeout);
  } finally {
    client.close(force: true);
  }
}
