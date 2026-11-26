import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../core/security/crypto/crypto_errors.dart';
import '../core/security/crypto/vault_crypto.dart';
import '../data/models/vault_document.dart';
import '../data/vault_file_system.dart';
import '../data/vault_history.dart';

/// Almacena y gestiona el archivo cifrado de la bóveda.
///
/// Usa AES-256-GCM para cifrar el contenido de la bóveda. El archivo tiene:
/// - Una cabecera en claro (formato, versión, fecha, parámetros del KDF).
/// - El contenido cifrado en base64.
abstract class VaultStorage {
  /// Crea un nuevo almacenamiento de bóveda.
  factory VaultStorage({
    required VaultFileSystem initialFileSystem,
    VaultHistory? history,
  }) = _VaultStorage;

  /// Historial de versiones (null si no se usa, por ejemplo en tests).
  VaultHistory? get history;

  /// El sistema de archivos usado (permite inyectar uno en memoria para tests).
  VaultFileSystem get fileSystem;

  /// Ruta del archivo de la bóveda.
  String get vaultPath;

  /// Guarda el contenido de la bóveda en el archivo cifrado.
  Future<void> save(VaultDocument document, SecretKey key);

  /// Carga el contenido de la bóveda desde el archivo cifrado.
  Future<VaultDocument?> load(SecretKey key);

  /// Verifica si existe un archivo de bóveda.
  Future<bool> exists();

  /// Borra el archivo de la bóveda.
  Future<void> delete();
}

/// Implementación real sobre [VaultFileSystem].
class _VaultStorage implements VaultStorage {
  _VaultStorage({
    required VaultFileSystem initialFileSystem,
    this._history,
  })  : _fileSystem = initialFileSystem;

  final VaultFileSystem _fileSystem;
  final VaultHistory? _history;

  @override
  VaultHistory? get history => _history;

  @override
  VaultFileSystem get fileSystem => _fileSystem;

  @override
  String get vaultPath => _fileSystem.vaultPath;

  final VaultCrypto _crypto = VaultCrypto();

  @override
  Future<void> save(VaultDocument document, SecretKey key) async {
    // Antes de sobrescribir, guardamos la versión buena como histórico.
    await _history?.snapshot();
    final plainJson = utf8.encode(jsonEncode(document.toJson()));
    final blob = await _crypto.encryptVault(plainJson, key);
    final envelope = <String, Object?>{
      'format': 'llavero-vault',
      'version': VaultDocument.currentVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'payload': base64Encode(blob),
    };
    await _fileSystem.writeAtomic(vaultPath, utf8.encode(jsonEncode(envelope)));
  }

  @override
  Future<VaultDocument?> load(SecretKey key) async {
    final bytes = await _fileSystem.read(vaultPath);
    if (bytes == null) return null;

    final texto = utf8.decode(bytes);
    final Map<String, Object?> envelope;
    try {
      final decoded = jsonDecode(texto);
      if (decoded is! Map<String, Object?>) {
        throw const TamperedDataException();
      }
      envelope = decoded;
    } on FormatException {
      throw const TamperedDataException();
    }
    if (envelope['format'] != 'llavero-vault') {
      throw const TamperedDataException();
    }
    final int version;
    try {
      version = (envelope['version'] as int?) ?? VaultDocument.currentVersion;
    } catch (_) {
      throw const TamperedDataException();
    }
    if (version != VaultDocument.currentVersion) {
      throw const TamperedDataException();
    }
    final payload = envelope['payload'] as String?;
    if (payload == null) {
      throw const TamperedDataException();
    }
    final List<int> blob;
    try {
      blob = base64Decode(payload);
    } on FormatException {
      // El payload manipulado puede romper el base64.
      throw const TamperedDataException();
    }
    final plainJson = await _crypto.decryptVault(blob, key);
    final docJson = jsonDecode(utf8.decode(plainJson)) as Map<String, Object?>;
    return VaultDocument.fromJson(docJson);
  }

  @override
  Future<bool> exists() async {
    final bytes = await _fileSystem.read(vaultPath);
    return bytes != null;
  }

  @override
  Future<void> delete() async {
    await _fileSystem.deleteVault();
  }
}
