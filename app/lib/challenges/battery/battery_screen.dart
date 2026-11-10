import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import 'battery_art.dart';
import 'battery_game.dart';

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({
    super.key,
    required this.onComplete,
    this.level = const BatteryLevel(),
    this.alreadyCompleted = false,
  });
  final BatteryLevel level;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late BatteryGame _game;
  late final Ticker _ticker;
  Duration? _previous;
  bool _paused = false, _foreground = true;
  @override
  void initState() {
    super.initState();
    _game = BatteryGame(widget.level);
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      if (!_foreground || ModalRoute.of(context)?.isCurrent == false) {
        setState(_pause);
        return;
      }
      final previous = _previous;
      _previous = elapsed;
      if (previous == null) return;
      setState(() => _game.advance((elapsed - previous).inMicroseconds / 1e6));
      if (_game.phase != BatteryPhase.playing) _ticker.stop();
    });
  }

  void _pause() {
    if (_game.phase == BatteryPhase.playing) _paused = true;
    _ticker.stop();
    _previous = null;
  }

  void _play() {
    if (!_foreground) return;
    setState(() {
      _game.start();
      _paused = false;
      _previous = null;
    });
    if (_game.phase == BatteryPhase.playing && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void _connect(int index) {
    if (_paused || !_foreground) return;
    setState(() => _game.connect(index));
    if (_game.phase == BatteryPhase.ready) _play();
  }

  void _restart() {
    _ticker.stop();
    setState(() {
      _game = BatteryGame(widget.level);
      _paused = false;
      _previous = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == false) _pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) setState(_pause);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terminal =
        _game.phase == BatteryPhase.won || _game.phase == BatteryPhase.lost;
    final enabled = !terminal && !_paused && _foreground;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return GameScaffold(
      title: 'Akku-Panik',
      instructions:
          'Ein Kabel, fünf fast leere Geräte. Zieh den Stecker auf ein Gerät oder tippe es an. Nur dieses Gerät lädt. Halte alle Akkus ${widget.level.duration.round()} Sekunden über 0 %. Kleine Symbole zeigen Stromfresser an. Zum Schluss wird es hektischer. Nach einer Pause geht es erst mit „Weiter“ weiter.',
      alreadyCompleted: widget.alreadyCompleted,
      onRestart: _restart,
      children: [
        GameStats(text: '${_game.remaining.ceil()} s · 5 Geräte · 1 Kabel'),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _game.progress,
            minHeight: 4,
            color: CalendarStyle.green,
            backgroundColor: CalendarStyle.line,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 440,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CablePainter(
                        _game.connected,
                        CalendarStyle.green.withValues(alpha: .6),
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < 5; i++)
                  Positioned(
                    left: i == 4 || i.isEven ? 0 : constraints.maxWidth / 2 + 6,
                    top: (i ~/ 2) * 124,
                    width: i == 4
                        ? constraints.maxWidth
                        : constraints.maxWidth / 2 - 6,
                    height: 112,
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (_) => enabled,
                      onAcceptWithDetails: (_) => _connect(i),
                      builder: (context, candidates, rejected) =>
                          BatteryDeviceTile(
                            key: ValueKey('battery-device-$i'),
                            device: _game.devices[i],
                            charging: _game.connected == i,
                            highlighted: candidates.isNotEmpty,
                            failed: _game.failedDevice == i,
                            time: _game.elapsed,
                            reducedMotion: reduced,
                            onTap: enabled ? () => _connect(i) : null,
                          ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Draggable<int>(
                      key: const ValueKey('battery-cable'),
                      data: 1,
                      maxSimultaneousDrags: enabled ? 1 : 0,
                      feedback: const Material(
                        color: Colors.transparent,
                        child: _Plug(dragging: true),
                      ),
                      childWhenDragging: const Opacity(
                        opacity: .25,
                        child: _Plug(),
                      ),
                      child: const Tooltip(
                        message: 'Kabel ziehen oder Gerät antippen',
                        child: _Plug(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: Center(
            child: Text(
              _game.feedbackLeft > 0
                  ? _game.feedback
                  : _game.phase == BatteryPhase.ready
                  ? 'Wen lädst du zuerst?'
                  : '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CalendarStyle.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        if (_game.phase == BatteryPhase.ready || _paused)
          FilledButton.icon(
            key: const ValueKey('battery-start'),
            onPressed: _play,
            icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.bolt_rounded),
            label: Text(_paused ? 'Weiter' : 'Los geht’s'),
          )
        else if (!terminal)
          Center(
            child: IconButton(
              tooltip: 'Pause',
              onPressed: () => setState(_pause),
              icon: const Icon(Icons.pause_rounded),
            ),
          ),
        if (_game.phase == BatteryPhase.won)
          CompletionPanel(
            onComplete: widget.onComplete,
            onReplay: _restart,
            message: 'Du hast tatsächlich mal etwas rechtzeitig geladen!',
          )
        else if (_game.phase == BatteryPhase.lost)
          DefeatPanel(message: 'War doch noch bei 2 %!', onRetry: _restart),
      ],
    );
  }
}

class _Plug extends StatelessWidget {
  const _Plug({this.dragging = false});
  final bool dragging;
  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: CalendarStyle.green,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: CalendarStyle.green.withValues(alpha: .15),
          blurRadius: dragging ? 18 : 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: const Icon(
      Icons.power_rounded,
      size: 36,
      color: CalendarStyle.ivory,
    ),
  );
}

class BatteryDeviceTile extends StatelessWidget {
  const BatteryDeviceTile({
    super.key,
    required this.device,
    required this.charging,
    required this.highlighted,
    required this.failed,
    required this.time,
    required this.reducedMotion,
    this.onTap,
  });
  final BatteryDevice device;
  final bool charging, highlighted, failed, reducedMotion;
  final double time;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final low = device.battery < 5;
    final event = device.eventLeft > 0;
    final accent = failed || low && !charging
        ? const Color(0xFFB75E53)
        : CalendarStyle.green;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label:
          '${device.kind.label}, ${device.battery.ceil()} Prozent${charging ? ', lädt' : ''}${event ? ', ${device.kind.eventLabel}' : ''}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: highlighted
              ? const Color(0xFFE1ECDD)
              : charging
              ? const Color(0xFFE6EEDF)
              : const Color(0xFFF1E9DA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: highlighted || charging || failed
                  ? accent
                  : Colors.transparent,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                deviceIcon(device.kind),
                                size: 32,
                                color: accent,
                              ),
                              if (device.kind != DeviceKind.headphones)
                                Positioned(
                                  top: 8,
                                  child: SizedBox(
                                    width: 18,
                                    height: 17,
                                    child: CustomPaint(
                                      painter: DeviceFace(
                                        low,
                                        charging,
                                        time,
                                        reducedMotion,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            device.kind.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: accent),
                          ),
                        ),
                        if (event)
                          Tooltip(
                            message: device.kind.eventLabel,
                            child: Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                              color: accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 23,
                          child: CustomPaint(
                            painter: BatteryPainter(
                              percent: device.battery,
                              charging: charging,
                              time: time,
                              reducedMotion: reducedMotion,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 48,
                        height: 24,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${device.battery.ceil()} %',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 16,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: charging
                          ? Icon(Icons.bolt_rounded, size: 16, color: accent)
                          : low
                          ? Icon(
                              Icons.battery_alert_rounded,
                              size: 16,
                              color: accent,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
