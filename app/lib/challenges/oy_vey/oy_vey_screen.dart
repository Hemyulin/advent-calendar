import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import 'mouth_camera.dart';
import 'mouth_tracking.dart';
import 'oy_vey_art.dart';
import 'oy_vey_game.dart';

class OyVeyScreen extends StatefulWidget {
  const OyVeyScreen({
    super.key,
    required this.onComplete,
    this.level = const OyVeyLevel(),
    this.camera,
    this.alreadyCompleted = false,
    this.developmentPreview = false,
  });
  final OyVeyLevel level;
  final MouthCamera? camera;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted, developmentPreview;
  @override
  State<OyVeyScreen> createState() => _OyVeyScreenState();
}

class _OyVeyScreenState extends State<OyVeyScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final MouthCamera _camera;
  late OyVeyGame _game;
  final _tracker = MouthTracker();
  late final Ticker _ticker;
  Duration? _previous;
  bool _testMode = false, _started = false, _paused = false, _tracking = false;
  bool _foreground = true;
  Timer? _frameWatchdog;
  double _testX = .5, _testY = .68;

  @override
  void initState() {
    super.initState();
    _game = OyVeyGame(widget.level);
    _camera = widget.camera ?? LocalMouthCamera();
    _camera.addListener(_onCamera);
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      final previous = _previous;
      _previous = elapsed;
      if (previous == null ||
          !_foreground ||
          _paused ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final dt = (elapsed - previous).inMicroseconds / 1e6;
      setState(() => _game.advance(dt, _mouth, aspectRatio: _aspect));
      if (_game.won || _game.lost) {
        _ticker.stop();
        if (!_testMode) unawaited(_camera.stop());
      }
    });
  }

  double get _aspect => _testMode ? .75 : _camera.aspectRatio;
  CatchMouth? get _mouth {
    if (_testMode) {
      return CatchMouth(_testX, _testY, .11, halfHeight: .022);
    }
    final mouth = _tracker.mouth;
    if (!_tracking || mouth == null) return null;
    return CatchMouth(
      mouth.x,
      mouth.y,
      (mouth.width * .8).clamp(.07, .17),
      halfHeight: .022,
    );
  }

  bool get _canPlay => _testMode || _tracking;
  void _onCamera() {
    if (!mounted || _testMode) return;
    final observation = _camera.observation;
    setState(() {
      _tracker.update(observation);
      _tracking =
          observation?.valid == true && _camera.state == MouthCameraState.ready;
      _frameWatchdog?.cancel();
      if (_tracking) {
        _frameWatchdog = Timer(const Duration(milliseconds: 400), () {
          if (mounted && !_testMode) {
            setState(() {
              _tracking = false;
              _tracker.lost();
              _game.resetTracking();
            });
          }
        });
      } else {
        _game.resetTracking();
        if (_started &&
            !_game.won &&
            !_game.lost &&
            _camera.state != MouthCameraState.ready) {
          _pause();
        }
      }
    });
  }

  void _pause() {
    _paused = _started;
    _ticker.stop();
    _previous = null;
    _game.resetTracking();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == false) _pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive &&
        _camera.state == MouthCameraState.loading) {
      return;
    }
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      setState(() {
        _pause();
        _tracker.reset();
        _tracking = false;
      });
      if (!_testMode) unawaited(_camera.stop());
    }
  }

  Future<void> _startCamera() async {
    _tracker.reset();
    _tracking = false;
    await _camera.start();
  }

  void _play() {
    if (!_canPlay || !_foreground) return;
    setState(() {
      _started = true;
      _paused = false;
      _previous = null;
      _game.resetTracking();
    });
    if (!_ticker.isActive) _ticker.start();
  }

  void _restart() {
    _ticker.stop();
    setState(() {
      _game = OyVeyGame(widget.level);
      _started = false;
      _paused = false;
      _previous = null;
    });
    if (!_testMode) unawaited(_startCamera());
  }

  void _test() {
    unawaited(_camera.stop());
    setState(() {
      _testMode = true;
      _tracking = true;
      _started = false;
      _paused = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frameWatchdog?.cancel();
    _camera.removeListener(_onCamera);
    _camera.dispose();
    super.dispose();
  }

  String get _status {
    if (_testMode) return 'Vorschau ohne Kamera';
    return switch (_camera.state) {
      MouthCameraState.idle => 'Kamera ist aus',
      MouthCameraState.loading => 'Kamera wird gestartet …',
      MouthCameraState.permissionDenied =>
        'Bitte erlaube den Kamerazugriff in den Systemeinstellungen.',
      MouthCameraState.unavailable =>
        'Hier ist keine unterstützte Frontkamera verfügbar.',
      MouthCameraState.failed =>
        'Die Kameraerkennung funktioniert gerade nicht.',
      MouthCameraState.ready =>
        !_tracking
            ? (_camera.multipleFaces
                  ? 'Bitte nur ein Gesicht vor der Kamera.'
                  : 'Schau mit deinem Gesicht zur Kamera.')
            : _paused
            ? 'Bereit? Weiter geht’s!'
            : _started
            ? 'Kopf bewegen'
            : 'Bereit!',
    };
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    title: 'Oy Vey, Weihnachten!',
    alreadyCompleted: widget.alreadyCompleted,
    onRestart: _restart,
    instructions:
        'Bewege deinen Kopf, um Sufganiyot, Sevivonim und Chanukkiot zu sammeln. Meide Weihnachtsbäume, Weihnachtsmützen und Zuckerstangen. 15 richtige Objekte gewinnen, 3 Weihnachtsobjekte beenden den Versuch. Du musst den Mund nicht öffnen. Ohne erkanntes Gesicht fällt alles weiter; mit erkanntem Gesicht sammelst du automatisch. Die Kamera bleibt lokal: Es wird nichts aufgenommen oder hochgeladen.',
    children: [
      GameStats(
        text:
            '${_game.collected} / ${widget.level.target} gesammelt · ${_game.mistakes} / ${widget.level.mistakeLimit} Fehler',
      ),
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: _aspect,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              key: const ValueKey('oy-vey-stage'),
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _testMode
                  ? (details) => setState(() {
                      _testX = (details.localPosition.dx / constraints.maxWidth)
                          .clamp(.04, .96);
                      _testY =
                          (details.localPosition.dy / constraints.maxHeight)
                              .clamp(.1, .85);
                    })
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFFE6E9DD),
                    child: _testMode
                        ? const Center(
                            child: Icon(
                              Icons.face_outlined,
                              size: 100,
                              color: Color(0x33678A78),
                            ),
                          )
                        : _camera.preview(),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: OyVeyPainter(
                        _game,
                        _mouth,
                        visible: _testMode || _tracking,
                      ),
                    ),
                  ),
                  if (!_started || _paused || !_canPlay)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: CalendarStyle.ivory.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: CalendarStyle.green),
                        ),
                      ),
                    ),
                  if (_game.feedbackLeft > 0 && _started && !_paused)
                    Align(
                      alignment: const Alignment(0, -.72),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CalendarStyle.ivory.withValues(alpha: .93),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          _game.feedback,
                          style: CalendarStyle.heading.copyWith(fontSize: 25),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (!_started || _paused) ...[
        if (_testMode || _camera.state == MouthCameraState.ready) ...[
          FilledButton.icon(
            key: const ValueKey('oy-vey-play'),
            onPressed: _canPlay ? _play : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(_started ? 'Weiter' : 'Los geht’s'),
          ),
        ] else ...[
          FilledButton.icon(
            onPressed: _camera.state == MouthCameraState.loading
                ? null
                : _startCamera,
            icon: const Icon(Icons.videocam_outlined),
            label: Text(
              _camera.state == MouthCameraState.idle
                  ? 'Kamera starten'
                  : 'Erneut versuchen',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nur auf deinem Gerät · Keine Aufnahme',
            textAlign: TextAlign.center,
            style: TextStyle(color: CalendarStyle.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.check_rounded, color: CalendarStyle.green),
              FestiveObjectIcon(FestiveObject.sufganiyah),
              FestiveObjectIcon(FestiveObject.dreidel),
              FestiveObjectIcon(FestiveObject.hanukkiah),
              Icon(Icons.close_rounded, color: Color(0xFFAF6A5B)),
              FestiveObjectIcon(FestiveObject.tree),
              FestiveObjectIcon(FestiveObject.hat),
              FestiveObjectIcon(FestiveObject.cane),
            ],
          ),
        ],
      ],
      if (widget.developmentPreview && !_testMode && !_started)
        TextButton(onPressed: _test, child: const Text('Ohne Kamera testen')),
      if (_game.won)
        CompletionPanel(
          onComplete: widget.onComplete,
          onReplay: _restart,
          message: 'Mazel tov! Alles eingesammelt!',
        )
      else if (_game.lost)
        DefeatPanel(
          message: 'Oy vey! Da war zu viel Weihnachten dabei.',
          onRetry: _restart,
        ),
    ],
  );
}
