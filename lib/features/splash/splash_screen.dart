import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../l10n/generated/app_l10n.dart';

/// Pantalla de arranque.
///
/// Tras [LockController.initialize] sabe si ya existe una bóveda (estado
/// guardado) o no. Si no existe, arranca en el onboarding para crear el
/// PIN; si ya existe, va a la pantalla de bloqueo (fase 4, tarea 2).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final lock = AppScope.of(context).lock;
    // Mientras el LockController no haya terminado de leer el estado del
    // dispositivo no sabemos todavía si hay bóveda, así que mostramos el
    // contenido normal.
    final bool showOnboarding = lock.initialized && !lock.hasPin;

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
            l10n.appTitle,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appTagline,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () {
              if (showOnboarding) {
                Navigator.of(context).pushNamed(AppRoutes.onboarding);
                return;
              }
              Navigator.of(context).pushReplacementNamed(AppRoutes.lock);
            },
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
  }
}
