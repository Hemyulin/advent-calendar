import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late BatteryGame _game;
  late final Ticker _ticker;
  late final AnimationController _ending;
  final _deskKey = GlobalKey();
  Duration? _previous;
  bool _paused = false, _foreground = true, _showResult = false;
  bool _dragging = false, _haptics = false, _sound = true;
  Offset? _dragPoint, _dragGlobal;
  int? _dragOrigin;
  final _warned = <int>{};
  double _lastWarning = -10;
  int _lastSecond = 45;

  @override
  void initState() {
    super.initState();
    _game = BatteryGame(widget.level);
    _lastSecond = widget.level.duration.ceil();
    WidgetsBinding.instance.addObserver(this);
    _ending =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted && _foreground) {
            setState(() => _showResult = true);
          }
        });
    _ticker = createTicker((elapsed) {
      if (!_foreground || ModalRoute.of(context)?.isCurrent == false) {
        setState(_pause);
        return;
      }
      final previous = _previous;
      _previous = elapsed;
      if (previous == null) return;
      setState(() => _game.advance((elapsed - previous).inMicroseconds / 1e6));
      _feedback();
      if (_game.phase != BatteryPhase.playing) _finish();
    });
  }

  void _effect(Future<void> effect) =>
      unawaited(effect.catchError((Object _) {}));

  void _feedback() {
    final critical = {
      for (var i = 0; i < 5; i++)
        if (_game.devices[i].battery < 3) i,
    };
    final fresh = critical.difference(_warned);
    if (_haptics && fresh.isNotEmpty && _game.elapsed - _lastWarning >= 1.5) {
      _lastWarning = _game.elapsed;
      _effect(HapticFeedback.mediumImpact());
    }
    _warned.removeWhere((i) => _game.devices[i].battery >= 6);
    _warned.addAll(critical);
    final second = _game.remaining.ceil();
    if (_sound &&
        second != _lastSecond &&
        second >= 1 &&
        second <= 10 &&
        _game.phase == BatteryPhase.playing) {
      _effect(SystemSound.play(SystemSoundType.click));
    }
    _lastSecond = second;
  }

  void _pause() {
    if (_game.phase == BatteryPhase.playing) _paused = true;
    _cancelDrag();
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
    if (_paused ||
        !_foreground ||
        _showResult ||
        !_dragging ||
        index == _dragOrigin) {
      return;
    }
    final old = _game.connected;
    setState(() => _game.connect(index));
    if (_haptics && old != _game.connected) {
      _effect(HapticFeedback.selectionClick());
    }
    if (_game.phase == BatteryPhase.ready) _play();
  }

  void _finish() {
    _ticker.stop();
    _dragging = false;
    _dragPoint = null;
    _dragOrigin = null;
    _ending.duration = Duration(
      milliseconds: _game.phase == BatteryPhase.won ? 1400 : 650,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _showResult = true);
    } else {
      _ending.forward(from: 0);
    }
  }

  void _restart() {
    _ticker.stop();
    _ending.reset();
    setState(() {
      _game = BatteryGame(widget.level);
      _paused = false;
      _showResult = false;
      _previous = null;
      _dragging = false;
      _dragPoint = null;
      _dragOrigin = null;
      _warned.clear();
      _lastWarning = -10;
      _lastSecond = widget.level.duration.ceil();
    });
  }

  void _dragStarted() {
    if (_paused || !_foreground) return;
    setState(() {
      _dragging = true;
      _dragOrigin = _game.connected;
      final box = _deskKey.currentContext!.findRenderObject() as RenderBox;
      _dragPoint = _dragGlobal == null
          ? cableDock(box.size)
          : box.globalToLocal(_dragGlobal!);
      _game.disconnect();
    });
  }

  void _dragUpdated(DragUpdateDetails details) {
    if (!_dragging) return;
    final box = _deskKey.currentContext!.findRenderObject() as RenderBox;
    // The first multi-drag update reports the down position plus a pending
    // delta. Accumulating global deltas also handles that first movement.
    _dragGlobal = (_dragGlobal ?? details.globalPosition) + details.delta;
    setState(() => _dragPoint = box.globalToLocal(_dragGlobal!));
  }

  void _cancelDrag() {
    if (_dragging && _dragOrigin != null) _game.connect(_dragOrigin!);
    _dragging = false;
    _dragPoint = null;
    _dragOrigin = null;
  }

  void _dragEnded(DraggableDetails details) {
    if (!mounted) return;
    setState(() {
      if (!details.wasAccepted) {
        _cancelDrag();
      } else {
        _dragging = false;
        _dragPoint = null;
        _dragOrigin = null;
      }
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
    if (!_foreground) {
      setState(_pause);
      _ending.stop();
    } else if (_game.phase == BatteryPhase.won ||
        _game.phase == BatteryPhase.lost) {
      if (!_showResult) {
        if (_ending.isCompleted) {
          setState(() => _showResult = true);
        } else {
          _ending.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _ending.dispose();
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
          'Ein Kabel, fünf fast leere Geräte. Zieh den Stecker auf das erste Gerät. Danach ziehst du ihn vom angeschlossenen Gerät auf ein anderes. Antippen allein steckt das Kabel nicht um. Nur dieses Gerät lädt. Halte alle Akkus ${widget.level.duration.round()} Sekunden über 0 %. Auf den Geräten siehst du, was gerade Strom frisst. Beim Ziehen ist das Kabel kurz ausgesteckt. Lässt du es daneben los, kehrt es zurück. Zum Schluss wird es hektischer. Nach einer Pause geht es erst mit „Weiter“ weiter. Vibration und Uhrenticken kannst du unten einschalten; das Ticken folgt den Systemtönen deines Handys.',
      alreadyCompleted: widget.alreadyCompleted,
      onRestart: _restart,
      children: [
        BatteryCountdown(
          remaining: _game.remaining,
          elapsed: _game.elapsed,
          running: _game.phase == BatteryPhase.playing && !_paused,
          reducedMotion: reduced,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _game.progress,
            minHeight: 4,
            color: CalendarStyle.green,
            backgroundColor: CalendarStyle.line,
          ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: .7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final source = _game.connected ?? _dragOrigin;
                final sourceRect = source == null
                    ? Rect.fromCenter(
                        center: cableDock(size) - const Offset(0, 6),
                        width: 56,
                        height: 56,
                      )
                    : deskDeviceRect(source, size);
                final end =
                    _dragPoint ??
                    (_game.connected == null
                        ? cableDock(size)
                        : deskPort(_game.connected!, size));
                return AnimatedBuilder(
                  animation: _ending,
                  builder: (context, _) {
                    final victory = _game.phase == BatteryPhase.won
                        ? Curves.easeOut.transform(_ending.value)
                        : 0.0;
                    return Stack(
                      key: _deskKey,
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: DeskPainter(victory: victory),
                            ),
                          ),
                        ),
                        for (var i = 0; i < 5; i++)
                          Positioned.fromRect(
                            rect: deskDeviceRect(i, size),
                            child: DragTarget<int>(
                              onWillAcceptWithDetails: (_) =>
                                  enabled && _dragging && i != _dragOrigin,
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
                                    victory: victory,
                                    urgent:
                                        _game.phase == BatteryPhase.playing &&
                                        _game.remaining <= 10,
                                  ),
                            ),
                          ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: TweenAnimationBuilder<Offset>(
                              duration: _dragging || reduced
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              tween: Tween(end: end),
                              builder: (_, point, _) => CustomPaint(
                                key: const ValueKey('battery-cord'),
                                painter: CablePainter(
                                  end: point,
                                  connected: _game.connected != null,
                                  dragging: _dragging,
                                ),
                              ),
                            ),
                          ),
                        ),
                        for (var i = 0; i < 5; i++)
                          Positioned(
                            left: deskPort(i, size).dx - 7,
                            top: deskPort(i, size).dy - 2,
                            width: 14,
                            height: 4,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _game.connected == i
                                      ? const Color(0xFFD7B46B)
                                      : CalendarStyle.green.withValues(
                                          alpha: .35,
                                        ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fromRect(
                          rect: sourceRect,
                          child: Draggable<int>(
                            key: const ValueKey('battery-cable'),
                            data: 1,
                            maxSimultaneousDrags: enabled ? 1 : 0,
                            dragAnchorStrategy: (_, _, position) {
                              _dragGlobal = position;
                              return Offset.zero;
                            },
                            onDragStarted: _dragStarted,
                            onDragUpdate: _dragUpdated,
                            onDragEnd: _dragEnded,
                            feedback: const SizedBox(width: 1, height: 1),
                            childWhenDragging: const SizedBox(
                              width: 48,
                              height: 48,
                            ),
                            child: Tooltip(
                              message: source == null
                                  ? 'Stecker zum ersten Gerät ziehen'
                                  : 'Stecker zu einem anderen Gerät ziehen',
                              child: Semantics(
                                label: 'Ladekabel',
                                child: Listener(
                                  behavior: HitTestBehavior.opaque,
                                  child: source == null
                                      ? CustomPaint(
                                          painter: ChargingPlugPainter(),
                                        )
                                      : const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _game.feedbackLeft > 0
                    ? _game.feedback
                    : _game.phase == BatteryPhase.ready
                    ? 'Stecker zum Gerät ziehen'
                    : '',
                style: const TextStyle(
                  color: CalendarStyle.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_paused)
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('battery-start'),
                  onPressed: _play,
                  icon: Icon(
                    _paused ? Icons.play_arrow_rounded : Icons.bolt_rounded,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text('Weiter'),
                  ),
                ),
              )
            else if (!terminal && _game.phase == BatteryPhase.playing)
              IconButton(
                tooltip: 'Pause',
                onPressed: () => setState(_pause),
                icon: const Icon(Icons.pause_rounded),
              ),
            IconButton(
              isSelected: _haptics,
              tooltip: _haptics
                  ? 'Vibration ausschalten'
                  : 'Vibration einschalten',
              onPressed: () {
                setState(() => _haptics = !_haptics);
                if (_haptics) _effect(HapticFeedback.selectionClick());
              },
              icon: Icon(
                Icons.vibration_rounded,
                color: _haptics ? CalendarStyle.green : CalendarStyle.muted,
              ),
            ),
            IconButton(
              isSelected: _sound,
              tooltip: _sound
                  ? 'Uhrenticken ausschalten'
                  : 'Uhrenticken einschalten',
              onPressed: () => setState(() => _sound = !_sound),
              icon: Icon(
                _sound ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                color: _sound ? CalendarStyle.green : CalendarStyle.muted,
              ),
            ),
          ],
        ),
        if (_showResult && _game.phase == BatteryPhase.won)
          CompletionPanel(
            onComplete: widget.onComplete,
            onReplay: _restart,
            message: 'Du hast tatsächlich mal etwas rechtzeitig geladen!',
          )
        else if (_showResult && _game.phase == BatteryPhase.lost)
          DefeatPanel(message: 'War doch noch bei 2 %!', onRetry: _restart),
      ],
    );
  }
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
    this.victory = 0,
    this.urgent = false,
  });
  final BatteryDevice device;
  final bool charging, highlighted, failed, reducedMotion, urgent;
  final double time, victory;
  @override
  Widget build(BuildContext context) {
    final low = device.battery < 5;
    final accent = failed || low && !charging
        ? const Color(0xFFB75E53)
        : CalendarStyle.green;
    return Semantics(
      label:
          '${device.kind.label}, ${device.battery.ceil()} Prozent${charging ? ', lädt' : ''}${device.eventLeft > 0 ? ', ${device.kind.eventLabel}' : ''}',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: highlighted
                              ? CalendarStyle.green
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomPaint(
                        painter: DeviceIllustration(
                          device.kind,
                          low,
                          charging,
                          time,
                          reducedMotion,
                          eventActive: device.eventLeft > 0,
                          dead: failed,
                          victory: victory,
                          urgent: urgent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 23,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                device.kind.label,
                                style: TextStyle(fontSize: 11, color: accent),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        SizedBox(
                          width: 45,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${device.battery.ceil()} %',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 13,
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
                      if (charging || low) ...[
                        const SizedBox(width: 3),
                        Icon(
                          charging
                              ? Icons.bolt_rounded
                              : Icons.battery_alert_rounded,
                          size: 14,
                          color: accent,
                        ),
                      ],
                      if (device.eventLeft > 0)
                        Tooltip(
                          message: device.kind.eventLabel,
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 12,
                            color: CalendarStyle.muted,
                          ),
                        ),
                    ],
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
