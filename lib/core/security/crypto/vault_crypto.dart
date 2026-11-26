import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'crypto_errors.dart';

/// Cifrado simétrico de la bóveda (AES-256-GCM).
///
/// Idea general (la "caja fuerte"):
///
/// 1. Al crear la bóveda se genera una **DEK** (Data Encryption Key) de
///    256 bits al azar. Esa es la clave con la que se cifra el contenido.
/// 2. La DEK se **envuelve** (se cifra) con una **KEK** (Key Encryption Key)
///    derivada del PIN del usuario con un KDF lento (Argon2id).
/// 3. En el dispositivo solo se guarda la DEK envuelta, la sal y los
///    parámetros del KDF. El PIN nunca se guarda.
///
/// Al desbloquear, se deriva la KEK con el PIN, se desenvuelve la DEK y con
/// ella se abre la bóveda.
class VaultCrypto {
  VaultCrypto();

  /// Longitud de la DEK en bytes (256 bits).
  static const int dekLengthBytes = 32;

  /// Longitud del nonce (vector de inicialización) en bytes.
  static const int nonceLength = 12;

  /// Longitud del código de autenticación (GCM tag) en bytes.
  static const int macLength = 16;

  /// Versión del formato de los datos cifrados.
  static const int formatVersion = 1;

  /// Datos extra ("associated data") al envolver la DEK.
  ///
  /// Sirve para que la DEK solo pueda desenveloparse en el contexto de
  /// Llavero (evita que alguien reutilice el blob en otro sitio).
  ///
  /// Bytes de "llavero:dek-wrap:v1".
  static const List<int> dekWrapAad = <int>[
    108, 108, 97, 118, 101, 114, 111, 58, 100, 101, 107, 45, 119, 114, 97,
    112, 58, 118, 49,
  ];

  /// Datos extra al cifrar el contenido de la bóveda.
  ///
  /// Bytes de "llavero:vault:v1".
  static const List<int> vaultPayloadAad = <int>[
    108, 108, 97, 118, 101, 114, 111, 58, 118, 97, 117, 108, 116, 58, 118, 49,
  ];

  /// Datos extra al cifrar un archivo de respaldo.
  ///
  /// Bytes de "llavero:backup:v1".
  static const List<int> backupAad = <int>[
    108, 108, 97, 118, 101, 114, 111, 58, 98, 97, 99, 107, 117, 112, 58, 118,
    49,
  ];

  final AesGcm _cipher = AesGcm.with256bits();

  /// Genera una DEK aleatoria de 256 bits.
  Future<SecretKey> generateDek() async {
    final random = Random.secure();
    final bytes = List<int>.generate(
      dekLengthBytes,
      (_) => random.nextInt(256),
    );
    return SecretKey(bytes);
  }

  /// Cifra [plainText] con [key] y devuelve un blob autocontenido.
  ///
  /// Formato del blob: `[versión][nonce][mac][cifrado]`
  Future<List<int>> encrypt(
    List<int> plainText,
    SecretKey key, {
    List<int> aad = vaultPayloadAad,
  }) async {
    final secretBox = await _cipher.encrypt(
      plainText,
      secretKey: key,
      aad: aad,
    );
    return _pack(secretBox);
  }

  /// Descifra un blob creado por [encrypt].
  ///
  /// Si alguien ha tocado un solo byte del blob, el código de autenticación
  /// no cuadra y lanzamos [TamperedDataException].
  Future<List<int>> decrypt(
    List<int> blob,
    SecretKey key, {
    List<int> aad = vaultPayloadAad,
  }) async {
    final secretBox = _unpack(blob);
    try {
      return await _cipher.decrypt(
        secretBox,
        secretKey: key,
        aad: aad,
      );
    } on SecretBoxAuthenticationError {
      throw const TamperedDataException();
    }
  }

  /// Envuelve la DEK con una clave derivada del PIN.
  Future<List<int>> wrapDek(SecretKey dek, SecretKey keyFromPin) async {
    final dekBytes = await dek.extractBytes();
    return encrypt(dekBytes, keyFromPin, aad: dekWrapAad);
  }

  /// Desenvuelve la DEK con una clave derivada del PIN.
  ///
  /// Si el PIN es incorrecto, el código de autenticación no cuadra y lanzamos
  /// [InvalidPinException] (que también cubre el caso de un blob dañado).
  Future<SecretKey> unwrapDek(List<int> wrapped, SecretKey keyFromPin) async {
    final List<int> dekBytes;
    try {
      dekBytes = await decrypt(wrapped, keyFromPin, aad: dekWrapAad);
    } on TamperedDataException {
      throw const InvalidPinException();
    }
    return SecretKey(dekBytes);
  }

  /// Cifra el contenido de la bóveda con la DEK.
  Future<List<int>> encryptVault(List<int> plainJson, SecretKey dek) {
    return encrypt(plainJson, dek, aad: vaultPayloadAad);
  }

  /// Descifra el contenido de la bóveda con la DEK.
  Future<List<int>> decryptVault(List<int> blob, SecretKey dek) {
    return decrypt(blob, dek, aad: vaultPayloadAad);
  }

  /// Empaqueta un [SecretBox] en el formato de la app.
  List<int> _pack(SecretBox box) {
    return <int>[
      formatVersion,
      ...box.nonce,
      ...box.mac.bytes,
      ...box.cipherText,
    ];
  }

  /// Desempaqueta el blob en un [SecretBox].
  SecretBox _unpack(List<int> blob) {
    const headerLength = 1 + nonceLength + macLength;
    if (blob.length < headerLength) {
      throw const TamperedDataException();
    }
    if (blob[0] != formatVersion) {
      throw const TamperedDataException(
        'El archivo está en un formato que esta versión no entiende.',
      );
    }
    final nonce = blob.sublist(1, 1 + nonceLength);
    final mac = blob.sublist(1 + nonceLength, headerLength);
    final cipherText = blob.sublist(headerLength);
    return SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
  }
}
