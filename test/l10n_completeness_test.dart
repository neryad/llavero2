import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readArb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) => arb.keys
    .where((key) => !key.startsWith('@') && key != '@@locale')
    .toSet();

void main() {
  group('Task 8 — Revisión ES/EN', () {
    final es = _readArb('lib/l10n/app_es.arb');
    final en = _readArb('lib/l10n/app_en.arb');

    test('ambos idiomas tienen exactamente las mismas claves', () {
      expect(_keys(es), equals(_keys(en)));
    });

    test('ningún texto está vacío', () {
      for (final key in _keys(es)) {
        expect((es[key] as String).trim(), isNotEmpty, reason: 'es:$key');
        expect((en[key] as String).trim(), isNotEmpty, reason: 'en:$key');
      }
    });

    test('los metadatos @ existen para cada clave', () {
      for (final key in _keys(es)) {
        expect(es.containsKey('@$key'), isTrue, reason: 'es:@$key');
        expect(en.containsKey('@$key'), isTrue, reason: 'en:@$key');
      }
    });
  });
}
