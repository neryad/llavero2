import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:llavero2/core/theme/app_spacing.dart';

import '../../../core/app_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/security/pin_validator.dart';
import '../../../core/widgets/adaptive_segmented.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/pin_code_input.dart';
import '../legal/legal_document.dart';
import '../../../l10n/generated/app_l10n.dart';
import '../shared/pin_message.dart';
import 'onboarding_screen.dart';

/// Creación de PIN: elige longitud, escribe el PIN y lo confirma.
///
/// No hay botón de confirmar: al escribir el último dígito se avanza
/// automáticamente a la fase de confirmación y después se crea la bóveda.
class PinCreateScreen extends StatefulWidget {
  const PinCreateScreen({super.key});

  @override
  State<PinCreateScreen> createState() => _PinCreateScreenState();
}

class _PinCreateScreenState extends State<PinCreateScreen> {
  late int _length;
  String? _firstPin;
  String? _error;
  bool _busy = false;

  bool _initialized = false;
  late final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer()
    ..onTap = _openTerms;
  late final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer()
    ..onTap = _openPrivacy;

  void _openTerms() {
    if (mounted) {
      Navigator.of(context).pushNamed(
        AppRoutes.legal,
        arguments: LegalDocumentKind.terms,
      );
    }
  }

  void _openPrivacy() {
    if (mounted) {
      Navigator.of(context).pushNamed(
        AppRoutes.legal,
        arguments: LegalDocumentKind.privacy,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final configured = AppScope.of(context).settings.pinLength;
    _length = (configured == 4 || configured == 8) ? configured : 6;
  }

  void _onPin(String pin) async {
    if (_busy) return;
    final l10n = L10n.of(context);
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

    if (_firstPin == null) {
      setState(() {
        _firstPin = pin;
        _error = null;
      });
      return;
    }

    if (pin != _firstPin) {
      setState(() => _error = l10n.pinMismatchError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controllers = AppScope.of(context);
      await controllers.lock.createVault(pin);
      controllers.settings.setPinLength(pin.length);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.vaultCreationError;
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return AppScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _firstPin == null ? l10n.pinLabel : l10n.confirmPinLabel,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _firstPin == null ? l10n.pinLengthHelp : l10n.confirmPinHelp,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_firstPin == null)
                AdaptiveSegmented<int>(
                  values: const <int>[4, 6, 8],
                  labels: const <String>['4', '6', '8'],
                  selected: _length,
                  onChanged: (value) => setState(() {
                    _length = value;
                    _error = null;
                  }),
                ),
              const SizedBox(height: AppSpacing.xl),
              if (_busy)
                const CircularProgressIndicator()
              else
                PinCodeInput(
                  length: _length,
                  error: _error,
                  onCompleted: _onPin,
                  semanticLabel: l10n.pinLabel,
                ),
              const SizedBox(height: AppSpacing.md),
              if (_error != null)
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppSpacing.md),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: <InlineSpan>[
                    TextSpan(text: l10n.onboardingLegalPrefix),
                    TextSpan(
                      text: l10n.legalTermsTitle,
                      style: const TextStyle(decoration: TextDecoration.underline),
                      recognizer: _termsRecognizer,
                    ),
                    TextSpan(text: l10n.onboardingLegalJoin),
                    TextSpan(
                      text: l10n.legalPrivacyTitle,
                      style: const TextStyle(decoration: TextDecoration.underline),
                      recognizer: _privacyRecognizer,
                    ),
                    TextSpan(text: l10n.onboardingLegalSuffix),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_firstPin == null)
                PinLossWarning(message: l10n.pinLossWarning),
            ],
          ),
        ),
      ),
    );
  }
}
