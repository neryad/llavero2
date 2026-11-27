import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_scope.dart';
import '../../core/platform/clipboard_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/security/secret_detector.dart';
import '../../core/security/wifi_qr.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/category_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/category_icon_badge.dart';
import '../../controllers/lock_controller.dart';
import '../shared/category_name.dart';
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
  final Set<int> _revealed = <int>{};
  final ClipboardService _clipboard = ClipboardService.instance;
  Timer? _revealTimer;
  Timer? _qrTimer;
  bool _qrVisible = false;
  LockController? _lock;

  void _toggleReveal(int index) {
    setState(() {
      if (_revealed.contains(index)) {
        _revealed.remove(index);
      } else {
        _revealed.add(index);
      }
    });
    _revealTimer?.cancel();
    _revealTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      setState(() => _revealed.clear());
    });
  }

  void _showQr() {
    _qrTimer?.cancel();
    setState(() => _qrVisible = true);
    _qrTimer = Timer(const Duration(seconds: 30), _hideQr);
  }

  void _hideQr() {
    _qrTimer?.cancel();
    if (!mounted || !_qrVisible) return;
    setState(() => _qrVisible = false);
  }

  void _onLockChanged() {
    if (_lock?.isLocked ?? false) _hideQr();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lock = AppScope.of(context).lock;
    if (identical(_lock, lock)) return;
    _lock?.removeListener(_onLockChanged);
    _lock = lock;
    _lock!.addListener(_onLockChanged);
  }

  @override
  void dispose() {
    _lock?.removeListener(_onLockChanged);
    _revealTimer?.cancel();
    _qrTimer?.cancel();
    _clipboard.dispose();
    super.dispose();
  }

  Widget _wifiQrSection(
    BuildContext context,
    L10n l10n,
    String? payload,
  ) {
    if (!_qrVisible) {
      return OutlinedButton.icon(
        onPressed: payload == null ? null : _showQr,
        icon: const Icon(Icons.qr_code_2_outlined),
        label: Text(l10n.wifiQrShowLabel),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          children: <Widget>[
            QrImageView(data: payload!, version: QrVersions.auto, size: 180),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.wifiQrNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _hideQr,
              icon: const Icon(Icons.visibility_off_outlined),
              label: Text(l10n.wifiQrHideLabel),
            ),
          ],
        ),
      ),
    );
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

        final isWifi = entry.categoryId == CategoryIds.wifi;
        final ssid = isWifi ? WifiQr.ssidOf(entry) : null;
        final payload = isWifi ? WifiQr.payloadFor(entry) : null;

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
            padding: const EdgeInsets.only(bottom: AppSpacing.listBottom),
            children: <Widget>[
              ListTile(
                leading: CategoryIconBadge(categoryId: entry.categoryId),
                title: Text(
                  categoryDisplayName(
                    entry.categoryId,
                    l10n,
                    AppScope.of(context).categories,
                  ),
                ),
                subtitle: entry.person == null ? null : Text(entry.person!),
              ),
              if (isWifi) ...[
                const SizedBox(height: AppSpacing.cardGap),
                if (ssid == null)
                  Text(
                    l10n.wifiMissingSsid,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  )
                else
                  _wifiQrSection(context, l10n, payload),
              ],
              const SizedBox(height: AppSpacing.headerToItem),
              Text(
                l10n.fieldsLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.headerToItem),
              for (final field in entry.fields)
                _FieldRow(
                  field: field,
                  revealed: _revealed.contains(entry.fields.indexOf(field)),
                  onToggle: () => _toggleReveal(entry.fields.indexOf(field)),
                  onCopy: () => _clipboard.copySecret(
                    field.value,
                    Duration(
                      seconds: AppScope.of(context).settings.clipboardTimeoutSeconds,
                    ),
                  ),
                ),
              if (entry.notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.headerToItem),
                Text(
                  l10n.notesFieldLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.headerToItem),
                Text(entry.notes),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => entries.duplicate(entry.id),
                      icon: const Icon(Icons.copy_all_outlined),
                      label: Text(l10n.duplicateLabel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(field.label, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      SecretDetector.isSecret(field) && !revealed
                          ? '••••••••'
                          : field.value,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (SecretDetector.isSecret(field))
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
      ),
    );
  }
}
