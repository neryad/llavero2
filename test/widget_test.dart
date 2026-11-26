import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/app.dart';
import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

/// Monta la app con un idioma concreto para poder comprobar las dos
/// traducciones sin depender del idioma del emulador.
Future<AppControllers> pumpApp(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.spanish,
}) async {
  final controllers = AppControllers(
    entries: EntriesController(
      initialStorage: VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      ),
    ),
  );
  controllers.settings.setLanguage(language);
  await tester.pumpWidget(LlaveroApp(controllers: controllers));
  await tester.pumpAndSettle();
  return controllers;
}

void main() {
  testWidgets('la app arranca y muestra la pantalla de inicio', (tester) async {
    await pumpApp(tester);

    expect(find.text('Llavero'), findsOneWidget);
    expect(find.text('Todo offline, todo tuyo'), findsOneWidget);
  });

  testWidgets('el botón continuar lleva a la pantalla de bloqueo', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Elige 4, 6 u 8 dígitos. Más dígitos, más seguridad.'), findsOneWidget);
  });

  testWidgets('cambiar el idioma a inglés traduce la interfaz al instante',
      (tester) async {
    final controllers = await pumpApp(tester);

    controllers.settings.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();

    expect(find.text('Everything offline, yours to keep'), findsOneWidget);
    expect(find.text('Todo offline, todo tuyo'), findsNothing);
  });

  testWidgets('el tema oscuro se aplica al cambiar el ajuste', (tester) async {
    final controllers = await pumpApp(tester);

    controllers.settings.setThemeMode(AppThemeMode.dark);
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('el tema del sistema se respeta al arrancar', (tester) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });

  test('la app ofrece los dos idiomas requeridos', () {
    expect(
      L10n.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['es', 'en']),
    );
  });
}
