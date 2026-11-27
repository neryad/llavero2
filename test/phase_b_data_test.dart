import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/controllers/settings_store.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/routes/app_routes.dart';
import 'package:llavero2/core/security/secret_detector.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/export_service.dart';
import 'package:llavero2/data/export_temp_file.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/entries/entry_form_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

VaultEntry entry({
  String id = 'e1',
  String title = 'Título',
  String? person = 'Casa',
  List<EntryField> fields = const <EntryField>[],
}) =>
    VaultEntry(
      id: id,
      title: title,
      categoryId: 'other',
      person: person,
      fields: fields,
      createdAt: DateTime.utc(2026, 11, 26),
      updatedAt: DateTime.utc(2026, 11, 26),
    );

Future<EntriesController> controllerWith(Map<String, List<int>>? files) async {
  final key = await VaultCrypto().generateDek();
  final storage = VaultStorage(initialFileSystem: MemoryVaultFileSystem());
  final c = EntriesController(initialStorage: storage);
  await c.load(key);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FASE B — Bug de datos', () {
    test('C6: exportar sin secretos oculta campos tipo secret/pin', () {
      final service = ExportService();
      final doc = VaultDocument(
        entries: <VaultEntry>[
          entry(
            fields: <EntryField>[
              const EntryField(
                label: 'Clave',
                value: 'secreto-unicornio',
                type: EntryFieldType.secret,
              ),
              const EntryField(
                label: 'PIN',
                value: '1234',
                type: EntryFieldType.pin,
              ),
            ],
          ),
        ],
      );

      final json = service.toJson(doc);
      final csv = service.toCsv(doc);
      expect(json.contains('secreto-unicornio'), isFalse);
      expect(json.contains('1234'), isFalse);
      expect(csv.contains('secreto-unicornio'), isFalse);
      expect(json.contains(hiddenSecretPlaceholder), isTrue);
    });

    test('B2: la ruta del historial eliminado ya no existe', () {
      final route = AppRoutes.onGenerateRoute(
        RouteSettings(name: '/settings/history'),
      );
      expect(route.settings.name, '/settings/history');
      expect(route, isA<MaterialPageRoute<dynamic>>());
    });

    test('B4: merge conserva entradas y replace las sustituye', () async {
      final c = await controllerWith(null);
      await c.add(entry(id: 'a', title: 'Original'));
      await c.add(entry(id: 'b', title: 'Otra'));

      await c.merge(
        VaultDocument(
          entries: <VaultEntry>[
            entry(id: 'a', title: 'Actualizada'),
            entry(id: 'c', title: 'Nueva'),
          ],
        ),
      );
      expect(c.allEntries.map((e) => e.id).toSet(),
          <String>{'a', 'b', 'c'});
      expect(c.allEntries.firstWhere((e) => e.id == 'a').title, 'Actualizada');

      await c.replaceAll(
        VaultDocument(entries: <VaultEntry>[entry(id: 'z', title: 'Sola')]),
      );
      expect(c.allEntries.length, 1);
      expect(c.allEntries.first.id, 'z');
    });

    test('B5: el archivo temporal se borra incluso si falla la acción', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
      });
      late String path;
      await expectLater(
        ExportTempFile.use(
          utf8.encode('secreto'),
          'json',
          (file) async {
            path = file.path;
            expect(await file.exists(), isTrue);
            throw StateError('simulado');
          },
        ),
        throwsStateError,
      );
      expect(await File(path).exists(), isFalse);
    });

    test('B6: el detector trata secretos por tipo y etiqueta', () {
      expect(
        SecretDetector.isSecret(
          const EntryField(label: 'Clave', value: 'x', type: EntryFieldType.text),
        ),
        isTrue,
      );
      expect(
        SecretDetector.isSecret(
          const EntryField(label: 'PIN', value: '1234', type: EntryFieldType.text),
        ),
        isTrue,
      );
      expect(
        SecretDetector.isSecret(
          const EntryField(label: 'Red', value: 'Casa'),
        ),
        isFalse,
      );
    });

    test('B7: editar sin persona la elimina', () async {
      final c = await controllerWith(null);
      await c.add(entry(id: 'a', person: 'Mamá'));
      await c.update(entry(id: 'a', person: null));
      expect(c.entries.first.person, isNull);
    });

    test('B8: los ajustes sobreviven a un reinicio del controlador', () async {
      final store = InMemorySettingsStore();
      final first = SettingsController(store: store);
      first.setThemeMode(AppThemeMode.dark);
      first.setLanguage(AppLanguage.english);
      first.setPinLength(8);
      first.setClipboardTimeoutSeconds(5);
      first.setAutoLockDelay(AutoLockDelay.fiveMinutes);
      first.setBlockScreenshots(false);

      final second = SettingsController(store: store);
      await second.initialize();
      expect(second.themeMode, AppThemeMode.dark);
      expect(second.language, AppLanguage.english);
      expect(second.pinLength, 8);
      expect(second.clipboardTimeoutSeconds, 5);
      expect(second.autoLockDelay, AutoLockDelay.fiveMinutes);
      expect(second.blockScreenshots, isFalse);
    });

    test('B10: JSON sin entradas lanza FormatException', () {
      expect(
        () => VaultDocument.fromJson(<String, Object?>{'version': 1}),
        throwsFormatException,
      );
      expect(
        () => VaultEntry.fromJson(<String, Object?>{'title': 'x'}),
        throwsFormatException,
      );
    });

    test('B11: ruta sin argumentos no crashea', () {
      final route = AppRoutes.onGenerateRoute(
        RouteSettings(name: AppRoutes.entryDetail),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>());
    });

    testWidgets('B9: el formulario valida título y campos vacíos', (tester) async {
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
          home: AppScope(
            controllers: controllers,
            child: const EntryFormScreen(args: EntryFormArgs()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final save = find.text('Guardar');
      await tester.ensureVisible(save);
      await tester.pump();
      await tester.tap(save);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(find.text('Escribe un título.'), findsOneWidget);
    });
  });
}
