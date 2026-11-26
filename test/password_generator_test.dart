import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/security/password_generator.dart';

void main() {
  const generator = PasswordGenerator();

  group('Task 5 — Generador de contraseñas', () {
    test('genera la longitud pedida', () {
      final password = generator.generate(length: 20);
      expect(password, hasLength(20));
    });

    test('incluye al menos un carácter de cada conjunto activo', () {
      final password = generator.generate(length: 16);

      expect(password.contains(RegExp('[A-Z]')), isTrue);
      expect(password.contains(RegExp('[a-z]')), isTrue);
      expect(password.contains(RegExp('[0-9]')), isTrue);
      expect(password.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.?]')), isTrue);
    });

    test('respeta los conjuntos desactivados', () {
      final password = generator.generate(
        length: 12,
        uppercase: false,
        lowercase: false,
        symbols: false,
      );

      expect(password.contains(RegExp('[A-Z]')), isFalse);
      expect(password.contains(RegExp('[a-z]')), isFalse);
      expect(password.contains(RegExp('[^0-9]')), isFalse);
    });

    test('sin conjuntos activos falla', () {
      expect(
        () => generator.generate(
          uppercase: false,
          lowercase: false,
          digits: false,
          symbols: false,
        ),
        throwsArgumentError,
      );
    });

    test('genera PINs numéricos de la longitud pedida', () {
      final pin = generator.generatePin(6);
      expect(pin, hasLength(6));
      expect(pin.contains(RegExp(r'^[0-9]+$')), isTrue);
    });

    test('semillas distintas producen resultados distintos', () {
      final a = generator.generate(length: 16, random: Random(1));
      final b = generator.generate(length: 16, random: Random(2));
      expect(a, isNot(b));
    });
  });
}
