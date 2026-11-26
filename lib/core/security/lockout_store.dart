import 'dart:convert';

import 'lockout_policy.dart';
import 'secure_store.dart';

/// Guarda el estado del bloqueo (intentos fallidos y hasta cuándo).
///
/// Persistirlo es lo que hace que el castigo sobreviva a reiniciar la app:
/// si no, cerrar y abrir Llavero sería una forma de saltarse el bloqueo.
abstract class LockoutStore {
  /// Lee el estado guardado.
  Future<LockoutState> load();

  /// Guarda el estado.
  Future<void> save(LockoutState state);

  /// Borra el estado guardado.
  Future<void> clear();
}

/// Implementación sobre el almacén seguro del sistema.
class SecureStoreLockoutStore implements LockoutStore {
  SecureStoreLockoutStore(this._store);

  final SecureStore _store;

  @override
  Future<LockoutState> load() async {
    final raw = await _store.read(SecureStoreKeys.lockoutState);
    if (raw == null) return LockoutState.initial;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return LockoutState.initial;
      return LockoutState.fromJson(decoded.cast<String, Object?>());
    } on FormatException {
      // Si el estado guardado está corrupto, empezamos limpio.
      return LockoutState.initial;
    }
  }

  @override
  Future<void> save(LockoutState state) {
    return _store.write(SecureStoreKeys.lockoutState, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() {
    return _store.delete(SecureStoreKeys.lockoutState);
  }
}

/// Implementación en memoria, solo para los tests.
class InMemoryLockoutStore implements LockoutStore {
  LockoutState _state = LockoutState.initial;

  @override
  Future<LockoutState> load() async => _state;

  @override
  Future<void> save(LockoutState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = LockoutState.initial;
  }
}
