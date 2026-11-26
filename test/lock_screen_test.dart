import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/app.dart';
import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/biometric_auth.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/home/home_screen.dart';
import 'package:llavero2/features/lock/lock_screen.dart';

/// Servicio de claves falso con soporte de biometría para la lock screen.
class FakeLockKeyService implements VaultKeyService {
  FakeLockKeyService({this.correctPin = '482913', this.biometricDek});

  final String correctPin;
  final SecretKey? biometricDek;

  int pinAttempts = 0;
  bool vaultCreated = true;
  SecretKey? _dek;

  @override
  Future<bool> hasVault() async => vaultCreated;

  @override
  Future<void> createVault(String pin) async {
    vaultCreated = true;
  }

  @override
  Future<SecretKey> unlockWithPin(String pin) async {
    pinAttempts++;
    if (pin != correctPin) throw const InvalidPinException();
    return _dek ??= await VaultCrypto().generateDek();
  }

  @override
  Future<void> changePin(String currentPin, String newPin) async {}

  @override
  Future<void> enableBiometrics(SecretKey dek) async {}

  @override
  Future<void> disableBiometrics() async {}

  @override
  Future<SecretKey?> biometricKey() async => biometricDek;

  @override
  Future<void> eraseEverything() async {
    vaultCreated = false;
  }
}

/// Autenticación biométrica falsa: decide si el sistema confirmó o no.
class FakeBiometricAuth implements BiometricAuth {
  FakeBiometricAuth({this.authenticated = true});

  bool authenticated;
  int calls = 0;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    calls++;
    return authenticated;
  }
}

Future<AppControllers> pumpLockApp(
  WidgetTester tester, {
  required VaultKeyService service,
}) async {
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
  controllers.settings.setLanguage(AppLanguage.spanish);
  await controllers.lock.initialize();
  await tester.pumpWidget(LlaveroApp(controllers: controllers));
  await tester.pumpAndSettle();
  return controllers;
}

Future<void> goToLockScreen(WidgetTester tester) async {
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  expect(find.byType(LockScreen), findsOneWidget);
}

Future<void> main() async {
  group('Task 2 — Pantalla de bloqueo', () {
    testWidgets('un PIN correcto desbloquea y abre el inicio', (tester) async {
      final service = FakeLockKeyService();
      await pumpLockApp(tester, service: service);
      await goToLockScreen(tester);

      await tester.enterText(find.byType(TextField), '482913');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.pinAttempts, 1);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('un PIN incorrecto muestra error y no abre el inicio',
        (tester) async {
      final service = FakeLockKeyService();
      await pumpLockApp(tester, service: service);
      await goToLockScreen(tester);

      await tester.enterText(find.byType(TextField), '111111');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('PIN incorrecto. Inténtalo de nuevo.'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('el botón biométrico aparece solo si está habilitado',
        (tester) async {
      final dek = await VaultCrypto().generateDek();
      final service = FakeLockKeyService(biometricDek: dek);
      await pumpLockApp(tester, service: service);
      await goToLockScreen(tester);

      expect(find.text('Desbloquear con biometría'), findsOneWidget);

      await tester.tap(find.text('Desbloquear con biometría'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('tras 5 PINs fallidos se bloquea y muestra la cuenta atrás',
        (tester) async {
      final service = FakeLockKeyService();
      await pumpLockApp(tester, service: service);
      await goToLockScreen(tester);

      for (var i = 0; i < 5; i++) {
        await tester.enterText(find.byType(TextField), '111111');
        await tester.pump();
          await tester.pumpAndSettle();
      }

      // El controlador está bloqueado: aunque escribamos el PIN correcto
      // no se deriva la clave ni se abre la bóveda.
      final attemptsBefore = service.pinAttempts;
      expect(attemptsBefore, 5);
      expect(find.textContaining('Demasiados intentos fallidos'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    test('la DEK biométrica solo se lee si la biometría confirma', () async {
      final dek = await VaultCrypto().generateDek();
      final service = FakeLockKeyService(biometricDek: dek);
      final auth = FakeBiometricAuth(authenticated: false);
      final controller = LockController(
        initialKeyService: service,
        initialBiometricAuth: auth,
      );

      final ok = await controller.unlockWithBiometrics(
        localizedReason: 'prueba',
      );

      expect(ok, isFalse);
      expect(auth.calls, 1);
      expect(controller.isLocked, isTrue);
      expect(controller.unlockedDek, isNull);
    });

    test('la biometría correcta abre la bóveda y expone la DEK', () async {
      final dek = await VaultCrypto().generateDek();
      final service = FakeLockKeyService(biometricDek: dek);
      final auth = FakeBiometricAuth(authenticated: true);
      final controller = LockController(
        initialKeyService: service,
        initialBiometricAuth: auth,
      );

      final ok = await controller.unlockWithBiometrics(
        localizedReason: 'prueba',
      );

      expect(ok, isTrue);
      expect(auth.calls, 1);
      expect(controller.isLocked, isFalse);
      expect(await controller.unlockedDek!.extractBytes(),
          await dek.extractBytes());
    });

    test('el desbloqueo carga las entradas con la DEK', () async {
      final dek = await VaultCrypto().generateDek();
      final storage = VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      );
      await storage.save(
        VaultDocument(
          entries: <VaultEntry>[
            VaultEntry(
              id: 'e1',
              title: 'Wi-Fi de casa',
              categoryId: 'wifi',
              fields: const <EntryField>[],
              createdAt: DateTime.utc(2026, 11, 26),
              updatedAt: DateTime.utc(2026, 11, 26),
            ),
          ],
        ),
        dek,
      );

      final service = _FixedDekKeyService(dek: dek);
      final controllers = AppControllers(
        entries: EntriesController(initialStorage: storage),
        lock: LockController(
          initialKeyService: service,
          initialLockoutStore: InMemoryLockoutStore(),
        ),
      );
      await controllers.lock.initialize();

      expect(controllers.entries.entries, isEmpty);

      final ok = await controllers.lock.submitPin('482913');
      await pumpAndSettleEntries(controllers);

      expect(ok, isTrue);
      expect(controllers.entries.entries.length, 1);
      expect(controllers.entries.entries.first.title, 'Wi-Fi de casa');

      controllers.lock.lock();
      expect(controllers.entries.entries, isEmpty);
    });
  });
}

/// Servicio que siempre devuelve la misma DEK al abrir con PIN.
class _FixedDekKeyService implements VaultKeyService {
  _FixedDekKeyService({required this.dek});

  final SecretKey dek;

  @override
  Future<bool> hasVault() async => true;

  @override
  Future<void> createVault(String pin) async {}

  @override
  Future<SecretKey> unlockWithPin(String pin) async => dek;

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

Future<void> pumpAndSettleEntries(AppControllers controllers) async {
  // Pequeña espera para que los listeners asíncronos terminen.
  await Future<void>.delayed(const Duration(milliseconds: 20));
}
