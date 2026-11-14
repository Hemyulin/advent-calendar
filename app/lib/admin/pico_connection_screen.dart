import 'dart:async';
import 'package:flutter/material.dart';
import '../hardware/pico_service.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';

class PicoConnectionScreen extends StatefulWidget {
  const PicoConnectionScreen({super.key, this.service});
  final PicoService? service;
  @override
  State<PicoConnectionScreen> createState() => _PicoConnectionScreenState();
}

class _PicoConnectionScreenState extends State<PicoConnectionScreen>
    with WidgetsBindingObserver {
  PicoService? _service;
  StreamSubscription<PicoConnectionStatus>? _subscription;
  bool _active = true;
  String? _message;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _service = widget.service ?? PicoService();
      _subscription = _service!.changes.listen((state) {
        if (!mounted) return;
        setState(() {});
      });
    } catch (_) {
      _message = 'Die Pico-Adressen sind ungültig. Prüfe die Konfiguration.';
    }
  }

  void _updateMonitoring() {
    if (_active && ModalRoute.of(context)?.isCurrent != false) {
      _service?.startMonitoring();
    } else {
      _service?.stopMonitoring();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _updateMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _service?.stopMonitoring();
    if (widget.service == null) _service?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _service?.state ?? PicoConnectionStatus.disconnected;
    final connected = state == PicoConnectionStatus.connected;
    final connecting = state == PicoConnectionStatus.connecting;
    final health = _service?.health;
    final message =
        _message ?? (!connected && !connecting ? _service?.lastError : null);
    return Scaffold(
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
                connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                size: 56,
                color: connected ? CalendarStyle.green : CalendarStyle.muted,
              ),
              const SizedBox(height: 20),
              const Text(
                'Pico W · Verbindung',
                textAlign: TextAlign.center,
                style: TextStyle(color: CalendarStyle.green, fontSize: 22),
              ),
              const SizedBox(height: 12),
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
                      if (connecting) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        switch (state) {
                          PicoConnectionStatus.connected => 'Verbunden',
                          PicoConnectionStatus.connecting => 'Verbinde…',
                          PicoConnectionStatus.disconnected =>
                            'Nicht verbunden',
                        },
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CalendarStyle.green,
                        ),
                      ),
                      if (health != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${health.mode == 'hotspot'
                              ? 'Pico-Hotspot'
                              : health.mode == 'connected'
                              ? 'Heim-WLAN'
                              : 'Pico-Netzwerk'} · ${health.ip}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CalendarStyle.muted,
                          ),
                        ),
                      ],
                      if (message != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: CalendarStyle.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!connected && !connecting) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _service == null
                      ? null
                      : () => _service!.checkConnection(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Erneut verbinden'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verbinde dein Handy mit dem Heim-WLAN oder dem Pico-Hotspot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CalendarStyle.muted, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
