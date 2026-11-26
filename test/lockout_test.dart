import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/crypto/vault_crypto.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_policy.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/controllers/lock_controller.dart';

/// Servicio de claves falso para probar el controlador sin cifrado real.
class FakeVaultKeyService implements VaultKeyService {
  FakeVaultKeyService({this.correctPin = '482913'});

  final String correctPin;

  /// Número de veces que se ha intentado abrir con PIN.
  int pinAttempts = 0;

  bool vaultCreated = false;
  SecretKey? _dek;

  @override
  Future<bool> hasVault() async => vaultCreated;

  @override
  Future<void> createVault(String pin) async {
    vaultCreated = true;
  }

  @override
  Future<SecretKey> unlockWithPin(String pin) async {
    pinAttempts++;
    if (pin != correctPin) {
      throw const InvalidPinException();
    }
    return _dek ??= await VaultCrypto().generateDek();
  }

  @override
  Future<void> changePin(String currentPin, String newPin) async {}

  @override
  Future<void> enableBiometrics(SecretKey dek) async {}

  @override
  Future<void> disableBiometrics() async {}

  @override
  Future<SecretKey?> biometricKey() async => null;

  @override
  Future<void> eraseEverything() async {
    vaultCreated = false;
  }
}

void main() {
  group('Política de bloqueo', () {
    test('no hay bloqueo antes de 5 intentos fallidos', () {
      expect(LockoutPolicy.lockoutFor(0), isNull);
      expect(LockoutPolicy.lockoutFor(4), isNull);
    });

    test('el castigo sube de forma escalonada', () {
      expect(LockoutPolicy.lockoutFor(5), const Duration(seconds: 30));
      expect(LockoutPolicy.lockoutFor(6), const Duration(minutes: 1));
      expect(LockoutPolicy.lockoutFor(7), const Duration(minutes: 5));
      expect(LockoutPolicy.lockoutFor(8), const Duration(minutes: 15));
      expect(LockoutPolicy.lockoutFor(9), const Duration(hours: 1));
    });

    test('a partir del décimo intento sigue siendo una hora', () {
      expect(LockoutPolicy.lockoutFor(10), const Duration(hours: 1));
      expect(LockoutPolicy.lockoutFor(50), const Duration(hours: 1));
    });
  });

  group('Estado del bloqueo', () {
    final inicio = DateTime.utc(2026, 11, 25, 12);

    test('un fallo antes del límite no bloquea', () {
      final estado = LockoutState.initial.registerFailure(inicio);

      expect(estado.failedAttempts, 1);
      expect(estado.isLockedOut(inicio), isFalse);
      expect(estado.lockedUntil, isNull);
    });

    test('el quinto fallo bloquea 30 segundos', () {
      var estado = LockoutState.initial;
      for (var i = 0; i < 5; i++) {
        estado = estado.registerFailure(inicio);
      }

      expect(estado.failedAttempts, 5);
      expect(estado.isLockedOut(inicio), isTrue);
      expect(estado.remaining(inicio), const Duration(seconds: 30));
      expect(estado.lockedUntil, inicio.add(const Duration(seconds: 30)));
    });

    test('la cuenta atrás baja y llega a cero', () {
      var estado = LockoutState.initial;
      for (var i = 0; i < 5; i++) {
        estado = estado.registerFailure(inicio);
      }

      expect(estado.remaining(inicio.add(const Duration(seconds: 10))),
          const Duration(seconds: 20));
      expect(estado.remaining(inicio.add(const Duration(seconds: 30))),
          Duration.zero);
      expect(estado.remaining(inicio.add(const Duration(minutes: 5))),
          Duration.zero);
    });

    test('un acierto borra los intentos anteriores', () {
      var estado = LockoutState.initial;
      for (var i = 0; i < 3; i++) {
        estado = estado.registerFailure(inicio);
      }

      final estadoSinFallos = estado.registerSuccess();

      expect(estadoSinFallos.failedAttempts, 0);
      expect(estadoSinFallos.lockedUntil, isNull);
    });

    test('el estado se guarda y se recupera sin perder información', () {
      var estado = LockoutState.initial;
      for (var i = 0; i < 5; i++) {
        estado = estado.registerFailure(inicio);
      }

      final recuperado = LockoutState.fromJson(estado.toJson());

      expect(recuperado.failedAttempts, 5);
      expect(recuperado.lockedUntil, estado.lockedUntil);
      expect(recuperado.isLockedOut(inicio), isTrue);
    });
  });

  group('LockController', () {
    late FakeVaultKeyService service;
    late InMemoryLockoutStore store;
    late DateTime ahora;
    late LockController controller;

    setUp(() {
      service = FakeVaultKeyService();
      store = InMemoryLockoutStore();
      ahora = DateTime.utc(2026, 11, 25, 12);
      controller = LockController(
        initialKeyService: service,
        initialLockoutStore: store,
        clock: () => ahora,
      );
    });

    test('un PIN correcto abre la bóveda', () async {
      final abierto = await controller.submitPin('482913');

      expect(abierto, isTrue);
      expect(controller.isLocked, isFalse);
      expect(controller.failedAttempts, 0);
    });

    test('un PIN incorrecto suma un intento y no abre', () async {
      final abierto = await controller.submitPin('111111');

      expect(abierto, isFalse);
      expect(controller.isLocked, isTrue);
      expect(controller.failedAttempts, 1);
    });

    test('tras 5 fallos la app queda bloqueada', () async {
      for (var i = 0; i < 5; i++) {
        await controller.submitPin('111111');
      }

      expect(controller.isLockedOut, isTrue);
      expect(controller.remainingLockout(), const Duration(seconds: 30));
    });

    test('mientras está bloqueada no se intenta validar el PIN', () async {
      for (var i = 0; i < 5; i++) {
        await controller.submitPin('111111');
      }
      final intentosAntes = service.pinAttempts;

      final abierto = await controller.submitPin('482913');

      expect(abierto, isFalse);
      expect(service.pinAttempts, intentosAntes);
    });

    test('el PIN correcto limpia el contador de fallos', () async {
      await controller.submitPin('111111');
      await controller.submitPin('111111');
      expect(controller.failedAttempts, 2);

      await controller.submitPin('482913');

      expect(controller.failedAttempts, 0);
    });

    test('el bloqueo sobrevive a reiniciar la app', () async {
      for (var i = 0; i < 5; i++) {
        await controller.submitPin('111111');
      }
      expect(controller.isLockedOut, isTrue);

      // "Reiniciamos" la app: controlador nuevo, mismo almacenamiento.
      final nuevo = LockController(
        initialKeyService: service,
        initialLockoutStore: store,
        clock: () => ahora,
      );
      await nuevo.initialize();

      expect(nuevo.failedAttempts, 5);
      expect(nuevo.isLockedOut, isTrue);
      expect(nuevo.remainingLockout(), const Duration(seconds: 30));
    });

    test('reloj reiniciado a un valor menor no acorta el bloqueo', () async {
      for (var i = 0; i < 5; i++) {
        await controller.submitPin('111111');
      }
      final restante = controller.remainingLockout();
      expect(restante, const Duration(seconds: 30));

      // Simula un reinicio con el reloj movido hacia atrás.
      ahora = ahora.subtract(const Duration(minutes: 10));

      expect(controller.isLockedOut, isTrue);
      expect(controller.remainingLockout(), restante);
      final intentosAntes = service.pinAttempts;
      expect(await controller.submitPin('482913'), isFalse);
      expect(service.pinAttempts, intentosAntes);
    });

    test('al vencer el bloqueo se puede volver a intentar', () async {
      for (var i = 0; i < 5; i++) {
        await controller.submitPin('111111');
      }
      expect(controller.isLockedOut, isTrue);

      // Pasamos 30 segundos.
      ahora = ahora.add(const Duration(seconds: 31));

      expect(controller.isLockedOut, isFalse);
      final abierto = await controller.submitPin('482913');
      expect(abierto, isTrue);
    });

    test('cerrar la bóveda la vuelve a bloquear', () async {
      await controller.submitPin('482913');
      expect(controller.isLocked, isFalse);

      controller.lock();

      expect(controller.isLocked, isTrue);
    });
  });
}
