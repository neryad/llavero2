import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

class _FailingBackupFileSystem extends MemoryVaultFileSystem {
  @override
  Future<void> writeAtomic(String path, List<int> bytes) async {
    if (path.endsWith('.v1.bak')) throw StateError('no se pudo copiar');
    await super.writeAtomic(path, bytes);
  }
}

Future<void> _writeVault(
  VaultFileSystem fs,
  SecretKey dek, {
  int version = 1,
  List<Object?>? entries,
}) async {
  final crypto = VaultCrypto();
  final document = <String, Object?>{
    'version': version,
    'entries': entries ??
        <Object?>[
          <String, Object?>{
            'id': 'wifi-1',
            'title': 'Wi-Fi',
            'categoryId': 'wifi',
            'person': null,
            'fields': <Object?>[
              <String, Object?>{
                'label': 'Red',
                'value': 'Casa',
                'type': 'text',
                'isSecret': false,
              },
              <String, Object?>{
                'label': 'Contraseña',
                'value': 'secreto',
                'type': 'secret',
                'isSecret': true,
              },
            ],
            'notes': '',
            'isFavorite': false,
            'createdAt': '2026-01-01T00:00:00.000Z',
            'updatedAt': '2026-01-01T00:00:00.000Z',
            'deletedAt': null,
          },
        ],
  };
  final blob = await crypto.encryptVault(utf8.encode(jsonEncode(document)), dek);
  await fs.writeAtomic(
    fs.vaultPath,
    utf8.encode(jsonEncode(<String, Object?>{
      'format': 'llavero-vault',
      'version': version,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'payload': base64Encode(blob),
    })),
  );
}

Map<String, Object?> _envelope(VaultFileSystem fs) =>
    jsonDecode(utf8.decode(fs.bytesAt(fs.vaultPath)!)) as Map<String, Object?>;

void main() {
  test('una bóveda en formato v1 sin keys de campo debe cargarse', () async {
    final crypto = VaultCrypto();
    final dek = await crypto.generateDek();
    final fs = MemoryVaultFileSystem();
    await _writeVault(fs, dek);

    final document = await VaultStorage(initialFileSystem: fs).load(dek);

    expect(document, isNotNull);
    expect(document!.entries.single.title, 'Wi-Fi');
    final fields = document.entries.single.fields;
    expect(fields.first.key, 'ssid');
    expect(fields.last.key, 'password');
  });

  test('una versión más nueva se rechaza con error específico', () async {
    final dek = await VaultCrypto().generateDek();
    final fs = MemoryVaultFileSystem();
    await _writeVault(fs, dek, version: 3);

    expect(
      () => VaultStorage(initialFileSystem: fs).load(dek),
      throwsA(isA<UnsupportedVaultVersionException>()),
    );
  });

  test('tras cargar v1 el archivo es v2, existe v1.bak y vuelve a cargar',
      () async {
    final dek = await VaultCrypto().generateDek();
    final fs = MemoryVaultFileSystem();
    await _writeVault(fs, dek);
    final storage = VaultStorage(initialFileSystem: fs);

    final first = await storage.load(dek);

    expect(_envelope(fs)['version'], 2);
    final backup = fs.bytesAt('${fs.vaultPath}.v1.bak');
    expect(backup, isNotNull);
    expect(
      (jsonDecode(utf8.decode(backup!)) as Map<String, Object?>)['version'],
      1,
    );
    final second = await storage.load(dek);
    expect(second!.entries.length, first!.entries.length);
  });

  test('si falla la copia de seguridad, el archivo original sigue intacto',
      () async {
    final dek = await VaultCrypto().generateDek();
    final fs = _FailingBackupFileSystem();
    await _writeVault(fs, dek);
    final original = fs.bytesAt(fs.vaultPath)!;
    final storage = VaultStorage(initialFileSystem: fs);

    final document = await storage.load(dek);

    expect(document!.entries, hasLength(1));
    expect(fs.bytesAt(fs.vaultPath), original);
  });
}
