import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_scope.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../l10n/generated/app_l10n.dart';

/// Lista de copias locales de la bóveda y restauración de una versión.
class VaultHistoryScreen extends StatefulWidget {
  const VaultHistoryScreen({super.key});

  @override
  State<VaultHistoryScreen> createState() => _VaultHistoryScreenState();
}

class _VaultHistoryScreenState extends State<VaultHistoryScreen> {
  late Future<List<DateTime>> _versions;

  @override
  void initState() {
    super.initState();
    _versions = _load();
  }

  Future<List<DateTime>> _load() async {
    final history = AppScope.of(context).entries.history;
    if (history == null) return <DateTime>[];
    return history.versions();
  }

  Future<void> _restore(DateTime version) async {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    final history = controllers.entries.history;
    final dek = controllers.lock.unlockedDek;
    if (history == null || dek == null) return;

    await history.restore(version);
    await controllers.entries.open(dek);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.versionRestored)),
    );
    setState(() => _versions = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.historyLabel)),
      body: FutureBuilder<List<DateTime>>(
        future: _versions,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final versions = snapshot.data ?? <DateTime>[];
          if (versions.isEmpty) {
            return Center(child: Text(l10n.historyEmpty));
          }
          return ListView.builder(
            itemCount: versions.length,
            itemBuilder: (context, index) {
              final version = versions[index].toLocal();
              final label = DateFormat.yMd().add_Hms().format(version);
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(label),
                trailing: TextButton(
                  onPressed: () => _restore(versions[index]),
                  child: Text(l10n.restoreVersionLabel),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
