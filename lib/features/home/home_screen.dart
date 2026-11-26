import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/category_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/vault_entry.dart';
import '../../l10n/generated/app_l10n.dart';

/// Pantalla principal: listado de entradas con búsqueda y filtros.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _onlyFavorites = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final entries = AppScope.of(context).entries;

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.homeLabel),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.trashLabel,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.trash),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.entryForm),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: entries,
        builder: (context, _) {
          var visible = entries.search(_searchController.text);
          if (_onlyFavorites) {
            visible = visible.where((e) => e.isFavorite).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<bool>(
                  segments: <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(l10n.allEntriesLabel),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(l10n.favoritesFilterLabel),
                    ),
                  ],
                  selected: <bool>{_onlyFavorites},
                  onSelectionChanged: (selection) {
                    setState(() => _onlyFavorites = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: visible.isEmpty
                    ? Center(child: Text(l10n.emptyVaultMessage))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: visible.length,
                        itemBuilder: (context, index) =>
                            _EntryTile(entry: visible[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final categories = Theme.of(context).extension<CategoryColors>();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categories?.colorOf(entry.categoryId),
          child: const Icon(Icons.key_rounded, size: 20),
        ),
        title: Text(entry.title),
        subtitle: Text(entry.person ?? entry.categoryId),
        trailing: entry.isFavorite
            ? const Icon(Icons.star, color: Colors.amber)
            : null,
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.entryDetail,
          arguments: entry.id,
        ),
      ),
    );
  }
}
