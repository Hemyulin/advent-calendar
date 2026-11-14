import 'package:flutter/material.dart';
import '../challenges/games/game_preview_screen.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';
import 'pico_connection_screen.dart';
import '../hardware/pico_service.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, this.picoService});
  final PicoService? picoService;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('Advent-Verwaltung'),
      ),
    ),
    body: SafeArea(
      child: ViewportFit(
        maxWidth: 560,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _section(
              context,
              title: 'Kalender bearbeiten',
              description: 'Spiele und Schwierigkeit pro Dezembertag.',
              icon: Icons.calendar_month_outlined,
            ),
            _section(
              context,
              title: 'Spiele testen',
              description: 'Alle Spiele, unabhängig vom Datum.',
              icon: Icons.sports_esports_outlined,
              page: const GamePreviewScreen(),
            ),
            _section(
              context,
              title: 'Box-Steuerung',
              description: 'Pico-Verbindung und Netzwerkstatus.',
              page: PicoConnectionScreen(service: picoService),
              icon: Icons.inventory_2_outlined,
            ),
            _section(
              context,
              title: 'Diagnose & Fortschritt',
              description: 'Erfolge prüfen und Fehler eingrenzen.',
              icon: Icons.fact_check_outlined,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _section(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    Widget? page,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: const Color(0xFFF1E9DA),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                page ??
                _PlannedSection(
                  title: title,
                  description: description,
                  icon: icon,
                ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: CalendarStyle.green, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: CalendarStyle.green,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: CalendarStyle.muted,
                        fontSize: 13,
                      ),
                    ),
                    if (page == null) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'In Vorbereitung',
                        style: TextStyle(
                          color: CalendarStyle.gold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: CalendarStyle.green,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PlannedSection extends StatelessWidget {
  const _PlannedSection({
    required this.title,
    required this.description,
    required this.icon,
  });
  final String title, description;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: FittedBox(fit: BoxFit.scaleDown, child: Text(title)),
    ),
    body: SafeArea(
      child: ViewportFit(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: CalendarStyle.green),
            const SizedBox(height: 24),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CalendarStyle.green, fontSize: 18),
            ),
            const SizedBox(height: 14),
            const Text(
              'Dieser Bereich ist noch in Vorbereitung.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CalendarStyle.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
