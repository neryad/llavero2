import 'dart:io';

/// Sistema de archivo virtual para la bóveda.
///
/// En Android, el archivo vive en `/data/data/<paquete>/files/llavero/vault.dat`.
/// En iOS, en `Documents/llavero/vault.dat`.
abstract class VaultFileSystem {
  /// Ruta privada donde se guarda la bóveda (ruta completa al archivo).
  String get vaultPath;

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
class PlatformVaultFileSystem implements VaultFileSystem {
  PlatformVaultFileSystem({required this._packageName});

  final String _packageName;
  Directory? _documentsDir;

  @override
  String get vaultPath {
    if (Platform.isAndroid) {
      // Android: /data/data/<paquete>/files/llavero/vault.dat
      return '/data/data/$_packageName/files/llavero/vault.dat';
    }
    // iOS: Documents de la app.
    if (_documentsDir != null) {
      return '${_documentsDir!.path}/llavero/vault.dat';
    }
    return 'Documents/llavero/vault.dat';
  }

  @override
  Future<void> write(String path, List<int> bytes) async {
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
    final tmpFile = File('$path.tmp');
    await tmpFile.writeAsBytes(bytes);
    // Renombrar de .tmp a el nombre final (operación atómica en el SO).
    await tmpFile.rename(path);
  }

  @override
  Future<List<int>?> readVault() async {
    return await read(vaultPath);
  }

  @override
  Future<bool> vaultExists() async {
    final bytes = await read(vaultPath);
    return bytes != null;
  }

  @override
  Future<void> deleteVault() async {
    final file = File(vaultPath);
    if (await file.exists()) {
      await file.delete();
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
  Future<void> write(String path, List<int> bytes) async {
    _files[path] = bytes;
  }

  @override
  Future<List<int>?> read(String path) async {
    return _files[path];
  }

  @override
  Future<void> writeAtomic(String path, List<int> bytes) async {
    // En memoria, .tmp y el archivo final son lo mismo.
    await write(path, bytes);
  }

  @override
  Future<List<int>?> readVault() async {
    return await read(vaultPath);
  }

  @override
  Future<bool> vaultExists() async {
    final bytes = await read(vaultPath);
    return bytes != null;
  }

  @override
  Future<void> deleteVault() async {
    _files.remove(vaultPath);
  }

  @override
  List<int>? bytesAt(String path) => _files[path];
}
