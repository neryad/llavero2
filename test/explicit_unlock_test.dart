import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

class _FakeKeyService implements VaultKeyService {
  _FakeKeyService({required this.dek});

  final SecretKey dek;

  @override
  Future<bool> hasVault() async => true;

  @override
  Future<void> createVault(String pin) async {}

  @override
  Future<SecretKey> unlockWithPin(String pin) async {
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

void main() {
  group('Mejora 18 — Wiring explícito de desbloqueo', () {
    test('unlockWithPin espera a que las entradas estén cargadas', () async {
      final fileSystem = MemoryVaultFileSystem();
      final storage = VaultStorage(initialFileSystem: fileSystem);
      final key = await VaultCrypto().generateDek();
      await storage.save(
        VaultDocument(
          entries: <VaultEntry>[
            VaultEntry(
              id: 'e1',
              title: 'Wi-Fi',
              categoryId: 'wifi',
              fields: const <EntryField>[],
              createdAt: DateTime.utc(2026, 11, 26),
              updatedAt: DateTime.utc(2026, 11, 26),
            ),
          ],
        ),
        key,
      );

      final controllers = AppControllers(
        entries: EntriesController(initialStorage: storage),
        lock: LockController(
          initialKeyService: _FakeKeyService(dek: key),
          initialLockoutStore: InMemoryLockoutStore(),
        ),
      );
      await controllers.lock.initialize();

      expect(controllers.entries.entries, isEmpty);

      final ok = await controllers.unlockWithPin('482913');

      expect(ok, isTrue);
      // Sin pumps ni delays: la carga ya terminó cuando volvió el Future.
      expect(controllers.pendingUnlock, isNotNull);
      expect(controllers.entries.entries.length, 1);
      expect(controllers.entries.entries.first.title, 'Wi-Fi');
    });

    test('un PIN incorrecto no cambia el estado', () async {
      final key = await VaultCrypto().generateDek();
      final controllers = AppControllers(
        entries: EntriesController(
          initialStorage: VaultStorage(
            initialFileSystem: MemoryVaultFileSystem(),
          ),
        ),
        lock: LockController(
          initialKeyService: _FakeKeyService(dek: key),
          initialLockoutStore: InMemoryLockoutStore(),
        ),
      );
      await controllers.lock.initialize();

      final ok = await controllers.unlockWithPin('111111');

      expect(ok, isFalse);
      expect(controllers.lock.isLocked, isTrue);
      expect(controllers.pendingUnlock, isNull);
    });
  });
}
