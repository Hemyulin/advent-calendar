import 'pico_response.dart';

Future<PicoResponse> getResponse(Uri uri, Duration timeout) async =>
    throw UnsupportedError('Native HTTP transport required');

Future<PicoResponse> postResponse(Uri uri, Duration timeout) async =>
    throw UnsupportedError('Native HTTP transport required');
