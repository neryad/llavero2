import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/security/vault_problem.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../l10n/generated/app_l10n.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({
    super.key,
    required this.problem,
    this.onOpenVault,
  });

  final VaultProblem problem;
  final VoidCallback? onOpenVault;

  String _message(L10n l10n) {
    switch (problem) {
      case VaultProblem.newerFormat:
        return l10n.recoveryNewerFormat;
      case VaultProblem.corrupted:
        return l10n.recoveryCorrupted;
      case VaultProblem.unreadable:
        return l10n.recoveryUnreadable;
      case VaultProblem.missing:
        return l10n.recoveryMissing;
    }
  }

  Future<void> _retry(BuildContext context) async {
    final ok = await AppScope.of(context).retryVaultLoad();
    if (!context.mounted || !ok) return;
    onOpenVault?.call();
  }

  Future<void> _startFresh(BuildContext context) async {
    final l10n = L10n.of(context);
    const acceptedWords = <String>{'BORRAR', 'ERASE'};
    final confirm = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.startFreshConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.startFreshConfirmBody),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: confirm,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.startFreshConfirmHint,
                  filled: true,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: acceptedWords.contains(confirm.text.trim().toUpperCase())
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: Text(l10n.startFreshLabel),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => confirm.dispose());
    if (accepted != true || !context.mounted) return;
    await AppScope.of(context).startFromScratch();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.onboarding,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final color = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 48, color: color.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                _message(l10n),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => _retry(context),
                child: Text(l10n.retryLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.exportImport),
                child: Text(l10n.importBackupLabel),
              ),
              if (problem != VaultProblem.newerFormat) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => _startFresh(context),
                  style: TextButton.styleFrom(foregroundColor: color.error),
                  child: Text(l10n.startFreshLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
