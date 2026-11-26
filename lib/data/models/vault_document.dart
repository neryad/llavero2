import 'vault_entry.dart';

/// El contenido completo de la bóveda.
///
/// Es lo que se guarda (cifrado) en el archivo del dispositivo y también lo
/// que se exporta en los respaldos.
class VaultDocument {
  const VaultDocument({required this.entries, this.version = currentVersion});

  /// Versión del formato del documento.
  static const int currentVersion = 1;

  /// Todas las entradas, incluidas las que están en la papelera.
  final List<VaultEntry> entries;

  /// Versión del formato (para poder migrar en el futuro).
  final int version;

  /// Documento vacío.
  static const VaultDocument empty = VaultDocument(entries: <VaultEntry>[]);

  /// Convierte el documento a JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': version,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }

  /// Lee un documento desde JSON.
  factory VaultDocument.fromJson(Map<String, Object?> json) {
    final rawEntries = json['entries'] as List<Object?>? ?? const <Object?>[];
    return VaultDocument(
      version: (json['version'] as int?) ?? currentVersion,
      entries: rawEntries
          .whereType<Map<Object?, Object?>>()
          .map((entry) => VaultEntry.fromJson(entry.cast<String, Object?>()))
          .toList(growable: false),
    );
  }
}
