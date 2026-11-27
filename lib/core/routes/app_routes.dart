import 'package:flutter/material.dart';

import '../../features/home/home_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/categories_screen.dart';
import '../../features/security/security_health_screen.dart';
import '../../features/settings/change_pin_screen.dart';
import '../../features/export_import/export_import_screen.dart';
import '../../features/entries/entry_detail_screen.dart';
import '../../features/entries/entry_form_screen.dart';
import '../../features/legal/legal_document.dart';
import '../../features/lock/lock_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/shared/coming_soon_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/trash/trash_screen.dart';

/// Rutas con nombre de la app.
///
/// Usamos el `Navigator` de Flutter con rutas con nombre (sin paquetes
/// extra). Todas las pantallas cuelgan de [onGenerateRoute].
abstract final class AppRoutes {
  /// Pantalla de inicio: decide entre onboarding y pantalla de bloqueo.
  static const String splash = '/';

  /// Primera configuración (solo la primera vez que se abre la app).
  static const String onboarding = '/onboarding';

  /// Pantalla del PIN.
  static const String lock = '/lock';

  /// Listado de entradas.
  static const String home = '/home';

  /// Detalle de una entrada.
  static const String entryDetail = '/entry/detail';

  /// Alta / edición de una entrada.
  static const String entryForm = '/entry/form';

  /// Papelera.
  static const String trash = '/trash';

  /// Exportar / importar.
  static const String exportImport = '/export-import';

  /// Ajustes.
  static const String settings = '/settings';

  /// Cambiar el PIN de la bóveda.
  static const String changePin = '/settings/change-pin';

  /// Categorías personalizadas.
  static const String categories = '/settings/categories';

  /// Estado de seguridad de las contraseñas.
  static const String securityHealth = '/security-health';

  /// Documentos legales (política y términos).
  static const String legal = '/legal';

  /// Genera la pantalla correspondiente a cada ruta.
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return _build(const SplashScreen(), routeSettings);
      case onboarding:
        return _build(const OnboardingScreen(), routeSettings);
      case home:
        return _build(const HomeScreen(), routeSettings);
      case lock:
        return _build(const LockScreen(), routeSettings);
      case entryDetail:
        final id = routeSettings.arguments as String?;
        if (id == null || id.isEmpty) {
          return _build(const ComingSoonScreen(), routeSettings);
        }
        return _build(EntryDetailScreen(entryId: id), routeSettings);
      case entryForm:
        return _build(
          EntryFormScreen(
            args: routeSettings.arguments as EntryFormArgs? ??
                const EntryFormArgs(),
          ),
          routeSettings,
        );
      case trash:
        return _build(const TrashScreen(), routeSettings);
      case exportImport:
        return _build(const ExportImportScreen(), routeSettings);
      case settings:
        return _build(const SettingsScreen(), routeSettings);
      case categories:
        return _build(const CategoriesScreen(), routeSettings);
      case changePin:
        return _build(const ChangePinScreen(), routeSettings);
      case securityHealth:
        return _build(const SecurityHealthScreen(), routeSettings);
      case legal:
        return _build(
          LegalDocumentScreen(
            kind: routeSettings.arguments as LegalDocumentKind? ??
                LegalDocumentKind.privacy,
          ),
          routeSettings,
        );
      default:
        return _build(const ComingSoonScreen(), routeSettings);
    }
  }

  static MaterialPageRoute<dynamic> _build(
    Widget page,
    RouteSettings routeSettings,
  ) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => page,
      settings: routeSettings,
    );
  }
}
