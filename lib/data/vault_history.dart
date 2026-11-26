import 'dart:io';

/// Copias locales de versiones anteriores de la bóveda.
///
/// Antes de cada escritura se guarda el archivo bueno en `history/`. Así se
/// puede recuperar una versión reciente aunque la papelera ya haya purgado
/// una entrada. El historial es local y nunca sale del dispositivo.
class VaultHistory {
  VaultHistory({required String vaultPath, this.keep = 10})
      : _vaultFile = File(vaultPath);

  final File _vaultFile;

  /// Número máximo de versiones conservadas.
  final int keep;

  Directory get _directory =>
      Directory('${_vaultFile.parent.path}/history');

  String _pathFor(DateTime version) =>
      '${_directory.path}/vault-${version.microsecondsSinceEpoch}.dat';

  /// Guarda una copia del archivo actual si existe.
  Future<void> snapshot() async {
    if (!await _vaultFile.exists()) return;
    await _directory.create(recursive: true);
    final version = DateTime.now().toUtc();
    await File(_pathFor(version)).writeAsBytes(await _vaultFile.readAsBytes());
    await prune();
  }

  /// Versiones disponibles, de más reciente a más antigua.
  Future<List<DateTime>> versions() async {
    if (!await _directory.exists()) return <DateTime>[];
    final files = _directory
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
    final file = File(_pathFor(version));
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// Restaura una versión como archivo actual de la bóveda.
  Future<void> restore(DateTime version) async {
    final bytes = await read(version);
    if (bytes == null) return;
    await _vaultFile.parent.create(recursive: true);
    await _vaultFile.writeAsBytes(bytes);
  }

  /// Elimina las versiones más allá de [keep].
  Future<void> prune() async {
    final all = await versions();
    for (final version in all.skip(keep)) {
      await File(_pathFor(version)).delete();
    }
  }

  /// Borra todo el historial.
  Future<void> clear() async {
    if (await _directory.exists()) {
      await _directory.delete(recursive: true);
    }
  }
}
