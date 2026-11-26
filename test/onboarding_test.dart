import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/app.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/onboarding/onboarding_screen.dart';
import 'package:llavero2/features/onboarding/pin_create_screen.dart';

/// Servicio de claves falso para probar el onboarding sin cifrado real.
class FakeVaultKeyService implements VaultKeyService {
  FakeVaultKeyService({this.correctPin = '482913'});

  final String correctPin;

  /// Número de veces que se ha intentado abrir con PIN.
  int pinAttempts = 0;

  bool vaultCreated = false;
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
    if (pin != correctPin) {
      throw const InvalidPinException();
    }
    return _dek ??= await VaultCrypto().generateDek();
  }

  @override
  Future<void> enableBiometrics(SecretKey dek) async {}

  @override
  Future<void> disableBiometrics() async {}

  @override
  Future<SecretKey?> biometricKey() async => null;

  @override
  Future<void> eraseEverything() async {
    vaultCreated = false;
  }
}

/// Monta la app completa (con el flujo de onboarding) sobre un controlador
/// con el estado que se le indique al servicio de claves.
Future<AppControllers> pumpOnboardingApp(
  WidgetTester tester, {
  VaultKeyService? keyService,
}) async {
  final controllers = AppControllers(
    entries: EntriesController(
      initialStorage: VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      ),
    ),
    lock: LockController(
      initialKeyService: keyService,
      initialLockoutStore: InMemoryLockoutStore(),
    ),
  );
  controllers.settings.setLanguage(AppLanguage.spanish);
  await controllers.lock.initialize();
  await tester.pumpWidget(LlaveroApp(controllers: controllers));
  await tester.pumpAndSettle();
  return controllers;
}

void main() {
  group('Task 1 — Onboarding: crear bóveda con PIN', () {
    testWidgets(
      'onboarding crea la bóveda con un PIN válido',
      (tester) async {
        final service = FakeVaultKeyService();
        final controllers = await pumpOnboardingApp(tester, keyService: service);

        // Flujo: primera ejecución -> splash -> onboarding -> crear PIN.
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(find.text('Continuar'), findsOneWidget);

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(await service.hasVault(), isFalse);

        await tester.tap(
          find.descendant(
            of: find.byType(OnboardingScreen),
            matching: find.text('Crear bóveda'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PinCreateScreen), findsOneWidget);

        final pinField = find.byType(TextField);
        await tester.enterText(pinField, '482913');
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: find.byType(PinCreateScreen),
            matching: find.text('Crear bóveda'),
          ),
        );
        await tester.pumpAndSettle();

        // Tras el primer PIN válido pasamos a confirmar el mismo PIN.
        expect(
          find.descendant(
            of: find.byType(PinCreateScreen),
            matching: find.text('Confirmar PIN'),
          ),
          findsOneWidget,
        );

        await tester.enterText(pinField, '482913');
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: find.byType(PinCreateScreen),
            matching: find.text('Crear bóveda'),
          ),
        );
        await tester.pumpAndSettle();

        // La bóveda se creó y el controlador quedó en estado bloqueado.
        expect(await service.hasVault(), isTrue);
        expect(controllers.lock.hasPin, isTrue);
        expect(controllers.lock.isLocked, isTrue);
        expect(find.byType(PinCreateScreen), findsNothing);
      },
    );

    testWidgets('onboarding no se muestra si ya existe bóveda', (tester) async {
      final service = FakeVaultKeyService();
      await service.createVault('482913');
      final controllers = await pumpOnboardingApp(tester, keyService: service);

      expect(controllers.lock.hasPin, isTrue);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('onboarding rechaza un PIN inválido y no crea la bóveda',
        (tester) async {
      final service = FakeVaultKeyService();
      final controllers = await pumpOnboardingApp(tester, keyService: service);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(OnboardingScreen),
          matching: find.text('Crear bóveda'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PinCreateScreen), findsOneWidget);

      // Secuencia inválida (123456).
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(PinCreateScreen),
          matching: find.text('Crear bóveda'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('El PIN no es válido'), findsOneWidget);
      expect(await service.hasVault(), isFalse);
      expect(controllers.lock.hasPin, isFalse);
    });
  });
}
