import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/calendar_day.dart';
import '../progress/mock_progress_repository.dart';
import '../progress/progress_repository.dart';
import 'calendar_style.dart';
import 'challenge_screen.dart';
import 'festive_art.dart';
import 'illustrated_door.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.now, this.progressRepository});

  final DateTime? now;
  final ProgressRepository? progressRepository;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  Timer? _midnightTimer;
  Set<String> _completed = {};
  late int _selected;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDateRefresh();
    _selected = _now.month < 12 ? 1 : math.min(_now.day, 24);
    _loadProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scheduleDateRefresh() {
    _midnightTimer?.cancel();
    if (widget.now != null) return;
    final now = _now;
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(midnight.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleDateRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleDateRefresh();
    }
  }

  Future<void> _loadProgress() async {
    final repository = widget.progressRepository ?? MockProgressRepository();
    final completed = await repository.completedChallengeIds();
    if (mounted) setState(() => _completed = completed);
  }

  void _scrollToSelected() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final extent = position.viewportDimension / 5;
    final offset = ((_selected - 3) * extent).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      offset,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _status(CalendarDay day) => switch (day.state) {
    DayState.future => 'Öffnet am ${day.number}. Dezember',
    DayState.today => 'Dein Moment für heute',
    DayState.available => 'Ein Türchen wartet noch auf dich',
    DayState.completed => 'Schon geöffnet. Noch einmal entdecken?',
  };

  @override
  Widget build(BuildContext context) {
    final days = calendarDays(_now, _completed);
    final day = days[_selected - 1];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final tileHeight = math.max(
      92.0,
      MediaQuery.textScalerOf(context).scale(26) + 34,
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(0, constraints.maxHeight - 176),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'ZEIT FÜR VORFREUDE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: CalendarStyle.gold,
                                fontSize: 10,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Dein Adventskalender',
                              textAlign: TextAlign.center,
                              style: CalendarStyle.heading.copyWith(
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '24 kleine Momente voller Weihnachtszauber.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: CalendarStyle.muted,
                              ),
                            ),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.025),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: SizedBox(
                                key: ValueKey(day.number),
                                width: (constraints.maxHeight * 0.37).clamp(
                                  192.0,
                                  280.0,
                                ),
                                child: IllustratedDoor(
                                  day: day,
                                  onTap: day.isAvailable
                                      ? () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                ChallengeScreen(day: day),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _status(day),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: CalendarStyle.green,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              day.isAvailable
                                  ? 'Tippe auf das Türchen.'
                                  : 'Die Vorfreude darf noch ein wenig wachsen.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: CalendarStyle.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: Divider(color: CalendarStyle.line, height: 1),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'DEZEMBER',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.5,
                      color: CalendarStyle.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: tileHeight,
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemExtent: constraints.maxWidth / 5,
                      itemCount: days.length,
                      itemBuilder: (context, index) => _DayTile(
                        day: days[index],
                        selected: _selected == index + 1,
                        onTap: days[index].isAvailable
                            ? () {
                                setState(() => _selected = index + 1);
                                _scrollToSelected();
                              }
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.selected, this.onTap});

  final CalendarDay day;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final design = DoorDesign.forDay(day.number);
    final color = day.isAvailable || selected
        ? design.color
        : CalendarStyle.muted;
    final label = switch (day.state) {
      DayState.future => 'Gesperrt',
      DayState.today => 'Heute',
      DayState.available => 'Noch offen',
      DayState.completed => day.isToday ? 'Heute, geschafft' : 'Geschafft',
    };
    return Semantics(
      label: '${day.number}. Dezember, $label',
      selected: selected,
      button: true,
      enabled: day.isAvailable,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Color.lerp(
              CalendarStyle.ivory,
              design.color,
              selected ? 0.15 : 0.045,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: selected || day.isToday
                    ? design.color
                    : Colors.transparent,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${day.number}'.padLeft(2, '0'),
                        maxLines: 1,
                        softWrap: false,
                        style: CalendarStyle.heading.copyWith(
                          fontSize: 26,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    switch (day.state) {
                      DayState.future => Icons.lock_outline_rounded,
                      DayState.completed => Icons.lock_open_rounded,
                      DayState.today => Icons.circle,
                      DayState.available => Icons.circle_outlined,
                    },
                    color: day.state == DayState.today
                        ? CalendarStyle.gold
                        : color,
                    size: day.state == DayState.today ? 7 : 13,
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
