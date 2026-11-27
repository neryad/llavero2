import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/security/crypto/backup_crypto.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/kdf.dart';

Map<String, Object?> _json({
  required String type,
  int saltLength = 16,
  int? memoryKiB,
  int? iterations,
  int parallelism = 1,
  int keyBits = 256,
}) =>
    <String, Object?>{
      'type': type,
      'salt': List<int>.filled(saltLength, 1),
      'memoryKiB': memoryKiB,
      'iterations': iterations,
      'parallelism': parallelism,
      'keyBits': keyBits,
    };

void main() {
  test('los parámetros que crea la app están dentro de los límites', () {
    for (final type in KdfType.values) {
      final params = KdfParameters.random(type);
      final json = params.toJson();
      final restored = KdfParameters.fromJson(json);
      expect(restored.type, type);
      expect(restored.salt.length, inInclusiveRange(16, 64));
      expect(restored.parallelism, inInclusiveRange(1, 4));
      expect(restored.keyBits, inInclusiveRange(128, 512));
      if (type == KdfType.argon2id) {
        expect(restored.memoryKiB,
            inInclusiveRange(KdfBounds.minArgon2MemoryKiB, KdfBounds.maxArgon2MemoryKiB));
        expect(restored.iterations,
            inInclusiveRange(KdfBounds.minArgon2Iterations, KdfBounds.maxArgon2Iterations));
      } else {
        expect(restored.iterations,
            inInclusiveRange(KdfBounds.minPbkdf2Iterations, KdfBounds.maxPbkdf2Iterations));
      }
    }

    // Valores históricos y del benchmark.
    for (final memory in <int>[16 * 1024, 32 * 1024, 64 * 1024]) {
      expect(memory,
          inInclusiveRange(KdfBounds.minArgon2MemoryKiB, KdfBounds.maxArgon2MemoryKiB));
    }
    expect(1000,
        inInclusiveRange(KdfBounds.minPbkdf2Iterations, KdfBounds.maxPbkdf2Iterations));
    expect(600000,
        inInclusiveRange(KdfBounds.minPbkdf2Iterations, KdfBounds.maxPbkdf2Iterations));
  });

  test('rechaza valores fuera de rango antes de derivar', () {
    final cases = <Map<String, Object?>>[
      _json(type: 'argon2id', memoryKiB: 1 << 30, iterations: 3),
      _json(type: 'argon2id', memoryKiB: 64 * 1024, iterations: 1000000),
      _json(type: 'pbkdf2-hmac-sha256', iterations: 1 << 30),
      _json(type: 'argon2id', memoryKiB: 64 * 1024, iterations: 3, saltLength: 4),
      _json(type: 'argon2id', memoryKiB: 64 * 1024, iterations: 3, parallelism: 99),
      _json(type: 'argon2id', memoryKiB: 64 * 1024, iterations: 3, keyBits: 9999),
    ];
    for (final json in cases) {
      expect(
        () => KdfParameters.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('un backup con parámetros gigantes se rechaza sin derivar clave', () async {
    final backup = <String, Object?>{
      'format': BackupCrypto.formatId,
      'version': 1,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'kdf': _json(type: 'argon2id', memoryKiB: 1 << 30, iterations: 3),
      'data': base64Encode(<int>[1, 2, 3]),
    };
    expect(
      () => BackupCrypto().decryptBackup(backup, 'contraseña'),
      throwsA(isA<InvalidBackupFileException>()),
    );
  });
}
