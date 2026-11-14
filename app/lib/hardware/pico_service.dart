import 'dart:async';
import 'dart:convert';
import 'pico_response.dart';
import 'pico_transport_stub.dart'
    if (dart.library.io) 'pico_transport_io.dart'
    as transport;
export 'pico_response.dart';

typedef PicoRequest = Future<PicoResponse> Function(Uri uri, Duration timeout);

enum PicoConnectionStatus { connected, connecting, disconnected }

class PicoException implements Exception {
  const PicoException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class PicoHealth {
  const PicoHealth({
    required this.device,
    required this.status,
    required this.mode,
    required this.ip,
  });
  final String device, status, mode, ip;
  factory PicoHealth.parse(String body) {
    final json = jsonDecode(body);
    if (json is! Map || json['device'] != 'DoorZero') {
      throw const PicoException('Die Gegenstelle ist kein DoorZero.');
    }
    final ip = json['ip'];
    final octets = ip is String ? ip.split('.') : <String>[];
    final validIp =
        octets.length == 4 &&
        octets.every(
          (o) => RegExp(r'^\d{1,3}$').hasMatch(o) && int.parse(o) <= 255,
        );
    if (json['status'] != 'ready' ||
        json['mode'] is! String ||
        (json['mode'] as String).isEmpty ||
        !validIp) {
      throw const PicoException(
        'DoorZero ist noch nicht bereit oder meldet ungültige Verbindungsdaten.',
      );
    }
    return PicoHealth(
      device: 'DoorZero',
      status: 'ready',
      mode: json['mode'] as String,
      ip: ip as String,
    );
  }
}

/// Existing Pico boundary, now with verified health and bounded reconnection.
/// This service has no lock-unlock operation or device authorization capability.
class PicoService {
  PicoService({
    String? baseUrl,
    List<String>? baseUrls,
    this.timeout = const Duration(milliseconds: 1500),
    this.pollInterval = const Duration(seconds: 15),
    this.retryInterval = const Duration(seconds: 5),
    this.maxRetryInterval = const Duration(seconds: 30),
    PicoRequest? request,
    PicoRequest? postRequest,
  }) : candidates = List.unmodifiable(
         (baseUrls ??
                 (baseUrl == null
                     ? [defaultBaseUrl, defaultHotspotUrl]
                     : [baseUrl]))
             .map(Uri.parse)
             .toSet(),
       ),
       _request = request ?? transport.getResponse,
       _postRequest = postRequest ?? transport.postResponse {
    if (candidates.isEmpty ||
        candidates.any(
          (u) =>
              !['http', 'https'].contains(u.scheme) ||
              u.host.isEmpty ||
              u.userInfo.isNotEmpty ||
              u.hasQuery ||
              u.hasFragment ||
              !['', '/'].contains(u.path),
        ) ||
        [
          timeout,
          pollInterval,
          retryInterval,
          maxRetryInterval,
        ].any((d) => d <= Duration.zero) ||
        maxRetryInterval < retryInterval) {
      throw ArgumentError('Invalid Pico configuration');
    }
  }
  static const defaultBaseUrl = String.fromEnvironment(
    'PICO_BASE_URL',
    defaultValue: 'http://192.168.178.68',
  );
  static const defaultHotspotUrl = String.fromEnvironment(
    'PICO_HOTSPOT_URL',
    defaultValue: 'http://192.168.4.1',
  );
  final List<Uri> candidates;
  final Duration timeout, pollInterval, retryInterval, maxRetryInterval;
  final PicoRequest _request, _postRequest;
  final _changes = StreamController<PicoConnectionStatus>.broadcast();
  PicoConnectionStatus _state = PicoConnectionStatus.disconnected;
  PicoConnectionStatus get state => _state;
  Stream<PicoConnectionStatus> get changes => _changes.stream;
  PicoHealth? _health;
  PicoHealth? get health => _health;
  String? _lastError;
  String? get lastError => _lastError;
  Uri? _activeUri, _lastGood;
  Uri get baseUri => _activeUri ?? candidates.first;
  Timer? _timer;
  Future<bool>? _checking;
  bool _monitoring = false, _disposed = false;
  int _epoch = 0, _failures = 0;

