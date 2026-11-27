import '../../controllers/entries_controller.dart';
import '../../core/security/crypto/crypto_errors.dart';
import '../../data/models/vault_document.dart';
import '../../l10n/generated/app_l10n.dart';

/// Tipo de error de importación, sin exponer mensajes internos.
enum ImportErrorKind {
  wrongPassword,
  invalidFile,
  newerVersion,
  generic,
}

ImportErrorKind importErrorKind(Object error) {
  if (error is InvalidBackupPasswordException) {
    return ImportErrorKind.wrongPassword;
  }
  if (error is UnsupportedBackupVersionException) {
    return ImportErrorKind.newerVersion;
  }
  if (error is InvalidBackupFileException || error is FormatException) {
    return ImportErrorKind.invalidFile;
  }
  return ImportErrorKind.generic;
}

String importMessage(ImportErrorKind kind, L10n l10n) {
  switch (kind) {
    case ImportErrorKind.wrongPassword:
      return l10n.invalidBackupPasswordOrFile;
    case ImportErrorKind.invalidFile:
      return l10n.invalidBackupFile;
    case ImportErrorKind.newerVersion:
      return l10n.unsupportedBackupVersion;
    case ImportErrorKind.generic:
      return l10n.importError;
  }
}

/// Aplica un respaldo combinando o reemplazando las entradas actuales.
Future<void> applyImport(
  EntriesController entries,
  VaultDocument document, {
  required bool merge,
}) async {
  if (merge) {
    await entries.merge(document);
  } else {
    await entries.replaceAll(document);
  }
}
