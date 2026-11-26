import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_scope.dart';

/// Punto de entrada de Llavero.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Los controladores se crean una sola vez y se comparten con toda la app
  // a través del `AppScope`.
  final controllers = await AppControllers.secure();

  // Al arrancar comprobamos si ya existe una bóveda en el dispositivo y
  // recuperamos el estado del bloqueo por intentos fallidos.
  await controllers.lock.initialize();

  runApp(LlaveroApp(controllers: controllers));
}
