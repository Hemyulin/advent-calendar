import 'package:flutter/material.dart';
import '../achievements/achievement_store.dart';
import '../presentation/viewport_fit.dart';

class AchievementRewardsScreen extends StatefulWidget {
  const AchievementRewardsScreen({super.key, required this.store});
  final AchievementStore store;
  @override
  State<AchievementRewardsScreen> createState() =>
      _AchievementRewardsScreenState();
}

class _AchievementRewardsScreenState extends State<AchievementRewardsScreen> {
  final _text = TextEditingController();
  bool _saving = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    widget.store.ready.then((_) {
      if (mounted) setState(_read);
    });
  }

  void _read() {
    _text.text = widget.store.reward(finalReward) ?? '';
    _message = null;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.store.setReward(finalReward, _text.text);
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
    appBar: AppBar(title: const FittedBox(child: Text('Erfolge & Gutscheine'))),
    body: SafeArea(
      child: ViewportFit(
        maxWidth: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Ein Extra-Bonus für alle Erfolge',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _text,
              maxLength: 240,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Versteckte Belohnung',
                hintText: 'Zum Beispiel: Dein persönlicher Gutschein …',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dieser Extra-Bonus wird nach allen Erfolgen sichtbar – zusätzlich zu den täglichen Geschenken. Leer lassen, bis die Überraschung feststeht.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Speichert…' : 'Speichern'),
            ),
            if (_message != null) Text(_message!, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
