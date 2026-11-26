import 'package:flutter/services.dart';

/// Resultado de la comprobación de integridad del dispositivo.
enum DeviceIntegrity {
  /// El dispositivo parece íntegro (o no se pudo comprobar).
  intact,

  /// El dispositivo está rooteado (Android) o jailbreakeado (iOS).
  compromised;

  bool get isCompromised => this == compromised;
}

/// Consulta al sistema si el dispositivo está rooteado/jailbreakeado.
///
/// Es una señal **informativa**, no una barrera de seguridad: un atacante
/// puede ocultarla. Sirve para avisar al usuario de que los datos cifrados
/// están en un entorno menos confiable.
abstract final class DeviceIntegrityChecker {
  static const MethodChannel _channel = MethodChannel('llavero/device_integrity');

  static Future<DeviceIntegrity> check() async {
    try {
      final result = await _channel.invokeMethod<bool>('isCompromised');
      return result == true
          ? DeviceIntegrity.compromised
          : DeviceIntegrity.intact;
    } on MissingPluginException {
      return DeviceIntegrity.intact;
    } on PlatformException {
      return DeviceIntegrity.intact;
    }
  }
}
