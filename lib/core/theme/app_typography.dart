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
    return TextTheme(
      // Display 32/700
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      // Headline 24/700
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      // Title 18/600
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      // Body 16/400
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: text,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      // Label 13/600
      labelLarge: TextStyle(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
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
