import 'package:flutter/material.dart';
import '../challenges/games/game_preview_screen.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';
import 'pico_connection_screen.dart';
import 'achievement_rewards_screen.dart';
import '../achievements/achievement_store.dart';
import '../hardware/pico_service.dart';
import '../content/calendar_access.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({
    super.key,
    this.picoService,
    required this.achievements,
    this.access,
  });
  final AchievementStore achievements;
  final CalendarAccess? access;
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
            if (access != null) _UnlockAllSwitch(access: access!),
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
              title: 'Erfolge & Gutscheine',
              description: 'Die große Abschlussbelohnung festlegen.',
              icon: Icons.workspace_premium_outlined,
              page: AchievementRewardsScreen(store: achievements),
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
    required Widget page,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: const Color(0xFFF1E9DA),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => page)),
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

class _UnlockAllSwitch extends StatefulWidget {
  const _UnlockAllSwitch({required this.access});
  final CalendarAccess access;
  @override
  State<_UnlockAllSwitch> createState() => _UnlockAllSwitchState();
}

class _UnlockAllSwitchState extends State<_UnlockAllSwitch> {
  bool _saving = false;
  Future<void> _set(bool value) async {
    setState(() => _saving = true);
    try {
      await widget.access.setUnlockAll(value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Die Einstellung konnte nicht gespeichert werden.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: ListenableBuilder(
      listenable: widget.access,
      builder: (context, _) => SwitchListTile(
        key: const ValueKey('admin-unlock-all'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: const Text('Alle Türchen freischalten'),
        subtitle: const Text(
          'Nur zum Testen: auch spätere Spiele, Stufen und Lieder freigeben.',
        ),
        value: widget.access.unlockAll,
        onChanged: _saving ? null : _set,
      ),
    ),
  );
}
