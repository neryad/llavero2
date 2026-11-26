import 'package:flutter/material.dart';

/// Identificadores de las categorías por defecto de la bóveda.
///
/// Son identificadores de texto (no un enum) porque el usuario puede crear
/// sus propias categorías más adelante: así podemos guardar en el archivo
/// cifrado un `categoryId` que todavía no existía en la app.
abstract final class CategoryIds {
  static const String wifi = 'wifi';
  static const String email = 'email';
  static const String streaming = 'streaming';
  static const String banking = 'banking';
  static const String pinCode = 'pin_code';
  static const String social = 'social';
  static const String devices = 'devices';
  static const String documents = 'documents';
  static const String other = 'other';
}

/// Colores de cada categoría, guardados en el tema mediante un
/// [ThemeExtension].
///
/// Uso dentro de un widget:
///
/// ```dart
/// final categories = Theme.of(context).extension<CategoryColors>()!;
/// final color = categories.colorOf(entry.categoryId);
/// ```
class CategoryColors extends ThemeExtension<CategoryColors> {
  const CategoryColors({required this.colors, required this.otherColor});

  /// Color por identificador de categoría.
  final Map<String, Color> colors;

  /// Color de reserva para categorías creadas por el usuario.
  final Color otherColor;

  /// Devuelve el color de la categoría indicada.
  ///
  /// Si la categoría no existe (porque es nueva o el archivo viene de una
  /// versión más nueva), devuelve el color de "Otras" en lugar de fallar.
  Color colorOf(String categoryId) => colors[categoryId] ?? otherColor;

  @override
  CategoryColors copyWith({Map<String, Color>? colors, Color? otherColor}) {
    return CategoryColors(
      colors: colors ?? this.colors,
      otherColor: otherColor ?? this.otherColor,
    );
  }

  @override
  CategoryColors lerp(CategoryColors? other, double t) {
    if (other == null) return this;
    // Interpolamos cada color por separado para que las transiciones
    // entre temas se vean suaves.
    final merged = <String, Color>{};
    final allIds = <String>{...colors.keys, ...other.colors.keys};
    for (final id in allIds) {
      final from = colors[id];
      final to = other.colors[id];
      if (from == null || to == null) {
        merged[id] = to ?? from!;
      } else {
        merged[id] = Color.lerp(from, to, t)!;
      }
    }
    return CategoryColors(
      colors: merged,
      otherColor: Color.lerp(otherColor, other.otherColor, t)!,
    );
  }

  /// Colores de las categorías en tema claro.
  static CategoryColors light() {
    return const CategoryColors(
      colors: <String, Color>{
        CategoryIds.wifi: Color(0xFF3E8FB0),
        CategoryIds.email: Color(0xFFC8553D),
        CategoryIds.streaming: Color(0xFF8E5BB5),
        CategoryIds.banking: Color(0xFF4C8C6B),
        CategoryIds.pinCode: Color(0xFFE0A458),
        CategoryIds.social: Color(0xFFD9667F),
        CategoryIds.devices: Color(0xFF5F7175),
        CategoryIds.documents: Color(0xFF7A8F3B),
        CategoryIds.other: Color(0xFF8C7B6B),
      },
      otherColor: Color(0xFF8C7B6B),
    );
  }

  /// Colores de las categorías en tema oscuro.
  ///
  /// Son un poco más claros que en el tema claro para que resalten sobre
  /// el fondo oscuro.
  static CategoryColors dark() {
    return const CategoryColors(
      colors: <String, Color>{
        CategoryIds.wifi: Color(0xFF63AECC),
        CategoryIds.email: Color(0xFFE0836E),
        CategoryIds.streaming: Color(0xFFAC8BD1),
        CategoryIds.banking: Color(0xFF7CC59B),
        CategoryIds.pinCode: Color(0xFFF0B866),
        CategoryIds.social: Color(0xFFE391A4),
        CategoryIds.devices: Color(0xFF97ACB0),
        CategoryIds.documents: Color(0xFFA9C05C),
        CategoryIds.other: Color(0xFFB3A395),
      },
      otherColor: Color(0xFFB3A395),
    );
  }
}
