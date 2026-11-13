import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_authenticator.dart';

class AdminPinDialog extends StatefulWidget {
  const AdminPinDialog({super.key, required this.authenticator});
  final AdminAuthenticator authenticator;
  @override
  State<AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<AdminPinDialog> {
  final _pin = TextEditingController();
  final _focus = FocusNode();
  bool _checking = false;
  String? _error;

  Future<void> _submit() async {
    if (_checking || _pin.text.length != 4) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final valid = await widget.authenticator.authenticate(_pin.text);
      if (!mounted) return;
      if (valid) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _checking = false;
        _error = 'Falscher PIN';
        _pin.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = 'PIN konnte nicht geprüft werden.';
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('PIN eingeben'),
    content: TextField(
      key: const ValueKey('admin-pin'),
      controller: _pin,
      focusNode: _focus,
      autofocus: true,
      obscureText: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      autocorrect: false,
      enableSuggestions: false,
      enabled: !_checking,
      decoration: InputDecoration(
        labelText: 'PIN',
        errorText: _error,
        errorMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() => _error = null),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        onPressed: !_checking && _pin.text.length == 4 ? _submit : null,
        child: _checking
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Öffnen'),
      ),
    ],
  );
}
