import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/settings/settings_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

void main() {
  testWidgets('el texto de iOS se muestra solo en that plataforma',
      (tester) async {
    final controllers = AppControllers(
      entries: EntriesController(
        initialStorage: VaultStorage(
          initialFileSystem: MemoryVaultFileSystem(),
        ),
      ),
      lock: LockController(),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('es'),
        home: AppScope(controllers: controllers, child: const SettingsScreen()),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // Los tests corren en el host (macOS): no se muestra la nota de iOS.
    expect(find.textContaining('no se pueden bloquear las capturas'), findsNothing);
    expect(find.text('Bloquear capturas'), findsOneWidget);
  });
}
