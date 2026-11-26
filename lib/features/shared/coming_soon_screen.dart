import 'package:flutter/material.dart';

import 'package:llavero2/core/theme/app_spacing.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../l10n/generated/app_l10n.dart';

/// Pantalla temporal para las rutas que todavía no están implementadas.
///
/// Cada fase va sustituyendo una de estas pantallas por la versión real.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.notReadyYet,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
