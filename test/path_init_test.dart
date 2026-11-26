import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/data/vault_file_system.dart';

void main() {
  group('Mejora 19 — Directorio siempre resuelto', () {
    test('sin initialize() usar vaultPath falla con StateError', () {
      final fs = PlatformVaultFileSystem(packageName: 'com.example.test');
      expect(() => fs.vaultPath, throwsStateError);
    });

    test('con un directorio inyectado la ruta es absoluta', () async {
      final dir = await Directory.systemTemp.createTemp('llavero_init_test');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final fs = PlatformVaultFileSystem(
        packageName: 'com.example.test',
        baseDirectory: dir,
      );
      expect(fs.vaultPath, '${dir.path}/llavero/vault.dat');
      expect(fs.vaultPath.startsWith('/'), isTrue);
    });

    test('resolveVaultPath devuelve una ruta absoluta', () async {
      final dir = await Directory.systemTemp.createTemp('llavero_init_test2');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final fs = PlatformVaultFileSystem(
        packageName: 'com.example.test',
        baseDirectory: dir,
      );
      final path = await fs.resolveVaultPath();
      expect(path.startsWith('/'), isTrue);
      expect(path, '${dir.path}/llavero/vault.dat');
    });
  });
}
