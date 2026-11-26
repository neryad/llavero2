import 'dart:async';

import 'package:flutter/widgets.dart';

import '../app_scope.dart';
import '../../controllers/settings_controller.dart';

/// Bloquea la bóveda automáticamente cuando la app pasa a segundo plano.
///
/// El retardo se lee de `SettingsController.autoLockDelay`:
/// `immediately` bloquea al instante; el resto espera antes de bloquear.
/// Si el usuario vuelve antes, se cancela el temporizador.
class AppLifecycleLock extends StatefulWidget {
  const AppLifecycleLock({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleLock> createState() => _AppLifecycleLockState();
}

class _AppLifecycleLockState extends State<AppLifecycleLock>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controllers = AppScope.of(context);
    final delay = controllers.settings.autoLockDelay;

    if (state == AppLifecycleState.resumed) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    final backgrounded = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    if (!backgrounded) return;

    if (delay == AutoLockDelay.immediately) {
      controllers.lock.lock();
      return;
    }

    _timer?.cancel();
    _timer = Timer(delay.duration, () {
      if (!mounted) return;
      AppScope.of(context).lock.lock();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
