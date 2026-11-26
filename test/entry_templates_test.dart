import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/data/entry_templates.dart';
import 'package:llavero2/data/models/entry_field.dart';

void main() {
  final now = DateTime.utc(2026, 11, 26);

  group('Task 5 — Plantillas de entradas', () {
    test('hay plantillas para los tipos principales', () {
      expect(EntryTemplates.byId('wifi'), isNotNull);
      expect(EntryTemplates.byId('website'), isNotNull);
      expect(EntryTemplates.byId('pin'), isNotNull);
      expect(EntryTemplates.byId('card'), isNotNull);
      expect(EntryTemplates.byId('note'), isNotNull);
    });

    test('una plantilla desconocida devuelve null', () {
      expect(EntryTemplates.byId('no-existe'), isNull);
    });

    test('crear una entrada con la plantilla wifi', () {
      final entry = EntryTemplates.wifi.create(id: 'e1', now: now);

      expect(entry.title, 'Wi-Fi');
      expect(entry.categoryId, 'wifi');
      expect(entry.fields.length, 2);
      expect(entry.fields[1].type, EntryFieldType.secret);
      expect(entry.createdAt, now);
    });

    test('el título se puede personalizar', () {
      final entry = EntryTemplates.wifi.create(
        id: 'e1',
        now: now,
        title: 'Wi-Fi de casa',
      );
      expect(entry.title, 'Wi-Fi de casa');
    });

    test('las copias no comparten la lista de campos', () {
      final a = EntryTemplates.pin.create(id: 'a', now: now);
      final b = EntryTemplates.pin.create(id: 'b', now: now);

      expect(a.fields, isNot(same(b.fields)));
    });
  });
}
