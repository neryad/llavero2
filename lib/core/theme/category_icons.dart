import 'package:flutter/material.dart';

import 'category_colors.dart';

/// Iconos Material por categoría.
///
/// Las categorías por defecto tienen un icono fijo. Las personalizadas guardan
/// el nombre de su icono (ver `VaultCategory.iconName`) y se resuelven aquí.
abstract final class CategoryIcons {
  static const Map<String, IconData> defaults = <String, IconData>{
    CategoryIds.wifi: Icons.wifi,
    CategoryIds.email: Icons.mail_outline,
    CategoryIds.streaming: Icons.play_circle_outline,
    CategoryIds.banking: Icons.account_balance,
    CategoryIds.pinCode: Icons.dialpad,
    CategoryIds.social: Icons.forum_outlined,
    CategoryIds.devices: Icons.router_outlined,
    CategoryIds.documents: Icons.badge_outlined,
    CategoryIds.other: Icons.category_outlined,
  };

  /// Lista curada para que el usuario elija icono en sus categorías.
  static const List<IconData> curated = <IconData>[
    Icons.wifi,
    Icons.mail_outline,
    Icons.play_circle_outline,
    Icons.account_balance,
    Icons.dialpad,
    Icons.forum_outlined,
    Icons.router_outlined,
    Icons.badge_outlined,
    Icons.category_outlined,
    Icons.home_outlined,
    Icons.work_outline,
    Icons.school_outlined,
    Icons.local_hospital_outlined,
    Icons.shopping_cart_outlined,
    Icons.flight_takeoff,
    Icons.directions_car_outlined,
    Icons.pets,
    Icons.favorite_outline,
    Icons.vpn_key_outlined,
    Icons.lock_outline,
    Icons.phone_outlined,
    Icons.computer_outlined,
    Icons.calendar_today_outlined,
    Icons.note_outlined,
  ];

  static IconData byId(String categoryId, {String? customIconName}) {
    final defaultIcon = defaults[categoryId];
    if (defaultIcon != null) return defaultIcon;
    if (customIconName != null) {
      final index = int.tryParse(customIconName);
      if (index != null && index >= 0 && index < curated.length) {
        return curated[index];
      }
    }
    return Icons.category_outlined;
  }

  static String nameOf(IconData icon) => '${icon.codePoint}';
}
