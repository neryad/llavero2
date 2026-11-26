import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_scope.dart';
import '../../controllers/categories_controller.dart';
import '../../core/security/password_generator.dart';
import '../../core/theme/category_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../shared/category_name.dart';
import '../../data/entry_templates.dart';
import '../../data/models/entry_field.dart';
import '../../data/models/vault_entry.dart';
import '../../l10n/generated/app_l10n.dart';

/// Argumentos de la ruta del formulario de entrada.
class EntryFormArgs {
  const EntryFormArgs({this.entryId, this.templateId});

  /// ID de la entrada a editar (null si se crea una nueva).
  final String? entryId;

  /// ID de la plantilla a usar (null si no se usa plantilla).
  final String? templateId;
}

/// Formulario para crear o editar una entrada.
class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({super.key, required this.args});

  final EntryFormArgs args;

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _FieldEditor {
  _FieldEditor({
    required this.label,
    required this.value,
    required this.type,
    required this.isSecret,
  });

  final TextEditingController label;
  final TextEditingController value;
  EntryFieldType type;
  bool isSecret;

  EntryField build() => EntryField(
        label: label.text.trim(),
        value: value.text,
        type: type,
        isSecret: isSecret,
      );

  void dispose() {
    label.dispose();
    value.dispose();
  }
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _person = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final List<_FieldEditor> _fields = <_FieldEditor>[];

  late String _id;
  late String _categoryId;
  bool _isFavorite = false;
  bool _loading = true;

  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load() async {
    final entries = AppScope.of(context).entries;
    VaultEntry? original;
    if (widget.args.entryId != null) {
      original = entries.allEntries
          .where((e) => e.id == widget.args.entryId)
          .firstOrNull;
    }

    final template = widget.args.templateId == null
        ? null
        : EntryTemplates.byId(widget.args.templateId!);

    _id = original?.id ?? const Uuid().v4();
    _categoryId = original?.categoryId ?? template?.categoryId ?? CategoryIds.other;
    _isFavorite = original?.isFavorite ?? false;
    _title.text = original?.title ?? template?.title ?? '';
    _person.text = original?.person ?? '';
    _notes.text = original?.notes ?? '';

    final source = original?.fields ?? template?.fields ?? const <EntryField>[];
    for (final field in source) {
      _fields.add(
        _FieldEditor(
          label: TextEditingController(text: field.label),
          value: TextEditingController(text: field.value),
          type: field.type,
          isSecret: field.isSecret,
        ),
      );
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _person.dispose();
    _notes.dispose();
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() {
      _fields.add(
        _FieldEditor(
          label: TextEditingController(),
          value: TextEditingController(),
          type: EntryFieldType.text,
          isSecret: false,
        ),
      );
    });
  }

  void _generate(_FieldEditor field) {
    const generator = PasswordGenerator();
    setState(() {
      field.value.text = field.type == EntryFieldType.pin
          ? generator.generatePin(6)
          : generator.generate();
    });
  }

  Future<void> _save() async {
    final now = DateTime.now().toUtc();
    final entry = VaultEntry(
      id: _id,
      title: _title.text.trim(),
      categoryId: _categoryId,
      person: _person.text.trim().isEmpty ? null : _person.text.trim(),
      fields: _fields.map((f) => f.build()).toList(growable: false),
      notes: _notes.text,
      isFavorite: _isFavorite,
      createdAt: now,
      updatedAt: now,
    );

    final entries = AppScope.of(context).entries;
    if (widget.args.entryId == null) {
      await entries.add(entry);
    } else {
      await entries.update(entry);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isNew = widget.args.entryId == null;

    return AppScaffold(
      appBar: AppBar(
        title: Text(isNew ? l10n.newEntryLabel : l10n.editEntryLabel),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: l10n.titleFieldLabel,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _person,
                  decoration: InputDecoration(
                    labelText: l10n.personFieldLabel,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: InputDecoration(
                    labelText: l10n.categoryFieldLabel,
                    filled: true,
                  ),
                  items: <String>[
                    ...CategoriesController.defaultIds,
                    for (final c in AppScope.of(context).categories.custom) c.id,
                  ].map(
                    (id) => DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        categoryDisplayName(id, l10n, AppScope.of(context).categories),
                      ),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _categoryId = value);
                  },
                ),
                const SizedBox(height: 16),
                Text(l10n.fieldsLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final field in _fields) ...[
                  TextField(
                    controller: field.label,
                    decoration: InputDecoration(
                      labelText: l10n.labelFieldLabel,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: field.value,
                          obscureText: field.isSecret,
                          decoration: InputDecoration(
                            labelText: l10n.valueFieldLabel,
                            filled: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.casino),
                        tooltip: l10n.generateLabel,
                        onPressed: () => _generate(field),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    value: field.isSecret,
                    title: Text(l10n.secretFieldLabel),
                    onChanged: (value) {
                      setState(() => field.isSecret = value ?? false);
                    },
                  ),
                  const Divider(),
                ],
                TextButton.icon(
                  onPressed: _addField,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addFieldLabel),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.notesFieldLabel,
                    filled: true,
                  ),
                ),
                SwitchListTile(
                  value: _isFavorite,
                  title: Text(l10n.favoriteLabel),
                  onChanged: (value) => setState(() => _isFavorite = value),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _save,
                  child: Text(l10n.saveLabel),
                ),
                ],
              ),
            ),
    );
  }
}
