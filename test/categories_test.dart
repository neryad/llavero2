import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/categories_controller.dart';
import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/secure_store.dart';
import 'package:llavero2/core/theme/category_colors.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/settings/categories_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

void main() {
  group('Mejora 13 — Categorías personalizadas', () {
    test('crear, actualizar y borrar persisten en el almacén', () async {
      final store = InMemorySecureStore();
      final controller = CategoriesController(store: store);
      await controller.initialize();
      expect(controller.custom, isEmpty);

      final category = await controller.add(
        name: 'Mascotas',
        colorId: CategoryIds.devices,
      );
      expect(controller.custom.length, 1);
      expect(controller.byId(category.id)?.name, 'Mascotas');

      await controller.update(category.copyWith(name: 'Animales'));
      expect(controller.byId(category.id)?.name, 'Animales');

      // simulamos reinicio
      final otro = CategoriesController(store: store);
      await otro.initialize();
      expect(otro.custom.length, 1);
      expect(otro.custom.first.name, 'Animales');
      expect(otro.custom.first.colorId, CategoryIds.devices);

      await otro.remove(category.id);
      final otro2 = CategoriesController(store: store);
      await otro2.initialize();
      expect(otro2.custom, isEmpty);
    });

    testWidgets('la pantalla permite crear una categoría', (tester) async {
      final controllers = AppControllers(
        entries: EntriesController(
          initialStorage: VaultStorage(
            initialFileSystem: MemoryVaultFileSystem(),
          ),
        ),
      );
      await controllers.categories.initialize();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          locale: const Locale('es'),
          home: AppScope(
            controllers: controllers,
            child: const CategoriesScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Todavía no has creado categorías.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Mascotas');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(controllers.categories.custom.length, 1);
      expect(find.text('Mascotas'), findsOneWidget);
    });
  });
}
