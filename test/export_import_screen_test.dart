import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/export_import/export_import_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

void main() {
  testWidgets('la pantalla muestra las opciones de exportar e importar',
      (tester) async {
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

    expect(find.text('Exportar / importar'), findsOneWidget);
    expect(find.text('Contraseña del respaldo'), findsOneWidget);
    expect(find.text('Exportar copia'), findsOneWidget);
    expect(find.text('Importar respaldo'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);
    expect(find.text('Exportar JSON'), findsOneWidget);
    expect(find.text('Exportar CSV'), findsOneWidget);
  });
}
