import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

void main() {
  late MemoryVaultFileSystem fileSystem;
  late VaultStorage storage;
  late SecretKey key;
  late DateTime ahora;
  late int contadorDeId;

  EntriesController crearControlador() {
    contadorDeId = 0;
    return EntriesController(
      initialStorage: storage,
      clock: () => ahora,
      idGenerator: () => 'id-${++contadorDeId}',
    );
  }

  VaultEntry nuevaEntrada({
    String id = 'e1',
    String title = 'Wi-Fi de casa',
    String categoryId = 'wifi',
    String? person = 'Casa',
    List<EntryField>? fields,
    bool isFavorite = false,
  }) {
    return VaultEntry(
      id: id,
      title: title,
      categoryId: categoryId,
      person: person,
      fields: fields ??
          const <EntryField>[
            EntryField(label: 'Contraseña', value: 'secreto', isSecret: true),
          ],
      isFavorite: isFavorite,
      createdAt: ahora,
      updatedAt: ahora,
    );
  }

  setUp(() async {
    fileSystem = MemoryVaultFileSystem();
    storage = VaultStorage(initialFileSystem: fileSystem);
    key = await VaultCrypto().generateDek();
    ahora = DateTime.utc(2026, 11, 25, 12);
  });

  group('Entradas en memoria', () {
    test('una bóveda nueva empieza vacía', () async {
      final controller = crearControlador();
      await controller.load(key);

      expect(controller.entries, isEmpty);
      expect(controller.isEmpty, isTrue);
      expect(controller.favorites, isEmpty);
      expect(controller.trashed, isEmpty);
    });

    test('añadir una entrada la deja en memoria y en el archivo', () async {
      final controller = crearControlador();
      await controller.load(key);

      await controller.add(nuevaEntrada());

      expect(controller.entries.length, 1);
      expect(controller.entries.first.title, 'Wi-Fi de casa');

      // Y también está guardada en el archivo.
      final recargado = crearControlador();
      await recargado.load(key);
      expect(recargado.entries.length, 1);
      expect(recargado.entries.first.id, 'e1');
    });

    test('actualizar una entrada cambia el contenido y la fecha', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada());

      ahora = ahora.add(const Duration(minutes: 5));
      await controller.update(
        controller.entries.first.copyWith(title: 'Wi-Fi de la abuela'),
      );

      expect(controller.entries.first.title, 'Wi-Fi de la abuela');
      expect(controller.entries.first.updatedAt, ahora);
    });

    test('mover a la papelera saca la entrada de la lista normal', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada());

      await controller.moveToTrash('e1');

      expect(controller.entries, isEmpty);
      expect(controller.trashed.length, 1);
      expect(controller.trashed.first.isDeleted, isTrue);
    });

    test('restaurar desde la papelera la devuelve', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada());
      await controller.moveToTrash('e1');

      await controller.restore('e1');

      expect(controller.entries.length, 1);
      expect(controller.trashed, isEmpty);
    });

    test('borrar para siempre elimina la entrada', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada());
      await controller.moveToTrash('e1');

      await controller.deleteForever('e1');

      expect(controller.allEntries, isEmpty);
      expect(controller.trashed, isEmpty);
    });

    test('marcar como favorita', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada());

      await controller.toggleFavorite('e1');
      expect(controller.favorites.length, 1);

      await controller.toggleFavorite('e1');
      expect(controller.favorites, isEmpty);
    });

    test('duplicar crea una copia con identificador nuevo', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada());

      await controller.duplicate('e1');

      expect(controller.entries.length, 2);
      final copia = controller.entries.last;
      expect(copia.id, isNot('e1'));
      expect(copia.title, 'Wi-Fi de casa (copia)');
      expect(copia.fields.first.value, 'secreto');
    });

    test('la papelera se purga a los 30 días', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada());
      await controller.moveToTrash('e1');

      // Todavía no ha pasado el plazo.
      ahora = ahora.add(const Duration(days: 29));
      await controller.purgeExpiredTrash();
      expect(controller.trashed.length, 1);

      // Ya ha pasado el plazo.
      ahora = ahora.add(const Duration(days: 2));
      await controller.purgeExpiredTrash();
      expect(controller.trashed, isEmpty);
      expect(controller.allEntries, isEmpty);
    });

    test('cerrar la bóveda borra las entradas de la memoria', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada());
      expect(controller.entries.length, 1);

      controller.lock();

      expect(controller.entries, isEmpty);
      expect(controller.allEntries, isEmpty);
    });

    test('no se puede modificar con la bóveda cerrada', () async {
      final controller = crearControlador();
      await controller.load(key);
      controller.lock();

      expect(
        () => controller.add(nuevaEntrada()),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Personas y categorías', () {
    test('lista las personas sin repetir y ordenadas', () async {
      final controller = crearControlador();
      await controller.load(key);

      await controller.add(nuevaEntrada(id: 'e1', person: 'Mamá'));
      await controller.add(nuevaEntrada(id: 'e2', person: 'Abuela'));
      await controller.add(nuevaEntrada(id: 'e3', person: 'Mamá'));
      await controller.add(nuevaEntrada(id: 'e4', person: null));

      expect(controller.persons, <String>['Abuela', 'Mamá']);
    });

    test('lista las categorías que tienen entradas', () async {
      final controller = crearControlador();
      await controller.load(key);

      await controller.add(nuevaEntrada(id: 'e1', categoryId: 'wifi'));
      await controller.add(nuevaEntrada(id: 'e2', categoryId: 'email'));

      expect(controller.categoryIds, <String>['email', 'wifi']);
    });
  });

  group('Búsqueda', () {
    test('busca por título', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada(id: 'e1', title: 'Wi-Fi de casa'));
      await controller.add(nuevaEntrada(id: 'e2', title: 'Netflix'));

      final resultados = controller.search('wi-fi');

      expect(resultados.length, 1);
      expect(resultados.first.id, 'e1');
    });

    test('busca por persona', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada(id: 'e1', person: 'Abuela'));

      expect(controller.search('abuela').length, 1);
    });

    test('busca por la etiqueta de un campo', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(
        nuevaEntrada(
          id: 'e1',
          fields: const <EntryField>[
            EntryField(label: 'Contraseña del router', value: 'secreto'),
          ],
        ),
      );

      expect(controller.search('router').length, 1);
    });

    test('NUNCA busca por el valor de un secreto', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(
        nuevaEntrada(
          id: 'e1',
          fields: const <EntryField>[
            EntryField(label: 'Contraseña', value: 'unicidadvisible'),
          ],
        ),
      );

      final resultados = controller.search('unicidadvisible');

      expect(resultados, isEmpty);
    });

    test('una búsqueda vacía devuelve todas las entradas', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada(id: 'e1'));
      await controller.add(nuevaEntrada(id: 'e2'));

      expect(controller.search('   ').length, 2);
    });

    test('la búsqueda no encuentra lo que está en la papelera', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada(id: 'e1', title: 'Router'));
      await controller.moveToTrash('e1');

      expect(controller.search('router'), isEmpty);
    });
  });

  group('Persistencia', () {
    test('los cambios sobreviven a reiniciar la app', () async {
      final controller = crearControlador();
      await controller.load(key);
      await controller.add(nuevaEntrada(id: 'e1'));
      await controller.add(nuevaEntrada(id: 'e2', title: 'Netflix'));
      await controller.moveToTrash('e2');

      // "Reiniciamos": controlador nuevo, mismo archivo.
      final nuevo = crearControlador();
      await nuevo.load(key);

      expect(nuevo.entries.length, 1);
      expect(nuevo.entries.first.id, 'e1');
      expect(nuevo.trashed.length, 1);
    });

    test('el archivo se reescribe en cada cambio', () async {
      final controller = crearControlador();
      await controller.load(key);

      await controller.add(nuevaEntrada(id: 'e1'));
      final despuesDeCrear = fileSystem.bytesAt('/memory/vault.llavero');

      await controller.toggleFavorite('e1');
      final despuesDeMarcar = fileSystem.bytesAt('/memory/vault.llavero');

      expect(despuesDeCrear, isNotNull);
      expect(despuesDeMarcar, isNotNull);
      expect(despuesDeCrear, isNot(equals(despuesDeMarcar)));
    });
  });
}
