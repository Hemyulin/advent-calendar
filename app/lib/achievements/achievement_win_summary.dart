import 'package:flutter/material.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';
import 'achievement_art.dart';
import 'achievement_store.dart';

/// Won awards remain in the result after the temporary toast has disappeared.
/// A horizontal pager keeps multiple unlocks readable without a taller modal.
class AchievementWinSummary extends StatefulWidget {
  const AchievementWinSummary({super.key, required this.achievements});
  final List<Achievement> achievements;
  @override
  State<AchievementWinSummary> createState() => _AchievementWinSummaryState();
}

class _AchievementWinSummaryState extends State<AchievementWinSummary> {
  final _pages = PageController();
  int _index = 0;
  void _show(int index) => _pages.animateToPage(
    index,
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240),
    curve: Curves.easeOut,
  );
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('completion-achievements'),
    margin: const EdgeInsets.only(top: 18),
    decoration: BoxDecoration(
      color: const Color(0xFFF5E7CC),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5CFA5)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Text(
            'Neu in deiner Sammlung',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CalendarStyle.gold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: PageView.builder(
            controller: _pages,
            itemCount: widget.achievements.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final award = widget.achievements[index];
              return ViewportFit(
                key: ValueKey('completion-award-${award.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    AchievementIllustration(
                      achievementId: award.id,
                      earned: true,
                      width: 84,
                      height: 64,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        award.title,
                        style: const TextStyle(
                          color: CalendarStyle.green,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.achievements.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Vorheriger Erfolg',
                onPressed: _index > 0 ? () => _show(_index - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
              ),
              Flexible(
                child: Semantics(
                  liveRegion: true,
                  label:
                      'Erfolg ${_index + 1} von ${widget.achievements.length}',
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_index + 1} / ${widget.achievements.length}',
                        style: const TextStyle(
                          color: CalendarStyle.green,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Nächster Erfolg',
                onPressed: _index + 1 < widget.achievements.length
                    ? () => _show(_index + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
              ),
            ],
          ),
      ],
    ),
  );
}
