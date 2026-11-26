import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';
import 'category_colors.dart';

/// Construction del `ThemeData` de Llavero.
///
/// Los widgets nunca escriben colores literales: todo sale de aquí.
abstract final class AppTheme {
  /// Radio de las tarjetas.
  static const double cardRadius = 16;

  /// Radio de botones y hojas inferiores.
  static const double controlRadius = 28;

  /// Theme claro.
  static ThemeData light() => _build(AppPalette.light, CategoryColors.light());

  /// Theme oscuro.
  static ThemeData dark() => _build(AppPalette.dark, CategoryColors.dark());

  static ThemeData _build(AppPalette palette, CategoryColors categoryColors) {
    final scheme = ColorScheme(
      brightness: palette.brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primary.withValues(alpha: 0.14),
      // onPrimary/onPrimaryContainer del M3 son ilegibles en los dos temas:
      // el texto del contenedor es el color normal del tema.
      onPrimaryContainer: palette.text,
      secondary: palette.accent,
      onSecondary: palette.onAccent,
      secondaryContainer: palette.accent.withValues(alpha: 0.18),
      onSecondaryContainer: palette.brightness == Brightness.dark
          ? palette.text
          : palette.onAccent,
      tertiary: palette.success,
      onTertiary: palette.onPrimary,
      error: palette.error,
      onError: palette.brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF3A0E06),
      errorContainer: palette.error.withValues(alpha: 0.16),
      onErrorContainer: palette.brightness == Brightness.light
          ? Color.lerp(palette.error, Colors.black, 0.30)!
          : palette.error,
      surface: palette.surface,
      onSurface: palette.text,
      surfaceDim: palette.background,
      surfaceBright: palette.surface,
      surfaceContainerLowest: palette.background,
      surfaceContainerLow: palette.surface,
      surfaceContainer: palette.surfaceVariant,
      surfaceContainerHigh: palette.surfaceVariant,
      surfaceContainerHighest: palette.surfaceVariant,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.outline,
      outlineVariant: palette.outline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: palette.text,
      onInverseSurface: palette.background,
      inversePrimary: palette.primary,
      surfaceTint: palette.primary,
    );

    final textTheme = AppTypography.textTheme(palette.text, palette.textSecondary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      // Material 3 con sombras suaves: la app debe sentirse tranquila,
      // no "técnica".
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: palette.brightness == Brightness.light ? 1 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: palette.outline.withValues(alpha: 0.6)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(
        color: palette.outline.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: palette.outline),
          foregroundColor: palette.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        // Un único estilo para TODOS los segmentos (PIN, tema, idioma, filtros).
        // El color del check se fija aparte: M3 lo toma de onSecondaryContainer,
        // que en dark no tiene suficiente contraste.
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              // En dark el acento es sólido; en light se mantiene el look
              // anterior (acento suave sobre la superficie).
              return palette.brightness == Brightness.dark
                  ? palette.accent
                  : palette.accent.withValues(alpha: 0.18);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            return states.contains(WidgetState.selected)
                ? palette.onAccent
                : palette.text;
          }),
          iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
            return states.contains(WidgetState.selected)
                ? palette.onAccent
                : palette.text;
          }),
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
            return states.contains(WidgetState.selected)
                ? BorderSide.none
                : BorderSide(color: palette.outline);
          }),
          textStyle: WidgetStatePropertyAll<TextStyle>(textTheme.labelLarge!),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceVariant,
        selectedColor: palette.primary.withValues(alpha: 0.16),
        side: BorderSide.none,
        labelStyle: textTheme.labelLarge,
        // En dark el check por defecto (onSecondaryContainer) era casi negro
        // sobre un fondo oscuro: 1.41:1. El texto del tema siempre cumple.
        checkmarkColor: palette.text,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(controlRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius + 4),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.background),
        // En dark el SnackBar tiene fondo claro: el acento (ámbar) daba
        // 1.52:1. El color inverso del fondo garantiza el contraste.
        actionTextColor: palette.brightness == Brightness.dark
            ? palette.background
            : palette.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      // Los colores de categoría viajan con el tema.
      extensions: <ThemeExtension<dynamic>>[categoryColors],
    );
  }
}
