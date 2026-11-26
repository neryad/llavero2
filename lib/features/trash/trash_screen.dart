import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/vault_entry.dart';
import '../../l10n/generated/app_l10n.dart';

/// Papelera: entradas borradas que se pueden restaurar o borrar para siempre.
class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final entries = AppScope.of(context).entries;

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.trashLabel),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.purgeTrashLabel,
            onPressed: () => entries.purgeExpiredTrash(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: entries,
        builder: (context, _) {
          final trashed = entries.trashed;
          if (trashed.isEmpty) {
            return Center(child: Text(l10n.emptyTrashMessage));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trashed.length,
            itemBuilder: (context, index) =>
                _TrashedTile(entry: trashed[index]),
          );
        },
      ),
    );
  }
}

class _TrashedTile extends StatelessWidget {
  const _TrashedTile({required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final entries = AppScope.of(context).entries;

    return Card(
      child: ListTile(
        title: Text(entry.title),
        subtitle: Text(entry.categoryId),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: l10n.restoreLabel,
              onPressed: () => entries.restore(entry.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined),
              tooltip: l10n.deleteForeverLabel,
              onPressed: () => entries.deleteForever(entry.id),
            ),
          ],
        ),
      ),
    );
  }
}
