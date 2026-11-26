import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../controllers/categories_controller.dart';
import '../../core/theme/category_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/vault_category.dart';
import '../../l10n/generated/app_l10n.dart';

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
              const SizedBox(height: 16),
              Text(l10n.categoryColorLabel),
              const SizedBox(height: 8),
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
      await controllers.categories.add(name: name, colorId: colorId);
    } else {
      await controllers.categories.update(
        editing.copyWith(name: name, colorId: colorId),
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
          if (categories.custom.isEmpty) {
            return Center(child: Text(l10n.noCustomCategories));
          }
          return ListView.builder(
            itemCount: categories.custom.length,
            itemBuilder: (context, index) {
              final category = categories.custom[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .extension<CategoryColors>()
                      ?.colorOf(category.colorId),
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
              );
            },
          );
        },
      ),
    );
  }
}
