import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

import '../core/security/crypto/backup_crypto.dart';
import 'models/vault_document.dart';

/// Texto que sustituye a los valores secretos en exportaciones en claro.
const String hiddenSecretPlaceholder = '[oculto]';

/// Servicio de exportación e importación de la bóveda.
///
/// El respaldo `.llavero` va cifrado con una contraseña distinta del PIN.
/// JSON, CSV y PDF **nunca** incluyen valores secretos en claro.
class ExportService {
  ExportService({BackupCrypto? backupCrypto})
      : _backup = backupCrypto ?? BackupCrypto();

  final BackupCrypto _backup;

  /// Crea el contenido de un respaldo cifrado `.llavero`.
  Future<Map<String, Object?>> createEncryptedBackup(
    VaultDocument document,
    String password, {
    DateTime? createdAt,
  }) async {
    final plain = utf8.encode(jsonEncode(document.toJson()));
    return _backup.encryptBackup(
      plain,
      password,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
  }

  /// Lee un respaldo cifrado y devuelve el documento.
  Future<VaultDocument> readEncryptedBackup(
    Map<String, Object?> backup,
    String password,
  ) async {
    final plain = await _backup.decryptBackup(backup, password);
    return VaultDocument.fromJson(
      jsonDecode(utf8.decode(plain)) as Map<String, Object?>,
    );
  }

  /// Exporta la bóveda a JSON sin secretos en claro.
  String toJson(VaultDocument document) {
    return jsonEncode(_safeDocument(document).toJson());
  }

  /// Exporta la bóveda a CSV sin secretos en claro.
  String toCsv(VaultDocument document) {
    final buffer = StringBuffer()
      ..writeln('titulo,categoria,persona,etiqueta,valor,tipo,secreto,notas');
    for (final entry in _safeDocument(document).entries) {
      for (final field in entry.fields) {
        buffer.writeln(<String>[
          entry.title,
          entry.categoryId,
          entry.person ?? '',
          field.label,
          field.value,
          field.type.name,
          field.isSecret.toString(),
          entry.notes,
        ].map(_csvEscape).join(','));
      }
    }
    return buffer.toString();
  }

  /// Genera un PDF con el resumen de la bóveda (sin secretos en claro).
  Future<Uint8List> toPdf(VaultDocument document) async {
    final pdf = pw.Document();
    final safe = _safeDocument(document);
    final fontData = await rootBundle.load(
      'assets/fonts/Plus_Jakarta_Sans/static/PlusJakartaSans-Regular.ttf',
    );
    final font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) => <pw.Widget>[
          pw.Header(level: 0, child: pw.Text('Llavero')),
          for (final entry in safe.entries) ...<pw.Widget>[
            pw.Header(level: 1, child: pw.Text(entry.title)),
            pw.Text('Categoría: ${entry.categoryId}'),
            if (entry.person != null) pw.Text('Persona: ${entry.person}'),
            for (final field in entry.fields)
              pw.Text('${field.label}: ${field.value}'),
            if (entry.notes.isNotEmpty) pw.Text('Notas: ${entry.notes}'),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Copia del documento con los valores secretos ocultos.
  VaultDocument _safeDocument(VaultDocument document) {
    return VaultDocument(
      version: document.version,
      entries: document.entries
          .map(
            (entry) => entry.copyWith(
              fields: entry.fields
                  .map(
                    (field) => field.isSecret
                        ? field.copyWith(value: hiddenSecretPlaceholder)
                        : field,
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
