import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../core/security/biometric_auth.dart';
import '../core/security/crypto/crypto_errors.dart';
import '../core/security/key_vault_service.dart';
import '../core/security/lockout_policy.dart';
import '../core/security/vault_problem.dart';
import '../core/security/lockout_store.dart';

/// Estado del candado de la bóveda.
class LockController extends ChangeNotifier {
  LockController({
    VaultKeyService? initialKeyService,
    LockoutStore? initialLockoutStore,
    BiometricAuth? initialBiometricAuth,
    DateTime Function()? clock,
  })  : _keyService = initialKeyService,
        _lockoutStore = initialLockoutStore,
        _biometricAuth = initialBiometricAuth,
        _clock = clock ?? DateTime.now;

  final VaultKeyService? _keyService;
  final LockoutStore? _lockoutStore;
  final BiometricAuth? _biometricAuth;
  final DateTime Function() _clock;

  bool _isLocked = true;
  bool _hasPin = false;
  bool _biometricsEnabled = false;
  LockoutState _lockoutState = LockoutState.initial;
  bool _initialized = false;
  VaultProblem? _vaultProblem;

  SecretKey? _unlockedDek;

  /// Serializa los intentos para que dos llamadas simultáneas no se pierdan.
  Future<void> _attemptQueue = Future<void>.value();

  SecretKey? get unlockedDek => _unlockedDek;
  bool get isLocked => _isLocked;
  bool get hasPin => _hasPin;
  bool get biometricsEnabled => _biometricsEnabled;
  int get failedAttempts => _lockoutState.failedAttempts;
  DateTime? get lockedUntil => _lockoutState.lockedUntil;
  LockoutState get lockoutState => _lockoutState;
  bool get initialized => _initialized;

  /// `true` si la bóveda no se pudo abrir (por cualquier motivo concreto).
  bool get vaultCorrupted => _vaultProblem != null;

  /// Motivo concreto por el que no se pudo abrir la bóveda.
  VaultProblem? get vaultProblem => _vaultProblem;

  bool get isLockedOut => _lockoutState.isLockedOut(_clock());
  Duration remainingLockout() => _lockoutState.remaining(_clock());

  Future<void> initialize() async {
    final store = _lockoutStore;
    if (store != null) _lockoutState = await store.load();
    final service = _keyService;
    if (service != null) {
      _hasPin = await service.hasVault();
      _biometricsEnabled = await service.biometricKey() != null;
    }
    _initialized = true;
    notifyListeners();
  }

  /// Avanza la cuenta atrás del castigo (llamado cada segundo por la UI).
  Future<void> tickLockout() async {
    final next = _lockoutState.tick(_clock());
    if (next.remainingMicros == _lockoutState.remainingMicros) return;
    _lockoutState = next;
    await _persistLockoutState();
    notifyListeners();
  }

  Future<bool> submitPin(String pin) => _serialized(() => _submitPin(pin));

