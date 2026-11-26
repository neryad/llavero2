import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/security/pin_validator.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../l10n/generated/app_l10n.dart';

/// Pantalla para cambiar el PIN de la bóveda.
///
/// No re-cifra los datos: verifica el PIN actual, valida el nuevo y vuelve a
/// envolver la DEK con una KEK derivada del nuevo PIN.
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _newPin = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    final current = _current.text.trim();
    final newPin = _newPin.text.trim();
    final confirm = _confirm.text.trim();

    if (PinValidator.validate(newPin) != PinIssue.ok) {
      setState(() => _error = l10n.pinInvalidError);
      return;
    }
    if (newPin != confirm) {
      setState(() => _error = l10n.pinMismatchError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await controllers.lock.changePin(current, newPin);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _busy = false;
        _error = l10n.wrongCurrentPin;
      });
      return;
    }

    // El ajuste de longitud debe reflejar el PIN real recién creado.
    controllers.settings.setPinLength(newPin.length);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.pinChangedSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.changePinLabel)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _current,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: l10n.currentPinLabel,
              filled: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: l10n.newPinLabel,
              filled: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirm,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: l10n.confirmNewPinLabel,
              filled: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saveLabel),
          ),
        ],
      ),
    );
  }
}
