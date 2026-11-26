import 'package:flutter/services.dart';

/// Pide al sistema operativo que un archivo **no** se copie a la nube.
///
/// En iOS, los archivos de la carpeta de la app se incluyen por defecto en
/// la copia de iCloud. La bóveda cifrada no debe viajar: por eso marcamos el
/// archivo con la bandera `NSURLIsExcludedFromBackupKey`.
///
/// En Android no hace falta nada: el manifiesto ya desactiva la copia de
/// seguridad (`android:allowBackup="false"`), así que allí la llamada es un
/// no-op.
abstract final class BackupExclusion {
  /// Canal con la implementación nativa.
  static const MethodChannel _channel = MethodChannel('llavero/secure_file');

  /// Marca el archivo de la ruta [path] para que no se copie.
  ///
  /// Si el sistema no lo soporta, no pasa nada: no es un error crítico.
  static Future<void> excludeFromBackup(String path) async {
    try {
      await _channel.invokeMethod<void>('excludeFromBackup', path);
    } on MissingPluginException {
      // Plataforma sin implementación (por ejemplo, en los tests).
    } on PlatformException {
      // El sistema no ha podido excluirlo: avisamos, pero seguimos.
    }
  }
}
