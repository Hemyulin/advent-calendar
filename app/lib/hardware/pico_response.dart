class PicoResponse {
  const PicoResponse(this.statusCode, [this.body = '']);
  final int statusCode;
  final String body;
}
