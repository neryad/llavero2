import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/security/password_health.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/vault_entry.dart';
import '../../l10n/generated/app_l10n.dart';
import '../shared/category_name.dart';

/// Informe de salud de las contraseñas guardadas.
///
/// Muestra solo títulos: nunca revela los valores de los secretos.
class SecurityHealthScreen extends StatelessWidget {
  const SecurityHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    final report = PasswordHealth.analyze(controllers.entries.allEntries);

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.securityHealthLabel)),
      body: ListenableBuilder(
        listenable: controllers.entries,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.healthSummary(report.total),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              if (report.isEmpty || (report.weak.isEmpty && report.reused.isEmpty))
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.allGood,
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                if (report.weak.isNotEmpty) ...[
                  Text(
                    l10n.weakPasswords,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final entry in report.weak)
                    _EntryRow(entry: entry),
                  const SizedBox(height: 16),
                ],
                if (report.reused.isNotEmpty) ...[
                  Text(
                    l10n.reusedPasswords,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final entry in report.reused)
                    _EntryRow(entry: entry),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final controllers = AppScope.of(context);
    return ListTile(
      leading: const Icon(Icons.warning_amber_outlined),
      title: Text(entry.title),
      subtitle: Text(
        categoryDisplayName(
          entry.categoryId,
          L10n.of(context),
          controllers.categories,
        ),
      ),
    );
  }
}
