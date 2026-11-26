import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/security/pin_validator.dart';

void main() {
  group('PINs válidos', () {
    test('un PIN normal de 6 dígitos es válido', () {
      expect(PinValidator.validate('482913'), PinIssue.ok);
      expect(PinValidator.isValid('573920'), isTrue);
    });

    test('se aceptan longitudes entre 4 y 8 dígitos', () {
      expect(PinValidator.validate('4829'), PinIssue.ok);
      expect(PinValidator.validate('48291357'), PinIssue.ok);
    });
  });

  group('PINs demasiado cortos o largos', () {
    test('menos de 4 dígitos se rechaza', () {
      expect(PinValidator.validate('123'), PinIssue.tooShort);
      expect(PinValidator.validate(''), PinIssue.tooShort);
    });

    test('más de 8 dígitos se rechaza', () {
      expect(PinValidator.validate('123456789'), PinIssue.tooLong);
    });
  });

  group('PINs triviales', () {
    test('todos los dígitos iguales se rechazan', () {
      expect(PinValidator.validate('000000'), PinIssue.repeated);
      expect(PinValidator.validate('1111'), PinIssue.repeated);
    });

    test('las secuencias se rechazan', () {
      expect(PinValidator.validate('123456'), PinIssue.sequential);
      expect(PinValidator.validate('654321'), PinIssue.sequential);
      expect(PinValidator.validate('0123'), PinIssue.sequential);
      expect(PinValidator.validate('987654'), PinIssue.sequential);
    });

    test('los PINs más usados se rechazan', () {
      expect(PinValidator.validate('121212'), PinIssue.tooCommon);
      expect(PinValidator.validate('112233'), PinIssue.tooCommon);
      expect(PinValidator.validate('696969'), PinIssue.tooCommon);
    });
  });

  group('PINs con letras', () {
    test('los caracteres no numéricos se rechazan', () {
      expect(PinValidator.validate('48a913'), PinIssue.notDigits);
      expect(PinValidator.validate('48 913'), PinIssue.notDigits);
      expect(PinValidator.validate('48-913'), PinIssue.notDigits);
    });
  });

  group('Longitud configurada en Ajustes', () {
    test('un PIN de 6 dígitos no es válido si el usuario pide 4', () {
      expect(
        PinValidator.isLengthAsExpected('482913', expectedLength: 4),
        isFalse,
      );
      expect(
        PinValidator.isLengthAsExpected('4829', expectedLength: 4),
        isTrue,
      );
    });

    test('la longitud esperada no invalida un PIN correcto', () {
      expect(PinValidator.validate('4829', expectedLength: 4), PinIssue.ok);
      expect(PinValidator.validate('4829', expectedLength: 6), PinIssue.ok);
    });
  });
}
