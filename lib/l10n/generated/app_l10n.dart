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

  /// Hint of the search field on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// Filter option that shows all entries.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allEntriesLabel;

  /// Filter option that shows only favorite entries.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesFilterLabel;

  /// Label of the button that creates a new entry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntryLabel;

  /// Message shown when the vault has no entries.
  ///
  /// In en, this message translates to:
  /// **'Your vault is empty. Add your first entry.'**
  String get emptyVaultMessage;

  /// Title of the trash screen and its button on home.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashLabel;

  /// Title of the form when creating an entry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntryLabel;

  /// Title of the form when editing an entry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntryLabel;

  /// Label of the entry title field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleFieldLabel;

  /// Label of the entry category field.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryFieldLabel;

  /// Label of the entry person field.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get personFieldLabel;

  /// Label of the entry notes field.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesFieldLabel;

  /// Section title of the entry fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fieldsLabel;

  /// Button that adds a field to an entry.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get addFieldLabel;

  /// Label of a field's label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelFieldLabel;

  /// Label of a field's value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueFieldLabel;

  /// Checkbox label that hides a field value.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get secretFieldLabel;

  /// Label of the template selector.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get templateFieldLabel;

  /// Button that generates a random password or PIN.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generateLabel;

  /// Button that saves an entry.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// Checkbox label that marks an entry as favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favoriteLabel;

  /// Button that temporarily reveals a secret value.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get revealLabel;

  /// Button that hides a revealed secret value.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideLabel;

  /// Button that copies a value to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// Button that moves an entry to the trash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get moveToTrashLabel;

  /// Button that duplicates an entry.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateLabel;

  /// Message shown when an entry cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Entry not found'**
  String get entryNotFound;

  /// Message shown when the trash has no entries.
  ///
  /// In en, this message translates to:
  /// **'The trash is empty.'**
  String get emptyTrashMessage;

  /// Button that restores an entry from the trash.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreLabel;

  /// Button that permanently deletes an entry.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForeverLabel;

  /// Button that empties the trash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get purgeTrashLabel;

  /// Title of the export and import screen.
  ///
  /// In en, this message translates to:
  /// **'Export / import'**
  String get exportImportTitle;

  /// Label of the backup password field.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get backupPasswordLabel;

  /// Warning shown when exporting an encrypted backup.
  ///
  /// In en, this message translates to:
  /// **'Save this password: it cannot be recovered.'**
  String get backupWarning;

  /// Button that exports an encrypted backup file.
  ///
  /// In en, this message translates to:
  /// **'Export backup (.llavero)'**
  String get exportBackupLabel;

  /// Button that imports an encrypted backup file.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackupLabel;

  /// Button that exports the vault as a PDF.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdfLabel;

  /// Button that exports the vault as JSON.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJsonLabel;

  /// Button that exports the vault as CSV.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsvLabel;

  /// Button that shares an exported file.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// Button that prints the PDF.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printLabel;

  /// Message shown after a successful backup import.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully.'**
  String get importSuccess;

  /// Message shown when a backup import fails.
  ///
  /// In en, this message translates to:
  /// **'Could not import the backup.'**
  String get importError;

  /// Section title of the security status on settings.
  ///
  /// In en, this message translates to:
  /// **'Security status'**
  String get securityStatusLabel;

  /// Status shown when the vault exists.
  ///
  /// In en, this message translates to:
  /// **'Vault created'**
  String get vaultCreatedStatus;

  /// Status shown when there is no vault yet.
  ///
  /// In en, this message translates to:
  /// **'No vault'**
  String get noVaultStatus;

  /// Status shown when biometrics is enabled.
  ///
  /// In en, this message translates to:
  /// **'Biometrics enabled'**
  String get biometricsStatusOn;

  /// Status shown when biometrics is disabled.
  ///
  /// In en, this message translates to:
  /// **'Biometrics disabled'**
  String get biometricsStatusOff;

  /// Label of the failed PIN attempts counter.
  ///
  /// In en, this message translates to:
  /// **'Failed attempts'**
  String get failedAttemptsLabel;

  /// Setting that controls how many digits the PIN has.
  ///
  /// In en, this message translates to:
  /// **'PIN length'**
  String get pinLengthSettingLabel;

  /// Setting that controls when the vault locks itself.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get autoLockSettingLabel;

  /// Auto-lock option: lock when the app goes to background.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get autoLockImmediately;

  /// Auto-lock option: 30 seconds.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get autoLock30Seconds;

  /// Auto-lock option: 1 minute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get autoLock1Minute;

  /// Auto-lock option: 5 minutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get autoLock5Minutes;

  /// Setting that blocks screenshots and screen recording.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots'**
  String get blockScreenshotsSettingLabel;

  /// Setting that controls how long copied secrets stay in the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard timeout'**
  String get clipboardTimeoutSettingLabel;

  /// Button that locks the vault immediately.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get lockNowLabel;

  /// Button and title of the change PIN screen.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePinLabel;

  /// Label of the current PIN field when changing it.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPinLabel;

  /// Label of the new PIN field.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPinLabel;

  /// Label of the new PIN confirmation field.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get confirmNewPinLabel;

  /// Message shown after changing the PIN.
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully.'**
  String get pinChangedSuccess;

  /// Error shown when the current PIN is wrong.
  ///
  /// In en, this message translates to:
  /// **'The current PIN is incorrect.'**
  String get wrongCurrentPin;

  /// Warning shown before creating a PIN so the user knows there is no recovery without a backup.
  ///
  /// In en, this message translates to:
  /// **'If you forget your PIN, it cannot be recovered. You will only be able to restore your data from an encrypted backup.'**
  String get pinLossWarning;

  /// Explanation shown when the biometrics switch is disabled because the vault is locked.
  ///
  /// In en, this message translates to:
  /// **'Only available while the vault is unlocked.'**
  String get biometricsNeedsUnlock;

  /// Label of the device integrity check in settings.
  ///
  /// In en, this message translates to:
  /// **'Device integrity'**
  String get deviceIntegrityLabel;

  /// Status shown when no root/jailbreak signals were found.
  ///
  /// In en, this message translates to:
  /// **'Device intact'**
  String get deviceOkStatus;

  /// Warning shown when root or jailbreak signals are detected.
  ///
  /// In en, this message translates to:
  /// **'This device appears to be rooted or jailbroken. Your secrets may be at risk.'**
  String get compromisedDeviceWarning;

  /// Note shown on iOS explaining that screenshot blocking is an overlay, not a system block.
  ///
  /// In en, this message translates to:
  /// **'On iOS, screenshots cannot be blocked: the app only dims the screen when it detects them.'**
  String get screenshotsIosNote;
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
