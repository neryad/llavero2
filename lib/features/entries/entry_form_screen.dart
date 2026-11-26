import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app.dart';
import '../../core/app_scope.dart';
import '../../controllers/categories_controller.dart';
import '../../core/security/password_generator.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/category_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/category_icon_badge.dart';
import '../shared/category_name.dart';
import '../../data/entry_templates.dart';
import '../../data/models/entry_field.dart';
import '../../data/models/vault_entry.dart';
import '../../l10n/generated/app_l10n.dart';

class EntryFormArgs {
  const EntryFormArgs({this.entryId, this.templateId});

  final String? entryId;
  final String? templateId;
}

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
  String? _saveError;
  bool _dirty = false;
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
    _categoryId = original?.categoryId ??
        template?.categoryId ??
        CategoryIds.other;
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
      _dirty = true;
    });
  }

  void _moveField(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _fields.length) return;
    setState(() {
      final field = _fields.removeAt(index);
      _fields.insert(target, field);
      _dirty = true;
    });
  }

  void _applyStreamingTemplate(String title) {
    setState(() {
      _title.text = title;
      _categoryId = CategoryIds.streaming;
      _fields
        ..clear()
        ..add(
          _FieldEditor(
            label: TextEditingController(text: 'Contraseña'),
            value: TextEditingController(),
            type: EntryFieldType.secret,
            isSecret: true,
          ),
        );
      _dirty = true;
    });
  }

  void _generate(_FieldEditor field) {
    const generator = PasswordGenerator();
    setState(() {
      field.value.text = field.type == EntryFieldType.pin
          ? generator.generatePin(6)
          : generator.generate();
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final l10n = L10n.of(context);
    String? validation;
    if (_title.text.trim().isEmpty) validation = l10n.titleRequired;
    if (_fields.isEmpty) validation ??= l10n.fieldsRequired;
    if (validation != null) {
      setState(() => _saveError = validation);
      return;
    }
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
    try {
      if (widget.args.entryId == null) {
        await entries.add(entry);
      } else {
        await entries.update(entry);
      }
    } on StateError {
      if (!mounted) return;
      LlaveroApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.lock,
        (_) => false,
      );
      return;
    }
    if (!mounted) return;
    _dirty = false;
    Navigator.of(context).pop();
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = L10n.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.discardLabel),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  List<Widget> _fieldWidgets(L10n l10n) {
    final widgets = <Widget>[];
    for (final item in _fields.asMap().entries) {
      final index = item.key;
      final field = item.value;
      widgets.add(
        TextField(
          controller: field.label,
          decoration: InputDecoration(
            labelText: l10n.labelFieldLabel,
            filled: true,
          ),
          onChanged: (_) => setState(() => _dirty = true),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      widgets.add(
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
                onChanged: (_) => setState(() => _dirty = true),
              ),
            ),
            Semantics(
              button: true,
              label: l10n.generateLabel,
              child: IconButton(
                icon: const Icon(Icons.casino),
                tooltip: l10n.generateLabel,
                onPressed: () => _generate(field),
              ),
            ),
          ],
        ),
      );
      widgets.add(
        Row(
          children: <Widget>[
            Expanded(
              child: SwitchListTile(
                value: field.isSecret,
                title: Text(l10n.secretFieldLabel),
                onChanged: (value) {
                  setState(() {
                    field.isSecret = value;
                    _dirty = true;
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              tooltip: l10n.moveUp,
              onPressed: () => _moveField(index, -1),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              tooltip: l10n.moveDown,
              onPressed: () => _moveField(index, 1),
            ),
          ],
        ),
      );
      widgets.add(const Divider());
    }
    return widgets;
  }

  Widget _categoryGrid(L10n l10n) {
    final custom = AppScope.of(context).categories.custom;
    final ids = <String>[...CategoriesController.defaultIds, ...custom.map((c) => c.id)];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.4,
      ),
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final id = ids[index];
        final isCustom = index >= CategoriesController.defaultIds.length;
        final category = isCustom ? custom[index - CategoriesController.defaultIds.length] : null;
        final selected = id == _categoryId;
        return InkWell(
          onTap: () => setState(() {
            _categoryId = id;
            _dirty = true;
          }),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Row(
              children: <Widget>[
                CategoryIconBadge(
                  categoryId: category?.colorId ?? id,
                  customIconName: category?.iconName,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category?.name ??
                        categoryDisplayName(id, l10n, AppScope.of(context).categories),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isNew = widget.args.entryId == null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AppScaffold(
        appBar: AppBar(
          title: Text(isNew ? l10n.newEntryLabel : l10n.editEntryLabel),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextField(
                            controller: _title,
                            onChanged: (_) => setState(() => _dirty = true),
                            decoration: InputDecoration(
                              labelText: l10n.titleFieldLabel,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _person,
                            onChanged: (_) => setState(() => _dirty = true),
                            decoration: InputDecoration(
                              labelText: l10n.personFieldLabel,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.categoryFieldLabel,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          _categoryGrid(l10n),
                          if (_categoryId == CategoryIds.streaming) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children: <Widget>[
                                for (final t in <String>[
                                  l10n.templateNetflix,
                                  l10n.templateDisney,
                                  l10n.templateSpotify,
                                  l10n.templateHbo,
                                ])
                                  ActionChip(
                                    label: Text(t),
                                    onPressed: () => _applyStreamingTemplate(t),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            l10n.fieldsLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._fieldWidgets(l10n),
                          TextButton.icon(
                            onPressed: _addField,
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addFieldLabel),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notes,
                            maxLines: 3,
                            onChanged: (_) => setState(() => _dirty = true),
                            decoration: InputDecoration(
                              labelText: l10n.notesFieldLabel,
                              filled: true,
                            ),
                          ),
                          SwitchListTile(
                            value: _isFavorite,
                            title: Text(l10n.favoriteLabel),
                            onChanged: (value) {
                              setState(() {
                                _isFavorite = value;
                                _dirty = true;
                              });
                            },
                          ),
                          if (_saveError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _saveError!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(l10n.saveLabel),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
