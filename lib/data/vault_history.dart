import 'dart:io';

/// Copias locales de versiones anteriores de la bóveda.
///
/// Antes de cada escritura se guarda el archivo bueno en `history/`. Así se
/// puede recuperar una versión reciente aunque la papelera ya haya purgado
/// una entrada. El historial es local y nunca sale del dispositivo.
class VaultHistory {
  VaultHistory({
    String? vaultPath,
    this._pathProvider,
    this.keep = 10,
  }) : _fixedPath = vaultPath ?? 'PrivateSupportDirectory/llavero/vault.dat';

  final String _fixedPath;
  final Future<String> Function()? _pathProvider;

  /// Número máximo de versiones conservadas.
  final int keep;

  /// Ruta actual del archivo (puede cambiar tras una actualización).
  Future<String> get path async => _pathProvider?.call() ?? _fixedPath;

  Future<Directory> _directory() async =>
      Directory('${File(await path).parent.path}/history');

  String _pathFor(Directory dir, DateTime version) =>
      '${dir.path}/vault-${version.microsecondsSinceEpoch}.dat';

  /// Guarda una copia del archivo actual si existe.
  Future<void> snapshot() async {
    final file = File(await path);
    if (!await file.exists()) return;
    final dir = await _directory();
    await dir.create(recursive: true);
    final version = DateTime.now().toUtc();
    await File(_pathFor(dir, version)).writeAsBytes(await file.readAsBytes());
    await prune();
  }

  /// Versiones disponibles, de más reciente a más antigua.
  Future<List<DateTime>> versions() async {
    final dir = await _directory();
    if (!await dir.exists()) return <DateTime>[];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dat'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    return files
        .map(
          (file) => DateTime.fromMicrosecondsSinceEpoch(
            int.parse(
              file.path.split('vault-').last.replaceFirst('.dat', ''),
            ),
          ),
        )
        .toList(growable: false);
  }

  /// Lee una versión concreta.
  Future<List<int>?> read(DateTime version) async {
    final file = File(_pathFor(await _directory(), version));
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// Restaura una versión como archivo actual de la bóveda.
  Future<void> restore(DateTime version) async {
    final bytes = await read(version);
    if (bytes == null) return;
    final file = File(await path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  /// Elimina las versiones más allá de [keep].
  Future<void> prune() async {
    final dir = await _directory();
    final all = await versions();
    for (final version in all.skip(keep)) {
      await File(_pathFor(dir, version)).delete();
    }
  }

  /// Borra todo el historial.
  Future<void> clear() async {
    final dir = await _directory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
