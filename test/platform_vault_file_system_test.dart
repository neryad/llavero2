import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/data/vault_file_system.dart';

void main() {
  group('PlatformVaultFileSystem — escritura real', () {
    late Directory tempDir;
    late PlatformVaultFileSystem fileSystem;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('llavero_fs_test');
      fileSystem = PlatformVaultFileSystem(
        packageName: 'com.example.test',
        baseDirectory: tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('la ruta apunta a llavero/vault.dat dentro del directorio privado',
        () {
      expect(
        fileSystem.vaultPath,
        '${tempDir.path}/llavero/vault.dat',
      );
    });

    test('crea el directorio llavero/ en la primera escritura atómica',
        () async {
      final vaultDir = Directory('${tempDir.path}/llavero');
      expect(vaultDir.existsSync(), isFalse);

      await fileSystem.writeAtomic(
        fileSystem.vaultPath,
        utf8.encode('contenido-cifrado'),
      );

      expect(vaultDir.existsSync(), isTrue);
      expect(await fileSystem.readVault(), utf8.encode('contenido-cifrado'));
    });

    test('no deja archivos .tmp después de escribir', () async {
      await fileSystem.writeAtomic(
        fileSystem.vaultPath,
        utf8.encode('datos'),
      );

      final tmp = File('${fileSystem.vaultPath}.tmp');
      expect(await tmp.exists(), isFalse);
      expect(await fileSystem.vaultExists(), isTrue);
    });

    test('sobrescribir mantiene una sola versión del archivo', () async {
      await fileSystem.writeAtomic(fileSystem.vaultPath, utf8.encode('v1'));
      await fileSystem.writeAtomic(fileSystem.vaultPath, utf8.encode('v2'));

      expect(await fileSystem.readVault(), utf8.encode('v2'));
    });
  });
}
