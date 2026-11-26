import 'package:flutter/services.dart';

/// Controla si el sistema permite capturas de pantalla de la app.
///
/// En Android usa `FLAG_SECURE` (ni capturas ni grabación). En iOS muestra un
/// overlay cuando se detecta una captura o grabación de pantalla.
///
/// Si la plataforma no implementa el canal (por ejemplo, en tests), la
/// llamada se ignora: no es un error crítico.
abstract final class ScreenSecurity {
  static const MethodChannel _channel = MethodChannel('llavero/screen_security');

  /// Activa o desactiva el bloqueo de capturas.
  static Future<void> setScreenshotsBlocked(bool blocked) async {
    try {
      await _channel.invokeMethod<void>(
        'setScreenshotsBlocked',
        <String, Object?>{'blocked': blocked},
      );
    } on MissingPluginException {
      // Plataforma sin implementación.
    } on PlatformException {
      // El sistema no ha podido aplicarlo: seguimos sin bloquear la app.
    }
  }
}
