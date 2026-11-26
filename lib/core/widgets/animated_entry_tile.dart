import 'package:flutter/material.dart';

/// Tarjeta que aparece con una animación sutil de fundido y desplazamiento.
///
/// Respeta la preferencia del sistema de reducir animaciones
/// (`MediaQuery.disableAnimations`): en ese caso muestra el contenido directo,
/// sin movimiento.
class AnimatedEntryTile extends StatelessWidget {
  const AnimatedEntryTile({
    super.key,
    required this.index,
    required this.child,
  });

  /// Posición en la lista: se usa para escalonar la animación.
  final int index;

  /// Contenido de la tarjeta.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return child;

    final delay = Duration(milliseconds: (index * 30).clamp(0, 240));

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260) + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
