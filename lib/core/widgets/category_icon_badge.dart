import 'package:flutter/material.dart';

import '../theme/category_colors.dart';
import '../theme/category_icons.dart';

/// Icono de categoría: cuadrado redondeado de 40dp con el color de la
/// categoría al 20 % y el icono en el color pleno (variante clara en dark).
class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    super.key,
    required this.categoryId,
    this.customIconName,
    this.size = 40,
  });

  final String categoryId;
  final String? customIconName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CategoryColors>();
    final color = colors?.colorOf(categoryId) ?? Colors.grey;
    final icon = CategoryIcons.byId(categoryId, customIconName: customIconName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
