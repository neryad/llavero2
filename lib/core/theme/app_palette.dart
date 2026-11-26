import 'package:flutter/material.dart';

/// Paleta de colores de Llavero.
///
/// Separamos los colores en una clase propia (y no dentro de `ThemeData`)
/// para poder leerlos desde cualquier sitio sin depender del contexto.
///
/// Regla del proyecto: los widgets NUNCA escriben un color literal.
/// Siempre leen del tema, por ejemplo:
///
/// ```dart
/// final color = Theme.of(context).colorScheme.primary;
/// ```
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.textSecondary,
    required this.outline,
    required this.success,
    required this.warning,
    required this.error,
  });

  // ---------------------------------------------------------------- LIGHT
  static const Color lightBackground = Color(0xFFF7F5F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFECE8DF);
  static const Color lightPrimary = Color(0xFF2F5D62);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFFE0A458);
  static const Color lightOnAccent = Color(0xFF2A1B00);
  static const Color lightText = Color(0xFF1B2B2E);
  static const Color lightTextSecondary = Color(0xFF5F7175);
  static const Color lightOutline = Color(0xFFD5D0C5);
  static const Color lightSuccess = Color(0xFF4C8C6B);
  static const Color lightWarning = Color(0xFFD9962B);
  static const Color lightError = Color(0xFFC8553D);

  // ----------------------------------------------------------------- DARK
  static const Color darkBackground = Color(0xFF0F1A1C);
  static const Color darkSurface = Color(0xFF172426);
  static const Color darkSurfaceVariant = Color(0xFF1F3033);
  static const Color darkPrimary = Color(0xFF6FB3B8);
  static const Color darkOnPrimary = Color(0xFF06282B);
  static const Color darkAccent = Color(0xFFF0B866);
  static const Color darkOnAccent = Color(0xFF2A1B00);
  static const Color darkText = Color(0xFFE6EEEE);
  static const Color darkTextSecondary = Color(0xFF8DA3A6);
  static const Color darkOutline = Color(0xFF2E4447);
  static const Color darkSuccess = Color(0xFF7CC59B);
  static const Color darkWarning = Color(0xFFF0B866);
  static const Color darkError = Color(0xFFFF8A73);

  /// Paleta completa del tema claro.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: lightBackground,
    surface: lightSurface,
    surfaceVariant: lightSurfaceVariant,
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    accent: lightAccent,
    onAccent: lightOnAccent,
    text: lightText,
    textSecondary: lightTextSecondary,
    outline: lightOutline,
    success: lightSuccess,
    warning: lightWarning,
    error: lightError,
  );

  /// Paleta completa del tema oscuro.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: darkBackground,
    surface: darkSurface,
    surfaceVariant: darkSurfaceVariant,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    accent: darkAccent,
    onAccent: darkOnAccent,
    text: darkText,
    textSecondary: darkTextSecondary,
    outline: darkOutline,
    success: darkSuccess,
    warning: darkWarning,
    error: darkError,
  );

  final Brightness brightness;

  /// Fondo general de la app.
  final Color background;

  /// Color de las tarjetas y hojas.
  final Color surface;

  /// Color de superficies secundarias (chips, campos, banners).
  final Color surfaceVariant;

  /// Color principal de la marca.
  final Color primary;

  /// Color del texto/íconos sobre [primary].
  final Color onPrimary;

  /// Color de acento (detalles, advertencias, QR...).
  final Color accent;

  /// Color del texto/íconos sobre [accent].
  final Color onAccent;

  /// Texto principal.
  final Color text;

  /// Texto secundario (subtítulos, ayudas).
  final Color textSecondary;

  /// Bordes y separadores.
  final Color outline;

  /// Estado correcto.
  final Color success;

  /// Estado de aviso.
  final Color warning;

  /// Estado de error.
  final Color error;
}
