import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/lock_controller.dart';
import 'package:llavero2/core/security/crypto/crypto_errors.dart';
import 'package:llavero2/core/security/key_vault_service.dart';
import 'package:llavero2/core/security/lockout_store.dart';
import 'package:llavero2/core/security/vault_problem.dart';

class _ScriptedKeys implements VaultKeyService {
  String correctPin = '482913';
  int calls = 0;
  Object? error;
  Future<void>? block;
  bool throwsOnWrong = true;

  @override
  Future<bool> hasVault() async => true;

  @override
  Future<void> createVault(String pin) async {}

  @override
  Future<SecretKey> unlockWithPin(String pin) async {
    calls++;
    final wait = block;
    if (wait != null) await wait;
    final failure = error;
    if (failure != null) throw failure;
    if (throwsOnWrong && pin != correctPin) throw const InvalidPinException();
    return SecretKey(List<int>.filled(32, 3));
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
  Future<void> eraseEverything() async {}
}

void main() {
  late InMemoryLockoutStore store;
  late _ScriptedKeys service;
  late LockController controller;

  setUp(() {
    store = InMemoryLockoutStore();
    service = _ScriptedKeys();
    controller = LockController(
      initialKeyService: service,
      initialLockoutStore: store,
    );
  });

  test('cuatro fallos y el quinto PIN correcto abre sin bloqueo', () async {
    for (var i = 0; i < 4; i++) {
      expect(await controller.submitPin('111111'), isFalse);
    }
    expect(controller.failedAttempts, 4);

    final gate = Completer<void>();
    service.block = gate.future;
    final future = controller.submitPin('482913');
    await Future<void>.delayed(Duration.zero);

    // El intento ya se persistió, pero todavía no hay castigo aplicado.
    expect(controller.failedAttempts, 5);
    expect(controller.isLockedOut, isFalse);

    gate.complete();
    expect(await future, isTrue);
    expect(controller.failedAttempts, 0);
    expect(controller.isLockedOut, isFalse);
  });

  test('un error que no es PIN equivocado no cuenta el intento', () async {
    service.error = const TamperedDataException();
    expect(await controller.submitPin('111111'), isFalse);
    expect(controller.failedAttempts, 0);
    expect(controller.vaultProblem, VaultProblem.corrupted);

    // Otro error no-PIN tampoco cuenta.
    service.error = const FormatException('parametros');
    expect(await controller.submitPin('111111'), isFalse);
    expect(controller.failedAttempts, 0);
  });

  test('una excepción no bloquea los intentos posteriores', () async {
    service.error = StateError('fallo inesperado');
    expect(await controller.submitPin('111111'), isFalse);

    service.error = null;
    expect(await controller.submitPin('482913'), isTrue);
    expect(controller.failedAttempts, 0);
  });

  test('dos intentos fallidos simultáneos cuentan dos', () async {
    final results = await Future.wait<bool>(<Future<bool>>[
      controller.submitPin('111111'),
      controller.submitPin('222222'),
    ]);
    expect(results, <bool>[false, false]);
    expect(controller.failedAttempts, 2);
  });

  test('el conteo persiste aunque se interrumpa la verificación', () async {
    final gate = Completer<void>();
    service.block = gate.future;
    final future = controller.submitPin('111111');
    await Future<void>.delayed(Duration.zero);

    final restarted = LockController(
      initialKeyService: service,
      initialLockoutStore: store,
    );
    await restarted.initialize();
    expect(restarted.failedAttempts, 1);

    gate.complete();
    await future;
  });
}
