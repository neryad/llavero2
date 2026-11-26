import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_scope.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/reauth_dialog.dart';
import '../../data/export_service.dart';
import '../../data/export_temp_file.dart';
import '../../data/models/vault_document.dart';
import '../../core/security/crypto/crypto_errors.dart';
import '../../l10n/generated/app_l10n.dart';

/// Pantalla para exportar e importar la bóveda.
class ExportImportScreen extends StatefulWidget {
  const ExportImportScreen({super.key});

  @override
  State<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends State<ExportImportScreen> {
  final TextEditingController _password = TextEditingController();
  final ExportService _service = ExportService();
  String? _message;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  VaultDocument _document() {
    return VaultDocument(entries: AppScope.of(context).entries.allEntries);
  }

  /// Todas las exportaciones exigen re-autenticación.
  Future<void> _withReauth(Future<void> Function() action) async {
    if (!await requireReauth(context)) return;
    await action();
  }

  Future<void> _exportBackup() async {
    await _withReauth(() async {
      final map = await _service.createEncryptedBackup(
        _document(),
        _password.text,
      );
      await ExportTempFile.use(utf8.encode(jsonEncode(map)), 'llavero', (file) async {
        await SharePlus.instance.share(
          ShareParams(files: <XFile>[XFile(file.path)]),
        );
      });
    });
  }

  Future<void> _importBackup() async {
    final l10n = L10n.of(context);
    final entries = AppScope.of(context).entries;
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['llavero'],
    );
    if (picked.isEmpty || picked.first.path == null) return;

    try {
      final file = File(picked.first.path!);
      final backup = jsonDecode(await file.readAsString()) as Map<String, Object?>;
      final document = await _service.readEncryptedBackup(
        backup,
        _password.text,
      );
      if (!mounted || !context.mounted) return;
      final merge = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.importModeTitle),
          content: Text(l10n.importConfirm),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.mergeLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.replaceLabel),
            ),
          ],
        ),
      );
      if (!context.mounted || merge == null) return;
      if (merge) {
        await entries.merge(document);
      } else {
        if (!mounted || !context.mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.replaceLabel),
            content: Text(l10n.importConfirm),
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
        if (confirm != true) return;
        await entries.replaceAll(document);
      }
      if (!mounted) return;
      setState(() => _message = l10n.importSuccess);
    } on InvalidBackupFileException {
      if (!mounted) return;
      setState(() => _message = l10n.invalidBackupFile);
    } on InvalidBackupPasswordException {
      if (!mounted) return;
      setState(() => _message = l10n.invalidBackupPassword);
    } on UnsupportedBackupVersionException {
      if (!mounted) return;
      setState(() => _message = l10n.unsupportedBackupVersion);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = l10n.importError);
    }
  }

  bool _includeSecrets = false;

  Future<bool> _confirmSecretsExport() async {
    final l10n = L10n.of(context);
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.includeSecretsLabel),
        content: Text(l10n.secretsExportWarning),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return false;

    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.includeSecretsLabel),
        content: Text(l10n.secretsExportConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.exportAnywayLabel),
          ),
        ],
      ),
    );
    return second == true;
  }

  /// Ejecuta una exportación, pidiendo doble confirmación si se van a
  /// incluir secretos en claro.
  Future<void> _guarded(Future<void> Function() action) async {
    if (_includeSecrets) {
      final confirmed = await _confirmSecretsExport();
      if (!confirmed || !mounted) return;
    }
    await action();
  }

  Future<void> _exportPdf() async {
    await _guarded(() async {
      await _withReauth(() async {
        final bytes = await _service.toPdf(
          _document(),
          includeSecrets: _includeSecrets,
        );
        await ExportTempFile.use(bytes, 'pdf', (file) async {
          await Printing.layoutPdf(onLayout: (_) async => await file.readAsBytes());
        });
      });
    });
  }

  Future<void> _exportText(String extension, String content) async {
    await _withReauth(() async {
      await ExportTempFile.use(utf8.encode(content), extension, (file) async {
        await SharePlus.instance.share(
          ShareParams(files: <XFile>[XFile(file.path)]),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.exportImportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.backupPasswordLabel,
              filled: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.backupWarning, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l10n.includeSecretsLabel),
            value: _includeSecrets,
            onChanged: (value) => setState(() => _includeSecrets = value),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _exportBackup,
            icon: const Icon(Icons.backup_outlined),
            label: Text(l10n.exportBackupLabel),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _importBackup,
            icon: const Icon(Icons.file_upload_outlined),
            label: Text(l10n.importBackupLabel),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(l10n.exportPdfLabel),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _guarded(
              () => _exportText(
                'json',
                _service.toJson(
                  _document(),
                  includeSecrets: _includeSecrets,
                ),
              ),
            ),
            icon: const Icon(Icons.code_outlined),
            label: Text(l10n.exportJsonLabel),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _guarded(
              () => _exportText(
                'csv',
                _service.toCsv(
                  _document(),
                  includeSecrets: _includeSecrets,
                ),
              ),
            ),
            icon: const Icon(Icons.table_chart_outlined),
            label: Text(l10n.exportCsvLabel),
          ),
          if (_message != null) ...[
            const SizedBox(height: 24),
            Text(
              _message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
