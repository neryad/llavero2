// Benchmark del KDF dentro de un dispositivo Flutter (emulador o móvil real).
//
// Ejecutar con:
//   flutter run -d <id> -t tool/bench_kdf_device.dart --release
//
// Imprime los tiempos en logcat:
//   adb logcat -d | grep BENCH_KDF
import 'package:flutter/material.dart';

import 'package:llavero2/core/security/crypto/kdf.dart';

Future<void> _bench(String label, int memoryKiB) async {
  final salt = List<int>.generate(16, (i) => i);
  final params = KdfParameters.argon2id(
    salt: salt,
    memoryKiB: memoryKiB,
    iterations: 3,
    parallelism: 1,
  );
  final stopwatch = Stopwatch()..start();
  await params.deriveKey('123456');
  stopwatch.stop();
  debugPrint('BENCH_KDF $label: ${stopwatch.elapsedMilliseconds} ms');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _bench('64 MiB', 64 * 1024);
  await _bench('32 MiB', 32 * 1024);
  await _bench('16 MiB', 16 * 1024);

  // Widget mínimo para mantener el isolate vivo mientras se leen los logs.
  runApp(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));
}
