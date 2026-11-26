// Benchmark del KDF (herramienta de desarrollo, no forma parte de la app).
//
// Ejecutar con:
//   dart run tool/bench_kdf.dart
//
// Sirve para decidir cuántos bucles de PBKDF2 podemos permitirnos en un
// móvil de gama baja, ya que el paquete `cryptography` usa implementación
// en Dart puro (no hay aceleración nativa sin `cryptography_flutter`).
import 'dart:math';

import 'package:cryptography/cryptography.dart';

Future<int> timeIt(String label, Future<void> Function() action) async {
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();
  final ms = stopwatch.elapsedMilliseconds;
  // ignore: avoid_print
  print('$label: $ms ms');
  return ms;
}

Future<void> main() async {
  const password = '123456';
  final salt = List<int>.generate(16, (i) => i);

  for (final iterations in <int>[100000, 200000, 400000, 600000]) {
    final kdf = Pbkdf2.hmacSha256(iterations: iterations, bits: 256);
    await timeIt('PBKDF2-HMAC-SHA256 $iterations iteraciones', () async {
      await kdf.deriveKeyFromPassword(password: password, nonce: salt);
    });
  }

  // Argon2id: se mide con parámetros×H con hologramas para tener una idea
  // del orden de magnitud (en móvil será más lento, nunca más rápido).
  final argon = Argon2id(
    memory: 65536,
    parallelism: 1,
    iterations: 3,
    hashLength: 32,
  );
  await timeIt('Argon2id (64 MiB, 3 iteraciones, 1 hilo)', () async {
    await argon.deriveKeyFromPassword(password: password, nonce: salt);
  });

  // Coste del cifrado simétrico (el volumen de datos es pequeño).
  final cipher = AesGcm.with256bits();
  final key = SecretKey(List<int>.generate(32, (i) => i));
  final data = List<int>.filled(64 * 1024, 7);
  await timeIt('AES-256-GCM (64 KiB)', () async {
    await cipher.encrypt(data, secretKey: key);
  });

  // Aleatoriedad segura (para el DEK y las sales).
  final random = Random.secure();
  await timeIt('32 bytes aleatorios seguros', () async {
    random.nextInt(1 << 32);
  });
}
