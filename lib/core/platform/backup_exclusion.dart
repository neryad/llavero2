import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pide al sistema operativo que un archivo **no** se copie a la nube.
///
/// En iOS los archivos de la carpeta de la app se incluyen por defecto en la
/// copia de iCloud; marcamos el archivo con `NSURLIsExcludedFromBackupKey`.
/// En Android no hace falta: el manifiesto ya desactiva la copia de seguridad.
abstract final class BackupExclusion {
  static const MethodChannel _channel = MethodChannel('llavero/secure_file');

  /// Solo para tests: permite simular iOS en cualquier plataforma.
  static bool Function()? platformProbe;

  static bool get _isIOS {
    final probe = platformProbe;
    if (probe != null) return probe();
    return !kIsWeb && Platform.isIOS;
  }

  static Future<void> excludeFromBackup(String path) async {
    // Evitar canales en tests unitarios que no tienen binding inicializado.
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod<void>('excludeFromBackup', path);
    } on MissingPluginException {
      // Plataforma sin implementación.
    } on PlatformException {
      // El sistema no ha podido excluirlo: avisamos, pero seguimos.
    }
  }
}
