import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/platform/backup_exclusion.dart';
import 'package:llavero2/core/platform/clipboard_service.dart';
import 'package:llavero2/core/platform/screen_security.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_policy.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/core/security/secure_store.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/core/security/crypto/backup_crypto.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

class _FakeKeyService implements VaultKeyService {
  _FakeKeyService({required this.dek, this.failUnwrap = false});

  final SecretKey dek;
  final bool failUnwrap;

  @override
  Future<bool> hasVault() async => true;

  @override
  Future<void> createVault(String pin) async {}

  @override
  Future<SecretKey> unlockWithPin(String pin) async {
    if (failUnwrap) throw const TamperedDataException();
    if (pin != '482913') throw const InvalidPinException();
    return dek;
  }

  @override
  Future<void> changePin(String currentPin, String newPin) async {}

  @override
  Future<void> enableBiometrics(SecretKey dek) async {}

  @override
  Future<void> disableBiometrics() async {}

  @override
  Future<SecretKey?> biometricKey() async => null;

  @override
  Future<void> eraseEverything() async {}
}

/// Almacén que falla al escribir la segunda clave temporal del cambio de PIN.
class _FailingChangePinStore extends InMemorySecureStore {
  bool failing = false;

  @override
  Future<void> write(String key, String value) async {
    if (failing && key == SecureStoreKeys.wrappedDekTemp) {
      throw PlatformException(code: 'simulated', message: 'fallo');
    }
    await super.write(key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FASE B — Critical', () {
    test('C1: VaultStorage.save pide excluir el archivo de iCloud', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('llavero/secure_file'),
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('llavero/secure_file'),
          null,
        );
        BackupExclusion.platformProbe = null;
      });
      BackupExclusion.platformProbe = () => true;

