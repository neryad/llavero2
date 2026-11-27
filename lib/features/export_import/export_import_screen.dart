import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/reauth_dialog.dart';
import '../../data/export_service.dart';
import '../../data/export_temp_file.dart';
import '../../data/models/vault_document.dart';
import '../../l10n/generated/app_l10n.dart';
import 'import_actions.dart';

/// Pantalla para exportar e importar la bóveda.
class ExportImportScreen extends StatefulWidget {
  const ExportImportScreen({super.key});

  @override
  State<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends State<ExportImportScreen> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final ExportService _service = ExportService();
  String? _message;
  bool _obscure = true;
  bool _confirmObscure = true;
  bool _includeSecrets = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  VaultDocument _document() {
    return VaultDocument(entries: AppScope.of(context).entries.allEntries);
  }

  bool get _canExportBackup =>
      _password.text.length >= 8 && _password.text == _confirm.text;

  String _strength(L10n l10n) {
    final length = _password.text.length;
    if (length >= 12) return l10n.passwordStrengthStrong;
    if (length >= 8) return l10n.passwordStrengthOk;
    return l10n.passwordStrengthWeak;
  }

  /// Todas las exportaciones exigen re-autenticación.
  Future<void> _withReauth(Future<void> Function() action) async {
    if (!await requireReauth(context)) return;
    await action();
  }

  Future<void> _exportBackup() async {
    if (!_canExportBackup) return;
    final ctx = context;
    final document = _document();
    final settings = AppScope.of(ctx).settings;
    final tip = L10n.of(ctx).backupTip;
    await _withReauth(() async {
      final map = await _service.createEncryptedBackup(
        document,
        _password.text,
      );
      await ExportTempFile.use(
        utf8.encode(jsonEncode(map)),
        'llavero',
        (file) async {
          await SharePlus.instance.share(
            ShareParams(files: <XFile>[XFile(file.path)]),
          );
          final name = file.path.split(RegExp(r'[\\/]')).last;
          // Solo se guarda la fecha: nunca la contraseña del respaldo.
          await settings.setLastBackupAt(DateTime.now());
          if (!ctx.mounted) return;
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('$name · $tip')),
          );
        },
      );
      _password.clear();
      _confirm.clear();
      if (mounted) setState(() {});
    });
  }

  Future<void> _importBackup() async {
    final ctx = context;
    final l10n = L10n.of(ctx);
    final entries = AppScope.of(ctx).entries;
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
      if (! mounted) return;
      if (!ctx.mounted) return;
      final merge = await showDialog<bool>(
        context: ctx,
        builder: (context) => AlertDialog(
          title: Text(l10n.importModeTitle),
          content: Text(l10n.importEntriesFound(document.entries.length)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.mergeLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.replaceLabel),
            ),
          ],
        ),
      );
      if (!ctx.mounted) return;
      if (merge == null) return;
      if (!merge) {
        final confirmed = await showDialog<bool>(
          context: ctx,
          builder: (context) => AlertDialog(
            title: Text(l10n.replaceLabel),
            content: Text(l10n.replaceConfirmBody),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancelLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.okLabel),
              ),
            ],
          ),
        );
        if (confirmed != true || !ctx.mounted) return;
      }
      await applyImport(entries, document, merge: merge);
      if (!mounted) return;
      setState(() => _message = l10n.importSuccess);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _message = importMessage(importErrorKind(error), l10n));
    }
  }

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
          await Printing.layoutPdf(
            onLayout: (_) async => await file.readAsBytes(),
          );
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

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...children,
          const SizedBox(height: AppSpacing.lg),
        ],
      );

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          tooltip: obscure ? L10n.of(context).revealLabel : L10n.of(context).hideLabel,
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final color = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.exportImportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          _section(context, l10n.encryptedBackupSection, <Widget>[
            _passwordField(
              controller: _password,
              label: l10n.backupPasswordLabel,
              obscure: _obscure,
              onToggle: () => setState(() => _obscure = !_obscure),
            ),
            const SizedBox(height: AppSpacing.sm),
            _passwordField(
              controller: _confirm,
              label: l10n.confirmPasswordLabel,
              obscure: _confirmObscure,
              onToggle: () => setState(() => _confirmObscure = !_confirmObscure),
            ),
            if (_password.text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.backupPasswordLabel}: ${_strength(l10n)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.backupWarning, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _canExportBackup ? _exportBackup : null,
              icon: const Icon(Icons.backup_outlined),
              label: Text(l10n.exportBackupShortLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _importBackup,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(l10n.importBackupLabel),
            ),
          ]),
          _section(context, l10n.plainExportSection, <Widget>[
            Text(
              l10n.plainExportWarning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.error,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              title: Text(l10n.includeSecretsLabel),
              value: _includeSecrets,
              onChanged: (value) => setState(() => _includeSecrets = value),
            ),
            OutlinedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(l10n.exportPdfLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
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
          ]),
          if (_message != null)
            Text(
              _message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color.primary,
                  ),
            ),
        ],
      ),
    );
  }
}
