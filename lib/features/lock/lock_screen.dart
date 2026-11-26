import 'dart:async';

import 'package:flutter/material.dart';

import 'package:llavero2/core/theme/app_spacing.dart';

import '../../../core/app_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/pin_code_input.dart';
import '../../../l10n/generated/app_l10n.dart';

/// Pantalla que pide el PIN (o biometría) para abrir la bóveda.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  Timer? _lockoutTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      AppScope.of(context).lock.tickLockout();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _openVault() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _onPin(String pin) async {
    final controllers = AppScope.of(context);
    final ok = await controllers.unlockWithPin(pin);
    if (!mounted) return;
    if (ok) {
      _openVault();
      return;
    }
    setState(() => _error = L10n.of(context).wrongPinError);
  }

  Future<void> _onBiometrics() async {
    final controllers = AppScope.of(context);
    final ok = await controllers.unlockWithBiometrics(
      localizedReason: L10n.of(context).biometricReason,
    );
    if (!mounted) return;
    if (ok) {
      _openVault();
      return;
    }
    setState(() => _error = L10n.of(context).wrongPinError);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    final lock = controllers.lock;
    final lockedOut = lock.isLockedOut;
    final length = controllers.settings.pinLength;

    if (lock.vaultCorrupted) {
      return AppScaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.vaultCorruptedMessage, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock_outline_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.pinLengthHelp,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (lockedOut) ...[
                Text(
                  l10n.lockedOutMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${lock.remainingLockout().inSeconds}s',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ] else ...[
                PinCodeInput(
                  length: length,
                  error: _error,
                  onCompleted: _onPin,
                  semanticLabel: l10n.pinLabel,
                ),
                if (lock.biometricsEnabled) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: _onBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l10n.biometricUnlockLabel),
                  ),
                ],
              ],
              if (_error != null && !lockedOut) ...[
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
