import 'package:flutter/foundation.dart';

import '../core/security/crypto/crypto_errors.dart';
import '../core/security/key_vault_service.dart';
import '../core/security/lockout_policy.dart';
import '../core/security/lockout_store.dart';

/// Estado del candado de la bóveda.
///
/// Se ocupa de:
/// - saber si la bóveda está abierta o cerrada,
/// - contar los intentos fallidos y aplicar el bloqueo escalonado,
/// - guardar ese estado en el dispositivo para que sobreviva a reinicios.
///
/// Solo importa `foundation.dart` (y la capa de seguridad, que tampoco
/// depende de la interfaz), así que se puede testear sin montar la app.
class LockController extends ChangeNotifier {
  LockController({
    VaultKeyService? initialKeyService,
    LockoutStore? initialLockoutStore,
    DateTime Function()? clock,
  })  : _keyService = initialKeyService,
        _lockoutStore = initialLockoutStore,
        _clock = clock ?? DateTime.now;

  final VaultKeyService? _keyService;
  final LockoutStore? _lockoutStore;
  final DateTime Function() _clock;

  bool _isLocked = true;
  bool _hasPin = false;
  bool _biometricsEnabled = false;
  LockoutState _lockoutState = LockoutState.initial;
  bool _initialized = false;

  /// `true` cuando la bóveda está cerrada.
  bool get isLocked => _isLocked;

  /// `true` cuando el usuario ya creó un PIN.
  bool get hasPin => _hasPin;

  /// `true` cuando hay una copia de la clave lista para la biometría.
  bool get biometricsEnabled => _biometricsEnabled;

  /// Número de PIN incorrectos seguidos.
  int get failedAttempts => _lockoutState.failedAttempts;

  /// Momento (UTC) hasta el que sigue bloqueada la app.
  DateTime? get lockedUntil => _lockoutState.lockedUntil;

  /// Estado actual del bloqueo.
  LockoutState get lockoutState => _lockoutState;

  /// `true` si la app está bloqueada ahora mismo.
  bool get isLockedOut => _lockoutState.isLockedOut(_clock());

  /// `true` tras [initialize] haber comprobado el estado del dispositivo
  /// (existe bóveda o no).
  ///
  /// Mientras sea `false` el controlador todavía no sabe si hay una bóveda,
  /// así que la interfaz no debe decidir el flujo todavía.
  bool get initialized => _initialized;

  /// Tiempo que queda de bloqueo (cero si no está bloqueada).
  Duration remainingLockout() => _lockoutState.remaining(_clock());

  /// Carga el estado guardado y comprueba si ya existe una bóveda.
  ///
  /// Se llama al arrancar la app.
  Future<void> initialize() async {
    final store = _lockoutStore;
    if (store != null) {
      _lockoutState = await store.load();
    }
    final service = _keyService;
    if (service != null) {
      _hasPin = await service.hasVault();
      _biometricsEnabled = await service.biometricKey() != null;
    }
    _initialized = true;
    notifyListeners();
  }

  /// Intenta abrir la bóveda con el PIN.
  ///
  /// Devuelve `true` si el PIN es correcto. Si es incorrecto, suma un intento
  /// fallido y aplica el bloqueo que corresponda.
  Future<bool> submitPin(String pin) async {
    final service = _keyService;
    if (service == null) {
      throw StateError('LockController necesita un VaultKeyService para validar el PIN.');
    }

    // Si ya está bloqueada, ni siquiera intentamos derivar la clave:
    // así un atacante no puede "gastar" tiempo de la CPU del móvil.
    if (isLockedOut) {
      notifyListeners();
      return false;
    }

    try {
      await service.unlockWithPin(pin);
    } on InvalidPinException {
      await _registerFailedAttempt();
      return false;
    } on MissingVaultException {
      rethrow;
    }

    _lockoutState = _lockoutState.registerSuccess();
    await _persistLockoutState();
    _isLocked = false;
    notifyListeners();
    return true;
  }

  /// Intenta abrir la bóveda con la biometría.
  ///
  /// El PIN sigue siendo el plan B: si la biometría falla, el usuario
  /// escribe el PIN.
  Future<bool> unlockWithBiometrics() async {
    final service = _keyService;
    if (service == null) return false;
    if (isLockedOut) {
      notifyListeners();
      return false;
    }

    final key = await service.biometricKey();
    if (key == null) return false;

    _lockoutState = _lockoutState.registerSuccess();
    await _persistLockoutState();
    _isLocked = false;
    notifyListeners();
    return true;
  }

  /// Cierra la bóveda (por ejemplo al pasar a segundo plano).
  void lock() {
    if (_isLocked) return;
    _isLocked = true;
    notifyListeners();
  }

  /// Crea una nueva bóveda con el PIN (flujo de onboarding).
  ///
  /// Se llama cuando el usuario termina de escribir su PIN por primera vez.
  /// Tras crearla, la bóveda queda **cerrada**: el estado bloqueado le pide al
  /// usuario el PIN (plan B) antes de poder acceder a sus datos.
  Future<void> createVault(String pin) async {
    final service = _keyService;
    if (service == null) {
      throw StateError(
        'LockController necesita un VaultKeyService para crear la bóveda.',
      );
    }

    await service.createVault(pin);

    // La bóveda existe ahora: el usuario ya tiene su PIN.
    _hasPin = true;
    _biometricsEnabled = false;
    _isLocked = true;
    _lockoutState = LockoutState.initial;
    await _persistLockoutState();
    notifyListeners();
  }

  /// Registra que el PIN ya existe (después del onboarding).
  void setHasPin(bool value) {
    if (_hasPin == value) return;
    _hasPin = value;
    notifyListeners();
  }

  /// Activa o desactiva la copia de la clave para biometría.
  Future<void> setBiometricsEnabled(bool value) async {
    if (_biometricsEnabled == value) return;
    _biometricsEnabled = value;
    notifyListeners();
  }

  /// Borra los intentos fallidos (por ejemplo, tras un desbloqueo correcto).
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
    if (_lockoutState.failedAttempts == 0 && _lockoutState.lockedUntil == null) {
      await store.clear();
    } else {
      await store.save(_lockoutState);
    }
  }
}
