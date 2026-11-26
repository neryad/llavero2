import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

void main() {
  final ahora = DateTime.utc(2026, 11, 25, 12);

  VaultDocument documentoDePrueba() {
    return VaultDocument(
      entries: <VaultEntry>[
        VaultEntry(
          id: 'a',
          title: 'Wi-Fi de casa',
          categoryId: 'wifi',
          person: 'Casa',
          fields: const <EntryField>[
            EntryField(label: 'Contraseña', value: 'clave-secreta'),
          ],
          createdAt: ahora,
          updatedAt: ahora,
        ),
      ],
    );
  }

  group('Archivo de la bóveda', () {
    late MemoryVaultFileSystem fileSystem;
    late VaultStorage storage;
    late SecretKey key;

    setUp(() async {
      fileSystem = MemoryVaultFileSystem();
      storage = VaultStorage(initialFileSystem: fileSystem);
      key = await VaultCrypto().generateDek();
    });

    test('guardar y cargar devuelve lo mismo', () async {
      await storage.save(documentoDePrueba(), key);

      final cargado = await storage.load(key);

      expect(cargado, isNotNull);
      expect(cargado!.entries.length, 1);
      expect(cargado.entries.first.title, 'Wi-Fi de casa');
      expect(cargado.entries.first.fields.first.value, 'clave-secreta');
    });

    test('el archivo NO contiene los secretos en claro', () async {
      await storage.save(documentoDePrueba(), key);

      final bytes = fileSystem.bytesAt('/memory/vault.llavero')!;
      final texto = utf8.decode(bytes);

      expect(texto.contains('clave-secreta'), isFalse);
      expect(texto.contains('Wi-Fi de casa'), isFalse);
      // Solo se ve la cabecera en claro.
      expect(texto.contains('llavero-vault'), isTrue);
    });

    test('una clave distinta no puede leer la bóveda', () async {
      await storage.save(documentoDePrueba(), key);
      final otra = await VaultCrypto().generateDek();

      expect(
        () => storage.load(otra),
        throwsA(isA<TamperedDataException>()),
      );
    });

    test('un archivo manipulado se detecta', () async {
      await storage.save(documentoDePrueba(), key);

      final bytes = fileSystem.bytesAt('/memory/vault.llavero')!;
      final texto = utf8.decode(bytes);
      // Cambiamos un carácter del contenido cifrado (la carga en base64).
      final manipulado = texto.replaceFirst('"payload":"', '"payload":"A');
      await fileSystem.writeAtomic(
        '/memory/vault.llavero',
        utf8.encode(manipulado),
      );

      expect(
        () => storage.load(key),
        throwsA(isA<TamperedDataException>()),
      );
    });

    test('si no hay archivo, la bóveda está vacía (null)', () async {
      expect(await storage.load(key), isNull);
      expect(await storage.exists(), isFalse);
    });

    test('después de guardar, el archivo existe', () async {
      await storage.save(documentoDePrueba(), key);

      expect(await storage.exists(), isTrue);
    });

    test('cada guardado reescribe el archivo', () async {
      await storage.save(documentoDePrueba(), key);
      final primero = fileSystem.bytesAt('/memory/vault.llavero');

      await storage.save(documentoDePrueba(), key);
      final segundo = fileSystem.bytesAt('/memory/vault.llavero');

      // El contenido cifrado cambia porque el nonce es aleatorio.
      expect(primero, isNotNull);
      expect(segundo, isNotNull);
      expect(primero, isNot(equals(segundo)));
    });
  });
}
