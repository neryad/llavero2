import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';

void main() {
  final ahora = DateTime.utc(2026, 11, 25, 12);

  VaultEntry entradaDePrueba({String id = 'entrada-1'}) {
    return VaultEntry(
      id: id,
      title: 'Wi-Fi de casa',
      categoryId: 'wifi',
      person: 'Casa',
      fields: const <EntryField>[
        EntryField(label: 'Red', value: 'Casa-5G'),
        EntryField(
          label: 'Contraseña',
          value: 'clave-secreta',
          type: EntryFieldType.secret,
          isSecret: true,
        ),
      ],
      notes: 'La contraseña está en la caja fuerte.',
      isFavorite: true,
      createdAt: ahora,
      updatedAt: ahora,
    );
  }

  group('EntryField', () {
    test('ida y vuelta a JSON', () {
      const field = EntryField(
        label: 'Contraseña',
        value: 'abc123',
        type: EntryFieldType.secret,
        isSecret: true,
      );

      final recuperado = EntryField.fromJson(field.toJson());

      expect(recuperado.label, field.label);
      expect(recuperado.value, field.value);
      expect(recuperado.type, EntryFieldType.secret);
      expect(recuperado.isSecret, isTrue);
    });

    test('un tipo desconocido se lee como texto', () {
      final campo = EntryField.fromJson(<String, Object?>{
        'label': 'X',
        'value': 'Y',
        'type': 'tipo-del-futuro',
      });

      expect(campo.type, EntryFieldType.text);
    });

    test('un campo de tipo PIN se oculta aunque el archivo no lo diga', () {
      final campo = EntryField.fromJson(<String, Object?>{
        'label': 'PIN',
        'value': '1234',
        'type': 'pin',
      });

      expect(campo.isSecret, isTrue);
    });

    test('copyWith cambia solo lo indicado', () {
      const field = EntryField(label: 'Usuario', value: 'mama');

      final cambiado = field.copyWith(value: 'abuela');

      expect(cambiado.label, 'Usuario');
      expect(cambiado.value, 'abuela');
      expect(cambiado.type, field.type);
    });
  });

  group('VaultEntry', () {
    test('ida y vuelta a JSON', () {
      final entrada = entradaDePrueba();

      final recuperada = VaultEntry.fromJson(entrada.toJson());

      expect(recuperada.id, entrada.id);
      expect(recuperada.title, entrada.title);
      expect(recuperada.categoryId, entrada.categoryId);
      expect(recuperada.person, entrada.person);
      expect(recuperada.fields.length, 2);
      expect(recuperada.fields[1].value, 'clave-secreta');
      expect(recuperada.fields[1].isSecret, isTrue);
      expect(recuperada.notes, entrada.notes);
      expect(recuperada.isFavorite, isTrue);
      expect(recuperada.createdAt, entrada.createdAt);
      expect(recuperada.updatedAt, entrada.updatedAt);
      expect(recuperada.deletedAt, isNull);
    });

    test('una entrada en la papelera conserva la fecha de borrado', () {
      final entrada = entradaDePrueba().copyWith(deletedAt: ahora);

      final recuperada = VaultEntry.fromJson(entrada.toJson());

      expect(recuperada.isDeleted, isTrue);
      expect(recuperada.deletedAt, ahora);
    });

    test('copyWith puede borrar la persona', () {
      final entrada = entradaDePrueba();

      final sinPersona = entrada.copyWith(clearPerson: true);

      expect(sinPersona.person, isNull);
      expect(entrada.person, 'Casa');
    });

    test('copyWith puede sacar una entrada de la papelera', () {
      final entrada = entradaDePrueba().copyWith(deletedAt: ahora);

      final restaurada = entrada.copyWith(clearDeletedAt: true);

      expect(restaurada.deletedAt, isNull);
      expect(restaurada.isDeleted, isFalse);
    });

    test('una entrada sin datos raros se lee sin romperse', () {
      final recuperada = VaultEntry.fromJson(<String, Object?>{
        'id': 'x',
        'title': 'Título',
      });

      expect(recuperada.categoryId, 'other');
      expect(recuperada.fields, isEmpty);
      expect(recuperada.person, isNull);
      expect(recuperada.notes, '');
    });
  });

  group('VaultDocument', () {
    test('ida y vuelta a JSON con varias entradas', () {
      final documento = VaultDocument(
        entries: <VaultEntry>[
          entradaDePrueba(id: 'a'),
          entradaDePrueba(id: 'b'),
        ],
      );

      final recuperado = VaultDocument.fromJson(documento.toJson());

      expect(recuperado.entries.length, 2);
      expect(recuperado.entries[0].id, 'a');
      expect(recuperado.entries[1].id, 'b');
      expect(recuperado.version, VaultDocument.currentVersion);
    });

    test('un documento vacío vale', () {
      final documento = VaultDocument.fromJson(<String, Object?>{
        'version': 1,
        'entries': <Object?>[],
      });

      expect(documento.entries, isEmpty);
    });
  });
}
