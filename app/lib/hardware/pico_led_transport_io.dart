import 'dart:io';

Future<int> getStatus(Uri uri, Duration timeout) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    return await (() async {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode;
    })().timeout(timeout);
  } finally {
    client.close(force: true);
  }
}
