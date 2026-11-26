/// Errores de la capa criptográfica.
///
/// Ninguno de estos mensajes contiene datos sensibles: ni el PIN, ni la
/// clave, ni el contenido de la bóveda.
library;

/// Error base de criptografía.
class CryptoFailure implements Exception {
  const CryptoFailure(this.message);

  /// Mensaje listo para mostrar al usuario (en español).
  final String message;

  @override
  String toString() => message;
}

/// El PIN no es correcto (o la clave guardada está dañada).
class InvalidPinException extends CryptoFailure {
  const InvalidPinException([
    super.message =
        'El PIN no es correcto o los datos guardados están dañados.',
  ]);
}

/// Los datos cifrados han sido modificados o están corruptos.
class TamperedDataException extends CryptoFailure {
  const TamperedDataException([
    super.message = 'Los datos guardados están dañados o han sido modificados.',
  ]);
}

/// Todavía no existe una bóveda en este dispositivo.
class MissingVaultException extends CryptoFailure {
  const MissingVaultException([
    super.message = 'Todavía no hay ninguna bóveda en este dispositivo.',
  ]);
}

/// La contraseña del backup no es correcta.
class InvalidBackupPasswordException extends CryptoFailure {
  const InvalidBackupPasswordException([
    super.message = 'La contraseña del archivo de respaldo no es correcta.',
  ]);
}

/// El archivo de respaldo está dañado o no es un respaldo de Llavero.
class InvalidBackupFileException extends CryptoFailure {
  const InvalidBackupFileException([
    super.message = 'El archivo de respaldo no es válido o está dañado.',
  ]);
}

/// El respaldo se creó con una versión que esta app no entiende.
class UnsupportedBackupVersionException extends CryptoFailure {
  const UnsupportedBackupVersionException([
    super.message = 'Este respaldo se creó con una versión más nueva de Llavero.',
  ]);
}
