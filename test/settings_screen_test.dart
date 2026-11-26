import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/settings/settings_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

void main() {
  Future<AppControllers> pumpSettings(WidgetTester tester) async {
    final controllers = AppControllers(
      entries: EntriesController(
        initialStorage: VaultStorage(
          initialFileSystem: MemoryVaultFileSystem(),
        ),
      ),
      lock: LockController(),
      settings: SettingsController(),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('es'),
        home: AppScope(
          controllers: controllers,
          child: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controllers;
  }

  group('Task 7 — Ajustes', () {
    testWidgets('muestra el estado de seguridad y los ajustes', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Estado de seguridad'), findsOneWidget);
      expect(find.text('Sin bóveda'), findsOneWidget);
      expect(find.text('Integridad del dispositivo'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Bloqueo automático'), findsOneWidget);
      expect(find.text('Longitud del PIN'), findsOneWidget);
      expect(find.text('Bloquear capturas'), findsOneWidget);
      expect(find.text('Exportar / importar'), findsOneWidget);
    });

    testWidgets('cambiar el tema actualiza el controlador', (tester) async {
      final controllers = await pumpSettings(tester);

      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      expect(controllers.settings.themeMode, AppThemeMode.dark);
    });

    testWidgets('cambiar el idioma actualiza el controlador', (tester) async {
      final controllers = await pumpSettings(tester);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      await tester.tap(find.text('Inglés'));
      await tester.pumpAndSettle();

      expect(controllers.settings.language, AppLanguage.english);
    });

    testWidgets('el bloqueo de capturas se puede cambiar', (tester) async {
      final controllers = await pumpSettings(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      final switcher = find.byType(Switch).last;

      expect(controllers.settings.blockScreenshots, isTrue);
      await tester.tap(switcher);
      await tester.pumpAndSettle();

      expect(controllers.settings.blockScreenshots, isFalse);
    });
  });
}
