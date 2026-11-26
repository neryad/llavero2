// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Llavero';

  @override
  String get appTagline => 'Everything offline, yours to keep';

  @override
  String get splashLoading => 'Preparing your vault…';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get okLabel => 'OK';

  @override
  String get backLabel => 'Back';

  @override
  String get phase1Title => 'Llavero is alive';

  @override
  String get phase1Message =>
      'Phase 1 is ready: theme, bundled fonts, ES/EN languages and named routes are all in place.';

  @override
  String get notReadyYet => 'This screen arrives in a later phase';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get homeLabel => 'Home';

  @override
  String get onboardingTitle => 'Create your vault';

  @override
  String get onboardingMessage =>
      'Choose a 4 to 8 digit PIN to protect your passwords. You will use it every time you open the app.';

  @override
  String get createVaultLabel => 'Create vault';

  @override
  String get pinLabel => 'PIN';

  @override
  String get confirmPinLabel => 'Confirm PIN';

  @override
  String get pinMismatchError => 'The two PINs do not match. Try again.';

  @override
  String get pinInvalidError =>
      'The PIN is not valid. Use 4 to 8 digits, without sequences, repeats or common PINs.';
}
