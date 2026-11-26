import 'package:local_auth/local_auth.dart';

/// Abstracción sobre la autenticación biométrica del dispositivo.
///
/// Existe para poder testear el `LockController` sin depender del hardware
/// real: los tests inyectan una implementación que responde `true`/`false`.
abstract class BiometricAuth {
  /// Pide al usuario que confirme huella/rostro.
  ///
  /// Devuelve `true` solo si el sistema confirma la biometría.
  Future<bool> authenticate({required String localizedReason});
}

/// Implementación real sobre `local_auth`.
class DeviceBiometricAuth implements BiometricAuth {
  DeviceBiometricAuth({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        // Solo biometría: el PIN de la app sigue siendo el plan B.
        biometricOnly: true,
      );
    } catch (_) {
      // No hay sensor, biometría no inscrita o el usuario canceló.
      return false;
    }
  }
}
