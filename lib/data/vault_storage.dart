import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../core/platform/backup_exclusion.dart';
import '../core/security/crypto/crypto_errors.dart';
import '../core/security/crypto/vault_crypto.dart';
import '../data/models/vault_document.dart';
import '../data/vault_file_system.dart';

/// Almacena y gestiona el archivo cifrado de la bóveda.
///
/// Usa AES-256-GCM para cifrar el contenido de la bóveda. El archivo tiene:
/// - Una cabecera en claro (formato, versión, fecha, parámetros del KDF).
/// - El contenido cifrado en base64.
abstract class VaultStorage {
  /// Crea un nuevo almacenamiento de bóveda.
  factory VaultStorage({
    required VaultFileSystem initialFileSystem,
    Future<void> Function(String path)? testExclude,
  }) = _VaultStorage;

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

  /// Mueve el archivo actual a `vault.damaged-<fecha>` sin borrarlo.
  Future<void> renameVaultAsDamaged() =>
      throw UnsupportedError('renameVaultAsDamaged no disponible');

  /// Borra el archivo de la bóveda.
  Future<void> delete();

  /// Pide al sistema que el archivo no se copie a la nube (iOS).
  Future<void> excludeFromBackup();
}

/// Implementación real sobre [VaultFileSystem].
class _VaultStorage implements VaultStorage {
  _VaultStorage({
    required VaultFileSystem initialFileSystem,
    testExclude,
  })  : _fileSystem = initialFileSystem,
        _testExclude = testExclude;

  final VaultFileSystem _fileSystem;
  final Future<void> Function(String path)? _testExclude;
  String? _pendingExclusionPath;

  @override
  VaultFileSystem get fileSystem => _fileSystem;

  @override
  String get vaultPath => _fileSystem.vaultPath;

  final VaultCrypto _crypto = VaultCrypto();

  @override
  Future<void> save(VaultDocument document, SecretKey key) async {
    final path = await _fileSystem.resolveVaultPath();
    final plainJson = utf8.encode(jsonEncode(document.toJson()));
    final blob = await _crypto.encryptVault(plainJson, key);
    final envelope = <String, Object?>{
      'format': 'llavero-vault',
      'version': VaultDocument.currentVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'payload': base64Encode(blob),
    };
    final bytes = utf8.encode(jsonEncode(envelope));
    // Si una exclusión anterior falló, se reintenta antes de seguir.
    await _retryPendingExclusion();
    await _fileSystem.writeAtomic(path, bytes);
    // El archivo ya está guardado: un fallo aquí no debe parecer un fallo de
    // guardado. Se reintenta en el próximo save o al arrancar.
    try {
      await _exclude(path);
    } on Object {
      _pendingExclusionPath = path;
    }
  }

  Future<void> _exclude(String path) async {
    final override = _testExclude;
    if (override != null) {
      await override(path);
      return;
    }
    await BackupExclusion.excludeFromBackup(path);
  }

  Future<void> _retryPendingExclusion() async {
    final pending = _pendingExclusionPath;
    if (pending == null) return;
    try {
      await _exclude(pending);
      _pendingExclusionPath = null;
    } on Object {
      // Sin log: la ruta es información sensible.
    }
  }

  @override
  Future<VaultDocument?> load(SecretKey key) async {
    final path = await _fileSystem.resolveVaultPath();
    final bytes = await _fileSystem.read(path);
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
    if (version > VaultDocument.currentVersion) {
      throw const UnsupportedVaultVersionException();
    }
    if (version < 1) {
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
    final document = VaultDocument.fromJson(docJson);
    if (version < VaultDocument.currentVersion) {
      await _migrateInMemoryToCurrent(
        document: document,
        key: key,
        path: path,
        originalBytes: bytes,
        backupPath: '$path.v1.bak',
      );
    }
    return document;
  }

  /// Copia el archivo v1 a `vault.v1.bak` (sin sobrescribir), reescribe en v2
  /// de forma atómica y verifica la lectura. Si algo falla, restaura los bytes
  /// originales y se sigue adelante con los datos ya parseados en memoria.
  Future<void> _migrateInMemoryToCurrent({
    required VaultDocument document,
    required SecretKey key,
    required String path,
    required List<int> originalBytes,
    required String backupPath,
  }) async {
    try {
      if (await _fileSystem.read(backupPath) == null) {
        await _fileSystem.writeAtomic(backupPath, originalBytes);
      }
      await save(
        VaultDocument(
          entries: document.entries,
          version: VaultDocument.currentVersion,
        ),
        key,
      );
      final verified = await load(key);
      if (verified == null || verified.entries.length != document.entries.length) {
        throw const TamperedDataException();
      }
    } on Object {
      // Último recurso: dejar el archivo original como estaba.
      try {
        await _fileSystem.writeAtomic(path, originalBytes);
      } on Object {
        // Best effort: el usuario entra igual con los datos en memoria.
      }
    }
  }

  @override
  Future<void> renameVaultAsDamaged() async {
    final path = await _fileSystem.resolveVaultPath();
    final slash = path.lastIndexOf('/');
    final dir = slash >= 0 ? path.substring(0, slash) : '';
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
    final prefix = dir.isEmpty ? '' : '$dir/';
    await _fileSystem.rename(path, '${prefix}vault.damaged-$stamp');
  }

  @override
  Future<bool> exists() async {
    final path = await _fileSystem.resolveVaultPath();
    final bytes = await _fileSystem.read(path);
    return bytes != null;
  }

  @override
  Future<void> delete() async {
    await _fileSystem.deleteVault();
  }

  @override
  Future<void> excludeFromBackup() async {
    await _retryPendingExclusion();
  }
}
