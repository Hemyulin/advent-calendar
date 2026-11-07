import 'package:flutter/material.dart';
import 'viewport_fit.dart';

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
        child: ViewportFit(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: CalendarStyle.gold,
                  size: 32,
                ),
                const SizedBox(height: 24),
                Text(
                  'Bald mehr',
                  textAlign: TextAlign.center,
                  style: CalendarStyle.heading.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hier wartet bald deine Überraschung.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.7, color: CalendarStyle.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
