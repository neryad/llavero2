import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén seguro de claves y datos pequeños.
///
/// En Android usa el Keystore del sistema y en iOS el Keychain, así que
/// estos datos quedan fuera del alcance del resto de apps del móvil.
///
/// La interfaz existe para poder cambiarla por una versión en memoria
/// durante los tests.
abstract class SecureStore {
  /// Guarda un valor (texto).
  Future<void> write(String key, String value);

  /// Lee un valor, o `null` si no existe.
  Future<String?> read(String key);

  /// Borra una clave.
  Future<void> delete(String key);

  /// Borra todas las claves de la app.
  Future<void> deleteAll();
}

/// Implementación real sobre `flutter_secure_storage`.
class FlutterSecureStore implements SecureStore {
  FlutterSecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) {
    return _storage.write(
      key: key,
      value: value,
      // Datos que no se sincronizan con iCloud y no viajan a otro
      // dispositivo (requisito de seguridad de Llavero).
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    );
  }

  @override
  Future<String?> read(String key) {
    return _storage.read(
      key: key,
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    );
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(
      key: key,
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    );
  }

  @override
  Future<void> deleteAll() {
    return _storage.deleteAll();
  }
}

/// Implementación en memoria, solo para los tests.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _values.clear();
  }
}

/// Claves que se usan dentro del almacén seguro.
abstract final class SecureStoreKeys {
  /// La DEK envuelta con la clave derivada del PIN.
  static const String wrappedDek = 'llavero.wrapped_dek';

  /// Parámetros del KDF usados para envolver la DEK (JSON).
  static const String kdfParameters = 'llavero.kdf_params';

  /// Copia de la DEK protegida con biometría (opcional).
  static const String biometricDek = 'llavero.biometric_dek';

  /// Estado del bloqueo por intentos fallidos (JSON).
  static const String lockoutState = 'llavero.lockout_state';

  /// Marca de que ya se completó el onboarding.
  static const String onboardingDone = 'llavero.onboarding_done';

  /// Categorías personalizadas (JSON).
  static const String categories = 'llavero.categories';
}
