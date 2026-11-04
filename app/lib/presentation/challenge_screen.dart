import 'package:flutter/material.dart';

import '../content/calendar_day.dart';
import 'calendar_style.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key, required this.day});

  final CalendarDay day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Türchen ${day.number}')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  color: CalendarStyle.gold,
                  size: 32,
                ),
                const SizedBox(height: 24),
                Text(
                  'Ein kleiner Weihnachtsmoment',
                  textAlign: TextAlign.center,
                  style: CalendarStyle.heading.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hier wartet bald deine Tagesaufgabe auf dich.\nMach es dir bis dahin gemütlich.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.7, color: CalendarStyle.muted),
                ),
                if (day.state == DayState.completed) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Bereits geschafft · jederzeit wieder entdecken',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zurück zum Kalender'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
