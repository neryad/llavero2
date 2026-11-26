import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

/// Almacén que cuenta lecturas y escrituras.
class _CountingStorage implements VaultStorage {
  _CountingStorage(this._inner);

  final VaultStorage _inner;
  int loads = 0;
  int saves = 0;

  @override
  VaultFileSystem get fileSystem => _inner.fileSystem;

  @override
  String get vaultPath => _inner.vaultPath;

  @override
  Future<void> save(VaultDocument document, SecretKey key) async {
    saves++;
    await _inner.save(document, key);
  }

  @override
  Future<VaultDocument?> load(SecretKey key) async {
    loads++;
    return _inner.load(key);
  }

  @override
  Future<bool> exists() => _inner.exists();

  @override
  Future<void> delete() => _inner.delete();
}

void main() {
  group('Mejora 9 — Sin re-lectura del archivo', () {
    test('cada cambio guarda una vez y no vuelve a cargar', () async {
      final storage = _CountingStorage(
        VaultStorage(initialFileSystem: MemoryVaultFileSystem()),
      );
      final key = await VaultCrypto().generateDek();
      final controller = EntriesController(initialStorage: storage);

      await controller.load(key);
      expect(storage.loads, 1);
      expect(storage.saves, 0);

      await controller.add(
        VaultEntry(
          id: 'e1',
          title: 'Wi-Fi',
          categoryId: 'wifi',
          fields: const <EntryField>[],
          createdAt: DateTime.utc(2026, 11, 26),
          updatedAt: DateTime.utc(2026, 11, 26),
        ),
      );

      // Solo la carga inicial; el cambio NO provoca otra lectura.
      expect(storage.loads, 1);
      expect(storage.saves, 1);
      expect(controller.entries.length, 1);
    });

    test('varios cambios siguen sin leer de nuevo', () async {
      final storage = _CountingStorage(
        VaultStorage(initialFileSystem: MemoryVaultFileSystem()),
      );
      final key = await VaultCrypto().generateDek();
      final controller = EntriesController(initialStorage: storage);
      await controller.load(key);

      VaultEntry entry(int i) => VaultEntry(
            id: 'e$i',
            title: 'Entrada $i',
            categoryId: 'other',
            fields: const <EntryField>[],
            createdAt: DateTime.utc(2026, 11, 26),
            updatedAt: DateTime.utc(2026, 11, 26),
          );

      await controller.add(entry(1));
      await controller.add(entry(2));
      await controller.toggleFavorite('e1');

      expect(storage.loads, 1);
      expect(storage.saves, 3);
      expect(controller.entries.length, 2);
    });
  });
}
