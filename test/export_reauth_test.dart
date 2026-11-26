import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/export_import/export_import_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

const warning =
    'Los secretos se guardarán sin cifrar. Cualquiera que lea el archivo podrá verlos.';

Future<AppControllers> pumpExport(WidgetTester tester) async {
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
  group('Exportaciones en claro', () {
    testWidgets('aviso rojo visible al activar «Incluir secretos en claro»',
        (tester) async {
      await pumpExport(tester);

      await tester.tap(find.text('Incluir secretos en claro'));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text(warning));
      expect(
        text.style?.color,
        Theme.of(tester.element(find.byType(ExportImportScreen)))
            .colorScheme
            .error,
      );
    });

    testWidgets('exportar JSON en claro pide re-autenticación antes del archivo',
        (tester) async {
      await pumpExport(tester);

      await tester.tap(find.text('Exportar JSON'));
      await tester.pumpAndSettle();

      expect(find.text('Confirma tu identidad'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Confirma tu identidad'), findsNothing);
    });

    testWidgets('exportar CSV con secretos confirma dos veces y luego reautentica',
        (tester) async {
      await pumpExport(tester);
      await tester.tap(find.text('Incluir secretos en claro'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exportar CSV'));
      await tester.pumpAndSettle();
      expect(find.text(warning), findsWidgets);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, exportar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirma tu identidad'), findsOneWidget);
    });
  });
}
