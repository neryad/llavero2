import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_l10n.dart';

/// Pantalla que pide el PIN (o la biometría) para abrir la bóveda.
///
/// Mientras la app esté bloqueada por intentos fallidos no se puede ni
/// escribir el PIN: se muestra la cuenta atrás.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  Timer? _lockoutTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Actualizamos la cuenta atrás cada segundo mientras haya bloqueo.
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      AppScope.of(context).lock.tickLockout();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _openVault() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _submitPin() async {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    final pin = _pinController.text.trim();

    if (pin.isEmpty) return;

    // Esperamos a que las entradas estén cargadas antes de navegar.
    final ok = await controllers.unlockWithPin(pin);
    _pinController.clear();
    if (!mounted) return;

    if (ok) {
      _openVault();
      return;
    }
    setState(() => _error = l10n.wrongPinError);
  }

  Future<void> _submitBiometrics() async {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);

    final ok = await controllers.unlockWithBiometrics(
      localizedReason: l10n.biometricReason,
    );
    if (!mounted) return;

    if (ok) {
      _openVault();
      return;
    }
    setState(() => _error = l10n.wrongPinError);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final lock = AppScope.of(context).lock;
    final lockedOut = lock.isLockedOut;

    if (lock.vaultCorrupted) {
      return AppScaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded, size: 48),
                const SizedBox(height: 16),
                Text(l10n.vaultCorruptedMessage, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.exportImport),
                  child: Text(l10n.importBackupLabel),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          if (lockedOut) ...[
            Text(
              l10n.lockedOutMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${lock.remainingLockout().inSeconds}s',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: AppTypography.monoFont,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
            ),
          ] else ...[
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              obscureText: true,
              enabled: !lockedOut,
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
              onSubmitted: (_) => _submitPin(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitPin,
              child: Text(l10n.unlockLabel),
            ),
            if (lock.biometricsEnabled) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _submitBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: Text(l10n.biometricUnlockLabel),
              ),
            ],
          ],
          if (_error != null && !lockedOut) ...[
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
    );
  }
}
