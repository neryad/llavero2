import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_entry_tile.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/category_icon_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../shared/category_name.dart';
import '../../data/models/vault_entry.dart';
import '../../l10n/generated/app_l10n.dart';

/// Pantalla principal: secciones Favoritas/Todas, búsqueda y filtros.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _categoryFilter;
  String? _personFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _chipGroup({
    required String label,
    required Map<String, String> items,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.chipGap,
          runSpacing: AppSpacing.chipGap,
          children: <Widget>[
            for (final item in items.entries)
              FilterChip(
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                selected: selected == item.key,
                onSelected: (picked) => onChanged(picked ? item.key : null),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    final entries = controllers.entries;

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.homeLabel),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsLabel,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.trashLabel,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.trash),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.entryForm),
        tooltip: l10n.addEntryLabel,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: entries,
        builder: (context, _) {
          var visible = entries.search(_searchController.text);
          if (_categoryFilter != null) {
            visible = visible
                .where((e) => e.categoryId == _categoryFilter)
                .toList();
          }
          if (_personFilter != null) {
            visible = visible.where((e) => e.person == _personFilter).toList();
          }
          final favorites = visible.where((e) => e.isFavorite).toList();
          final all = visible;

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.listBottom),
            children: <Widget>[
              Semantics(
                label: l10n.searchHint,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: AppSpacing.searchToChips),
              _chipGroup(
                label: l10n.filterByCategory,
                items: <String, String>{
                  for (final id in entries.categoryIds)
                    id: categoryDisplayName(id, l10n, controllers.categories),
                },
                selected: _categoryFilter,
                onChanged: (value) => setState(() => _categoryFilter = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _chipGroup(
                label: l10n.filterByPerson,
                items: <String, String>{
                  for (final person in entries.persons) person: person,
                },
                selected: _personFilter,
                onChanged: (value) => setState(() => _personFilter = value),
              ),
              const SizedBox(height: AppSpacing.chipsToList),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSpacing.cardPadding),
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(l10n.backupReminderTitle),
                  subtitle: Text(l10n.backupReminderBody),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.exportImport),
                ),
              ),
              if (all.isEmpty)
                EmptyState(
                  icon: Icons.key_outlined,
                  message: l10n.emptyVaultMessage,
                  actionLabel: l10n.emptyAction,
                  onAction: () => Navigator.of(context)
                      .pushNamed(AppRoutes.entryForm),
                )
              else ...[
                const SizedBox(height: AppSpacing.bannerGap),
                if (favorites.isNotEmpty) ...[
                  Text(
                    l10n.favoritesSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.headerToItem),
                  for (final entry in favorites)
                    _animatedTile(entry: entry, index: 0),
                  const SizedBox(height: AppSpacing.sectionGap),
                ],
                Text(
                  l10n.allSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.headerToItem),
                for (final entry in all) _animatedTile(entry: entry, index: 1),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _animatedTile({required VaultEntry entry, required int index}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: AnimatedEntryTile(
        index: index,
        child: Semantics(
          button: true,
          label: entry.title,
          child: _EntryTile(entry: entry),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.cardPadding),
        leading: CategoryIconBadge(categoryId: entry.categoryId),
        title: Text(entry.title),
        subtitle: Text(
          <String>[
            if (entry.person != null) entry.person!,
            categoryDisplayName(
              entry.categoryId,
              l10n,
              AppScope.of(context).categories,
            ),
          ].join(' · '),
        ),
        trailing: entry.isFavorite
            ? Icon(
                Icons.star,
                color: Colors.amber,
                semanticLabel: l10n.favoriteLabel,
              )
            : null,
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.entryDetail,
          arguments: entry.id,
        ),
      ),
    );
  }
}
