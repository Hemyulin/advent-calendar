import 'dart:async';
import 'pico_led_transport_stub.dart'
    if (dart.library.io) 'pico_led_transport_io.dart'
    as transport;

typedef PicoLedRequest = Future<int> Function(Uri uri, Duration timeout);

class PicoLedException implements Exception {
  const PicoLedException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Temporary LED-only diagnostic. This is not a LockGateway implementation and
/// does not grant authorization to operate a physical lock.
class PicoLedService {
  PicoLedService({
    String baseUrl = defaultBaseUrl,
    this.timeout = const Duration(seconds: 3),
    PicoLedRequest? request,
  }) : baseUri = Uri.parse(baseUrl),
       _request = request ?? transport.getStatus {
    if (!['http', 'https'].contains(baseUri.scheme) ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        !['', '/'].contains(baseUri.path) ||
        timeout <= Duration.zero) {
      throw ArgumentError('Invalid Pico LED configuration');
    }
  }
  static const defaultBaseUrl = String.fromEnvironment(
    'PICO_BASE_URL',
    defaultValue: 'http://192.168.178.68',
  );
  final Uri baseUri;
  final Duration timeout;
  final PicoLedRequest _request;

  Future<void> setLed(bool on) async {
    try {
      final status = await _request(
        baseUri.resolve(on ? '/led/on' : '/led/off'),
        timeout,
      ).timeout(timeout);
      if (status < 200 || status >= 300) {
        throw PicoLedException('Der Pico meldet einen Fehler (HTTP $status).');
      }
    } on PicoLedException {
      rethrow;
    } on TimeoutException {
      throw const PicoLedException(
        'Zeitüberschreitung. Prüfe, ob der Pico im selben WLAN erreichbar ist.',
      );
    } on UnsupportedError {
      throw const PicoLedException(
        'Der LED-Test wird auf dieser Plattform nicht unterstützt. Nutze die Android-App.',
      );
    } catch (_) {
      throw const PicoLedException(
        'Keine Verbindung zum Pico. Prüfe WLAN, Stromversorgung und Adresse.',
      );
    }
  }
}
