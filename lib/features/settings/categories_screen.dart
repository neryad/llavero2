import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../controllers/categories_controller.dart';
import '../../core/theme/category_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/category_icons.dart';
import '../../core/widgets/category_icon_badge.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/vault_category.dart';
import '../../l10n/generated/app_l10n.dart';
import '../shared/category_name.dart';

/// Gestión de categorías personalizadas.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Future<void> _showDialog({VaultCategory? editing}) async {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    final nameController = TextEditingController(text: editing?.name ?? '');
    var colorId = editing?.colorId ?? CategoryIds.other;
    var iconName = editing?.iconName;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            editing == null ? l10n.newCategoryLabel : l10n.editCategoryLabel,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.categoryNameLabel,
                  filled: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.categoryColorLabel),
              const SizedBox(height: AppSpacing.headerToItem),
              Wrap(
                spacing: 8,
                children: CategoriesController.defaultIds.map((id) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => colorId = id),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .extension<CategoryColors>()
                            ?.colorOf(id),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorId == id
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.categoryIconLabel),
              const SizedBox(height: AppSpacing.headerToItem),
              SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  child: Wrap(
                    children: <Widget>[
                      for (final icon in CategoryIcons.curated)
                        IconButton(
                          icon: Icon(icon),
                          color: iconName == CategoryIcons.nameOf(icon)
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          tooltip: l10n.categoryIconLabel,
                          onPressed: () => setDialogState(
                            () => iconName = CategoryIcons.nameOf(icon),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.saveLabel),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    if (editing == null) {
      await controllers.categories.add(
        name: name,
        colorId: colorId,
        iconName: iconName,
      );
    } else {
      await controllers.categories.update(
        editing.copyWith(name: name, colorId: colorId, iconName: iconName),
      );
    }
  }

  Future<void> _remove(VaultCategory category) async {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    if (controllers.entries.categoryIds.contains(category.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.categoryInUse)),
      );
      return;
    }
    await controllers.categories.remove(category.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final categories = AppScope.of(context).categories;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.categoriesLabel)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        tooltip: l10n.newCategoryLabel,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: categories,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpacing.cardPadding,
              bottom: AppSpacing.listBottom,
            ),
            children: <Widget>[
              Text(
                l10n.defaultCategoriesLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.headerToItem),
              for (final id in CategoriesController.defaultIds)
                ListTile(
                  leading: CategoryIconBadge(categoryId: id),
                  title: Text(categoryDisplayName(id, l10n, categories)),
                ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                l10n.customCategoriesLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.headerToItem),
              if (categories.custom.isEmpty)
                EmptyState(
                  icon: Icons.category_outlined,
                  message: l10n.noCustomCategories,
                  actionLabel: l10n.newCategoryLabel,
                  onAction: () => _showDialog(),
                )
              else
                for (final category in categories.custom)
                  ListTile(
                    leading: CategoryIconBadge(
                      categoryId: category.colorId,
                      customIconName: category.iconName,
                    ),
                    title: Text(category.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n.editCategoryLabel,
                          onPressed: () => _showDialog(editing: category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.deleteForeverLabel,
                          onPressed: () => _remove(category),
                        ),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
