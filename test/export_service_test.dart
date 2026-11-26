import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/export_service.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 11, 26, 12);

  VaultDocument document() => VaultDocument(
        entries: <VaultEntry>[
          VaultEntry(
            id: 'e1',
            title: 'Wi-Fi, de "casa"',
            categoryId: 'wifi',
            person: 'Casa',
            fields: <EntryField>[
              const EntryField(label: 'Red', value: 'Casa-5G'),
              EntryField(
                label: 'Contraseña',
                value: 'secreto-unicornio',
                type: EntryFieldType.secret,
                isSecret: true,
              ),
            ],
            notes: 'Nota de prueba',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

  group('Task 6 — Exportar/importar', () {
    final service = ExportService();

    test('backup cifrado: ida y vuelta', () async {
      final backup = await service.createEncryptedBackup(
        document(),
        'clave-del-respaldo',
        createdAt: now,
      );
      final restaurado = await service.readEncryptedBackup(
        backup,
        'clave-del-respaldo',
      );

      expect(restaurado.entries.length, 1);
      expect(restaurado.entries.first.fields.last.value, 'secreto-unicornio');
    });

    test('backup cifrado: contraseña errónea falla', () async {
      final backup = await service.createEncryptedBackup(
        document(),
        'correcta',
        createdAt: now,
      );

      expect(
        () => service.readEncryptedBackup(backup, 'incorrecta'),
        throwsA(isA<InvalidBackupPasswordException>()),
      );
    });

    test('el backup no contiene secretos en claro', () async {
      final backup = await service.createEncryptedBackup(
        document(),
        'clave',
        createdAt: now,
      );
      expect(jsonEncode(backup).contains('secreto-unicornio'), isFalse);
    });

    test('JSON no expone secretos', () {
      final json = service.toJson(document());

      expect(json.contains('secreto-unicornio'), isFalse);
      expect(json.contains(hiddenSecretPlaceholder), isTrue);
      expect(json.contains('Casa-5G'), isTrue);
    });

    test('CSV no expone secretos y escapa comillas', () {
      final csv = service.toCsv(document());

      expect(csv.contains('secreto-unicornio'), isFalse);
      expect(csv.contains(hiddenSecretPlaceholder), isTrue);
      expect(csv.contains('""casa""'), isTrue);
    });

    test('PDF se genera sin errores', () async {
      final bytes = await service.toPdf(document());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('includeSecrets=true incluye los secretos en JSON y CSV', () {
      final json = service.toJson(document(), includeSecrets: true);
      final csv = service.toCsv(document(), includeSecrets: true);

      expect(json.contains('secreto-unicornio'), isTrue);
      expect(csv.contains('secreto-unicornio'), isTrue);
      expect(json.contains(hiddenSecretPlaceholder), isFalse);
    });

    test('el respaldo cifrado nunca incluye secretos en claro', () async {
      final backup = await service.createEncryptedBackup(
        document(),
        'clave',
        createdAt: now,
      );
      expect(
        jsonEncode(backup).contains('secreto-unicornio'),
        isFalse,
      );
      expect(
        jsonEncode(backup).contains(hiddenSecretPlaceholder),
        isFalse,
      );
    });

    test('importar reemplaza las entradas y persiste el cambio', () async {
      final fileSystem = MemoryVaultFileSystem();
      final key = await VaultCrypto().generateDek();
      final controller = EntriesController(
        initialStorage: VaultStorage(initialFileSystem: fileSystem),
      );
      await controller.load(key);

      final imported = VaultDocument(
        entries: <VaultEntry>[
          VaultEntry(
            id: 'importada',
            title: 'Entrada importada',
            categoryId: 'other',
            fields: const <EntryField>[],
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      await controller.replaceAll(imported);

      expect(controller.entries.length, 1);
      expect(controller.entries.first.title, 'Entrada importada');

      final recargado = EntriesController(
        initialStorage: VaultStorage(initialFileSystem: fileSystem),
      );
      await recargado.load(key);
      expect(recargado.entries.first.title, 'Entrada importada');
    });
  });
}
