import 'package:flutter/material.dart';
import '../hardware/pico_led_service.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';

class PicoLedTestScreen extends StatefulWidget {
  const PicoLedTestScreen({super.key, this.service});
  final PicoLedService? service;
  @override
  State<PicoLedTestScreen> createState() => _PicoLedTestScreenState();
}

class _PicoLedTestScreenState extends State<PicoLedTestScreen> {
  PicoLedService? _service;
  bool _busy = false, _failed = false;
  bool? _led;
  String _status = 'Noch nicht geprüft';
  String? _message;
  @override
  void initState() {
    super.initState();
    try {
      _service = widget.service ?? PicoLedService();
    } catch (_) {
      _failed = true;
      _status = 'Konfiguration fehlerhaft';
      _message = 'Die Pico-Adresse ist ungültig. Prüfe PICO_BASE_URL.';
    }
  }

  Future<void> _send(bool on) async {
    if (_busy || _service == null) return;
    setState(() {
      _busy = true;
      _failed = false;
      _status = 'Verbindung wird geprüft …';
      _message = on ? 'LED wird eingeschaltet …' : 'LED wird ausgeschaltet …';
    });
    try {
      await _service!.setLed(on);
      if (!mounted) return;
      setState(() {
        _led = on;
        _status = 'Verbunden';
        _message = on ? 'LED eingeschaltet.' : 'LED ausgeschaltet.';
      });
    } on PicoLedException catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _led = null;
        _status = 'Verbindung fehlgeschlagen';
        _message = error.message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Box-Steuerung')),
    body: SafeArea(
      child: ViewportFit(
        maxWidth: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _led == true
                  ? Icons.lightbulb_rounded
                  : Icons.lightbulb_outline_rounded,
              size: 64,
              color: _failed
                  ? CalendarStyle.muted
                  : _led == true
                  ? CalendarStyle.gold
                  : CalendarStyle.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Pico W · LED-Test',
              textAlign: TextAlign.center,
              style: TextStyle(color: CalendarStyle.green, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              (_service?.baseUri.toString() ?? PicoLedService.defaultBaseUrl),
              textAlign: TextAlign.center,
              style: const TextStyle(color: CalendarStyle.muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E9DA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    if (_busy) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _failed
                            ? const Color(0xFFAE594C)
                            : CalendarStyle.green,
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: CalendarStyle.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy || _service == null ? null : () => _send(true),
              icon: const Icon(Icons.lightbulb_rounded),
              label: const Text('LED einschalten'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy || _service == null ? null : () => _send(false),
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: const Text('LED ausschalten'),
            ),
          ],
        ),
      ),
    ),
  );
}
