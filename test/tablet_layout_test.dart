import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/widgets/animated_entry_tile.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/home/home_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

class _FakeKeyService implements VaultKeyService {
  _FakeKeyService({required this.dek});

  final SecretKey dek;

  @override
  Future<bool> hasVault() async => true;

  @override
  Future<void> createVault(String pin) async {}

  @override
  Future<SecretKey> unlockWithPin(String pin) async => dek;

  @override
  Future<void> enableBiometrics(SecretKey dek) async {}

  @override
  Future<void> disableBiometrics() async {}

  @override
  Future<SecretKey?> biometricKey() async => null;

  @override
  Future<void> eraseEverything() async {}
}

Future<AppControllers> pumpHome(
  WidgetTester tester, {
  required double width,
  bool withEntry = true,
}) async {
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
  // Montamos primero; el reloj de los widget tests es falso y un
  // Future.delayed aquí fuera de pump() nunca terminaría.
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: const Locale('es'),
      home: AppScope(
        controllers: controllers,
        child: SizedBox(
          width: width,
          height: 800,
          child: const HomeScreen(),
        ),
      ),
    ),
  );

  await controllers.lock.initialize();
  await controllers.lock.submitPin('482913');
  await tester.pump(const Duration(milliseconds: 50));

  if (withEntry) {
    await controllers.entries.add(
      VaultEntry(
        id: 'e1',
        title: 'Wi-Fi de casa',
        categoryId: 'wifi',
        fields: const <EntryField>[],
        createdAt: DateTime.utc(2026, 11, 26),
        updatedAt: DateTime.utc(2026, 11, 26),
      ),
    );
  }

  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump();
  return controllers;
}

void main() {
  group('Task 8 — Diseño de tablets', () {
    testWidgets('en móvil se muestra la entrada', (tester) async {
      final controllers = await pumpHome(tester, width: 400);
      expect(controllers.entries.entries.length, 1);

      expect(find.text('Wi-Fi de casa'), findsOneWidget);
    });

    testWidgets('en tablet se muestra la entrada', (tester) async {
      final controllers = await pumpHome(tester, width: 1024);
      expect(controllers.entries.entries.length, 1);

      expect(find.text('Wi-Fi de casa'), findsOneWidget);
    });

    testWidgets('sin entradas muestra el mensaje de bóveda vacía', (tester) async {
      await pumpHome(tester, width: 400, withEntry: false);

      expect(find.text('Tu bóveda está vacía. Añade tu primera entrada.'),
          findsOneWidget);
      expect(find.byType(AnimatedEntryTile), findsNothing);
    });
  });
}
