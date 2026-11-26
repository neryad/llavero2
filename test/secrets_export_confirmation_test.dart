import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/export_import/export_import_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

void main() {
  Future<void> pumpExport(WidgetTester tester) async {
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
    await tester.pump();
  }

  group('Mejora 14 — Exportar secretos con doble confirmación', () {
    testWidgets('el interruptor aparece y empieza desactivado', (tester) async {
      await pumpExport(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final sw = find.byType(SwitchListTile);
      expect(sw, findsOneWidget);
      expect(tester.widget<SwitchListTile>(sw).value, isFalse);
    });

    testWidgets('activarlo y exportar pide dos confirmaciones', (tester) async {
      await pumpExport(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exportar JSON'));
      await tester.pumpAndSettle();

      // Primer aviso: en pantalla (rojo) y en el diálogo de confirmación.
      expect(
        find.text(
          'Los secretos se guardarán sin cifrar. Cualquiera que lea el archivo podrá verlos.',
        ),
        findsNWidgets(2),
      );

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Segunda confirmación.
      expect(
        find.text(
          '¿Confirmas que quieres exportar los secretos en claro?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
