import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Sistema de archivo virtual para la bóveda.
abstract class VaultFileSystem {
  /// Ruta privada donde se guarda la bóveda (ruta completa al archivo).
  String get vaultPath;

  /// Ruta resuelta ahora mismo.
  ///
  /// Por defecto es [vaultPath]; las implementaciones de plataforma pueden
  /// volver a consultar `path_provider` por si el directorio cambió tras una
  /// actualización del sistema operativo o de la app.
  Future<String> resolveVaultPath() async => vaultPath;

  /// Mueve un archivo sin borrarlo (se usa para conservar el dañado).
  Future<void> rename(String from, String to) =>
      throw UnsupportedError('rename no disponible en este sistema de archivos');

  /// Guarda el contenido del archivo en la ruta privada.
  Future<void> write(String path, List<int> bytes);

  /// Lee el contenido del archivo en la ruta privada.
  Future<List<int>?> read(String path);

  /// Escribir de forma atómica: primero en `.tmp`, luego renombrar.
  Future<void> writeAtomic(String path, List<int> bytes);

  /// Leer el archivo de la bóveda.
  Future<List<int>?> readVault();

  /// Verificar si existe el archivo de la bóveda.
  Future<bool> vaultExists();

  /// Borrar el archivo de la bóveda.
  Future<void> deleteVault();

  /// Lee los bytes de un archivo (solo para tests).
  List<int>? bytesAt(String path);
}

/// Implementación real: usa el sistema de archivo del dispositivo.
///
/// La ruta se resuelve con `path_provider` (directorio privado de la app) y
/// se guarda en `llavero/vault.dat`. Antes de escribir se crea el directorio
/// con `create(recursive: true)`: sin esto, la primera escritura falla con
/// `PathNotFoundException` porque `llavero/` todavía no existe.
class PlatformVaultFileSystem implements VaultFileSystem {
  PlatformVaultFileSystem({
    required this.packageName,
    Directory? baseDirectory,
  })  : _baseDir = baseDirectory,
        _injectedBase = baseDirectory != null;

  final String packageName;
  final bool _injectedBase;

  Directory? _baseDir;

  /// Resuelve la ruta privada. Debe llamarse antes de usar [vaultPath].
  Future<void> initialize() async {
    _baseDir ??= await _freshDirectory();
  }

  /// Vuelve a consultar `path_provider` y actualiza la ruta cacheada.
  ///
  /// Si se inyectó un directorio (tests), no se consulta el plugin.
  @override
  Future<String> resolveVaultPath() async {
    if (!_injectedBase) _baseDir = await _freshDirectory();
    return vaultPath;
  }

  Future<Directory> _freshDirectory() => getApplicationSupportDirectory();

  @override
  String get vaultPath {
    final base = _baseDir?.path;
    if (base == null) {
      throw StateError(
        'PlatformVaultFileSystem.initialize() debe llamarse antes de usar vaultPath.',
      );
    }
    return '$base/llavero/vault.dat';
  }

  @override
  Future<void> write(String path, List<int> bytes) async {
    // Crear el directorio padre (puede no existir en la primera escritura).
    await File(path).parent.create(recursive: true);
    await File(path).writeAsBytes(bytes);
  }

  @override
  Future<List<int>?> read(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  }

  @override
  Future<void> writeAtomic(String path, List<int> bytes) async {
    // Crear el directorio padre antes de abrir el .tmp.
    await File(path).parent.create(recursive: true);
    final tmpFile = File('$path.tmp');
    await tmpFile.writeAsBytes(bytes);
    // Renombrar de .tmp al nombre final (operación atómica del SO).
    await tmpFile.rename(path);
  }

  @override
  Future<List<int>?> readVault() async => read(vaultPath);

  @override
  Future<bool> vaultExists() async => (await read(vaultPath)) != null;

  @override
  Future<void> rename(String from, String to) async {
    final source = File(from);
    if (!await source.exists()) return;
    await File(to).parent.create(recursive: true);
    await source.rename(to);
  }

  @override
  Future<void> deleteVault() async {
    final file = File(vaultPath);
    if (await file.exists()) await file.delete();
    final backup = File('$vaultPath.v1.bak');
    if (await backup.exists()) await backup.delete();
    final dir = File(vaultPath).parent;
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        final name = entity.uri.pathSegments.last;
        if (entity is File && name.startsWith('vault.damaged-')) {
          await entity.delete();
        }
      }
    }
  }

  @override
  List<int>? bytesAt(String path) => null;
}

/// Implementación en memoria, solo para tests.
class MemoryVaultFileSystem implements VaultFileSystem {
  final Map<String, List<int>> _files = <String, List<int>>{};

  @override
  String get vaultPath => '/memory/vault.llavero';

  @override
  Future<String> resolveVaultPath() async => vaultPath;

  @override
  Future<void> write(String path, List<int> bytes) async {
    _files[path] = bytes;
  }

  @override
  Future<List<int>?> read(String path) async => _files[path];

  @override
  Future<void> rename(String from, String to) async {
    final bytes = _files.remove(from);
    if (bytes != null) _files[to] = bytes;
  }

  @override
  Future<void> writeAtomic(String path, List<int> bytes) async {
    await write(path, bytes);
  }

  @override
  Future<List<int>?> readVault() async => read(vaultPath);

  @override
  Future<bool> vaultExists() async => (await read(vaultPath)) != null;

  @override
  Future<void> deleteVault() async {
    _files.remove(vaultPath);
    _files.remove('$vaultPath.v1.bak');
    for (final path in paths.where((p) => p.contains('vault.damaged-')).toList()) {
      _files.remove(path);
    }
  }

  /// Rutas conocidas (solo para tests).
  Iterable<String> get paths => _files.keys;

  @override
  List<int>? bytesAt(String path) => _files[path];
}
