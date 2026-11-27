import 'package:cryptography/cryptography.dart';
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

VaultEntry _entry(String id, List<EntryField> fields) => VaultEntry(
      id: id,
      title: id,
      categoryId: 'email',
      fields: fields,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  test('dos entradas con la misma contraseña débil salen como débiles y repetidas',
      () {
    final report = PasswordHealth.analyze(<VaultEntry>[
      _entry('a', <EntryField>[
        const EntryField(
          key: 'password',
          label: 'Contraseña',
          value: 'abc12345',
          type: EntryFieldType.secret,
        ),
      ]),
      _entry('b', <EntryField>[
        const EntryField(
          key: 'password',
          label: 'Password',
          value: 'abc12345',
          type: EntryFieldType.secret,
        ),
      ]),
    ]);

    expect(report.entriesReviewed, 2);
    expect(report.weak.map((e) => e.id), containsAll(<String>['a', 'b']));
    expect(report.reused.map((e) => e.id), containsAll(<String>['a', 'b']));
    expect(report.problemCount, greaterThan(0));
  });

  test('una contraseña única y fuerte no se marca', () {
    final report = PasswordHealth.analyze(<VaultEntry>[
      _entry('a', <EntryField>[
        const EntryField(
          key: 'password',
          label: 'Contraseña',
          value: 'Tr0ub4dor&3-Xq',
          type: EntryFieldType.secret,
        ),
      ]),
    ]);

    expect(report.entriesReviewed, 1);
    expect(report.weak, isEmpty);
    expect(report.reused, isEmpty);
    expect(report.problemCount, 0);
  });

  test('analiza campos por clave aunque no tengan la casilla Secreto', () {
    final report = PasswordHealth.analyze(<VaultEntry>[
      _entry('a', <EntryField>[
        const EntryField(key: 'password', label: 'x', value: '123'),
        const EntryField(key: 'pin', label: 'y', value: '1234'),
      ]),
    ]);

    expect(report.total, 2);
    expect(report.weak, hasLength(1));
  });

  test('un PIN corto se marca como débil', () {
    final report = PasswordHealth.analyze(<VaultEntry>[
      _entry('a', <EntryField>[
        const EntryField(
          key: 'pin',
          label: 'PIN',
          value: '1234',
          type: EntryFieldType.pin,
        ),
      ]),
    ]);

    expect(report.weak, hasLength(1));
  });

  testWidgets('la pantalla indica cuántas entradas revisó, nunca un 0 suelto',
      (tester) async {
    final controller = EntriesController(
      initialStorage: VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      ),
    );
    await controller.open(SecretKey(List<int>.filled(32, 4)));
    await controller.add(_entry('a', <EntryField>[
      const EntryField(
        key: 'password',
        label: 'Contraseña',
        value: 'Tr0ub4dor&3-Xq',
        type: EntryFieldType.secret,
      ),
    ]));
    await controller.add(_entry('b', const <EntryField>[]));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('es'),
        home: AppScope(
          controllers: AppControllers(entries: controller),
          child: const SecurityHealthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 entradas revisadas, 0 problemas'), findsOneWidget);
  });
}
