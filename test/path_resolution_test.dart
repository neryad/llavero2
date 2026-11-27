import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';

/// FileSystem que cambia de ruta entre operaciones (simula una actualización).
class _ChangingPathFileSystem implements VaultFileSystem {
  _ChangingPathFileSystem(this._inner, this._path);

  final VaultFileSystem _inner;
  final String Function() _path;

  @override
  String get vaultPath => _path();

  @override
  Future<String> resolveVaultPath() async => _path();

  @override
  Future<void> rename(String from, String to) => _inner.rename(from, to);

  @override
  Future<void> write(String path, List<int> bytes) => _inner.write(path, bytes);

  @override
  Future<List<int>?> read(String path) => _inner.read(path);

  @override
  Future<void> writeAtomic(String path, List<int> bytes) =>
      _inner.writeAtomic(path, bytes);

  @override
  Future<List<int>?> readVault() => _inner.read(vaultPath);

  @override
  Future<bool> vaultExists() => _inner.vaultExists();

  @override
  Future<void> deleteVault() => _inner.deleteVault();

  @override
  List<int>? bytesAt(String path) => _inner.bytesAt(path);
}

void main() {
  group('Mejora 19 — Re-resolución de la ruta', () {
    test('MemoryVaultFileSystem resuelve su ruta actual', () async {
      final fs = MemoryVaultFileSystem();
      expect(await fs.resolveVaultPath(), fs.vaultPath);
    });

    test('el storage usa la ruta resuelta en cada lectura/escritura',
        () async {
      final fs = MemoryVaultFileSystem();
      final key = await VaultCrypto().generateDek();

      // La ruta cambia "tras una actualización".
      String currentPath = fs.vaultPath;
      final resolvingFs = _ChangingPathFileSystem(fs, () => currentPath);
      final resolvingStorage = VaultStorage(initialFileSystem: resolvingFs);

      await resolvingStorage.save(
        const VaultDocument(entries: <VaultEntry>[]),
        key,
      );
      expect(fs.bytesAt(currentPath), isNotNull);
      expect(await resolvingStorage.exists(), isTrue);

      currentPath = '/memory/nueva-ruta/vault.dat';
      expect(await resolvingStorage.exists(), isFalse);

      await resolvingStorage.save(
        const VaultDocument(entries: <VaultEntry>[]),
        key,
      );
      expect(fs.bytesAt(currentPath), isNotNull);
    });
  });
}
