import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/security/crypto/kdf.dart';

void main() {
  const salt = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

  group('Mejora 5 — Memoria configurable de Argon2id', () {
    test('el valor por defecto es 64 MiB', () {
      final params = KdfParameters.argon2id(salt: salt);
      expect(params.memoryKiB, 64 * 1024);
    });

    test('32 MiB se serializa y se recupera sin cambiar el formato', () {
      final params = KdfParameters.argon2id(salt: salt, memoryKiB: 32 * 1024);

      final json = params.toJson();
      expect(json['type'], 'argon2id');
      expect(json['memoryKiB'], 32768);

      final restaurado = KdfParameters.fromJson(json);
      expect(restaurado.memoryKiB, 32768);
      expect(restaurado.type, KdfType.argon2id);
      expect(restaurado.salt, salt);
    });

    test('deriva una clave de 256 bits con 32 MiB', () async {
      final params = KdfParameters.argon2id(salt: salt, memoryKiB: 32 * 1024);
      final key = await params.deriveKey('123456');
      final bytes = await key.extractBytes();

      expect(bytes, hasLength(32));
    });

    test('el JSON tiene las mismas claves a 64 y 32 MiB', () {
      final a = KdfParameters.argon2id(salt: salt).toJson();
      final b = KdfParameters.argon2id(salt: salt, memoryKiB: 32 * 1024).toJson();

      expect(a.keys.toSet(), equals(b.keys.toSet()));
    });
  });
}
