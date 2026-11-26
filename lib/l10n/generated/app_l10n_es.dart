// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class L10nEs extends L10n {
  L10nEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Llavero';

  @override
  String get appTagline => 'Todo offline, todo tuyo';

  @override
  String get splashLoading => 'Preparando tu bóveda…';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get okLabel => 'Aceptar';

  @override
  String get backLabel => 'Atrás';

  @override
  String get phase1Title => 'Llavero ya está vivo';

  @override
  String get phase1Message =>
      'La fase 1 está lista: tema, fuentes empaquetadas, idiomas ES/EN y rutas con nombre.';

  @override
  String get notReadyYet => 'Esta pantalla llega en una fase posterior';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get settingsLabel => 'Ajustes';

  @override
  String get homeLabel => 'Inicio';

  @override
  String get onboardingTitle => 'Crea tu bóveda';

  @override
  String get onboardingMessage =>
      'Elige un PIN de 4 a 8 dígitos para proteger tus contraseñas. Lo usarás cada vez que abras la app.';

  @override
  String get createVaultLabel => 'Crear bóveda';

  @override
  String get pinLabel => 'PIN';

  @override
  String get confirmPinLabel => 'Confirmar PIN';

  @override
  String get pinMismatchError =>
      'Los dos PINs no coinciden. Inténtalo de nuevo.';

  @override
  String get pinInvalidError =>
      'El PIN no es válido. Usa 4 a 8 dígitos, sin secuencias, repeticiones ni PINs comunes.';
}
