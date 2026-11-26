import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/theme/app_spacing.dart';
import 'package:llavero2/core/theme/app_theme.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/home/home_screen.dart';
import 'package:llavero2/features/security/security_health_screen.dart';
import 'package:llavero2/features/settings/categories_screen.dart';
import 'package:llavero2/features/settings/settings_screen.dart';
import 'package:llavero2/features/trash/trash_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

VaultEntry _entry(String id) => VaultEntry(
      id: id,
      title: 'Entrada $id',
      categoryId: 'wifi',
      fields: <EntryField>[
        EntryField(
          label: 'Contraseña',
          value: 'secreto-$id',
          type: EntryFieldType.secret,
        ),
      ],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

Future<AppControllers> _controllers({int entries = 0}) async {
  final controller = EntriesController(
    initialStorage: VaultStorage(
      initialFileSystem: MemoryVaultFileSystem(),
    ),
  );
  if (entries > 0) {
    await controller.open(SecretKey(List<int>.filled(32, 9)));
    for (var i = 0; i < entries; i++) {
      await controller.add(_entry('$i'));
    }
  }
  return AppControllers(entries: controller);
}

Widget _app({
  required ThemeData theme,
  required Widget child,
  required AppControllers controllers,
  double scale = 1,
  Size size = const Size(320, 640),
}) =>
    MaterialApp(
      theme: theme,
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: const Locale('es'),
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: size,
          textScaler: TextScaler.linear(scale),
        ),
        child: widget!,
      ),
      home: AppScope(controllers: controllers, child: child),
    );

void main() {
  testWidgets('las tarjetas de Home separan 12dp y la lista deja 96dp abajo',
      (tester) async {
    final controllers = await _controllers(entries: 2);
    await tester.pumpWidget(_app(
      theme: AppTheme.light(),
      controllers: controllers,
      child: const HomeScreen(),
      size: const Size(800, 900),
    ));
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(
      list.padding!.resolve(Directionality.of(tester.element(find.byType(ListView)))).bottom,
      greaterThanOrEqualTo(AppSpacing.listBottom),
    );

    final cards = find.byType(Card);
    expect(cards, findsNWidgets(3)); // banner + 2 entradas
    double top(int i) => tester.renderObject<RenderBox>(cards.at(i))
        .localToGlobal(Offset.zero).dy;
    double bottom(int i) {
      final box = tester.renderObject<RenderBox>(cards.at(i));
      return box.localToGlobal(Offset(0, box.size.height)).dy;
    }

    // Tarjeta 1 y 2 están en la sección «Todas».
    expect((top(2) - bottom(1)).round(), AppSpacing.cardGap.round());
  });

  testWidgets('pantallas de lista no desbordan a 320dp con fuente al 200 %',
      (tester) async {
    for (final theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
      for (final screen in <Widget>[
        const HomeScreen(),
        const TrashScreen(),
        const CategoriesScreen(),
        const SecurityHealthScreen(),
        const SettingsScreen(),
      ]) {
        final controllers = await _controllers();
        await tester.pumpWidget(_app(
          theme: theme,
          controllers: controllers,
          child: screen,
          scale: 2,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');

        if (find.byType(ListView).evaluate().isNotEmpty) {
          for (var i = 0; i < 8; i++) {
            await tester.drag(find.byType(ListView), const Offset(0, -300));
            await tester.pumpAndSettle();
          }
        }
        expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
      }
    }
  });

  testWidgets('las filas de Ajustes tienen altura mínima de 56dp', (tester) async {
    final controllers = await _controllers();
    await tester.pumpWidget(_app(
      theme: AppTheme.dark(),
      controllers: controllers,
      child: const SettingsScreen(),
    ));
    await tester.pumpAndSettle();

    for (final tile in find.byType(ListTile).evaluate()) {
      final widget = tile.widget as ListTile;
      expect(widget.minTileHeight, AppSpacing.rowMinHeight);
    }
  });
}
