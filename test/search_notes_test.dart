import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

void main() {
  group('Mejora 12 — Búsqueda en notas', () {
    late EntriesController controller;

    setUp(() async {
      final storage = VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      );
      final key = await VaultCrypto().generateDek();
      controller = EntriesController(initialStorage: storage);
      await controller.load(key);
    });

    VaultEntry entry({
      required String id,
      required String title,
      String notes = '',
      List<EntryField> fields = const <EntryField>[],
    }) {
      return VaultEntry(
        id: id,
        title: title,
        categoryId: 'other',
        notes: notes,
        fields: fields,
        createdAt: DateTime.utc(2026, 11, 26),
        updatedAt: DateTime.utc(2026, 11, 26),
      );
    }

    test('encuentra una entrada por el texto de sus notas', () async {
      await controller.add(
        entry(id: 'e1', title: 'Banco', notes: 'Caja fuerte del banco'),
      );
      await controller.add(
        entry(id: 'e2', title: 'Casa', notes: 'Wi-Fi del salón'),
      );

      final resultados = controller.search('caja fuerte');

      expect(resultados.length, 1);
      expect(resultados.first.id, 'e1');
    });

    test('la búsqueda en notas ignora mayúsculas', () async {
      await controller.add(
        entry(id: 'e1', title: 'Banco', notes: 'CAJA FUERTE'),
      );

      expect(controller.search('caja').length, 1);
    });

    test('sigue sin buscar en valores secretos', () async {
      await controller.add(
        entry(
          id: 'e1',
          title: 'Banco',
          fields: const <EntryField>[
            EntryField(label: 'Contraseña', value: 'secreto-unicornio', isSecret: true),
          ],
        ),
      );

      expect(controller.search('unicornio'), isEmpty);
    });

    test('la papelera se sigue ignorando', () async {
      await controller.add(
        entry(id: 'e1', title: 'Banco', notes: 'caja fuerte'),
      );
      await controller.moveToTrash('e1');

      expect(controller.search('caja'), isEmpty);
    });
  });
}
