import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../core/security/biometric_auth.dart';
import '../core/security/crypto/crypto_errors.dart';
import '../core/security/key_vault_service.dart';
import '../core/security/lockout_policy.dart';
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
  bool _vaultCorrupted = false;

  SecretKey? _unlockedDek;

  SecretKey? get unlockedDek => _unlockedDek;
  bool get isLocked => _isLocked;
  bool get hasPin => _hasPin;
  bool get biometricsEnabled => _biometricsEnabled;
  int get failedAttempts => _lockoutState.failedAttempts;
  DateTime? get lockedUntil => _lockoutState.lockedUntil;
  LockoutState get lockoutState => _lockoutState;
  bool get initialized => _initialized;

  /// `true` si el archivo de la bóveda está dañado y no se pudo abrir.
  bool get vaultCorrupted => _vaultCorrupted;

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

  Future<bool> submitPin(String pin) async {
    final service = _keyService;
    if (service == null) {
      throw StateError('LockController necesita un VaultKeyService.');
    }
    if (isLockedOut) {
      notifyListeners();
      return false;
    }

    final SecretKey dek;
    try {
      dek = await service.unlockWithPin(pin);
    } on InvalidPinException {
      await _registerFailedAttempt();
      return false;
    } on MissingVaultException {
      rethrow;
    } on TamperedDataException {
      _vaultCorrupted = true;
      notifyListeners();
      return false;
    }

    _lockoutState = _lockoutState.registerSuccess();
    await _persistLockoutState();
    _unlockedDek = dek;
    _vaultCorrupted = false;
    _isLocked = false;
    notifyListeners();
    return true;
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
      _vaultCorrupted = true;
      notifyListeners();
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
      _vaultCorrupted = true;
      notifyListeners();
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
  void markVaultCorrupted() {
    _vaultCorrupted = true;
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
