import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/calendar_screen.dart';
import 'presentation/calendar_style.dart';
import 'progress/progress_repository.dart';

class AdventCalendarApp extends StatelessWidget {
  const AdventCalendarApp({super.key, this.now, this.progressRepository});

  final DateTime? now;
  final ProgressRepository? progressRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adventskalender',
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: CalendarStyle.ivory,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CalendarStyle.green,
          surface: CalendarStyle.ivory,
          primary: CalendarStyle.green,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: CalendarStyle.ivory,
          foregroundColor: CalendarStyle.green,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: CalendarScreen(now: now, progressRepository: progressRepository),
    );
  }
}
