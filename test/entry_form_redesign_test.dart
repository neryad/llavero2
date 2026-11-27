import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/categories_controller.dart';
import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/secure_store.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/entries/entry_form_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

Future<void> _pump(WidgetTester tester) async {
  final controllers = AppControllers(
    entries: EntriesController(
      initialStorage: VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      ),
    ),
    initialCategories: CategoriesController(store: InMemorySecureStore()),
  );
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: const Locale('es'),
      home: AppScope(
        controllers: controllers,
        child: const EntryFormScreen(args: EntryFormArgs()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('categoría «Otros» empieza sin campos y con la pista',
      (tester) async {
    await _pump(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      find.text('Añade los datos que necesites, como usuario, contraseña o código.'),
      findsOneWidget,
    );
    expect(find.text('Añadir campo'), findsOneWidget);
  });

  testWidgets('elegir Wi-Fi carga la plantilla con claves estables',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Wi-Fi').first);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Red'), findsOneWidget);
    expect(find.byIcon(Icons.casino_outlined), findsOneWidget);
  });

  testWidgets('el bottom sheet añade un campo PIN con dado y ojo',
      (tester) async {
    await _pump(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir campo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre del campo'),
      'Código',
    );
    await tester.tap(find.text('PIN'));
    await tester.tap(find.text('Añadir campo').last);
    await tester.pumpAndSettle();

    expect(find.text('Código'), findsOneWidget);
    expect(find.byIcon(Icons.casino_outlined), findsWidgets);
    expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
  });
}
