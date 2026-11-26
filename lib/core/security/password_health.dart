import '../../data/models/entry_field.dart';
import '../../data/models/vault_entry.dart';

/// Nivel de salud de una contraseña.
enum PasswordHealthLevel {
  strong,
  weak,
  reused,
}

/// Informe sobre las contraseñas de la bóveda.
class PasswordHealthReport {
  const PasswordHealthReport({
    required this.weak,
    required this.reused,
    required this.total,
  });

  /// Entradas con contraseñas débiles.
  final List<VaultEntry> weak;

  /// Entradas que comparten contraseña con otra.
  final List<VaultEntry> reused;

  /// Número total de secretos revisados.
  final int total;

  bool get isEmpty => total == 0;
}

/// Analiza las contraseñas guardadas sin exponer sus valores.
abstract final class PasswordHealth {
  /// Longitud por debajo de la cual se considera débil.
  static const int minLength = 8;

  /// Contraseñas comunes que se marcan como débiles.
  static const Set<String> commonPasswords = <String>{
    'password',
    '123456',
    '12345678',
    'qwerty',
    'abc123',
    'letmein',
    'admin',
    'welcome',
  };

  /// Etiquetas que indican que un campo guarda un secreto aunque no se haya
  /// marcado la casilla «Secreto».
  static const Set<String> secretLabelHints = <String>{
    'contraseña',
    'contrasena',
    'password',
    'clave',
    'pin',
    'pass',
    'pwd',
    'secret',
  };

  /// Analiza las entradas activas de la bóveda.
  static PasswordHealthReport analyze(Iterable<VaultEntry> entries) {
    final active = entries.where((e) => !e.isDeleted).toList();
    final secrets = <VaultEntry, List<EntryField>>{};

    for (final entry in active) {
      final values = entry.fields
          .where((f) => f.value.isNotEmpty && _isSecret(f))
          .toList();
      if (values.isNotEmpty) secrets[entry] = values;
    }

    final byValue = <String, List<VaultEntry>>{};
    for (final mapEntry in secrets.entries) {
      for (final field in mapEntry.value) {
        byValue.putIfAbsent(field.value, () => <VaultEntry>[]).add(mapEntry.key);
      }
    }

    final weak = <VaultEntry>[];
    final reused = <VaultEntry>[];

    for (final mapEntry in secrets.entries) {
      final hasWeak = mapEntry.value.any(_isWeak);
      if (hasWeak) weak.add(mapEntry.key);

      final isReused = mapEntry.value.any(
        (field) => (byValue[field.value]?.length ?? 0) > 1,
      );
      if (isReused) reused.add(mapEntry.key);
    }

    return PasswordHealthReport(
      weak: weak,
      reused: reused,
      total: secrets.length,
    );
  }

  static bool _isSecret(EntryField field) {
    if (field.isSecret || field.type.hidesValueByDefault) return true;
    final label = field.label.toLowerCase().trim();
    return secretLabelHints.any(label.contains);
  }

  static bool _isWeak(EntryField field) {
    final value = field.value;
    if (value.length < minLength) return true;
    if (commonPasswords.contains(value.toLowerCase())) return true;
    if (RegExp(r'^(.)\1+$').hasMatch(value)) return true;
    return false;
  }
}
