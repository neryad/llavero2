/// Problemas que puede tener un PIN.
///
/// El usuario ve un mensaje según el resultado, para que entienda *por qué*
/// su PIN no es válido.
enum PinIssue {
  /// El PIN es válido.
  ok,

  /// Tiene menos dígitos de los permitidos.
  tooShort,

  /// Tiene más dígitos de los permitidos.
  tooLong,

  /// Contiene caracteres que no son dígitos.
  notDigits,

  /// Todos los dígitos son iguales (000000).
  repeated,

  /// Es una secuencia ascendente o descendente (123456, 654321).
  sequential,

  /// Es un PIN muy usado y fácil de adivinar.
  tooCommon,
}

/// Valida los PIN de Llavero.
///
/// Reglas:
/// - Solo dígitos.
/// - De 4 a 8 dígitos (6 por defecto, configurable en Ajustes).
/// - Se rechazan los PIN "triviales": todos los dígitos iguales, secuencias
///   y los más usados del mundo.
abstract final class PinValidator {
  /// Longitud mínima por defecto permitida.
  static const int minLength = 4;

  /// Longitud máxima por defecto permitida.
  static const int maxLength = 8;

  /// PINs que se rechazan porque son demasiado habituales.
  static const Set<String> _commonPins = <String>{
    '000000', '111111', '222222', '333333', '444444', '555555',
    '666666', '777777', '888888', '999999',
    '123456', '654321', '123123', '321321', '121212', '212121',
    '112233', '332211', '102030', '696969', '131313', '520520',
    '159753', '987654', '456789', '000111', '111000',
    '147258', '258369', '363636', '010101',
  };

  /// Comprueba un PIN y devuelve el primer problema encontrado.
  ///
  /// [expectedLength] es la longitud configurada en Ajustes (6 por
  /// defecto). Si no se indica, se usa [defaultLength].
  static PinIssue validate(
    String pin, {
    int expectedLength = defaultLength,
    int minimumLength = minLength,
    int maximumLength = maxLength,
  }) {
    if (pin.isEmpty) return PinIssue.tooShort;
    if (pin.length < minimumLength) return PinIssue.tooShort;
    if (pin.length > maximumLength) return PinIssue.tooLong;
    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) return PinIssue.notDigits;
    if (_isRepeated(pin)) return PinIssue.repeated;
    if (_isSequential(pin)) return PinIssue.sequential;
    if (_commonPins.contains(pin)) return PinIssue.tooCommon;
    // La longitud configurada es una recomendación, no un error: si el
    // usuario la cambia en Ajustes, se respeta. Solo avisamos si el PIN no
    // cumple, mediante [isLengthAsExpected].
    if (pin.length != expectedLength) return PinIssue.ok;
    return PinIssue.ok;
  }

  /// `true` si el PIN no tiene ningún problema.
  static bool isValid(
    String pin, {
    int expectedLength = defaultLength,
    int minimumLength = minLength,
    int maximumLength = maxLength,
  }) {
    return validate(
      pin,
      expectedLength: expectedLength,
      minimumLength: minimumLength,
      maximumLength: maximumLength,
    ) == PinIssue.ok;
  }

  /// `true` si el PIN tiene la longitud configurada en Ajustes.
  static bool isLengthAsExpected(String pin, {int expectedLength = defaultLength}) {
    return pin.length == expectedLength;
  }

  /// Longitud por defecto del PIN.
  static const int defaultLength = 6;

  /// Todos los dígitos son iguales (000000, 1111...).
  static bool _isRepeated(String pin) {
    final first = pin[0];
    for (final digit in pin.split('')) {
      if (digit != first) return false;
    }
    return true;
  }

  /// Los dígitos son una secuencia ascendente o descendente (123456).
  static bool _isSequential(String pin) {
    if (pin.length < 2) return false;
    final ascending = _isStep(pin, 1);
    final descending = _isStep(pin, -1);
    return ascending || descending;
  }

  static bool _isStep(String pin, int step) {
    for (var i = 1; i < pin.length; i++) {
      final previous = pin.codeUnitAt(i - 1) - 0x30;
      final current = pin.codeUnitAt(i) - 0x30;
      if (current - previous != step) return false;
    }
    return true;
  }
}