  void _publish(PicoConnectionStatus state) {
    if (_disposed) return;
    _state = state;
    _changes.add(state);
  }

  Future<PicoResponse> _send(Uri uri, {bool post = false}) async {
    try {
      final response = await (post ? _postRequest : _request)(
        uri,
        timeout,
      ).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PicoException(
          'Der Pico meldet einen Fehler (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      return response;
    } on PicoException {
      rethrow;
    } on TimeoutException {
      throw const PicoException(
        'Zeitüberschreitung. Prüfe WLAN und Pico-Adresse.',
      );
    } on FormatException {
      throw const PicoException(
        'Der Pico hat eine ungültige Antwort gesendet.',
      );
    } on UnsupportedError {
      throw const PicoException(
        'Die Pico-Verbindung wird auf dieser Plattform nicht unterstützt. Nutze die Android-App.',
      );
    } catch (_) {
      throw const PicoException(
        'Keine Verbindung zum Pico. Prüfe WLAN, Stromversorgung und Adresse.',
      );
    }
  }

  Future<bool> _probe(int epoch) async {
    if (_state != PicoConnectionStatus.connected) {
      _publish(PicoConnectionStatus.connecting);
    }
    final ordered = [?_lastGood, ...candidates.where((u) => u != _lastGood)];
    for (final uri in ordered) {
      try {
        final response = await _send(uri.resolve('/health'));
        final verified = PicoHealth.parse(response.body);
        if (_disposed || epoch != _epoch) return false;
        _activeUri = uri;
        _lastGood = uri;
        _health = verified;
        _lastError = null;
        _failures = 0;
        _publish(PicoConnectionStatus.connected);
        return true;
      } catch (error) {
        if (_disposed || epoch != _epoch) return false;
        _lastError = error is PicoException
            ? error.message
            : 'Die Gesundheitsprüfung hat eine ungültige Antwort erhalten.';
        _health = null;
        _activeUri = null;
        _publish(PicoConnectionStatus.connecting);
      }
    }
    _failures++;
    _publish(PicoConnectionStatus.disconnected);
    return false;
  }

  Future<bool> checkConnection() {
    if (_disposed) return Future.value(false);
    if (_checking != null) return _checking!;
    _timer?.cancel();
    final epoch = _epoch;
    final future = _probe(epoch);
    _checking = future;
    future.then((_) {
      _checking = null;
      if (!_monitoring || _disposed) return;
      if (epoch != _epoch) {
        unawaited(checkConnection());
      } else {
        _schedule();
      }
    });
    return future;
  }

  void _schedule() {
    _timer?.cancel();
    if (!_monitoring || _disposed) return;
    final delay = _state == PicoConnectionStatus.connected
        ? pollInterval
        : Duration(
            milliseconds:
                (retryInterval.inMilliseconds *
                        (1 << (_failures - 1).clamp(0, 3)))
                    .clamp(1, maxRetryInterval.inMilliseconds),
          );
    _timer = Timer(delay, () => unawaited(checkConnection()));
  }

  void startMonitoring() {
    if (_disposed || _monitoring) return;
    _monitoring = true;
    unawaited(checkConnection());
  }

  void stopMonitoring() {
    if (!_monitoring) return;
    _monitoring = false;
    _epoch++;
    _timer?.cancel();
    _health = null;
    _activeUri = null;
    _publish(PicoConnectionStatus.disconnected);
  }

  /// Completion LED animation only. Never retries an ambiguous POST, never
  /// queues offline events, and never invokes physical unlocking.
  Future<void> acknowledgeGameCompletion() async {
    if (_disposed) return;
    if (_activeUri == null && !await checkConnection()) return;
    final uri = _activeUri;
    if (_disposed || uri == null) return;
    try {
      await _send(uri.resolve('/game/completed'), post: true);
    } on PicoException catch (error) {
      if (error.statusCode == null) {
        _health = null;
        _activeUri = null;
        _lastError = error.message;
        _publish(PicoConnectionStatus.disconnected);
        _schedule();
      }
      rethrow;
    }
  }

  void dispose() {
    if (_disposed) return;
    _monitoring = false;
    _epoch++;
    _timer?.cancel();
    _disposed = true;
    unawaited(_changes.close());
  }
}
