import 'dart:math';

/// Generador de contraseñas y PINs aleatorios.
///
/// Usa `Random.secure()` para que las contraseñas no sean predecibles.
/// Garantiza al menos un carácter de cada conjunto seleccionado.
class PasswordGenerator {
  const PasswordGenerator();

  /// Conjuntos de caracteres disponibles.
  static const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String digitChars = '0123456789';
  static const String symbolChars = '!@#\$%^&*()-_=+[]{};:,.?';

  /// Genera una contraseña de [length] caracteres.
  ///
  /// Se pueden activar o desactivar conjuntos, pero al menos uno debe
  /// quedar activo. Se garantiza un carácter de cada conjunto activo.
  String generate({
    int length = 16,
    bool uppercase = true,
    bool lowercase = true,
    bool digits = true,
    bool symbols = true,
    Random? random,
  }) {
    final rng = random ?? Random.secure();
    final sets = <String>[
      if (uppercase) uppercaseChars,
      if (lowercase) lowercaseChars,
      if (digits) digitChars,
      if (symbols) symbolChars,
    ];
    if (sets.isEmpty) {
      throw ArgumentError('Debes activar al menos un conjunto de caracteres.');
    }
    if (length < sets.length) {
      throw ArgumentError(
        'La longitud ($length) debe ser al menos el número de conjuntos activos (${sets.length}).',
      );
    }

    final chars = <String>[];

    // Una de cada conjunto activo.
    for (final set in sets) {
      chars.add(set[rng.nextInt(set.length)]);
    }

    // El resto al azar de todos los conjuntos.
    final all = sets.join();
    for (var i = chars.length; i < length; i++) {
      chars.add(all[rng.nextInt(all.length)]);
    }

    // Mezclar para que la posición de los caracteres obligatorios no sea
    // predecible.
    for (var i = chars.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }

    return chars.join();
  }

  /// Genera un PIN numérico de [length] dígitos.
  String generatePin(int length, {Random? random}) {
    if (length < 1) {
      throw ArgumentError.value(length, 'length', 'debe ser al menos 1');
    }
    final rng = random ?? Random.secure();
    final chars = <String>[];
    for (var i = 0; i < length; i++) {
      chars.add(digitChars[rng.nextInt(digitChars.length)]);
    }
    return chars.join();
  }
}
