import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';

/// First-launch copy is independent of calendar progress and achievements.
class WelcomeGate extends StatefulWidget {
  const WelcomeGate({super.key, required this.child});
  static const seenKey = 'welcome.seen.v1';
  final Widget child;

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  bool? _seen;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var seen = false;
    try {
      seen =
          (await SharedPreferences.getInstance()).getBool(
            WelcomeGate.seenKey,
          ) ??
          false;
    } catch (_) {
      // A preferences failure should not prevent opening the calendar.
    }
    if (mounted) setState(() => _seen = seen);
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await (await SharedPreferences.getInstance()).setBool(
        WelcomeGate.seenKey,
        true,
      );
    } catch (_) {
      // The welcome may reappear next launch if storage is unavailable.
    }
    if (mounted) setState(() => _seen = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_seen == true) return widget.child;
    if (_seen == null) return const BrandSplash();
    return WelcomeScreen(onContinue: _saving ? null : _continue);
  }
}

/// The same centered mark used by the native launch screens; no artificial wait.
class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: ExcludeSemantics(child: BrandMark(size: 192))),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 112});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/advent-icon.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue});
  final VoidCallback? onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Widget _heading(String text, double size) => Text(
    text,
    textAlign: TextAlign.center,
    style: CalendarStyle.heading.copyWith(fontSize: size, height: 1.12),
  );

  Widget _copy(String text, {double size = 16}) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(color: CalendarStyle.muted, fontSize: size, height: 1.5),
  );

  Widget get _bonus => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF6E8CE),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.card_giftcard_rounded,
          color: CalendarStyle.gold,
          size: 26,
        ),
        const SizedBox(height: 10),
        _heading('Ein Geschenk obendrauf', 21),
        const SizedBox(height: 8),
        const Text(
          'Sammle alle regulären Auszeichnungen – dann wartet ein zusätzliches Geschenk auf dich.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CalendarStyle.green,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget get _secret => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _copy(
        'Psst … Es gibt auch geheime Auszeichnungen. Mit etwas Kreativität und Chuzpe kannst du sie entdecken. Für das Zusatzgeschenk brauchst du sie nicht.',
        size: 14,
      ),
      const SizedBox(height: 18),
      Text(
        'Dein Lieblingsmann, ps ich dich auch',
        textAlign: TextAlign.center,
        style: CalendarStyle.heading.copyWith(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      ),
    ],
  );

  Widget _fit(Widget child) => ViewportFit(
    maxWidth: 440,
    padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
    child: child,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Short screens and large text get three short pages instead of a tiny
          // scaled-down wall of text. Navigation remains a full-size touch target.
          final compact =
              constraints.maxHeight < 650 ||
              MediaQuery.textScalerOf(context).scale(16) > 21;
          return Column(
            children: [
              Expanded(
                child: compact
                    ? PageView(
                        controller: _pages,
                        onPageChanged: (page) => setState(() => _page = page),
                        children: [
                          _fit(
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const BrandMark(size: 80),
                                const SizedBox(height: 12),
                                _heading('Willkommen, Schlizi!', 22),
                                const SizedBox(height: 16),
                                _copy(
                                  'Jeden Tag ein neues Rätsel. Löse es, sammle Auszeichnungen und gewinne kleine Überraschungen.',
                                ),
                              ],
                            ),
                          ),
                          _fit(_bonus),
                          _fit(
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _heading('Ein kleines Geheimnis …', 24),
                                const SizedBox(height: 20),
                                _secret,
                              ],
                            ),
                          ),
                        ],
                      )
                    : _fit(
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BrandMark(),
                            const SizedBox(height: 12),
                            _heading(
                              'Willkommen in deinem Adventskalender, Schlizi!',
                              31,
                            ),
                            const SizedBox(height: 20),
                            _copy(
                              'Jeden Tag wartet ein neues Rätsel auf dich. Löse es, sammle Auszeichnungen und gewinne kleine Überraschungen.',
                            ),
                            const SizedBox(height: 24),
                            _bonus,
                            const SizedBox(height: 22),
                            _secret,
                          ],
                        ),
                      ),
              ),
              if (compact)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    label: 'Seite \${_page + 1} von 3',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _page
                                ? CalendarStyle.gold
                                : CalendarStyle.line,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('welcome-continue'),
                        onPressed: widget.onContinue == null
                            ? null
                            : compact && _page < 2
                            ? () => _pages.animateToPage(
                                _page + 1,
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                              )
                            : widget.onContinue,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          compact && _page < 2 ? 'Weiter' : 'Türchen entdecken',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
