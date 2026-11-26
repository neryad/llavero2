import 'dart:async';

import 'package:flutter/services.dart';

/// Copia secretos al portapapeles y los borra automáticamente.
///
/// En Android/iOS una app en segundo plano **no puede manipular** el
/// portapapeles de forma fiable (Android 10+ restringe el acceso a apps en
/// background; iOS tampoco lo permite). Por eso la limpieza al pasar a
/// segundo plano se hace "best effort": solo se garantiza si la app aún tiene
/// ciclo de vida activo en el momento del evento.
class ClipboardService {
  ClipboardService({this.clearOnBackground = true});

  /// Instante compartido por la UI y el observador de ciclo de vida.
  static final ClipboardService instance = ClipboardService();

  final bool clearOnBackground;
  Timer? _timer;

  /// Copia [text] y programa su borrado tras [timeout].
  Future<void> copySecret(String text, Duration timeout) async {
    _timer?.cancel();
    await Clipboard.setData(ClipboardData(text: text));
    if (timeout <= Duration.zero) {
      await clear();
      return;
    }
    _timer = Timer(timeout, clear);
  }

  /// Limpia el portapapeles y cancela el temporizador.
  Future<void> clear() async {
    _timer?.cancel();
    _timer = null;
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  /// Llamar al pasar a segundo plano.
  Future<void> onBackground() async {
    if (!clearOnBackground) return;
    try {
      await clear();
    } on Object {
      // Best effort: sin binding o sin permiso no se puede limpiar.
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
