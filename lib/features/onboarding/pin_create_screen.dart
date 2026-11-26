import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/security/pin_validator.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_l10n.dart';

/// Paso de creación de PIN dentro del onboarding.
///
/// Tiene dos fases:
/// 1. El usuario escribe su primer PIN y se valida con `PinValidator`.
/// 2. Confirma el mismo PIN; si coincide, se crea la bóveda mediante el
///    `LockController` (que a su vez usa el `VaultKeyService`).
///
/// Si el primer PIN no es válido (secuencia, repetición, común, largo, ...)
/// se muestra el error y se vuelve a pedir.
class PinCreateScreen extends StatefulWidget {
  const PinCreateScreen({super.key});

  @override
  State<PinCreateScreen> createState() => _PinCreateScreenState();
}

class _PinCreateScreenState extends State<PinCreateScreen> {
  final TextEditingController _pinController = TextEditingController();

  /// Primer PIN escrito por el usuario; `null` mientras se valida.
  String? _firstPin;

  /// Error actual (null si el PIN puede escribirse sin avisar).
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    final l10n = L10n.of(context);

    // Fase 1: validar el primer PIN.
    if (PinValidator.validate(pin) != PinIssue.ok) {
      setState(() {
        _error = l10n.pinInvalidError;
      });
      _pinController.clear();
      return;
    }

    if (_firstPin == null) {
      // PIN válido: guardarlo y pasar a la fase de confirmación.
      setState(() {
        _firstPin = pin;
        _error = null;
      });
      _pinController.clear();
      return;
    }

    // Fase 2: confirmar el primer PIN.
    if (pin != _firstPin) {
      setState(() => _error = l10n.pinMismatchError);
      _pinController.clear();
      return;
    }

    // PIN repetido correctamente: crear la bóveda (y pasar a estado
    // bloqueado, que es la pantalla que pedirá el PIN en la fase 2).
    final lock = AppScope.of(context).lock;
    try {
      await lock.createVault(pin);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.vaultCreationError);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _firstPin == null ? l10n.pinLabel : l10n.confirmPinLabel,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              // El rango permitido es 4–8; el ajuste pinLength solo es un
              // valor por defecto y no debe limitar lo que el usuario puede
              // escribir aquí (el validador acepta cualquier longitud 4–8).
              maxLength: 8,
              obscureText: true,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: AppTypography.monoFont,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
              decoration: InputDecoration(
                labelText: l10n.pinLabel,
                hintText: '••••••',
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: _submit,
              child: Text(l10n.createVaultLabel),
            ),
          ],
        ),
      ),
    );
  }
}
