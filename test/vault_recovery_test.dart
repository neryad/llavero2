import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/core/routes/app_routes.dart';
import 'package:llavero2/core/security/vault_problem.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/lock/recovery_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

class _FakeKeys implements VaultKeyService {
  String pin = '482913';
  bool exists = true;

  @override
  Future<bool> hasVault() async => exists;

  @override
  Future<void> createVault(String value) async {
    pin = value;
    exists = true;
  }

  @override
  Future<SecretKey> unlockWithPin(String value) async {
    if (value != pin || !exists) throw const InvalidPinException();
    return SecretKey(List<int>.filled(32, 7));
  }

  @override
  Future<void> changePin(String current, String next) async {
    if (current != pin) throw const InvalidPinException();
    pin = next;
  }

  @override
  Future<void> enableBiometrics(SecretKey key) async {}

  @override
  Future<void> disableBiometrics() async {}

  @override
  Future<SecretKey?> biometricKey() async => null;

  @override
  Future<void> eraseEverything() async => exists = false;
}

Future<AppControllers> _controllers(VaultFileSystem fs, {String pin = '482913'}) async {
  final service = _FakeKeys()..pin = pin;
  final controllers = AppControllers(
    entries: EntriesController(
      initialStorage: VaultStorage(initialFileSystem: fs),
    ),
    lock: LockController(
      initialKeyService: service,
      initialLockoutStore: InMemoryLockoutStore(),
    ),
  );
  await controllers.lock.createVault(pin);
  return controllers;
}

VaultEntry _oldEntry() => VaultEntry(
      id: 'old-1',
      title: 'Entrada antigua',
      categoryId: 'email',
      fields: const <EntryField>[
        EntryField(label: 'Contraseña', value: 'secreto', type: EntryFieldType.secret),
      ],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  group('clasificación de errores', () {
    test('cada excepción se mapea a su estado', () {
      expect(problemFor(const UnsupportedVaultVersionException()),
          VaultProblem.newerFormat);
      expect(problemFor(const MissingVaultException()), VaultProblem.missing);
      expect(problemFor(const TamperedDataException()), VaultProblem.corrupted);
      expect(problemFor(const FormatException()), VaultProblem.corrupted);
      expect(problemFor(const FileSystemException('x')), VaultProblem.unreadable);
      expect(problemFor(StateError('x')), VaultProblem.unreadable);
    });
  });

  group('pantalla de recuperación', () {
    Future<void> pump(WidgetTester tester, VaultProblem problem) async {
      final controllers = await _controllers(MemoryVaultFileSystem());
      controllers.lock.markVaultProblem(problem);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          locale: const Locale('es'),
          routes: <String, WidgetBuilder>{
            AppRoutes.onboarding: (_) => const SizedBox.shrink(),
          },
          home: AppScope(
            controllers: controllers,
            child: RecoveryScreen(problem: problem),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('newerFormat no ofrece borrar', (tester) async {
      await pump(tester, VaultProblem.newerFormat);
      expect(
        find.text(
          'Esta bóveda se creó con una versión más nueva de Llavero. Actualiza la app para abrirla.',
        ),
        findsOneWidget,
      );
      expect(find.text('Empezar de cero'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Importar respaldo'), findsOneWidget);
    });

    testWidgets('los otros estados sí ofrecen empezar de cero', (tester) async {
      for (final state in <VaultProblem>[
        VaultProblem.corrupted,
        VaultProblem.unreadable,
        VaultProblem.missing,
      ]) {
        await pump(tester, state);
        expect(find.text('Empezar de cero'), findsOneWidget);
      }
    });
  });

  group('empezar de cero', () {
    testWidgets('renombra, borra claves y el PIN nuevo abre sin entradas',
        (tester) async {
      final fs = MemoryVaultFileSystem();
      final controllers = await _controllers(fs);
      expect(await controllers.unlockWithPin('482913'), isTrue);
      await controllers.entries.add(_oldEntry());
      final original = fs.bytesAt(fs.vaultPath)!;
      controllers.lock.markVaultProblem(VaultProblem.corrupted);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          locale: const Locale('es'),
          routes: <String, WidgetBuilder>{
            AppRoutes.onboarding: (_) => const SizedBox.shrink(),
          },
          home: AppScope(
            controllers: controllers,
            child: const RecoveryScreen(problem: VaultProblem.corrupted),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Empezar de cero'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
        find.byType(TextField).last,
        'BORRAR',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'BORRAR',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Empezar de cero'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(fs.bytesAt(fs.vaultPath), isNull);
      final damaged = fs.paths.where((p) => p.contains('.damaged-')).toList();
      expect(damaged, hasLength(1));
      expect(fs.bytesAt(damaged.single), original);

      await controllers.lock.createVault('739264');
      expect(await controllers.unlockWithPin('739264'), isTrue);
      expect(controllers.entries.entries, isEmpty);
    });
  });

  test('Reintentar recarga con la DEK y limpia el problema', () async {
    final fs = MemoryVaultFileSystem();
    final controllers = await _controllers(fs);
    expect(await controllers.unlockWithPin('482913'), isTrue);
    await controllers.entries.add(_oldEntry());
    controllers.lock.markVaultProblem(VaultProblem.corrupted);

    expect(await controllers.retryVaultLoad(), isTrue);
    expect(controllers.lock.vaultProblem, isNull);
    expect(controllers.entries.entries, hasLength(1));
  });
}
