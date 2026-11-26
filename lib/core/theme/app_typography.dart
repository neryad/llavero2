import 'package:flutter/material.dart';

/// Tipografías de Llavero.
///
/// - "Plus Jakarta Sans" para toda la interfaz.
/// - "JetBrains Mono" para secretos, PIN y códigos (cifras tabulares para
///   que los números no "bailen" al escribirlos).
///
/// Las dos fuentes están empaquetadas como assets, así que la app funciona
/// sin conexión. No usamos `google_fonts`.
abstract final class AppTypography {
  static const String uiFont = 'Plus Jakarta Sans';
  static const String monoFont = 'JetBrains Mono';

  /// Escala tipográfica de la interfaz.
  static TextTheme textTheme(Color text, Color textSecondary) {
    // Todas las escalas usan la fuente de la interfaz. Antes no se indicaba
    // fontFamily y Flutter caía en Roboto aunque la fuente estuviera en pubspec.
    const family = uiFont;
    return TextTheme(
      // Display 32/700
      displaySmall: TextStyle(
        fontFamily: family,
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      // Headline 24/700
      headlineMedium: TextStyle(
        fontFamily: family,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      // Title 18/600
      titleLarge: TextStyle(
        fontFamily: family,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      // Body 16/400
      bodyLarge: TextStyle(
        fontFamily: family,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: text,
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      // Label 13/600
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      labelMedium: TextStyle(
        fontFamily: family,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: family,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
    );
  }

  /// Estilo mono 18/500 para secretos, PIN y códigos.
  static const TextStyle mono18 = TextStyle(
    fontFamily: monoFont,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  /// Versión pequeña del estilo mono (etiquetas, QR, códigos cortos).
  static const TextStyle mono14 = TextStyle(
    fontFamily: monoFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );
}