  /// Cola con liberación garantizada incluso si el intento lanza excepción.
  Future<T> _serialized<T>(Future<T> Function() action) async {
    final previous = _attemptQueue;
    final completer = Completer<void>();
    _attemptQueue = completer.future;
    try {
      await previous.catchError((Object _) {});
      return await action();
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  }

  Future<bool> _submitPin(String pin) async {
    final service = _keyService;
    if (service == null) {
      throw StateError('LockController necesita un VaultKeyService.');
    }
    if (isLockedOut) {
      notifyListeners();
      return false;
    }

    final before = _lockoutState;
    final attempts = before.failedAttempts + 1;
    // Conteo provisional: todavía no se aplica el castigo. Así un PIN
    // correcto nunca muestra bloqueo, aunque mate la app durante la KDF.
    _lockoutState = LockoutState(failedAttempts: attempts);
    await _persistLockoutState();
    notifyListeners();

    try {
      final dek = await service.unlockWithPin(pin);
      _lockoutState = LockoutState.initial;
      await _persistLockoutState();
      clearVaultProblem();
      _unlockedDek = dek;
      _isLocked = false;
      notifyListeners();
      return true;
    } on InvalidPinException {
      // Único fallo confirmado como PIN equivocado: aquí se aplica el retardo.
      final duration = LockoutPolicy.lockoutFor(attempts);
      final now = _clock();
      _lockoutState = duration == null
          ? LockoutState(failedAttempts: attempts)
          : LockoutState(
              failedAttempts: attempts,
              remainingMicros: duration.inMicroseconds,
              lastSeenMicros: now.microsecondsSinceEpoch,
            );
      await _persistLockoutState();
      notifyListeners();
      return false;
    } on Object catch (error) {
      // Otros fallos no son culpa del usuario: se deshace el conteo.
      _lockoutState = before;
      await _persistLockoutState();
      final problem = switch (error) {
        UnsupportedVaultVersionException() => VaultProblem.newerFormat,
        MissingVaultException() => VaultProblem.missing,
        TamperedDataException() || FormatException() => VaultProblem.corrupted,
        _ => VaultProblem.unreadable,
      };
      if (error is! MissingVaultException) markVaultProblem(problem);
      notifyListeners();
      if (error is MissingVaultException) rethrow;
      return false;
    }
  }

  /// Verifica un PIN sin abrir la bóveda (para re-autenticación).
  Future<bool> verifyPin(String pin) async {
    final service = _keyService;
    if (service == null) return false;
    try {
      await service.unlockWithPin(pin);
      return true;
    } on InvalidPinException {
      await _registerFailedAttempt();
      return false;
    } on TamperedDataException {
      markVaultProblem(VaultProblem.corrupted);
      return false;
    } on FormatException {
      markVaultProblem(VaultProblem.corrupted);
      return false;
    }
  }

  /// Confirma biometría sin abrir la bóveda (para re-autenticación).
  Future<bool> authenticateBiometric() async {
    final auth = _biometricAuth;
    if (auth == null) return false;
    return auth.authenticate(localizedReason: 'Confirma tu identidad');
  }

  Future<bool> unlockWithBiometrics({required String localizedReason}) async {
    final service = _keyService;
    if (service == null) return false;
    if (isLockedOut) {
      notifyListeners();
      return false;
    }

    final auth = _biometricAuth;
    if (auth != null) {
      if (!await auth.authenticate(localizedReason: localizedReason)) {
        return false;
      }
    }

    final key = await service.biometricKey();
    if (key == null) return false;

    _lockoutState = _lockoutState.registerSuccess();
    await _persistLockoutState();
    _unlockedDek = key;
    _isLocked = false;
    notifyListeners();
    return true;
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    final service = _keyService;
    if (service == null) return false;
    if (isLockedOut) return false;
    try {
      await service.changePin(currentPin, newPin);
    } on InvalidPinException {
      await _registerFailedAttempt();
      return false;
    } on TamperedDataException {
      markVaultProblem(VaultProblem.corrupted);
      return false;
    } on FormatException {
      markVaultProblem(VaultProblem.corrupted);
      return false;
    }
    _lockoutState = _lockoutState.registerSuccess();
    await _persistLockoutState();
    notifyListeners();
    return true;
  }

  void lock() {
    if (_isLocked) return;
    _isLocked = true;
    _unlockedDek = null;
    notifyListeners();
  }

  Future<void> createVault(String pin) async {
    final service = _keyService;
    if (service == null) {
      throw StateError('LockController necesita un VaultKeyService.');
    }
    await service.createVault(pin);
    _hasPin = true;
    _biometricsEnabled = false;
    _isLocked = true;
    _lockoutState = LockoutState.initial;
    await _persistLockoutState();
    notifyListeners();
  }

  /// Marca el archivo de la bóveda como dañado (lo detecta el cargador).
  void markVaultCorrupted() => markVaultProblem(VaultProblem.corrupted);

  /// Guarda el motivo concreto sin exponer mensajes internos.
  void markVaultProblem(VaultProblem problem) {
    _vaultProblem = problem;
    notifyListeners();
  }

  void clearVaultProblem() {
    if (_vaultProblem == null) return;
    _vaultProblem = null;
    notifyListeners();
  }

  /// Borra el material de claves para poder crear un PIN nuevo.
  Future<void> eraseKeyMaterial() async {
    final service = _keyService;
    if (service != null) await service.eraseEverything();
    _hasPin = false;
    _biometricsEnabled = false;
    _unlockedDek = null;
    _isLocked = true;
    clearVaultProblem();
    notifyListeners();
  }

  void setHasPin(bool value) {
    if (_hasPin == value) return;
    _hasPin = value;
    notifyListeners();
  }

  /// Activar/desactivar biometría. Desactivar exige re-autenticación previa.
  Future<void> setBiometricsEnabled(
    bool value, {
    bool reauthenticated = false,
  }) async {
    if (_biometricsEnabled == value) return;
    if (!value && !reauthenticated) return;
    final service = _keyService;
    if (service == null) return;

    if (value) {
      final dek = _unlockedDek;
      if (dek == null) return;
      await service.enableBiometrics(dek);
    } else {
      await service.disableBiometrics();
    }
    _biometricsEnabled = value;
    notifyListeners();
  }

  Future<void> resetAttempts() async {
    _lockoutState = _lockoutState.registerSuccess();
    await _persistLockoutState();
    notifyListeners();
  }

  Future<void> _registerFailedAttempt() async {
    _lockoutState = _lockoutState.registerFailure(_clock());
    await _persistLockoutState();
    notifyListeners();
  }

  Future<void> _persistLockoutState() async {
    final store = _lockoutStore;
    if (store == null) return;
    if (_lockoutState.failedAttempts == 0 &&
        _lockoutState.remainingMicros == 0) {
      await store.clear();
    } else {
      await store.save(_lockoutState);
    }
  }
}
