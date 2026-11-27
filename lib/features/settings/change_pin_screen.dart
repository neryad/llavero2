import 'package:flutter/material.dart';

import 'package:llavero2/core/theme/app_spacing.dart';

import '../../core/app_scope.dart';
import '../../core/security/pin_validator.dart';
import '../../core/widgets/adaptive_segmented.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/pin_code_input.dart';
import '../../l10n/generated/app_l10n.dart';
import '../shared/pin_message.dart';

/// Cambio de PIN en tres pasos: actual, nuevo y confirmación.
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  int _step = 0;
  late int _length;
  String? _currentPin;
  String? _newPin;
  String? _error;
  bool _busy = false;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final configured = AppScope.of(context).settings.pinLength;
    _length = (configured == 4 || configured == 8) ? configured : 6;
  }

  Future<void> _onPin(String pin) async {
    final l10n = L10n.of(context);
    if (_step == 0) {
      // Re-autenticación: solo se elige la nueva longitud si el PIN actual
      // es correcto. Después se reenvuelve la DEK de forma atómica.
      final valid = await AppScope.of(context).lock.verifyPin(pin);
      if (!mounted) return;
      if (!valid) {
        setState(() => _error = l10n.wrongCurrentPin);
        return;
      }
      _currentPin = pin;
      setState(() {
        _step = 1;
        _error = null;
      });
      return;
    }

    if (_step == 1) {
      final issue = PinValidator.validate(
        pin,
        expectedLength: _length,
        minimumLength: _length,
        maximumLength: _length,
      );
      if (issue != PinIssue.ok) {
        setState(() => _error = pinIssueMessage(issue, l10n));
        return;
      }
      _newPin = pin;
      setState(() {
        _step = 2;
        _error = null;
      });
      return;
    }

    if (pin != _newPin) {
      setState(() => _error = l10n.pinMismatchError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await AppScope.of(context).lock.changePin(_currentPin!, _newPin!);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = l10n.wrongCurrentPin;
      });
      return;
    }
    AppScope.of(context).settings.setPinLength(_length);
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _step == 0
                    ? l10n.currentPinLabel
                    : (_step == 1 ? l10n.newPinLabel : l10n.confirmNewPinLabel),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _step == 1 ? l10n.pinLengthHelp : l10n.confirmPinHelp,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_step == 1) ...[
                const SizedBox(height: AppSpacing.md),
                AdaptiveSegmented<int>(
                  values: const <int>[4, 6, 8],
                  labels: const <String>['4', '6', '8'],
                  selected: _length,
                  onChanged: (value) => setState(() => _length = value),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (_busy)
                const CircularProgressIndicator()
              else
                PinCodeInput(
                  length: _length,
                  error: _error,
                  onCompleted: _onPin,
                  semanticLabel: l10n.pinLabel,
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
