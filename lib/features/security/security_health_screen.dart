import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/routes/app_routes.dart';
import '../../core/security/password_health.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/vault_entry.dart';
import '../../l10n/generated/app_l10n.dart';
import '../shared/category_name.dart';

/// Informe de salud: muestra solo títulos, nunca valores de secretos.
class SecurityHealthScreen extends StatelessWidget {
  const SecurityHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.securityHealthLabel)),
      body: ListenableBuilder(
        listenable: controllers.entries,
        builder: (context, _) {
          final report = PasswordHealth.analyze(controllers.entries.allEntries);
          Widget group(String title, List<VaultEntry> entries) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.headerToItem),
                  for (final entry in entries) ...[
                    _EntryRow(entry: entry),
                    const SizedBox(height: AppSpacing.cardGap),
                  ],
                  const SizedBox(height: AppSpacing.sectionGap),
                ],
              );

          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpacing.cardPadding,
              bottom: AppSpacing.listBottom,
            ),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Text(
                    l10n.healthSummary(
                      report.entriesReviewed,
                      report.problemCount,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (report.entriesReviewed == 0)
                EmptyState(
                  icon: Icons.health_and_safety_outlined,
                  message: l10n.emptyHealth,
                )
              else if (report.problemCount == 0)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Text(
                    l10n.healthAllGood(report.total),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                if (report.weak.isNotEmpty) ...[
                  group(l10n.weakPasswords, report.weak),
                ],
                if (report.reused.isNotEmpty) ...[
                  group(l10n.reusedPasswords, report.reused),
                ],
                if (report.shortPins.isNotEmpty) ...[
                  group(l10n.shortPins, report.shortPins),
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
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.cardPadding),
        minTileHeight: AppSpacing.rowMinHeight,
        leading: const Icon(Icons.warning_amber_outlined),
        title: Text(entry.title),
        subtitle: Text(
          categoryDisplayName(
            entry.categoryId,
            L10n.of(context),
            controllers.categories,
          ),
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.entryDetail,
          arguments: entry.id,
        ),
      ),
    );
  }
}
