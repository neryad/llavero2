import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/data/models/vault_document.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';

void main() {
  test('un fallo al excluir de iCloud no se presenta como fallo de guardado',
      () async {
    var calls = 0;
    var fail = true;
    final storage = VaultStorage(
      initialFileSystem: MemoryVaultFileSystem(),
      testExclude: (_) async {
        calls++;
        if (fail) throw StateError('sin permiso');
      },
    );
    final key = await VaultCrypto().generateDek();
    final document = VaultDocument(entries: const <VaultEntry>[]);

    await storage.save(document, key);
    expect(calls, 1);

    fail = false;
    await storage.save(document, key);
    // Reintento del pendiente más la exclusión del nuevo guardado.
    expect(calls, 3);
  });
}
