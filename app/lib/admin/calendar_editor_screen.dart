import 'package:flutter/material.dart';
import '../challenges/games/difficulty.dart';
import '../challenges/games/game_kind.dart';
import '../content/calendar_schedule.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';

class CalendarEditorScreen extends StatefulWidget {
  const CalendarEditorScreen({super.key, required this.schedule});
  final CalendarSchedule schedule;
  @override
  State<CalendarEditorScreen> createState() => _CalendarEditorScreenState();
}

class _CalendarEditorScreenState extends State<CalendarEditorScreen> {
  int _day = 1;
  String _game = 'memory';
  GameDifficulty _difficulty = GameDifficulty.easy;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    widget.schedule.ready.then((_) {
      if (mounted) setState(_read);
    });
  }

  void _read() {
    final assignment = widget.schedule.forDay(_day);
    _game = assignment.game.name;
    _difficulty = assignment.difficulty;
    _message = widget.schedule.error;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await widget.schedule.assign(
        _day,
        DayAssignment(Minigame.values.byName(_game), _difficulty),
      );
      if (mounted) setState(() => _message = 'Gespeichert.');
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Speichern fehlgeschlagen. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const FittedBox(child: Text('Kalender bearbeiten'))),
    body: SafeArea(
      child: ViewportFit(
        maxWidth: 520,
        padding: const EdgeInsets.all(24),
        child: !widget.schedule.loaded
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // All dates remain visible without a long, scrolling list.
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 6,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: [
                      for (var day = 1; day <= 24; day++)
                        Semantics(
                          selected: _day == day,
                          child: Tooltip(
                            message:
                                '$day. Dezember · ${widget.schedule.forDay(day).title} · ${widget.schedule.forDay(day).difficulty.label}',
                            child: FilledButton.tonal(
                              key: ValueKey('edit-day-$day'),
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: _day == day
                                    ? CalendarStyle.green
                                    : const Color(0xFFF1E9DA),
                                foregroundColor: _day == day
                                    ? CalendarStyle.ivory
                                    : CalendarStyle.green,
                              ),
                              onPressed: _saving
                                  ? null
                                  : () => setState(() {
                                      _day = day;
                                      _read();
                                    }),
                              child: Text('$day'),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$_day. Dezember',
                    style: CalendarStyle.heading.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('game-$_day-$_game'),
                    initialValue: _game,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Spiel'),
                    items: [
                      for (final game in Minigame.values)
                        DropdownMenuItem(
                          value: game.name,
                          child: Text(
                            game.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() {
                            _game = value!;
                            _message = null;
                          }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GameDifficulty>(
                    key: ValueKey('difficulty-$_day-${_difficulty.name}'),
                    initialValue: _difficulty,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Schwierigkeit',
                    ),
                    items: [
                      for (final value in GameDifficulty.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() {
                            _difficulty = value!;
                            _message = null;
                          }),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Speichert…' : 'Speichern'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _message ??
                        'Erfolge bleiben beim jeweiligen Türchen erhalten.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CalendarStyle.muted),
                  ),
                ],
              ),
      ),
    ),
  );
}
