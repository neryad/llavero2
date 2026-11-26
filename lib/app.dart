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
/// cualquier pantalla pueda leer los controladores.
class LlaveroApp extends StatelessWidget {
  const LlaveroApp({super.key, required this.controllers});

  /// Controladores compartidos por toda la app.
  final AppControllers controllers;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controllers: controllers,
      child: AppLifecycleLock(
        child: ListenableBuilder(
          // Solo hay que reconstruir cuando cambian los ajustes (tema/idioma).
          listenable: controllers.settings,
        builder: (context, _) {
          return MaterialApp(
            title: 'Llavero',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _themeModeFor(controllers.settings.themeMode),
            locale: _localeFor(controllers.settings.language),
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
  ///
  /// El español es el idioma principal de Llavero, así que si el móvil está
  /// en un idioma que no soportamos, mostramos español.
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
  ///
  /// `null` significa "sigue al idioma del sistema".
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
