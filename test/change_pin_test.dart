import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/core/security/secure_store.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/settings/change_pin_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

class _FakeChangePinService implements VaultKeyService {
  _FakeChangePinService();

  String correctPin = '482913';
  int changeCalls = 0;

  @override
  Future<bool> hasVault() async => true;

  @override
  Future<void> createVault(String pin) async => correctPin = pin;

  @override
  Future<SecretKey> unlockWithPin(String pin) async {
    if (pin != correctPin) throw const InvalidPinException();
    return SecretKey(List<int>.filled(32, 7));
  }

  @override
  Future<void> changePin(String currentPin, String newPin) async {
    changeCalls++;
    if (currentPin != correctPin) throw const InvalidPinException();
    correctPin = newPin;
  }

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
  group('Mejora 1 — Cambio de PIN', () {
    test('el PIN viejo deja de abrir y el nuevo sí, con la misma DEK', () async {
      final store = InMemorySecureStore();
      final service = SecureStoreVaultKeyService(initialStore: store);
      await service.createVault('482913');

      final oldDek = await service.unlockWithPin('482913');
      final oldBytes = await oldDek.extractBytes();

      await service.changePin('482913', '739264');

      expect(
        () => service.unlockWithPin('482913'),
        throwsA(isA<InvalidPinException>()),
      );
      final newDek = await service.unlockWithPin('739264');
      expect(await newDek.extractBytes(), oldBytes);
    });

    test('un PIN actual incorrecto no cambia la clave', () async {
      final service = SecureStoreVaultKeyService(
        initialStore: InMemorySecureStore(),
      );
      await service.createVault('482913');

      expect(
        () => service.changePin('111111', '739264'),
        throwsA(isA<InvalidPinException>()),
      );
      expect(await service.unlockWithPin('482913'), isNotNull);
      expect(
        () => service.unlockWithPin('739264'),
        throwsA(isA<InvalidPinException>()),
      );
    });

    test('el controlador registra el intento fallido', () async {
      final service = _FakeChangePinService();
      final controller = LockController(
        initialKeyService: service,
        initialLockoutStore: InMemoryLockoutStore(),
      );

      final ok = await controller.changePin('111111', '739264');

      expect(ok, isFalse);
      expect(service.changeCalls, 1);
      expect(controller.failedAttempts, 1);
    });

    testWidgets('la pantalla cambia el PIN y avisa', (tester) async {
      final service = _FakeChangePinService();
      final controllers = AppControllers(
        entries: EntriesController(
          initialStorage: VaultStorage(
            initialFileSystem: MemoryVaultFileSystem(),
          ),
        ),
        lock: LockController(
          initialKeyService: service,
          initialLockoutStore: InMemoryLockoutStore(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          locale: const Locale('es'),
          home: AppScope(
            controllers: controllers,
            child: const ChangePinScreen(),
          ),
        ),
      );
      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '482913');
      await tester.enterText(fields.at(1), '739264');
      await tester.enterText(fields.at(2), '739264');
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(service.changeCalls, 1);
      expect(service.correctPin, '739264');
      expect(controllers.settings.pinLength, 6);
      expect(find.text('PIN cambiado correctamente.'), findsOneWidget);
    });
  });
}
