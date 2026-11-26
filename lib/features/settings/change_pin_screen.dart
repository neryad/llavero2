import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/security/pin_validator.dart';
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
              const SizedBox(height: 8),
              Text(
                _step == 1 ? l10n.pinLengthHelp : l10n.confirmPinHelp,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_step == 1) ...[
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  segments: <ButtonSegment<int>>[
                    for (final n in <int>[4, 6, 8])
                      ButtonSegment<int>(value: n, label: Text('$n')),
                  ],
                  selected: <int>{_length},
                  onSelectionChanged: (selection) {
                    setState(() => _length = selection.first);
                  },
                ),
              ],
              const SizedBox(height: 24),
              if (_busy)
                const CircularProgressIndicator()
              else
                PinCodeInput(
                  length: _step == 0 ? _length : _length,
                  error: _error,
                  onCompleted: _onPin,
                  semanticLabel: l10n.pinLabel,
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
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
