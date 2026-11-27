import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/platform/platform_capabilities.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/settings/settings_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

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
      home: AppScope(controllers: controllers, child: const SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return controllers;
}


Future<void> scrollTo(WidgetTester tester, String text) async {
  for (var i = 0; i < 12; i++) {
    if (find.text(text).evaluate().isNotEmpty) return;
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 12; i++) {
    if (find.text(text).evaluate().isNotEmpty) return;
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Fase C — Ajustes agrupados', () {
    testWidgets('muestra los cuatro grupos', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Seguridad'), findsOneWidget);
      await scrollTo(tester, 'Herramientas');
      expect(find.text('Herramientas'), findsOneWidget);
      await scrollTo(tester, 'Apariencia');
      expect(find.text('Apariencia'), findsOneWidget);
      await scrollTo(tester, 'Acerca de');
      expect(find.text('Acerca de'), findsNWidgets(2));
      expect(find.text('Categorías'), findsOneWidget);
      // Volver arriba para comprobar la etiqueta biométrica.
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, 400));
        await tester.pumpAndSettle();
      }
      expect(find.text('Desbloqueo biométrico'), findsOneWidget);
    });

    testWidgets('la longitud del PIN no está en Ajustes, solo en Cambiar PIN',
        (tester) async {
      await pumpSettings(tester);

      expect(find.text('Longitud del PIN'), findsNothing);
      expect(find.byType(SegmentedButton<int>), findsNothing);
      expect(find.text('Cambiar PIN'), findsOneWidget);
    });

    testWidgets('el tiempo de portapapeles se ve como un desplegable',
        (tester) async {
      await pumpSettings(tester);
      await scrollTo(tester, 'Tiempo en el portapapeles');

      final row = find.ancestor(
        of: find.text('Tiempo en el portapapeles'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(of: row, matching: find.byType(DropdownButton<int>)),
        findsOneWidget,
      );
    });

    testWidgets('cambiar el tema actualiza el controlador', (tester) async {
      final controllers = await pumpSettings(tester);
      await scrollTo(tester, 'Oscuro');
      await tester.ensureVisible(find.text('Oscuro').last);
      await tester.pump();
      await tester.tap(find.text('Oscuro').last);
      await tester.pumpAndSettle();

      expect(controllers.settings.themeMode, AppThemeMode.dark);
    });

    testWidgets('cambiar el idioma actualiza el controlador', (tester) async {
      final controllers = await pumpSettings(tester);
      await scrollTo(tester, 'Inglés');
      await tester.ensureVisible(find.text('Inglés').last);
      await tester.pump();
      await tester.tap(find.text('Inglés').last);
      await tester.pumpAndSettle();

      expect(controllers.settings.language, AppLanguage.english);
    });

    testWidgets('el bloqueo de capturas respeta la plataforma', (tester) async {
      final controllers = await pumpSettings(tester);
      await scrollTo(tester, 'Bloquear capturas');
      final switcher = find.ancestor(
        of: find.text('Bloquear capturas'),
        matching: find.byType(SwitchListTile),
      );

      if (PlatformCapabilities.detect().supportsScreenshotBlocking) {
        expect(tester.widget<SwitchListTile>(switcher).onChanged, isNotNull);
        await tester.tap(switcher);
        await tester.pumpAndSettle();
        expect(controllers.settings.blockScreenshots, isFalse);
      } else {
        expect(tester.widget<SwitchListTile>(switcher).onChanged, isNull);
        expect(
          find.text('El bloqueo de capturas solo está disponible en móvil.'),
          findsOneWidget,
        );
      }
    });
  });
}
