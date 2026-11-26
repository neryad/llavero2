import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
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
  String correctPin = '482913';

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
  test('cambiar 6 → 8 reenvuelve la DEK: el PIN viejo falla y el nuevo abre',
      () async {
    final service = SecureStoreVaultKeyService(
      initialStore: InMemorySecureStore(),
    );
    await service.createVault('482913');
    final oldBytes = await (await service.unlockWithPin('482913')).extractBytes();

    await service.changePin('482913', '73926458');

    expect(
      () => service.unlockWithPin('482913'),
      throwsA(isA<InvalidPinException>()),
    );
    final newDek = await service.unlockWithPin('73926458');
    expect(await newDek.extractBytes(), oldBytes);
  });

  testWidgets('la pantalla reautentica y aplica la longitud elegida',
      (tester) async {
    final service = _FakeChangePinService();
    final settings = SettingsController();
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
      settings: settings,
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
    await tester.pumpAndSettle();

    // El PIN actual se comprueba antes de dejar elegir la nueva longitud.
    await tester.enterText(find.byType(TextField), '111111');
    await tester.pumpAndSettle();
    expect(find.text('El PIN actual no es correcto.'), findsOneWidget);
    expect(find.text('Nuevo PIN'), findsNothing);

    await tester.enterText(find.byType(TextField), '482913');
    await tester.pumpAndSettle();
    expect(find.text('Nuevo PIN'), findsOneWidget);

    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '73926458');
    await tester.pumpAndSettle();
    expect(find.text('Confirmar nuevo PIN'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '73926458');
    await tester.pumpAndSettle();

    expect(service.correctPin, '73926458');
    expect(settings.pinLength, 8);
  });
}
