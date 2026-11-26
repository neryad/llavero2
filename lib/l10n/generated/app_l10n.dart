import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_l10n_en.dart';
import 'app_l10n_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Application name shown in the launcher and app bars.
  ///
  /// In en, this message translates to:
  /// **'Llavero'**
  String get appTitle;

  /// Short tagline used on the splash and welcome screens.
  ///
  /// In en, this message translates to:
  /// **'Everything offline, yours to keep'**
  String get appTagline;

  /// Message shown while the app checks if a PIN already exists.
  ///
  /// In en, this message translates to:
  /// **'Preparing your vault…'**
  String get splashLoading;

  /// Generic continue button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Generic cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// Generic confirm button.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// Generic back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// Title of the placeholder screen shown in phase 1.
  ///
  /// In en, this message translates to:
  /// **'Llavero is alive'**
  String get phase1Title;

  /// Body of the placeholder screen shown in phase 1.
  ///
  /// In en, this message translates to:
  /// **'Phase 1 is ready: theme, bundled fonts, ES/EN languages and named routes are all in place.'**
  String get phase1Message;

  /// Placeholder for screens that are not implemented yet.
  ///
  /// In en, this message translates to:
  /// **'This screen arrives in a later phase'**
  String get notReadyYet;

  /// Label of the theme setting.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// Theme option that follows the device setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Label of the language setting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Language option that follows the device setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Spanish language option.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// English language option.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// Title of the home screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeLabel;

  /// Title of the first-run onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Create your vault'**
  String get onboardingTitle;

  /// Body of the first-run onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4 to 8 digit PIN to protect your passwords. You will use it every time you open the app.'**
  String get onboardingMessage;

  /// Button that starts the first-run PIN creation flow.
  ///
  /// In en, this message translates to:
  /// **'Create vault'**
  String get createVaultLabel;

  /// Label of the PIN entry field.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// Label shown on the confirm PIN step.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPinLabel;

  /// Error shown when the create and confirm PINs differ.
  ///
  /// In en, this message translates to:
  /// **'The two PINs do not match. Try again.'**
  String get pinMismatchError;

  /// Error shown when the PIN does not pass the validation rules.
  ///
  /// In en, this message translates to:
  /// **'The PIN is not valid. Use 4 to 8 digits, without sequences, repeats or common PINs.'**
  String get pinInvalidError;

  /// Error shown when creating the vault fails during onboarding.
  ///
  /// In en, this message translates to:
  /// **'Could not create the vault. Please try again.'**
  String get vaultCreationError;

  /// Button that submits the PIN on the lock screen.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockLabel;

  /// Button that starts biometric unlock on the lock screen.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get biometricUnlockLabel;

  /// Error shown after a wrong PIN on the lock screen.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Try again.'**
  String get wrongPinError;

  /// Message shown while the app is locked out after failed PIN attempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please wait before trying again.'**
  String get lockedOutMessage;

  /// Reason shown by the system biometric prompt when unlocking the vault.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint or face to unlock Llavero.'**
  String get biometricReason;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'es':
      return L10nEs();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
