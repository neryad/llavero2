import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/security/crypto/backup_crypto.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/kdf.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/secure_store.dart';

void main() {
  // Para que los tests no tarden, usamos PBKDF2 con pocas iteraciones.
  // La app real usa Argon2id (ver KdfParameters.argon2id).
  KdfParameters fastParams() =>
      KdfParameters.pbkdf2(salt: List<int>.generate(16, (i) => i), iterations: 1000);

  group('Cifrado de la bóveda', () {
    test('cifrar y descifrar devuelve el mismo contenido', () async {
      final crypto = VaultCrypto();
      final key = await crypto.generateDek();
      const original = 'hola mundo';

      final blob = await crypto.encryptVault(utf8.encode(original), key);
      final result = await crypto.decryptVault(blob, key);

      expect(utf8.decode(result), original);
    });

    test('el nonce es aleatorio: dos cifrados del mismo texto difieren',
        () async {
      final crypto = VaultCrypto();
      final key = await crypto.generateDek();
      const original = 'mismo texto';

      final a = await crypto.encryptVault(utf8.encode(original), key);
      final b = await crypto.encryptVault(utf8.encode(original), key);

      expect(a, isNot(equals(b)));
    });

    test('la DEK generada es aleatoria y de 256 bits', () async {
      final crypto = VaultCrypto();
      final a = await crypto.generateDek();
      final b = await crypto.generateDek();

      expect(await a.extractBytes(), hasLength(32));
      expect(await a.extractBytes(), isNot(equals(await b.extractBytes())));
    });

    test('una clave distinta no puede descifrar', () async {
      final crypto = VaultCrypto();
      final key = await crypto.generateDek();
      final other = await crypto.generateDek();

      final blob = await crypto.encryptVault(utf8.encode('secreto'), key);

      expect(
        () => crypto.decryptVault(blob, other),
        throwsA(isA<TamperedDataException>()),
      );
    });
  });

  group('Envolver la DEK con el PIN', () {
    test('ida y vuelta: el PIN correcto devuelve la misma DEK', () async {
      final crypto = VaultCrypto();
      final dek = await crypto.generateDek();
      final params = fastParams();
      final kek = await params.deriveKey('482913');

      final wrapped = await crypto.wrapDek(dek, kek);
      final unwrapped = await crypto.unwrapDek(wrapped, kek);

      expect(await unwrapped.extractBytes(), await dek.extractBytes());
    });

    test('un PIN incorrecto falla', () async {
      final crypto = VaultCrypto();
      final dek = await crypto.generateDek();
      final params = fastParams();

      final kek = await params.deriveKey('482913');
      final wrongKek = await params.deriveKey('482914');
      final wrapped = await crypto.wrapDek(dek, kek);

      expect(
        () => crypto.unwrapDek(wrapped, wrongKek),
        throwsA(isA<InvalidPinException>()),
      );
    });

    test('manipular el blob envuelto se detecta', () async {
      final crypto = VaultCrypto();
      final dek = await crypto.generateDek();
      final params = fastParams();
      final kek = await params.deriveKey('482913');

      final wrapped = await crypto.wrapDek(dek, kek);
      final tampered = List<int>.from(wrapped);
      // Tocamos un byte del cifrado.
      tampered[tampered.length - 1] ^= 0xFF;

      expect(
        () => crypto.unwrapDek(tampered, kek),
        throwsA(isA<InvalidPinException>()),
      );
    });
  });

  group('Manipulación del contenido', () {
    test('cambiar un byte del contenido cifrado se detecta', () async {
      final crypto = VaultCrypto();
      final key = await crypto.generateDek();

      final blob = await crypto.encryptVault(utf8.encode('WiFi: casa'), key);
      final tampered = List<int>.from(blob);
      tampered[tampered.length - 1] ^= 0x01;

      expect(
        () => crypto.decryptVault(tampered, key),
        throwsA(isA<TamperedDataException>()),
      );
    });

    test('un blob truncado se detecta', () async {
      final crypto = VaultCrypto();
      final key = await crypto.generateDek();

      final blob = await crypto.encryptVault(utf8.encode('datos'), key);

      expect(
        () => crypto.decryptVault(blob.sublist(0, 5), key),
        throwsA(isA<TamperedDataException>()),
      );
    });
  });

  group('Respaldo cifrado', () {
    test('ida y vuelta: el contenido se recupera con la contraseña', () async {
      final backup = BackupCrypto();
      final contenido = utf8.encode('{"entradas": []}');

      final archivo = await backup.encryptBackup(
        contenido,
        'contraseña-del-respaldo',
        createdAt: DateTime.utc(2026, 11, 25),
      );
      final resultado = await backup.decryptBackup(archivo, 'contraseña-del-respaldo');

      expect(utf8.decode(resultado), '{"entradas": []}');
    });

    test('la contraseña equivocada falla', () async {
      final backup = BackupCrypto();

      final archivo = await backup.encryptBackup(
        utf8.encode('contenido'),
        'correcta',
        createdAt: DateTime.utc(2026, 11, 25),
      );

      expect(
        () => backup.decryptBackup(archivo, 'incorrecta'),
        throwsA(isA<InvalidBackupPasswordException>()),
      );
    });

    test('el archivo guarda los parámetros del KDF en la cabecera', () async {
      final backup = BackupCrypto();

      final archivo = await backup.encryptBackup(
        utf8.encode('contenido'),
        'contraseña',
        createdAt: DateTime.utc(2026, 11, 25),
        parameters: fastParams(),
      );

      expect(archivo['format'], 'llavero-backup');
      expect(archivo['version'], 1);
      final kdf = archivo['kdf']! as Map<String, Object?>;
      expect(kdf['type'], 'pbkdf2-hmac-sha256');
      expect(kdf['iterations'], 1000);
    });
  });

  group('Parámetros del KDF', () {
    test('se guardan y se recuperan sin perder información', () {
      final params = KdfParameters.argon2id(salt: List<int>.generate(16, (i) => i));

      final restaurado = KdfParameters.fromJson(params.toJson());

      expect(restaurado.type, KdfType.argon2id);
      expect(restaurado.salt, params.salt);
      expect(restaurado.memoryKiB, params.memoryKiB);
      expect(restaurado.iterations, params.iterations);
      expect(restaurado.parallelism, params.parallelism);
      expect(restaurado.keyBits, params.keyBits);
    });

    test('cada conjunto de parámetros usa una sal distinta', () {
      final a = KdfParameters.random(KdfType.argon2id);
      final b = KdfParameters.random(KdfType.argon2id);

      expect(a.salt, isNot(equals(b.salt)));
    });
  });

  group('Servicio de claves', () {
    test('crear la bóveda y abrirla con el PIN correcto', () async {
      final service = SecureStoreVaultKeyService(
        initialStore: InMemorySecureStore(),
        crypto: VaultCrypto(),
      );

      expect(await service.hasVault(), isFalse);

      await service.createVault('482913');

      expect(await service.hasVault(), isTrue);

      final key = await service.unlockWithPin('482913');
      expect(await key.extractBytes(), hasLength(32));
    });

    test('un PIN incorrecto no abre la bóveda', () async {
      final service = SecureStoreVaultKeyService(initialStore: InMemorySecureStore());

      await service.createVault('482913');

      expect(
        () => service.unlockWithPin('111111'),
        throwsA(isA<InvalidPinException>()),
      );
    });

    test('la copia biométrica se puede guardar, leer y borrar', () async {
      final service = SecureStoreVaultKeyService(initialStore: InMemorySecureStore());
      await service.createVault('482913');

      expect(await service.biometricKey(), isNull);

      final key = await service.unlockWithPin('482913');
      await service.enableBiometrics(key);

      final biometrics = await service.biometricKey();
      expect(biometrics, isNotNull);
      expect(await biometrics!.extractBytes(), await key.extractBytes());

      await service.disableBiometrics();
      expect(await service.biometricKey(), isNull);
    });

    test('borrar todo deja el dispositivo sin bóveda', () async {
      final store = InMemorySecureStore();
      final service = SecureStoreVaultKeyService(initialStore: store);

      await service.createVault('482913');
      await service.eraseEverything();

      expect(await service.hasVault(), isFalse);
    });
  });
}
