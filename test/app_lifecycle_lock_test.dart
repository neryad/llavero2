import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/app.dart';
import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

class _FakeKeyService implements VaultKeyService {
  @override
  Future<bool> hasVault() async => true;

  @override
  Future<void> createVault(String pin) async {}

  @override
  Future<SecretKey> unlockWithPin(String pin) async =>
      await const VaultCryptoPlaceholder().key();

  @override
  Future<void> enableBiometrics(SecretKey dek) async {}

  @override
  Future<void> disableBiometrics() async {}

  @override
  Future<SecretKey?> biometricKey() async => null;

  @override
  Future<void> eraseEverything() async {}
}

/// Pequeño ayudante para generar una clave sin importar VaultCrypto aquí.
class VaultCryptoPlaceholder {
  const VaultCryptoPlaceholder();

  Future<SecretKey> key() async =>
      SecretKey(List<int>.filled(32, 7, growable: false));
}

void main() {
  group('Task 7 — Bloqueo automático', () {
    testWidgets('immediately bloquea al pasar a segundo plano',
        (tester) async {
      final controllers = AppControllers(
        entries: EntriesController(
          initialStorage: VaultStorage(
            initialFileSystem: MemoryVaultFileSystem(),
          ),
        ),
        lock: LockController(
          initialKeyService: _FakeKeyService(),
          initialLockoutStore: InMemoryLockoutStore(),
        ),
        settings: SettingsController(
          initialAutoLockDelay: AutoLockDelay.immediately,
        ),
      );
      await controllers.lock.initialize();
      await controllers.lock.submitPin('482913');
      expect(controllers.lock.isLocked, isFalse);

      await tester.pumpWidget(LlaveroApp(controllers: controllers));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      expect(controllers.lock.isLocked, isTrue);
    });
  });
}
