import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_scope.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/export_service.dart';
import '../../data/models/vault_document.dart';
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

  Future<File> _temporaryFile(String extension, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final name = 'llavero-${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _exportBackup() async {
    final map = await _service.createEncryptedBackup(
      _document(),
      _password.text,
    );
    final file = await _temporaryFile('llavero', utf8.encode(jsonEncode(map)));
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(file.path)]),
    );
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
      await entries.replaceAll(document);
      if (!mounted) return;
      setState(() => _message = l10n.importSuccess);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = l10n.importError);
    }
  }

  Future<void> _exportPdf() async {
    final bytes = await _service.toPdf(_document());
    final file = await _temporaryFile('pdf', bytes);
    await Printing.layoutPdf(onLayout: (_) async => await file.readAsBytes());
  }

  Future<void> _exportText(String extension, String content) async {
    final file = await _temporaryFile(extension, utf8.encode(content));
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(file.path)]),
    );
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
          const SizedBox(height: 24),
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
            onPressed: () => _exportText('json', _service.toJson(_document())),
            icon: const Icon(Icons.code_outlined),
            label: Text(l10n.exportJsonLabel),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _exportText('csv', _service.toCsv(_document())),
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
