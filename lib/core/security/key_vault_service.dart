import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'crypto/crypto_errors.dart';
import 'crypto/kdf.dart';
import 'crypto/vault_crypto.dart';
import 'secure_store.dart';

/// Servicio que guarda y devuelve la clave de la bóveda.
///
/// Lo usa el `LockController` para abrir y cerrar la bóveda. La interfaz
/// permite testear el controlador con una implementación falsa.
abstract class VaultKeyService {
  /// `true` si el dispositivo ya tiene una bóveda creada.
  Future<bool> hasVault();

  /// Crea la bóveda: genera la DEK y la guarda envuelta con el PIN.
  ///
  /// Falla si ya existe una bóveda.
  Future<void> createVault(String pin);

  /// Abre la bóveda con el PIN y devuelve la DEK.
  ///
  /// Lanza [InvalidPinException] si el PIN no es correcto.
  Future<SecretKey> unlockWithPin(String pin);

  /// Cambia el PIN re-envolviendo la DEK con una KEK nueva.
  ///
  /// Los datos no se re-cifran: solo cambia la clave que envuelve a la DEK.
  /// Lanza [InvalidPinException] si el PIN actual no es correcto.
  Future<void> changePin(String currentPin, String newPin);

  /// Guarda una copia de la DEK para poder abrir con biometría.
  ///
  /// El PIN sigue siendo obligatorio y siempre funciona: la biometría es
  /// solo una comodidad.
  Future<void> enableBiometrics(SecretKey dek);

  /// Borra la copia de la DEK protegida por biometría.
  Future<void> disableBiometrics();

  /// Devuelve la DEK guardada para biometría, si existe.
  ///
  /// IMPORTANTE: quien llama debe haber autenticado con `local_auth` antes.
  Future<SecretKey?> biometricKey();

  /// Borra todo lo guardado en el dispositivo.
  Future<void> eraseEverything();
}

/// Implementación real: la DEK envuelta vive en el almacén seguro del
/// sistema (Keystore en Android, Keychain en iOS).
class SecureStoreVaultKeyService implements VaultKeyService {
  SecureStoreVaultKeyService({
    required SecureStore initialStore,
    VaultCrypto? crypto,
  })  : _store = initialStore,
        _crypto = crypto ?? VaultCrypto();

  final SecureStore _store;
  final VaultCrypto _crypto;

  @override
  Future<bool> hasVault() async {
    final wrapped = await _store.read(SecureStoreKeys.wrappedDek);
    final params = await _store.read(SecureStoreKeys.kdfParameters);
    return wrapped != null && params != null;
  }

  @override
  Future<void> createVault(String pin) async {
    if (await hasVault()) {
      throw const CryptoFailure('Ya existe una bóveda en este dispositivo.');
    }

    // 1. Clave de cifrado de los datos (DEK), aleatoria.
    final dek = await _crypto.generateDek();

    // 2. Clave derivada del PIN (KEK) con un KDF lento y sal aleatoria.
    final params = KdfParameters.random(KdfType.argon2id);
    final kek = await params.deriveKey(pin);

    // 3. Envolvemos la DEK con la KEK y guardamos solo lo envuelto.
    final wrappedDek = await _crypto.wrapDek(dek, kek);

    await _store.write(
      SecureStoreKeys.kdfParameters,
      jsonEncode(params.toJson()),
    );
    await _store.write(
      SecureStoreKeys.wrappedDek,
      base64Encode(wrappedDek),
    );
  }

  @override
  Future<SecretKey> unlockWithPin(String pin) async {
    final wrappedBase64 = await _store.read(SecureStoreKeys.wrappedDek);
    final paramsBase64 = await _store.read(SecureStoreKeys.kdfParameters);
    if (wrappedBase64 == null || paramsBase64 == null) {
      throw const MissingVaultException();
    }

    final params = KdfParameters.fromJson(
      (jsonDecode(paramsBase64) as Map<String, Object?>).cast<String, Object?>(),
    );
    final kek = await params.deriveKey(pin);
    final wrappedDek = base64Decode(wrappedBase64);
    return _crypto.unwrapDek(wrappedDek, kek);
  }

  @override
  Future<void> changePin(String currentPin, String newPin) async {
    final wrappedBase64 = await _store.read(SecureStoreKeys.wrappedDek);
    final paramsJson = await _store.read(SecureStoreKeys.kdfParameters);
    if (wrappedBase64 == null || paramsJson == null) {
      throw const MissingVaultException();
    }

    // 1. Desenvolver la DEK con la KEK derivada del PIN actual.
    final oldParams = KdfParameters.fromJson(
      (jsonDecode(paramsJson) as Map<String, Object?>).cast<String, Object?>(),
    );
    final oldKek = await oldParams.deriveKey(currentPin);
    final dek = await _crypto.unwrapDek(base64Decode(wrappedBase64), oldKek);

    // 2. Nueva sal y nueva KEK derivada del PIN nuevo.
    final newParams = KdfParameters.random(KdfType.argon2id);
    final newKek = await newParams.deriveKey(newPin);
    final newWrapped = await _crypto.wrapDek(dek, newKek);

    // 3. Guardar los parámetros y la DEK envuelta. Se escriben los dos juntos
    //    porque cualquier combinación mixta dejaría la bóveda inabierta.
    await _store.write(
      SecureStoreKeys.kdfParameters,
      jsonEncode(newParams.toJson()),
    );
    await _store.write(
      SecureStoreKeys.wrappedDek,
      base64Encode(newWrapped),
    );
  }

  @override
  Future<void> enableBiometrics(SecretKey dek) async {
    final bytes = await dek.extractBytes();
    await _store.write(SecureStoreKeys.biometricDek, base64Encode(bytes));
  }

  @override
  Future<void> disableBiometrics() async {
    await _store.delete(SecureStoreKeys.biometricDek);
  }

  @override
  Future<SecretKey?> biometricKey() async {
    final encoded = await _store.read(SecureStoreKeys.biometricDek);
    if (encoded == null) return null;
    return SecretKey(base64Decode(encoded));
  }

  @override
  Future<void> eraseEverything() async {
    await _store.deleteAll();
  }
}
