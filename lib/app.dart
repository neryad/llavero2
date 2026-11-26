import 'package:flutter/material.dart';

import 'core/app_scope.dart';
import 'core/widgets/app_lifecycle_lock.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'controllers/settings_controller.dart';
import 'l10n/generated/app_l10n.dart';

/// Raíz de la app.
///
/// Aquí se decide el tema y el idioma, y se cuelga el [AppScope] para que
/// cualquier pantalla pueda leer los controladores. También vigila el candado:
/// si la bóveda se cierra (auto-lock o botón «Bloquear ahora»), vuelve a la
/// pantalla de PIN para que no queden formularios con datos caducados.
class LlaveroApp extends StatefulWidget {
  const LlaveroApp({super.key, required this.controllers});

  /// Clave para poder navegar desde fuera del `MaterialApp`.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Controladores compartidos por toda la app.
  final AppControllers controllers;

  @override
  State<LlaveroApp> createState() => _LlaveroAppState();
}

class _LlaveroAppState extends State<LlaveroApp> {
  bool _wasLocked = true;

  @override
  void initState() {
    super.initState();
    widget.controllers.lock.addListener(_onLockChanged);
    _wasLocked = widget.controllers.lock.isLocked;
  }

  @override
  void dispose() {
    widget.controllers.lock.removeListener(_onLockChanged);
    super.dispose();
  }

  void _onLockChanged() {
    final lock = widget.controllers.lock;
    if (lock.isLocked && !_wasLocked && lock.hasPin) {
      // La bóveda acaba de cerrarse: descartamos pantallas intermedias.
      LlaveroApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.lock,
        (_) => false,
      );
    }
    _wasLocked = lock.isLocked;
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controllers: widget.controllers,
      child: AppLifecycleLock(
        child: ListenableBuilder(
          // Solo hay que reconstruir cuando cambian los ajustes (tema/idioma).
          listenable: widget.controllers.settings,
          builder: (context, _) {
            return MaterialApp(
              navigatorKey: LlaveroApp.navigatorKey,
              title: 'Llavero',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: _themeModeFor(widget.controllers.settings.themeMode),
              locale: _localeFor(widget.controllers.settings.language),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              // Si el idioma del dispositivo no es ninguno de los nuestros,
              // se usa español (es el idioma principal de la app).
              localeResolutionCallback: _resolveLocale,
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRoutes.onGenerateRoute,
            );
          },
        ),
      ),
    );
  }

  /// Decide qué idioma usar cuando el del dispositivo no es es/en.
  static Locale _resolveLocale(
    Locale? deviceLocale,
    Iterable<Locale> supportedLocales,
  ) {
    if (deviceLocale == null) return const Locale('es');
    for (final supported in supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) {
        return supported;
      }
    }
    return const Locale('es');
  }

  /// Traduce el ajuste de tema al `ThemeMode` de Material.
  static ThemeMode _themeModeFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// Traduce el ajuste de idioma al `Locale` de Material.
  static Locale? _localeFor(AppLanguage language) {
    switch (language) {
      case AppLanguage.system:
        return null;
      case AppLanguage.spanish:
        return const Locale('es');
      case AppLanguage.english:
        return const Locale('en');
    }
  }
}
