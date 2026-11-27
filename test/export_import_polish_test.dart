import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/controllers/settings_store.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/export_import/export_import_screen.dart';
import 'package:llavero2/features/export_import/import_actions.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

VaultEntry _entry(String id) => VaultEntry(
      id: id,
      title: id,
      categoryId: 'email',
      fields: const <EntryField>[],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

Future<AppControllers> _pump(WidgetTester tester) async {
  final controllers = AppControllers(
    entries: EntriesController(
      initialStorage: VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      ),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: const Locale('es'),
      home: AppScope(
        controllers: controllers,
        child: const ExportImportScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controllers;
}

void main() {
  testWidgets('exportar copia requiere 8 caracteres y contraseñas iguales',
      (tester) async {
    await _pump(tester);
    FilledButton button() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Exportar copia'),
        );

    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), 'abc');
    await tester.enterText(find.byType(TextField).at(1), 'abc');
    await tester.pumpAndSettle();
    expect(button().onPressed, isNull);
    expect(find.textContaining('Débil'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'contraseña-segura');
    await tester.enterText(find.byType(TextField).at(1), 'otra');
    await tester.pumpAndSettle();
    expect(button().onPressed, isNull);

    await tester.enterText(
      find.byType(TextField).at(1),
      'contraseña-segura',
    );
    await tester.pumpAndSettle();
    expect(button().onPressed, isNotNull);
    expect(find.textContaining('Fuerte'), findsOneWidget);
  });

  test('la fecha del último respaldo se guarda sola', () async {
    final store = InMemorySettingsStore();
    final settings = SettingsController(store: store);
    expect(settings.lastBackupAt, isNull);

    final date = DateTime.utc(2026, 11, 27, 10, 30);
    await settings.setLastBackupAt(date);

    final reloaded = SettingsController(store: store);
    await reloaded.initialize();
    expect(reloaded.lastBackupAt, date);
  });

  test('combinar y reemplazar producen recuentos distintos', () async {
    Future<EntriesController> controllerWith(String id) async {
      final entries = EntriesController(
        initialStorage: VaultStorage(
          initialFileSystem: MemoryVaultFileSystem(),
        ),
      );
      await entries.open(SecretKey(List<int>.filled(32, 5)));
      await entries.add(_entry(id));
      return entries;
    }

    final local = await controllerWith('local');
    final incoming = VaultDocument(entries: <VaultEntry>[_entry('nueva')]);
    await applyImport(local, incoming, merge: true);
    expect(local.entries, hasLength(2));

    final replaced = await controllerWith('local');
    await applyImport(replaced, incoming, merge: false);
    expect(replaced.entries, hasLength(1));
    expect(replaced.entries.single.id, 'nueva');
  });

  test('errores de importación se distinguen', () {
    expect(importErrorKind(const InvalidBackupPasswordException()),
        ImportErrorKind.wrongPassword);
    expect(importErrorKind(const InvalidBackupFileException()),
        ImportErrorKind.invalidFile);
    expect(importErrorKind(const UnsupportedBackupVersionException()),
        ImportErrorKind.newerVersion);
    expect(importErrorKind(StateError('x')), ImportErrorKind.generic);
  });
}
