import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/app.dart';
import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/home/home_screen.dart';
import 'package:llavero2/features/entries/entry_form_screen.dart';
import 'package:llavero2/features/trash/trash_screen.dart';

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

Finder _field(String label) => find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == label,
    );

Future<void> main() async {
  final dek = await VaultCrypto().generateDek();

  group('Task 7 — Flujo completo de la Fase 5', () {
    testWidgets('crear entrada, ver secreto oculto, papelera y restaurar',
        (tester) async {
      final controllers = AppControllers(
        entries: EntriesController(
          initialStorage: VaultStorage(
            initialFileSystem: MemoryVaultFileSystem(),
          ),
        ),
        lock: LockController(
          initialKeyService: _FakeKeyService(dek: dek),
          initialLockoutStore: InMemoryLockoutStore(),
        ),
      );
      controllers.settings.setLanguage(AppLanguage.spanish);
      await controllers.lock.initialize();

      await tester.pumpWidget(LlaveroApp(controllers: controllers));
      await tester.pumpAndSettle();

      // Desbloquear.
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '482913');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Crear una entrada.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byType(EntryFormScreen), findsOneWidget);
      expect(find.text('Nueva entrada'), findsOneWidget);

      await tester.enterText(_field('Título'), 'Wi-Fi de casa');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir campo'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Nombre del campo'), 'Contraseña');
      await tester.tap(find.text('Secreto'));
      await tester.tap(find.text('Añadir campo').last);
      await tester.pumpAndSettle();
      await tester.enterText(_field('Valor'), 'secreto-unicornio');
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
      await tester.pumpAndSettle();
      expect(controllers.entries.entries.length, 1);
      expect(find.byType(EntryFormScreen), findsNothing);
      expect(find.text('Wi-Fi de casa'), findsOneWidget);

      // El secreto NO se ve en claro en el detalle.
      await tester.tap(find.text('Wi-Fi de casa'));
      await tester.pumpAndSettle();
      expect(find.text('secreto-unicornio'), findsNothing);
      expect(find.text('••••••••'), findsOneWidget);

      // Mostrar el secreto sí lo revela.
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();
      expect(find.text('secreto-unicornio'), findsOneWidget);

      // Mover a papelera: desaparece del listado.
      await tester.tap(find.text('Mover a papelera'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Wi-Fi de casa'), findsNothing);

      // En la papelera aparece y se puede restaurar.
      await tester.tap(find.byIcon(Icons.delete_sweep_outlined).first);
      await tester.pumpAndSettle();
      expect(find.byType(TrashScreen), findsOneWidget);
      expect(find.text('Wi-Fi de casa'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.restore));
      await tester.pumpAndSettle();
      expect(controllers.entries.entries.length, 1);
      expect(controllers.entries.entries.first.title, 'Wi-Fi de casa');
    });
  });
}
