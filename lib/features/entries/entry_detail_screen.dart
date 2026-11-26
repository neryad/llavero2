import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/category_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/entry_field.dart';
import '../../l10n/generated/app_l10n.dart';
import 'entry_form_screen.dart';

/// Detalle de una entrada con los secretos ocultos por defecto.
class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  final Set<String> _revealed = <String>{};

  void _toggleReveal(String label) {
    setState(() {
      if (_revealed.contains(label)) {
        _revealed.remove(label);
      } else {
        _revealed.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final entries = AppScope.of(context).entries;

    return ListenableBuilder(
      listenable: entries,
      builder: (context, _) {
        final entry = entries.allEntries
            .where((e) => e.id == widget.entryId)
            .firstOrNull;
        if (entry == null) {
          return AppScaffold(
            appBar: AppBar(title: Text(l10n.homeLabel)),
            body: Center(child: Text(l10n.entryNotFound)),
          );
        }

        final categories = Theme.of(context).extension<CategoryColors>();

        return AppScaffold(
          appBar: AppBar(
            title: Text(entry.title),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  entry.isFavorite ? Icons.star : Icons.star_border,
                ),
                tooltip: l10n.favoriteLabel,
                onPressed: () => entries.toggleFavorite(entry.id),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.editEntryLabel,
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.entryForm,
                  arguments: EntryFormArgs(entryId: entry.id),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: categories?.colorOf(entry.categoryId),
                  child: const Icon(Icons.key_rounded, size: 20),
                ),
                title: Text(entry.categoryId),
                subtitle: entry.person == null ? null : Text(entry.person!),
              ),
              const SizedBox(height: 8),
              Text(l10n.fieldsLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final field in entry.fields)
                _FieldRow(
                  field: field,
                  revealed: _revealed.contains(field.label),
                  onToggle: () => _toggleReveal(field.label),
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: field.value));
                  },
                ),
              if (entry.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.notesFieldLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(entry.notes),
              ],
              const SizedBox(height: 32),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => entries.duplicate(entry.id),
                      icon: const Icon(Icons.copy_all_outlined),
                      label: Text(l10n.duplicateLabel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await entries.moveToTrash(entry.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.moveToTrashLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.revealed,
    required this.onToggle,
    required this.onCopy,
  });

  final EntryField field;
  final bool revealed;
  final VoidCallback onToggle;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(field.label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    field.isSecret && !revealed ? '••••••••' : field.value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (field.isSecret)
              IconButton(
                icon: Icon(revealed ? Icons.visibility_off : Icons.visibility),
                tooltip: revealed ? l10n.hideLabel : l10n.revealLabel,
                onPressed: onToggle,
              ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: l10n.copyLabel,
              onPressed: onCopy,
            ),
          ],
        ),
      ),
    );
  }
}
