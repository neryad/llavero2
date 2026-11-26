import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/routes/app_routes.dart';
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
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.trash),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text(l10n.trashLabel),
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final id in entries.categoryIds)
                    FilterChip(
                      label: Text(
                        categoryDisplayName(
                          id,
                          l10n,
                          controllers.categories,
                        ),
                      ),
                      selected: _categoryFilter == id,
                      onSelected: (selected) => setState(() {
                        _categoryFilter = selected ? id : null;
                      }),
                    ),
                  for (final person in entries.persons)
                    FilterChip(
                      label: Text(person),
                      selected: _personFilter == person,
                      onSelected: (selected) => setState(() {
                        _personFilter = selected ? person : null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(l10n.backupReminderTitle),
                  subtitle: Text(l10n.backupReminderBody),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.exportImport),
                ),
              ),
              Expanded(
                child: all.isEmpty
                    ? EmptyState(
                        icon: Icons.key_outlined,
                        message: l10n.emptyVaultMessage,
                        actionLabel: l10n.emptyAction,
                        onAction: () => Navigator.of(context)
                            .pushNamed(AppRoutes.entryForm),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 88),
                        children: <Widget>[
                          if (favorites.isNotEmpty) ...[
                            Text(
                              l10n.favoritesSection,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            for (final entry in favorites)
                              _animatedTile(entry: entry, index: 0),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            l10n.allSection,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          for (final entry in all)
                            _animatedTile(entry: entry, index: 1),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _animatedTile({required VaultEntry entry, required int index}) {
    return AnimatedEntryTile(
      index: index,
      child: Semantics(
        button: true,
        label: entry.title,
        child: _EntryTile(entry: entry),
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
