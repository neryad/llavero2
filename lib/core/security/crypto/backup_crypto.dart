import 'dart:convert';

import 'crypto_errors.dart';
import 'kdf.dart';
import 'vault_crypto.dart';

/// Formato del archivo de respaldo cifrado (`.llavero`).
///
/// El archivo es un JSON con la cabecera en claro (versión, fecha y
/// parámetros del KDF) y el contenido de la bóveda **cifrado** con una clave
/// derivada de una contraseña distinta del PIN.
///
/// Gracias a esto, un archivo de respaldo se puede importar en otro dispositivo
/// sin conocer el PIN original: el usuario escribe la contraseña del respaldo.
class BackupCrypto {
  BackupCrypto({VaultCrypto? vaultCrypto})
      : _vaultCrypto = vaultCrypto ?? VaultCrypto();

  /// Marca el archivo como respaldo de Llavero.
  static const String formatId = 'llavero-backup';

  /// Versión del formato de respaldo.
  static const int formatVersion = 1;

  final VaultCrypto _vaultCrypto;

  /// Cifra el contenido de la bóveda con una contraseña de respaldo.
  ///
  /// Devuelve el mapa JSON que se guarda en el archivo `.llavero`.
  Future<Map<String, Object?>> encryptBackup(
    List<int> plainVaultJson,
    String backupPassword, {
    required DateTime createdAt,
    KdfParameters? parameters,
  }) async {
    final params = parameters ?? KdfParameters.random(KdfType.argon2id);
    final key = await params.deriveKey(backupPassword);
    final blob = await _vaultCrypto.encrypt(
      plainVaultJson,
      key,
      aad: VaultCrypto.backupAad,
    );
    return <String, Object?>{
      'format': formatId,
      'version': formatVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'kdf': params.toJson(),
      'data': base64Encode(blob),
    };
  }

  /// Descifra el contenido de un archivo de respaldo.
  ///
  /// Si la contraseña no es correcta, lanza [InvalidBackupPasswordException].
  Future<List<int>> decryptBackup(
    Map<String, Object?> backup,
    String backupPassword,
  ) async {
    final format = backup['format'];
    if (format != formatId) {
      throw const TamperedDataException(
        'Este archivo no es un respaldo de Llavero.',
      );
    }
    final kdfJson = backup['kdf'];
    final data = backup['data'];
    if (kdfJson is! Map || data is! String) {
      throw const TamperedDataException();
    }

    final params = KdfParameters.fromJson(
      kdfJson.cast<String, Object?>(),
    );
    final key = await params.deriveKey(backupPassword);
    final blob = base64Decode(data);
    try {
      return await _vaultCrypto.decrypt(
        blob,
        key,
        aad: VaultCrypto.backupAad,
      );
    } on TamperedDataException {
      throw const InvalidBackupPasswordException();
    }
  }
}
