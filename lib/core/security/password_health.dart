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
    required this.shortPins,
    required this.total,
    required this.entriesReviewed,
  });

  final List<VaultEntry> weak;
  final List<VaultEntry> reused;
  final List<VaultEntry> shortPins;

  /// Número de secretos revisados.
  final int total;

  /// Número de entradas activas analizadas (aunque no tengan secretos).
  final int entriesReviewed;

  /// Entradas distintas con al menos un problema.
  int get problemCount {
    final ids = <String>{
      ...weak.map((e) => e.id),
      ...reused.map((e) => e.id),
      ...shortPins.map((e) => e.id),
    };
    return ids.length;
  }

  bool get isEmpty => entriesReviewed == 0;
}

/// Analiza las contraseñas guardadas sin exponer sus valores.
abstract final class PasswordHealth {
  static const int minLength = 8;

  /// Contraseñas comunes que se marcan como débiles.
  static const Set<String> commonPasswords = <String>{
    'password',
    '123456',
    '12345678',
    'abc12345',
    'abc123',
    'qwerty',
    'letmein',
    'admin',
    'welcome',
  };

  /// Un campo se revisa si es secreto, su tipo es secret/pin o su clave
  /// estable es password/pin. No depende solo de la casilla «Secreto».
  static bool shouldAnalyze(EntryField field) {
    if (field.value.isEmpty) return false;
    if (field.isSecret || field.type.hidesValueByDefault) return true;
    return field.key == 'password' ||
        field.key == 'pin' ||
        field.key == 'cvv';
  }

  static PasswordHealthReport analyze(Iterable<VaultEntry> entries) {
    final active = entries.where((e) => !e.isDeleted).toList();
    final secrets = <VaultEntry, List<EntryField>>{};

    for (final entry in active) {
      final values = entry.fields.where(shouldAnalyze).toList();
      if (values.isNotEmpty) secrets[entry] = values;
    }

    // Una misma contraseña en dos entradas distintas es reutilizada.
    final byValue = <String, Set<String>>{};
    for (final mapEntry in secrets.entries) {
      for (final field in mapEntry.value) {
        byValue.putIfAbsent(field.value, () => <String>{}).add(mapEntry.key.id);
      }
    }

    final weak = <VaultEntry>[];
    final reused = <VaultEntry>[];
    final shortPins = <VaultEntry>[];

    for (final mapEntry in secrets.entries) {
      if (mapEntry.value.any(_isWeak)) weak.add(mapEntry.key);
      if (mapEntry.value
          .any((field) => (byValue[field.value]?.length ?? 0) > 1)) {
        reused.add(mapEntry.key);
      }
      if (mapEntry.value.any(
          (field) => field.key == 'pin' && field.value.length < minLength)) {
        shortPins.add(mapEntry.key);
      }
    }

    return PasswordHealthReport(
      weak: weak,
      reused: reused,
      shortPins: shortPins,
      total: secrets.values.fold<int>(0, (sum, fields) => sum + fields.length),
      entriesReviewed: active.length,
    );
  }

  static bool _isWeak(EntryField field) {
    final value = field.value;
    if (value.length < minLength) return true;
    if (commonPasswords.contains(value.toLowerCase())) return true;
    if (RegExp(r'^(.)\1+$').hasMatch(value)) return true;
    return false;
  }
}
