import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Tipo de función de derivación de clave (KDF).
enum KdfType {
  /// Argon2id: resistente a GPUs y ASIC, es la opción por defecto.
  argon2id,

  /// PBKDF2-HMAC-SHA256: alternativa más compatible.
  pbkdf2;

  /// Nombre estable (se guarda en el archivo cifrado).
  String get name {
    switch (this) {
      case KdfType.argon2id:
        return 'argon2id';
      case KdfType.pbkdf2:
        return 'pbkdf2-hmac-sha256';
    }
  }

  /// Lee el tipo a partir de su nombre.
  static KdfType fromName(String name) {
    for (final type in KdfType.values) {
      if (type.name == name) return type;
    }
    throw FormatException('Tipo de KDF desconocido: $name');
  }
}

/// Memoria por defecto para Argon2id, en KiB.
///
/// Se puede ajustar al compilar sin cambiar el formato del archivo:
///   flutter build apk --dart-define=LLAVERO_KDF_MEMORY_KIB=32768
///
/// El valor elegido viaja en la cabecera de cada bóveda, así que las bóvedas
/// creadas con otra memoria siguen abriéndose normalmente.
const int kDefaultArgon2MemoryKiB =
    int.fromEnvironment('LLAVERO_KDF_MEMORY_KIB', defaultValue: 64 * 1024);

/// Parámetros del KDF: qué algoritmo se usó, con qué sal y con qué coste.
///
/// Estos parámetros se guardan (sin cifrar, no son secretos) junto a los
/// datos cifrados. Así una versión futura de la app puede leer archivos
/// antiguos aunque cambie el KDF, y también permite que un backup creado
/// con otro KDF se pueda importar.
class KdfParameters {
  const KdfParameters({
    required this.type,
    required this.salt,
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    required this.keyBits,
  });

  /// Argon2id con 64 MiB de memoria y 3 pasadas.
  ///
  /// Medido en este proyecto (ver `tool/bench_kdf.dart`): 64 MiB / 3
  /// pasadas ≈ 0,4 s en un portátil moderno y ≈ 1–2 s en un móvil de
  /// gama baja. Es más rápido **y** más seguro frente a ataques con GPU
  /// que PBKDF2 con 600 000 iteraciones (≈ 1,8 s aquí).
  factory KdfParameters.argon2id({
    required List<int> salt,
    int memoryKiB = kDefaultArgon2MemoryKiB,
    int iterations = 3,
    int parallelism = 1,
    int keyBits = 256,
  }) {
    return KdfParameters(
      type: KdfType.argon2id,
      salt: salt,
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
      keyBits: keyBits,
    );
  }

  /// PBKDF2-HMAC-SHA256 con 600 000 iteraciones (mínimo recomendado).
  factory KdfParameters.pbkdf2({
    required List<int> salt,
    int iterations = 600000,
    int keyBits = 256,
  }) {
    return KdfParameters(
      type: KdfType.pbkdf2,
      salt: salt,
      memoryKiB: 0,
      iterations: iterations,
      parallelism: 1,
      keyBits: keyBits,
    );
  }

  /// Crea parámetros con sal aleatoria segura.
  factory KdfParameters.random(
    KdfType type, {
    int saltLength = 16,
    Random? random,
  }) {
    final rng = random ?? Random.secure();
    final salt = List<int>.generate(saltLength, (_) => rng.nextInt(256));
    switch (type) {
      case KdfType.argon2id:
        return KdfParameters.argon2id(salt: salt);
      case KdfType.pbkdf2:
        return KdfParameters.pbkdf2(salt: salt);
    }
  }

  /// Algoritmo usado.
  final KdfType type;

  /// Sal (bytes aleatorios). No es secreto: se puede guardar en claro.
  final List<int> salt;

  /// Memoria en KiB (solo para Argon2id).
  final int memoryKiB;

  /// Iteraciones (Argon2id: pasadas; PBKDF2: bucles).
  final int iterations;

  /// Hilos en paralelo (solo para Argon2id).
  final int parallelism;

  /// Longitud de la clave derivada en bits.
  final int keyBits;

  /// Deriva la clave a partir de una contraseña (el PIN).
  Future<SecretKey> deriveKey(String password) async {
    switch (type) {
      case KdfType.argon2id:
        final argon2id = Argon2id(
          memory: memoryKiB,
          parallelism: parallelism,
          iterations: iterations,
          hashLength: keyBits ~/ 8,
        );
        return argon2id.deriveKeyFromPassword(password: password, nonce: salt);
      case KdfType.pbkdf2:
        final pbkdf2 = Pbkdf2.hmacSha256(
          iterations: iterations,
          bits: keyBits,
        );
        return pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
    }
  }

  /// Convierte los parámetros a JSON (se guardan en la cabecera del archivo).
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type.name,
      'salt': base64Encode(salt),
      'memoryKiB': memoryKiB,
      'iterations': iterations,
      'parallelism': parallelism,
      'keyBits': keyBits,
    };
  }

  /// Lee los parámetros desde JSON.
  factory KdfParameters.fromJson(Map<String, Object?> json) {
    return KdfParameters(
      type: KdfType.fromName(json['type'] as String),
      salt: base64Decode(json['salt'] as String),
      memoryKiB: (json['memoryKiB'] as int?) ?? 0,
      iterations: json['iterations'] as int,
      parallelism: (json['parallelism'] as int?) ?? 1,
      keyBits: (json['keyBits'] as int?) ?? 256,
    );
  }
}
