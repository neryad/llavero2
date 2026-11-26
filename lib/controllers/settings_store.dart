import 'dart:convert';

import '../core/security/secure_store.dart';

/// Persistencia de preferencias usando el almacén seguro ya disponible.
abstract class SettingsStore {
  Future<Map<String, Object?>?> load();
  Future<void> save(Map<String, Object?> values);
}

/// Implementación sobre `SecureStore` (sin paquetes nuevos).
class SecureSettingsStore implements SettingsStore {
  SecureSettingsStore(this._store);

  final SecureStore _store;

  static const String key = 'llavero.settings';

  @override
  Future<Map<String, Object?>?> load() async {
    final raw = await _store.read(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Ajustes corruptos: se usan los valores por defecto.
    }
    return null;
  }

  @override
  Future<void> save(Map<String, Object?> values) =>
      _store.write(key, jsonEncode(values));
}

/// Implementación en memoria para tests.
class InMemorySettingsStore implements SettingsStore {
  Map<String, Object?>? _values;

  @override
  Future<Map<String, Object?>?> load() async => _values;

  @override
  Future<void> save(Map<String, Object?> values) async {
    _values = Map<String, Object?>.from(values);
  }
}
