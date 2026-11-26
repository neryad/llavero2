import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/entries/entry_form_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

class _FakeKeyService implements VaultKeyService {
  @override
  Future<bool> hasVault() async => true;

  @override
  Future<void> createVault(String pin) async {}

  @override
  Future<SecretKey> unlockWithPin(String pin) async =>
      SecretKey(List<int>.filled(32, 7));

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
  group('Regresión — guardar con la bóveda cerrada', () {
    testWidgets('el formulario no propaga el StateError al guardar',
        (tester) async {
      final lock = LockController(
        initialKeyService: _FakeKeyService(),
        initialLockoutStore: InMemoryLockoutStore(),
      );
      await lock.initialize();
      await lock.submitPin('482913');
      expect(lock.isLocked, isFalse);

      final controllers = AppControllers(
        entries: EntriesController(
          initialStorage: VaultStorage(
            initialFileSystem: MemoryVaultFileSystem(),
          ),
        ),
        lock: lock,
      );
      await controllers.entries.load(lock.unlockedDek!);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          locale: const Locale('es'),
          home: AppScope(
            controllers: controllers,
            child: const EntryFormScreen(args: EntryFormArgs()),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Título'),
        'Wi-Fi',
      );
      await tester.pump();

      // Simulamos el auto-lock justo antes de guardar.
      lock.lock();
      await tester.pump();
      expect(lock.isLocked, isTrue);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pump();

      // No debe lanzarse StateError: la guarda del formulario lo captura.
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controllers.entries.entries, isEmpty);
    });
  });
}
