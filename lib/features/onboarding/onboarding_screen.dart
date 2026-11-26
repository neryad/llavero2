import 'package:flutter/material.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../features/onboarding/pin_create_screen.dart';
import '../../../l10n/generated/app_l10n.dart';

/// Pantalla de onboarding (primera ejecución).
///
/// Se muestra solo cuando el usuario todavía no tiene una bóveda creada.
/// El primer paso es crear el PIN: tras validarlo dos veces (creación +
/// confirmación), el `LockController` crea la bóveda y pasa a estado
/// bloqueado (la pantalla de bloqueo, fase 4, pedirá el PIN).
///
/// El routing entre onboarding / pantalla de bloqueo lo decide la pantalla
/// de arranque (`SplashScreen`) según el estado del `LockController`.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return AppScaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.vpn_key_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingTitle,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.onboardingMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: PinLossWarning(message: l10n.pinLossWarning),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PinCreateScreen(),
                ),
              );
            },
            child: Text(l10n.createVaultLabel),
          ),
        ],
      ),
    );
  }
}

/// Aviso visible antes de crear el PIN: no hay recuperación sin respaldo.
class PinLossWarning extends StatelessWidget {
  const PinLossWarning({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