      final storage = VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      );
      final key = await VaultCrypto().generateDek();
      await storage.save(const VaultDocument(entries: <VaultEntry>[]), key);

      expect(calls, hasLength(1));
      expect(calls.first.method, 'excludeFromBackup');
      expect(calls.first.arguments, '/memory/vault.llavero');
    });

    test('C2: ClipboardService limpia tras el tiempo configurado', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final service = ClipboardService();
      await service.copySecret('secreto', Duration.zero);
      service.dispose();

      expect(calls, isNotEmpty);
      // La última llamada debe ser un setData vacío.
      expect(calls.last.method, 'Clipboard.setData');
      expect(calls.last.arguments['text'], '');
    });

    test('C3: verifyPin y setBiometricsEnabled exigen re-auth', () async {
      final key = await VaultCrypto().generateDek();
      final lock = LockController(
        initialKeyService: _FakeKeyService(dek: key),
        initialLockoutStore: InMemoryLockoutStore(),
      );
      await lock.initialize();

      expect(await lock.verifyPin('111111'), isFalse);
      expect(await lock.verifyPin('482913'), isTrue);

      await lock.submitPin('482913');
      expect(lock.biometricsEnabled, isFalse);
      await lock.setBiometricsEnabled(true, reauthenticated: true);
      expect(lock.biometricsEnabled, isTrue);

      await lock.setBiometricsEnabled(false); // sin re-auth: ignorado
      expect(lock.biometricsEnabled, isTrue);
      await lock.setBiometricsEnabled(false, reauthenticated: true);
      expect(lock.biometricsEnabled, isFalse);
    });

    test('C4: reloj hacia atrás no acorta el bloqueo', () async {
      final t0 = DateTime.utc(2026, 11, 26, 12);
      var state = LockoutState.initial;
      for (var i = 0; i < 5; i++) {
        state = state.registerFailure(t0);
      }
      expect(state.isLockedOut(t0), isTrue);

      // El usuario adelanta el reloj 3 horas hacia atrás.
      expect(state.isLockedOut(t0.subtract(const Duration(hours: 3))), isTrue);
      // Avanza 10 s reales: el castigo baja solo 10 s.
      final ticked = state.tick(t0.add(const Duration(seconds: 10)));
      expect(ticked.remaining(t0.add(const Duration(seconds: 10))),
          const Duration(seconds: 20));
    });

    test('C5: fallo a mitad del cambio de PIN deja el anterior vigente',
        () async {
      final store = _FailingChangePinStore();
      final service = SecureStoreVaultKeyService(initialStore: store);
      await service.createVault('482913');
      final oldParams = await store.read(SecureStoreKeys.kdfParameters);
      final oldWrapped = await store.read(SecureStoreKeys.wrappedDek);
      store.failing = true;

      expect(
        () => service.changePin('482913', '739264'),
        throwsA(isA<PlatformException>()),
      );

      expect(await store.read(SecureStoreKeys.kdfParameters), oldParams);
      expect(await store.read(SecureStoreKeys.wrappedDek), oldWrapped);
      final key = await service.unlockWithPin('482913');
      expect(await key.extractBytes(), hasLength(32));
      expect(
        () => service.unlockWithPin('739264'),
        throwsA(isA<InvalidPinException>()),
      );
    });

    test('C7: dos duplicados en producción tienen IDs distintos', () async {
      final key = await VaultCrypto().generateDek();
      final controller = EntriesController(
        initialStorage: VaultStorage(
          initialFileSystem: MemoryVaultFileSystem(),
        ),
        idGenerator: () => 'id-${DateTime.now().microsecondsSinceEpoch}',
      );
      await controller.load(key);
      await controller.add(
        VaultEntry(
          id: 'base',
          title: 'Base',
          categoryId: 'other',
          fields: const [],
          createdAt: DateTime.utc(2026, 11, 26),
          updatedAt: DateTime.utc(2026, 11, 26),
        ),
      );
      await controller.duplicate('base');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await controller.duplicate('base');

      final ids = controller.allEntries.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('B12: el canal de capturas aplica y quita FLAG_SECURE', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('llavero/screen_security'),
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('llavero/screen_security'),
          null,
        );
      });

      await ScreenSecurity.setScreenshotsBlocked(true);
      await ScreenSecurity.setScreenshotsBlocked(false);
      expect(calls, hasLength(2));
      expect(calls.first.arguments['blocked'], isTrue);
      expect(calls.last.arguments['blocked'], isFalse);
    });
  });

  group('FASE B — Bug', () {
    test('B1: archivo corrupto marca vaultCorrupted sin lanzar', () async {
      final key = await VaultCrypto().generateDek();
      final controllers = AppControllers(
        entries: EntriesController(
          initialStorage: VaultStorage(
            initialFileSystem: MemoryVaultFileSystem(),
          ),
        ),
        lock: LockController(
          initialKeyService: _FakeKeyService(dek: key, failUnwrap: true),
          initialLockoutStore: InMemoryLockoutStore(),
        ),
      );
      await controllers.lock.initialize();

      final ok = await controllers.unlockWithPin('482913');
      expect(ok, isFalse);
      expect(controllers.vaultCorrupted, isTrue);
    });

    test('B3: errores de respaldo son distintos', () async {
      final crypto = BackupCrypto();
      final password = 'clave';
      final good = await crypto.encryptBackup(
        utf8.encode('{"entries":[]}'),
        password,
        createdAt: DateTime.utc(2026, 11, 26),
      );

      expect(
        () => crypto.decryptBackup(good, 'otra'),
        throwsA(isA<InvalidBackupPasswordException>()),
      );
      expect(
        () => crypto.decryptBackup(<String, Object?>{'format': 'otro'}, password),
        throwsA(isA<InvalidBackupFileException>()),
      );
      expect(
        () => crypto.decryptBackup(
          <String, Object?>{...good, 'version': 999},
          password,
        ),
        throwsA(isA<UnsupportedBackupVersionException>()),
      );
    });
  });
}
