import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../presentation/calendar_style.dart';
import 'achievement_store.dart';

/// Long checklists get their own viewport instead of shrinking the artwork,
/// text and every objective together. Page size follows available space.
class AchievementObjectivesScreen extends StatefulWidget {
  const AchievementObjectivesScreen({
    super.key,
    required this.store,
    required this.achievement,
    required this.label,
    required this.onOpenAchievement,
  });

  final AchievementStore store;
  final Achievement achievement;
  final String Function(String) label;
  final void Function(Achievement) onOpenAchievement;

  @override
  State<AchievementObjectivesScreen> createState() =>
      _AchievementObjectivesScreenState();
}

class _AchievementObjectivesScreenState
    extends State<AchievementObjectivesScreen> {
  bool _onlyOpen = false;
  int _page = 0;

  Achievement? _related(String token) {
    if (!token.startsWith('bonus:')) return null;
    for (final a in achievements) {
      if (a.id != 'allExtras' &&
          a.id != widget.achievement.id &&
          a.requirements.contains(token)) {
        return a;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final a = widget.achievement;
      final tokens = a.requirements
          .where((t) => !_onlyOpen || !widget.store.tokenComplete(t))
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Teilziele')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Semantics(
                      label:
                          '${widget.store.progress(a)} von ${a.requirements.length} geschafft',
                      child: LinearProgressIndicator(
                        value: widget.store.progress(a) / a.requirements.length,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(4),
                        color: CalendarStyle.green,
                        backgroundColor: CalendarStyle.green.withValues(
                          alpha: .1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        children: [
                          Text(
                            '${widget.store.progress(a)} / ${a.requirements.length}',
                          ),
                          FilterChip(
                            label: const Text('Offen'),
                            selected: _onlyOpen,
                            onSelected: (value) => setState(() {
                              _onlyOpen = value;
                              _page = 0;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: tokens.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 48,
                                    color: CalendarStyle.green,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Alle Teilziele geschafft!',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final columns =
                                    constraints.maxWidth >= 600 &&
                                        MediaQuery.textScalerOf(
                                              context,
                                            ).scale(16) <=
                                            24
                                    ? 2
                                    : 1;
                                final cardWidth =
                                    (constraints.maxWidth -
                                        (columns - 1) * 12) /
                                    columns;
                                // Measure at the user's text size rather than squeezing
                                // text down or truncating the longer objective names.
                                var cardHeight = 76.0;
                                for (final token in tokens) {
                                  final painter = TextPainter(
                                    text: TextSpan(
                                      text: widget.label(token),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    textDirection: Directionality.of(context),
                                    textScaler: MediaQuery.textScalerOf(
                                      context,
                                    ),
                                  )..layout(maxWidth: cardWidth - 96);
                                  cardHeight = math.max(
                                    cardHeight,
                                    painter.height + 32,
                                  );
                                  painter.dispose();
                                }
                                final rows = math.max(
                                  1,
                                  ((constraints.maxHeight - 56) /
                                          (cardHeight + 12))
                                      .floor(),
                                );
                                final perPage = rows * columns;
                                final pageCount = (tokens.length / perPage)
                                    .ceil();
                                final page = _page.clamp(0, pageCount - 1);
                                final visible = tokens
                                    .skip(page * perPage)
                                    .take(perPage)
                                    .toList();
                                void changePage(int delta) =>
                                    setState(() => _page = page + delta);
                                return Column(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onHorizontalDragEnd: (details) {
                                          final velocity =
                                              details.primaryVelocity ?? 0;
                                          if (velocity < -100 &&
                                              page < pageCount - 1) {
                                            changePage(1);
                                          }
                                          if (velocity > 100 && page > 0) {
                                            changePage(-1);
                                          }
                                        },
                                        child: Column(
                                          children: [
                                            for (
                                              var row = 0;
                                              row <
                                                  (visible.length / columns)
                                                      .ceil();
                                              row++
                                            )
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    for (
                                                      var col = 0;
                                                      col < columns;
                                                      col++
                                                    ) ...[
                                                      if (col > 0)
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                      Expanded(
                                                        child:
                                                            row * columns +
                                                                    col <
                                                                visible.length
                                                            ? _objective(
                                                                visible[row *
                                                                        columns +
                                                                    col],
                                                                cardHeight,
                                                              )
                                                            : const SizedBox.shrink(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 56,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            tooltip: 'Vorherige Teilziele',
                                            onPressed: page > 0
                                                ? () => changePage(-1)
                                                : null,
                                            icon: const Icon(
                                              Icons.chevron_left,
                                            ),
                                          ),
                                          Semantics(
                                            liveRegion: true,
                                            child: Text(
                                              '${page + 1}/$pageCount',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Weitere Teilziele',
                                            onPressed: page < pageCount - 1
                                                ? () => changePage(1)
                                                : null,
                                            icon: const Icon(
                                              Icons.chevron_right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _objective(String token, double height) {
    final done = widget.store.tokenComplete(token);
    final related = _related(token);
    return Semantics(
      label: '${widget.label(token)}, ${done ? 'Geschafft' : 'Noch offen'}',
      excludeSemantics: true,
      button: related != null,
      onTap: related == null ? null : () => widget.onOpenAchievement(related),
      child: Material(
        color: done ? const Color(0xFFE5EEE5) : const Color(0xFFF3E9D8),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('objective-$token'),
          onTap: related == null
              ? null
              : () => widget.onOpenAchievement(related),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    done ? Icons.check_circle_outline : Icons.circle_outlined,
                    color: done ? CalendarStyle.green : const Color(0xFFAA977D),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label(token),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CalendarStyle.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (related != null)
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: CalendarStyle.green,
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
