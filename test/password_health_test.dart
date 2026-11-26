import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/password_health.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/security/security_health_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

VaultEntry entryWithSecret(String id, String secret) => VaultEntry(
      id: id,
      title: id,
      categoryId: 'other',
      fields: <EntryField>[
        EntryField(label: 'Contraseña', value: secret, isSecret: true),
      ],
      createdAt: DateTime.utc(2026, 11, 26),
      updatedAt: DateTime.utc(2026, 11, 26),
    );

void main() {
  group('Mejora 15 — Salud de contraseñas', () {
    test('detecta débiles y repetidas', () {
      final report = PasswordHealth.analyze(<VaultEntry>[
        entryWithSecret('corta', 'abc'),
        entryWithSecret('comun', '123456'),
        entryWithSecret('repetida1', 'MismaClaveSegura123'),
        entryWithSecret('repetida2', 'MismaClaveSegura123'),
      ]);

      expect(report.total, 4);
      expect(report.weak.map((e) => e.id), containsAll(<String>['corta', 'comun']));
      expect(
        report.reused.map((e) => e.id),
        containsAll(<String>['repetida1', 'repetida2']),
      );
    });

    test('una contraseña fuerte y única no genera avisos', () {
      final report = PasswordHealth.analyze(<VaultEntry>[
        entryWithSecret('buena', 'Llavero2026!Segura'),
      ]);

      expect(report.total, 1);
      expect(report.weak, isEmpty);
      expect(report.reused, isEmpty);
    });

    testWidgets('la pantalla muestra el informe sin revelar secretos',
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
            child: const SecurityHealthScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Salud de contraseñas'), findsOneWidget);
      expect(find.text('Contraseñas revisadas: 0'), findsOneWidget);
      expect(
        find.text(
          'No hay campos secretos todavía. Marca la casilla «Secreto» en los campos de tus entradas para que se revisen.',
        ),
        findsOneWidget,
      );
      expect(find.text('Llavero2026!Segura'), findsNothing);
    });
  });
}
