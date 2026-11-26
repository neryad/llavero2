import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/data/vault_history.dart';

void main() {
  group('Mejora 16 — Historial de la bóveda', () {
    late Directory dir;
    late File vault;
    late VaultHistory history;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('llavero_history_test');
      vault = File('${dir.path}/llavero/vault.dat');
      await vault.parent.create(recursive: true);
      history = VaultHistory(vaultPath: vault.path, keep: 2);
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('sin archivo no hay versiones', () async {
      expect(await history.versions(), isEmpty);
      await history.snapshot();
      expect(await history.versions(), isEmpty);
    });

    test('guarda una versión antes de sobrescribir', () async {
      await vault.writeAsString('v1');
      await history.snapshot();
      await vault.writeAsString('v2');

      final versions = await history.versions();
      expect(versions, hasLength(1));
      expect(utf8Decode((await history.read(versions.first))!), 'v1');
    });

    test('respeta el número máximo de versiones', () async {
      for (var i = 0; i < 4; i++) {
        await vault.writeAsString('v$i');
        await history.snapshot();
      }

      expect(await history.versions(), hasLength(2));
    });

    test('restaurar devuelve el contenido anterior', () async {
      await vault.writeAsString('buena');
      await history.snapshot();
      await vault.writeAsString('malograda');

      final version = (await history.versions()).first;
      await history.restore(version);

      expect(utf8Decode(await vault.readAsBytes()), 'buena');
    });

    test('clear borra todo el historial', () async {
      await vault.writeAsString('v1');
      await history.snapshot();
      await history.clear();

      expect(await history.versions(), isEmpty);
    });
  });
}

String utf8Decode(List<int> bytes) =>
    String.fromCharCodes(bytes);
