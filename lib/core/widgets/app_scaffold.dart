import 'package:flutter/material.dart';

/// Contenedor estándar de las pantallas.
///
/// Añade tres cosas que repetimos en toda la app:
/// - respeta las zonas seguras (notch, barra de gestos),
/// - limita el ancho del contenido a 720dp en tablets,
/// - aplica el fondo del tema.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  /// Contenido de la pantalla.
  final Widget body;

  /// Barra superior opcional.
  final PreferredSizeWidget? appBar;

  /// Botón flotante opcional.
  final Widget? floatingActionButton;

  /// Barra inferior opcional.
  final Widget? bottomNavigationBar;

  /// Espacio entre el borde y el contenido.
  final EdgeInsetsGeometry padding;

  /// Ancho máximo del contenido en pantallas grandes.
  static const double maxContentWidth = 720;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(padding: padding, child: body),
          ),
        ),
      ),
    );
  }
}
