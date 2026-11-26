import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/platform/platform_capabilities.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/settings/settings_screen.dart';
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

Future<AppControllers> pumpSettings(
  WidgetTester tester, {
  required bool unlocked,
}) async {
  final lock = unlocked
      ? LockController(
          initialKeyService: _FakeKeyService(),
          initialLockoutStore: InMemoryLockoutStore(),
        )
      : LockController();
  if (unlocked) {
    await lock.initialize();
    await lock.submitPin('482913');
  }

  final controllers = AppControllers(
    entries: EntriesController(
      initialStorage: VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      ),
    ),
    lock: lock,
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: const Locale('es'),
      home: AppScope(controllers: controllers, child: const SettingsScreen()),
    ),
  );
  await tester.pump();
  return controllers;
}

void main() {
  final capabilities = PlatformCapabilities.detect();

  group('Mejora 3 + 17 — Switch de biometría honesto', () {
    testWidgets('con la bóveda cerrada el switch está deshabilitado y se explica',
        (tester) async {
      await pumpSettings(tester, unlocked: false);

      final biometricSwitch = find.byType(Switch).first;
      expect(tester.widget<Switch>(biometricSwitch).onChanged, isNull);

      if (capabilities.supportsBiometrics) {
        expect(
          find.text('Disponible solo con la bóveda abierta.'),
          findsOneWidget,
        );
      } else {
        expect(
          find.text('La biometría solo está disponible en móvil.'),
          findsOneWidget,
        );
      }
    });

    testWidgets('el switch solo funciona en móvil y con la bóveda abierta',
        (tester) async {
      final controllers = await pumpSettings(tester, unlocked: true);

      final biometricSwitch = find.byType(Switch).first;
      if (capabilities.supportsBiometrics) {
        expect(tester.widget<Switch>(biometricSwitch).onChanged, isNotNull);
        await tester.tap(biometricSwitch);
        await tester.pump();
        expect(controllers.lock.biometricsEnabled, isTrue);
      } else {
        expect(tester.widget<Switch>(biometricSwitch).onChanged, isNull);
        expect(controllers.lock.biometricsEnabled, isFalse);
      }
    });
  });
}
