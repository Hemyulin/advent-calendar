import 'package:flutter/gestures.dart';
import '../seasonal/game_skin_scope.dart';
import '../../achievements/run_facts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../presentation/calendar_style.dart';
import '../../presentation/app_haptics.dart';
import '../completion.dart';
import '../maze/maze_game.dart' show Vec2;
import '../maze/tilt_source.dart';
import '../games/game_widgets.dart';
import 'walk_game.dart';
import 'walk_art.dart';

class WalkScreen extends StatefulWidget {
  const WalkScreen({
    super.key,
    required this.onComplete,
    this.level = const WalkLevel(),
    this.tiltSource,
    this.alreadyCompleted = false,
  });
  final WalkLevel level;
  final TiltSource? tiltSource;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late WalkGame _game;
  late final Ticker _ticker;
  late final AnimationController _ending;
  final _focus = FocusNode();
  final _keys = <LogicalKeyboardKey>{};
  final _samples = <double>[];
  StreamSubscription<Vec2>? _subscription;
  Timer? _timeout;
  Duration? _previous;
  final _lightingRandom = math.Random();
  late bool _nightMode = _lightingRandom.nextBool();
  bool _useSensors = true,
      _ready = false,
      _active = true,
      _paused = false,
      _showResult = false;
  double _latest = 0, _zero = 0, _touchControl = 0;
  double _touchStart = 0;
  int _sensorEpoch = 0;
  String? _sensorMessage;
  @override
  void initState() {
    super.initState();
    _game = WalkGame(widget.level);
    WidgetsBinding.instance.addObserver(this);
    _ending =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1300),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _showResult = true);
          }
        });
    _ticker = createTicker((elapsed) {
      final previous = _previous;
      _previous = elapsed;
      if (previous == null ||
          !_active ||
          _paused ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final control = _keys.isNotEmpty
          ? (_keys.contains(LogicalKeyboardKey.arrowRight) ? 1.0 : 0) -
                (_keys.contains(LogicalKeyboardKey.arrowLeft) ? 1.0 : 0)
          : _useSensors
          ? ((_latest - _zero) * 3.4).clamp(-1.0, 1.0)
          : _touchControl;
      final bumps = _game.bumps;
      setState(
        () => _game.advance(
          (elapsed - previous).inMicroseconds / 1e6,
          control.toDouble(),
        ),
      );
      if (_game.bumps > bumps) AppHaptics.error(context);
      if (_game.phase != WalkPhase.walking) _finish();
    });
    _listen();
  }

  void _listen() {
    final epoch = ++_sensorEpoch;
    _subscription?.cancel();
    _timeout?.cancel();
    _samples.clear();
    _ready = false;
    _subscription = (widget.tiltSource ?? DeviceTiltSource()).events.listen(
      (event) {
        if (!mounted || !_active || !_useSensors || epoch != _sensorEpoch) {
          return;
        }
        setState(() {
          _latest = _ready ? _latest + (event.x - _latest) * .4 : event.x;
          if (!_ready) {
            _samples.add(event.x);
            if (_samples.length > 8) _samples.removeAt(0);
            if (_samples.length == 8 &&
                _samples.reduce(math.max) - _samples.reduce(math.min) < .06) {
              _zero = _samples.reduce((a, b) => a + b) / _samples.length;
              _ready = true;
            }
          }
        });
        _timeout?.cancel();
        _timeout = Timer(const Duration(seconds: 3), _fallback);
      },
      onError: (_) {
        if (epoch == _sensorEpoch) _fallback();
      },
      onDone: () {
        if (epoch == _sensorEpoch) _fallback();
      },
    );
    _timeout = Timer(const Duration(seconds: 3), _fallback);
  }

  void _fallback() {
    if (!mounted || !_useSensors) return;
    _sensorEpoch++;
    _subscription?.cancel();
    _timeout?.cancel();
    setState(() {
      _pause();
      _useSensors = false;
      _ready = false;
      _sensorMessage =
          'Keine Sensordaten. Ziehe auf der Straße oder nutze die Pfeiltasten.';
    });
  }

  void _pause() {
    if (_game.phase == WalkPhase.walking) _paused = true;
    _ticker.stop();
    _previous = null;
    _touchControl = 0;
    _keys.clear();
  }

  void _play() {
    if (!_active || (_useSensors && !_ready)) return;
    setState(() {
      _game.start();
      _paused = false;
      _previous = null;
    });
    _focus.requestFocus();
    if (!_ticker.isActive) _ticker.start();
  }

  void _finish() {
    _ticker.stop();
    _sensorEpoch++;
    _subscription?.cancel();
    _timeout?.cancel();
    _touchControl = 0;
    _keys.clear();
    if (!_ending.isAnimating && !_showResult) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _ending.value = 1;
      } else {
        _ending.forward();
      }
    }
  }

  void _restart() {
    _ticker.stop();
    _ending.reset();
    setState(() {
      _game = WalkGame(widget.level);
      _nightMode = _lightingRandom.nextBool();
      _paused = false;
      _showResult = false;
      _touchControl = 0;
      _keys.clear();
      _previous = null;
    });
    if (_useSensors) _listen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == false) _pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      setState(_pause);
      _sensorEpoch++;
      _subscription?.cancel();
      _timeout?.cancel();
    } else if (_useSensors &&
        _game.phase != WalkPhase.home &&
        _game.phase != WalkPhase.fallen) {
      setState(_listen);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sensorEpoch++;
    _subscription?.cancel();
    _timeout?.cancel();
    _ticker.dispose();
    _ending.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = _game.phase == WalkPhase.walking;
    final terminal =
        _game.phase == WalkPhase.home || _game.phase == WalkPhase.fallen;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event.logicalKey != LogicalKeyboardKey.arrowLeft &&
            event.logicalKey != LogicalKeyboardKey.arrowRight) {
          return KeyEventResult.ignored;
        }
        if (event is KeyUpEvent) {
          _keys.remove(event.logicalKey);
        } else if (event is KeyDownEvent) {
          _keys.add(event.logicalKey);
        }
        return KeyEventResult.handled;
      },
      child: GameScaffold(
        title: GameSkinScope.isHanukkah(context)
            ? 'Ein Kiddusch-Wein zu viel'
            : 'Ein Glühwein zu viel',
        alreadyCompleted: widget.alreadyCompleted,
        onRestart: _restart,
        instructions:
            '${GameSkinScope.isHanukkah(context) ? 'Bring die Figur zur Synagoge.' : 'Bring die Figur nach Hause.'} Neige das Handy sanft nach links oder rechts und gleiche das Schwanken aus. Weiche Schneemännern, Fahrrädern, Mülltonnen und schlafenden Feiernden aus. Eis macht die Straße rutschig. Wenn du zu lange schief stehst oder vom Weg abkommst, landest du im Schnee. Ziehe im Touch-Modus auf der Straße nach links oder rechts und halte den Finger dort. Am Computer gehen auch die Pfeiltasten. Die Mitte kannst du neu kalibrieren.',
        children: [
          GameStats(
            text:
                '${(_game.progress * 100).floor()} % · Noch ${_game.remaining.ceil()} s',
          ),
          Semantics(
            label: 'Gleichgewicht${_game.danger > 0 ? ', Vorsicht!' : ''}',
            child: SizedBox(
              height: 22,
              child: CustomPaint(
                painter: BalancePainter(
                  _game.lean / _game.level.leanLimit,
                  _game.danger,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: const ValueKey('walk-touch-area'),
            dragStartBehavior: DragStartBehavior.down,
            behavior: HitTestBehavior.opaque,
            onPanStart: !_useSensors && playing && !_paused
                ? (details) {
                    _touchStart = details.localPosition.dx;
                    _focus.requestFocus();
                  }
                : null,
            onPanUpdate: !_useSensors && playing && !_paused
                ? (details) {
                    setState(
                      () => _touchControl =
                          ((details.localPosition.dx - _touchStart) / 70).clamp(
                            -1.0,
                            1.0,
                          ),
                    );
                  }
                : null,
            onPanEnd: (_) => setState(() => _touchControl = 0),
            onPanCancel: () => setState(() => _touchControl = 0),
            child: AspectRatio(
              aspectRatio: .85,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedBuilder(
                      animation: _ending,
                      builder: (_, _) => CustomPaint(
                        key: const ValueKey('walk-street'),
                        painter: WinterStreetPainter(
                          _game,
                          Curves.easeOutCubic.transform(_ending.value),
                          reducedMotion: MediaQuery.disableAnimationsOf(
                            context,
                          ),
                          nightMode: _nightMode,
                          hanukkah: GameSkinScope.isHanukkah(context),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filledTonal(
                        key: const ValueKey('walk-lighting'),
                        tooltip: _nightMode
                            ? 'Zum Tagmodus wechseln'
                            : 'Zum Nachtmodus wechseln',
                        style: IconButton.styleFrom(
                          backgroundColor: CalendarStyle.ivory,
                          foregroundColor: CalendarStyle.green,
                        ),
                        onPressed: () =>
                            setState(() => _nightMode = !_nightMode),
                        icon: Icon(
                          _nightMode
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!terminal) ...[
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Neigen')),
                ButtonSegment(value: false, label: Text('Touch')),
              ],
              selected: {_useSensors},
              onSelectionChanged: (value) {
                setState(() {
                  _pause();
                  _useSensors = value.first;
                  _sensorMessage = null;
                });
                if (_useSensors) {
                  setState(_listen);
                } else {
                  _sensorEpoch++;
                  _subscription?.cancel();
                  _timeout?.cancel();
                }
              },
            ),
            const SizedBox(height: 10),
            if (_useSensors)
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!_ready)
                    const Text(
                      'Handy ruhig halten',
                      style: TextStyle(color: CalendarStyle.muted),
                    )
                  else
                    const Icon(
                      Icons.screen_rotation_alt_rounded,
                      color: CalendarStyle.green,
                    ),
                  IconButton(
                    tooltip: 'Diese Haltung als Mitte setzen',
                    onPressed: _ready
                        ? () => setState(() {
                            _pause();
                            _zero = _latest;
                          })
                        : null,
                    icon: const Icon(Icons.center_focus_strong_rounded),
                  ),
                ],
              ),
            if (_sensorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Tooltip(
                  message: _sensorMessage!,
                  child: const Icon(
                    Icons.sensors_off_rounded,
                    color: CalendarStyle.muted,
                    size: 18,
                  ),
                ),
              ),
            if (!playing || _paused) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('walk-start'),
                onPressed: !_useSensors || _ready ? _play : null,
                icon: const Icon(Icons.directions_walk_rounded),
                label: Text(_paused ? 'Weiter' : 'Los geht’s'),
              ),
            ],
          ],
          if (_showResult && _game.phase == WalkPhase.home)
            CompletionPanel(
              facts: RunFacts(
                feats: {
                  if (_game.bumps == 0) RunFeat.cleanWalk,
                  if (_game.bumps >= 5) RunFeat.roughWalk,
                },
              ),
              onComplete: widget.onComplete,
              onReplay: _restart,
              message: GameSkinScope.isHanukkah(context)
                  ? 'Die Synagoge ist erreicht. L’chaim!'
                  : 'Zu Hause! Ab auf die Couch.',
            )
          else if (_showResult && _game.phase == WalkPhase.fallen)
            DefeatPanel(
              message: 'Der Schnee hat dich aufgefangen.',
              onRetry: _restart,
            ),
        ],
      ),
    );
  }
}
