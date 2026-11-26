/// Espaciado único de la app. Ningún widget debe escribir estos valores a mano.
abstract final class AppSpacing {
  /// Separación vertical entre tarjetas de una lista.
  static const double cardGap = 12;

  /// Padding interior de las tarjetas.
  static const double cardPadding = 16;

  /// Espacio por encima de una cabecera de sección.
  static const double sectionGap = 24;

  /// Espacio entre una cabecera y su primer elemento.
  static const double headerToItem = 12;

  /// Espacio entre el banner de respaldo y la siguiente sección.
  static const double bannerGap = 24;

  /// Espacio entre la barra de búsqueda y los chips.
  static const double searchToChips = 12;

  /// Espacio entre los chips y la primera tarjeta o el banner.
  static const double chipsToList = 16;

  /// Espacio entre chips de una misma fila.
  static const double chipGap = 8;

  /// Padding inferior de las listas (deja sitio al FAB).
  static const double listBottom = 96;

  /// Espacio entre grupos de Ajustes.
  static const double groupGap = 24;

  /// Altura mínima de una fila de Ajustes.
  static const double rowMinHeight = 56;

  /// Escalones genéricos.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
}
