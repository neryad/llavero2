import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app.dart';
import '../../core/app_scope.dart';
import '../../controllers/categories_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/security/password_generator.dart';
import '../../core/theme/app_spacing.dart';
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
    this.keyStable,
    this.fixedLabel = false,
  });

  final TextEditingController label;
  final TextEditingController value;
  EntryFieldType type;
  bool isSecret;
  String? keyStable;
  bool fixedLabel;
  bool revealed = false;

  bool get passwordLike =>
      isSecret ||
      type == EntryFieldType.secret ||
      keyStable == FieldKeys.password ||
      keyStable == FieldKeys.cvv;

  EntryField build() => EntryField(
        key: keyStable,
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

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  const _PinnedHeader({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Material(color: Theme.of(context).scaffoldBackgroundColor, child: child);

  @override
  bool shouldRebuild(covariant _PinnedHeader oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
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

  EntryTemplate? _templateFor(String id) {
    switch (id) {
      case CategoryIds.wifi:
        return EntryTemplates.wifi;
      case CategoryIds.email:
        return EntryTemplates.website;
      case CategoryIds.pinCode:
        return EntryTemplates.pin;
      default:
        return null;
    }
  }

  void _loadTemplateFields(String id) {
    final template = _templateFor(id);
    _fields
      ..clear()
      ..addAll((template?.fields ?? const <EntryField>[]).map(
        (field) => _FieldEditor(
          label: TextEditingController(text: field.label),
          value: TextEditingController(text: field.value),
          type: field.type,
          isSecret: field.isSecret,
          keyStable: field.key,
          fixedLabel: true,
        ),
      ));
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

    if (original != null) {
      for (final field in original.fields) {
        _fields.add(_FieldEditor(
          label: TextEditingController(text: field.label),
          value: TextEditingController(text: field.value),
          type: field.type,
          isSecret: field.isSecret,
          keyStable: field.key,
          fixedLabel: field.key != null,
        ));
      }
    } else if (template != null) {
      _loadTemplateFields(_categoryId);
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

  Future<void> _changeCategory(String id) async {
    if (id == _categoryId) return;
    final hasData = _fields.any(
      (field) =>
          field.value.text.isNotEmpty || field.label.text.isNotEmpty,
    );
    if (hasData) {
      final l10n = L10n.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.replaceFieldsTitle),
          content: Text(l10n.replaceFieldsBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.okLabel),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() {
      _categoryId = id;
      _loadTemplateFields(id);
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

  Future<void> _deleteField(int index) async {
    final field = _fields[index];
    if (field.value.text.isNotEmpty) {
      final l10n = L10n.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteFieldConfirmTitle),
          content: Text(l10n.deleteFieldConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.deleteForeverLabel),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() {
      _fields.removeAt(index).dispose();
      _dirty = true;
    });
  }

  String _typeLabel(L10n l10n, EntryFieldType type) {
    switch (type) {
      case EntryFieldType.text:
        return l10n.fieldTypeText;
      case EntryFieldType.secret:
        return l10n.fieldTypeSecret;
      case EntryFieldType.pin:
        return l10n.fieldTypePin;
      case EntryFieldType.email:
        return l10n.fieldTypeEmail;
      case EntryFieldType.url:
        return l10n.fieldTypeUrl;
      case EntryFieldType.phone:
        return l10n.fieldTypePhone;
    }
  }

  Future<void> _showAddFieldSheet() async {
    final l10n = L10n.of(context);
    final name = TextEditingController();
    var type = EntryFieldType.text;
    final editor = await showModalBottomSheet<_FieldEditor>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l10n.addFieldSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: l10n.fieldNameLabel,
                  filled: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (final option in EntryFieldType.values)
                    ChoiceChip(
                      label: Text(_typeLabel(l10n, option)),
                      selected: type == option,
                      onSelected: (_) => setSheet(() => type = option),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(
                  _FieldEditor(
                    label: TextEditingController(text: name.text.trim()),
                    value: TextEditingController(),
                    type: type,
                    isSecret: type.hidesValueByDefault,
                  ),
                ),
                child: Text(l10n.addFieldLabel),
              ),
            ],
          ),
        ),
      ),
    );
    if (editor == null) return;
    setState(() {
      _fields.add(editor);
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

  Widget _fieldCard(int index, L10n l10n) {
    final field = _fields[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: field.fixedLabel
                      ? Text(field.label.text,
                          style: Theme.of(context).textTheme.labelLarge)
                      : TextField(
                          controller: field.label,
                          onChanged: (_) => setState(() => _dirty = true),
                          decoration: InputDecoration(
                            labelText: l10n.labelFieldLabel,
                            filled: true,
                          ),
                        ),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.fieldMenuLabel,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    switch (action) {
                      case 'up':
                        _moveField(index, -1);
                      case 'down':
                        _moveField(index, 1);
                      case 'delete':
                        _deleteField(index);
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      child: StatefulBuilder(
                        builder: (context, setMenu) => SwitchListTile(
                          value: field.isSecret,
                          title: Text(l10n.markAsSecret),
                          onChanged: (value) {
                            setMenu(() => field.isSecret = value);
                            setState(() => _dirty = true);
                          },
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'up',
                      enabled: index > 0,
                      child: Text(l10n.moveUp),
                    ),
                    PopupMenuItem<String>(
                      value: 'down',
                      enabled: index < _fields.length - 1,
                      child: Text(l10n.moveDown),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(l10n.deleteForeverLabel),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: field.value,
                    obscureText: field.isSecret && !field.revealed,
                    onChanged: (_) => setState(() => _dirty = true),
                    decoration: InputDecoration(
                      labelText: l10n.valueFieldLabel,
                      filled: true,
                    ),
                  ),
                ),
                if (field.isSecret || field.passwordLike)
                  IconButton(
                    icon: Icon(field.revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    tooltip: field.revealed ? l10n.hideLabel : l10n.revealLabel,
                    onPressed: () =>
                        setState(() => field.revealed = !field.revealed),
                  ),
                if (field.passwordLike)
                  Semantics(
                    button: true,
                    label: l10n.generateLabel,
                    child: IconButton(
                      icon: const Icon(Icons.casino_outlined),
                      tooltip: l10n.generateLabel,
                      onPressed: () => _generate(field),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid(L10n l10n) {
    final colors = Theme.of(context).colorScheme;
    final style = SegmentedButtonTheme.of(context).style;
    const states = <WidgetState>{WidgetState.selected};
    final selectedBg =
        style?.backgroundColor?.resolve(states) ?? colors.primaryContainer;
    final selectedFg =
        style?.foregroundColor?.resolve(states) ?? colors.onPrimaryContainer;

    final custom = AppScope.of(context).categories.custom;
    final ids = <String>[
      ...CategoriesController.defaultIds,
      ...custom.map((c) => c.id),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.2,
      ),
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final id = ids[index];
        final category =
            index >= CategoriesController.defaultIds.length
                ? custom[index - CategoriesController.defaultIds.length]
                : null;
        final selected = id == _categoryId;
        return InkWell(
          onTap: () => _changeCategory(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
              border: selected
                  ? null
                  : Border.all(color: colors.outline),
            ),
            child: Row(
              children: <Widget>[
                CategoryIconBadge(
                  categoryId: category?.colorId ?? id,
                  customIconName: category?.iconName,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    category?.name ??
                        categoryDisplayName(
                          id,
                          l10n,
                          AppScope.of(context).categories,
                        ),
                    maxLines: 2,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected ? selectedFg : colors.onSurface,
                        ),
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
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final headerHeight = 232 * scale;

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
                    child: CustomScrollView(
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                l10n.categoryFieldLabel,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _categoryGrid(l10n),
                              if (_categoryId == CategoryIds.streaming) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  children: <Widget>[
                                    for (final title in <String>[
                                      l10n.templateNetflix,
                                      l10n.templateDisney,
                                      l10n.templateSpotify,
                                      l10n.templateHbo,
                                    ])
                                      ActionChip(
                                        label: Text(title),
                                        onPressed: () => setState(() {
                                          _title.text = title;
                                          _loadTemplateFields(_categoryId);
                                          _dirty = true;
                                        }),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _PinnedHeader(
                            height: headerHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  TextField(
                                    controller: _title,
                                    onChanged: (_) =>
                                        setState(() => _dirty = true),
                                    decoration: InputDecoration(
                                      labelText: l10n.titleFieldLabel,
                                      filled: true,
                                    ),
                                  ),
                                  if (_fields.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    _fieldCard(0, l10n),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.listBottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                if (_fields.isEmpty &&
                                    _categoryId == CategoryIds.other)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.md,
                                    ),
                                    child: Text(
                                      l10n.otherCategoryHint,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: _person,
                                  onChanged: (_) =>
                                      setState(() => _dirty = true),
                                  decoration: InputDecoration(
                                    labelText: l10n.personFieldLabel,
                                    filled: true,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l10n.fieldsLabel,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                for (var i = 1; i < _fields.length; i++) ...[
                                  _fieldCard(i, l10n),
                                  const SizedBox(height: AppSpacing.sm),
                                ],
                                TextButton.icon(
                                  onPressed: _showAddFieldSheet,
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.addFieldLabel),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextField(
                                  controller: _notes,
                                  maxLines: 3,
                                  onChanged: (_) =>
                                      setState(() => _dirty = true),
                                  decoration: InputDecoration(
                                    labelText: l10n.notesFieldLabel,
                                    filled: true,
                                  ),
                                ),
                                SwitchListTile(
                                  value: _isFavorite,
                                  title: Text(l10n.favoriteLabel),
                                  onChanged: (value) => setState(() {
                                    _isFavorite = value;
                                    _dirty = true;
                                  }),
                                ),
                                if (_saveError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      _saveError!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
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
