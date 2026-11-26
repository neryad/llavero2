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

  @override
  String get vaultCreationError =>
      'Could not create the vault. Please try again.';

  @override
  String get unlockLabel => 'Unlock';

  @override
  String get biometricUnlockLabel => 'Unlock with biometrics';

  @override
  String get wrongPinError => 'Incorrect PIN. Try again.';

  @override
  String get lockedOutMessage =>
      'Too many failed attempts. Please wait before trying again.';

  @override
  String get biometricReason =>
      'Use your fingerprint or face to unlock Llavero.';

  @override
  String get searchHint => 'Search';

  @override
  String get allEntriesLabel => 'All';

  @override
  String get favoritesFilterLabel => 'Favorites';

  @override
  String get addEntryLabel => 'Add entry';

  @override
  String get emptyVaultMessage => 'Your vault is empty. Add your first entry.';

  @override
  String get trashLabel => 'Trash';

  @override
  String get newEntryLabel => 'New entry';

  @override
  String get editEntryLabel => 'Edit entry';

  @override
  String get titleFieldLabel => 'Title';

  @override
  String get categoryFieldLabel => 'Category';

  @override
  String get personFieldLabel => 'Person';

  @override
  String get notesFieldLabel => 'Notes';

  @override
  String get fieldsLabel => 'Fields';

  @override
  String get addFieldLabel => 'Add field';

  @override
  String get labelFieldLabel => 'Label';

  @override
  String get valueFieldLabel => 'Value';

  @override
  String get secretFieldLabel => 'Secret';

  @override
  String get templateFieldLabel => 'Template';

  @override
  String get generateLabel => 'Generate';

  @override
  String get saveLabel => 'Save';

  @override
  String get favoriteLabel => 'Favorite';

  @override
  String get revealLabel => 'Show';

  @override
  String get hideLabel => 'Hide';

  @override
  String get copyLabel => 'Copy';

  @override
  String get moveToTrashLabel => 'Move to trash';

  @override
  String get duplicateLabel => 'Duplicate';

  @override
  String get entryNotFound => 'Entry not found';

  @override
  String get emptyTrashMessage => 'The trash is empty.';

  @override
  String get restoreLabel => 'Restore';

  @override
  String get deleteForeverLabel => 'Delete forever';

  @override
  String get purgeTrashLabel => 'Empty trash';

  @override
  String get exportImportTitle => 'Export / import';

  @override
  String get backupPasswordLabel => 'Backup password';

  @override
  String get backupWarning => 'Save this password: it cannot be recovered.';

  @override
  String get exportBackupLabel => 'Export backup (.llavero)';

  @override
  String get importBackupLabel => 'Import backup';

  @override
  String get exportPdfLabel => 'Export PDF';

  @override
  String get exportJsonLabel => 'Export JSON';

  @override
  String get exportCsvLabel => 'Export CSV';

  @override
  String get shareLabel => 'Share';

  @override
  String get printLabel => 'Print';

  @override
  String get importSuccess => 'Backup imported successfully.';

  @override
  String get importError => 'Could not import the backup.';

  @override
  String get securityStatusLabel => 'Security status';

  @override
  String get vaultCreatedStatus => 'Vault created';

  @override
  String get noVaultStatus => 'No vault';

  @override
  String get biometricsStatusOn => 'Biometrics enabled';

  @override
  String get biometricsStatusOff => 'Biometrics disabled';

  @override
  String get failedAttemptsLabel => 'Failed attempts';

  @override
  String get pinLengthSettingLabel => 'PIN length';

  @override
  String get autoLockSettingLabel => 'Auto-lock';

  @override
  String get autoLockImmediately => 'Immediately';

  @override
  String get autoLock30Seconds => '30 seconds';

  @override
  String get autoLock1Minute => '1 minute';

  @override
  String get autoLock5Minutes => '5 minutes';

  @override
  String get blockScreenshotsSettingLabel => 'Block screenshots';

  @override
  String get clipboardTimeoutSettingLabel => 'Clipboard timeout';

  @override
  String get lockNowLabel => 'Lock now';

  @override
  String get changePinLabel => 'Change PIN';

  @override
  String get currentPinLabel => 'Current PIN';

  @override
  String get newPinLabel => 'New PIN';

  @override
  String get confirmNewPinLabel => 'Confirm new PIN';

  @override
  String get pinChangedSuccess => 'PIN changed successfully.';

  @override
  String get wrongCurrentPin => 'The current PIN is incorrect.';

  @override
  String get pinLossWarning =>
      'If you forget your PIN, it cannot be recovered. You will only be able to restore your data from an encrypted backup.';

  @override
  String get biometricsNeedsUnlock =>
      'Only available while the vault is unlocked.';

  @override
  String get deviceIntegrityLabel => 'Device integrity';

  @override
  String get deviceOkStatus => 'Device intact';

  @override
  String get compromisedDeviceWarning =>
      'This device appears to be rooted or jailbroken. Your secrets may be at risk.';

  @override
  String get screenshotsIosNote =>
      'On iOS, screenshots cannot be blocked: the app only dims the screen when it detects them.';

  @override
  String get categoriesLabel => 'Categories';

  @override
  String get newCategoryLabel => 'New category';

  @override
  String get editCategoryLabel => 'Edit category';

  @override
  String get categoryNameLabel => 'Name';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryInUse => 'Cannot delete: entries still use it.';

  @override
  String get categoryWifi => 'Wi-Fi';

  @override
  String get categoryEmail => 'Email';

  @override
  String get categoryStreaming => 'Streaming';

  @override
  String get categoryBanking => 'Banking';

  @override
  String get categoryPin => 'PIN';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryDevices => 'Devices';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryOther => 'Other';

  @override
  String get noCustomCategories => 'You haven\'t created any categories yet.';
}
