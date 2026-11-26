import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

void main() {
  group('Mejora 11 — Purga automática al abrir', () {
    test('elimina entradas caducadas al abrir la bóveda', () async {
      final fileSystem = MemoryVaultFileSystem();
      final storage = VaultStorage(initialFileSystem: fileSystem);
      final key = await VaultCrypto().generateDek();
      final now = DateTime.now().toUtc();

      VaultEntry entry(String id, DateTime deletedAt) => VaultEntry(
            id: id,
            title: id,
            categoryId: 'other',
            fields: const <EntryField>[],
            createdAt: now,
            updatedAt: now,
            deletedAt: deletedAt,
          );

      await storage.save(
        VaultDocument(
          entries: <VaultEntry>[
            entry('vieja', now.subtract(const Duration(days: 31))),
            entry('reciente', now.subtract(const Duration(days: 2))),
          ],
        ),
        key,
      );

      final controller = EntriesController(initialStorage: storage);
      await controller.open(key);

      expect(controller.trashed.length, 1);
      expect(controller.trashed.first.id, 'reciente');

      // El cambio se persistió: al abrir de nuevo sigue purgada.
      final otro = EntriesController(initialStorage: storage);
      await otro.open(key);
      expect(otro.trashed.length, 1);
      expect(otro.trashed.first.id, 'reciente');
    });
  });
}
