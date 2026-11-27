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

  @override
  String get includeSecretsLabel => 'Include secrets in plain text';

  @override
  String get secretsExportWarning =>
      'Secrets will be saved unencrypted. Anyone reading the file will see them.';

  @override
  String get secretsExportConfirm =>
      'Are you sure you want to export secrets in plain text?';

  @override
  String get exportAnywayLabel => 'Yes, export';

  @override
  String get securityHealthLabel => 'Password health';

  @override
  String healthSummary(int entries, int problems) {
    return '$entries entries reviewed, $problems problems';
  }

  @override
  String get weakPasswords => 'Weak passwords';

  @override
  String get reusedPasswords => 'Reused passwords';

  @override
  String get allGood => 'All good: no warnings.';

  @override
  String get biometricsNotSupported =>
      'Biometrics is only available on mobile.';

  @override
  String get screenshotsNotSupported =>
      'Screenshot blocking is only available on mobile.';

  @override
  String get webStorageWarning =>
      'On the web, data is stored in the browser rather than a system secure vault. Use the mobile app for stronger security.';

  @override
  String get noSecretsToCheck =>
      'There are no secret fields yet. Tick the \"Secret\" box on your entries\' fields so they can be checked.';

  @override
  String healthAllGood(Object count) {
    return '$count passwords checked, no warnings.';
  }

  @override
  String get defaultCategoriesLabel => 'Default categories';

  @override
  String get customCategoriesLabel => 'Your categories';

  @override
  String get vaultCorruptedMessage =>
      'Could not read the vault. It may be damaged. Import a backup to recover your data.';

  @override
  String get reauthTitle => 'Confirm your identity';

  @override
  String get reauthPinLabel => 'PIN';

  @override
  String get reauthBiometricLabel => 'Use biometrics';

  @override
  String get reauthFailed => 'Could not confirm.';

  @override
  String get importModeTitle => 'How do you want to import?';

  @override
  String get mergeLabel => 'Merge';

  @override
  String get replaceLabel => 'Replace';

  @override
  String get importConfirm => 'This may overwrite your current data.';

  @override
  String get titleRequired => 'Enter a title.';

  @override
  String get fieldsRequired => 'Add at least one field.';

  @override
  String get unsavedChangesTitle => 'Discard changes?';

  @override
  String get unsavedChangesMessage => 'You have unsaved changes.';

  @override
  String get discardLabel => 'Discard';

  @override
  String get invalidBackupFile => 'The backup file is invalid or damaged.';

  @override
  String get invalidBackupPassword => 'The backup password is incorrect.';

  @override
  String get unsupportedBackupVersion =>
      'The backup was created with a newer version.';

  @override
  String get exportTempError => 'Could not prepare the file to share.';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get pinLengthHelp =>
      'Choose 4, 6 or 8 digits. More digits, more security.';

  @override
  String get pinTooShort => 'The PIN is too short.';

  @override
  String get pinTooLong => 'The PIN is too long.';

  @override
  String get pinNotDigits => 'The PIN can only contain digits.';

  @override
  String get pinRepeated => 'All digits are the same. Choose another PIN.';

  @override
  String get pinSequential => 'The PIN is a sequence (123456). Choose another.';

  @override
  String get pinTooCommon => 'That PIN is very common. Choose another.';

  @override
  String get confirmPinHelp => 'Enter the PIN again to confirm it.';

  @override
  String get backupReminderTitle => 'Back up your vault';

  @override
  String get backupReminderBody =>
      'Your vault only lives on this device. Export an encrypted backup.';

  @override
  String get emptyFavorites => 'No favorites yet.';

  @override
  String get emptyCategories => 'No categories yet.';

  @override
  String get emptyHealth => 'No passwords to check yet.';

  @override
  String get emptyAction => 'Add the first one';

  @override
  String get favoritesSection => 'Favorites';

  @override
  String get allSection => 'All';

  @override
  String get aboutLabel => 'About';

  @override
  String get aboutText =>
      'Llavero — offline encrypted vault. Made for families.';

  @override
  String get biometricSettingLabel => 'Biometric unlock';

  @override
  String get securityLabel => 'Security';

  @override
  String get toolsLabel => 'Tools';

  @override
  String get appearanceLabel => 'Appearance';

  @override
  String get templateNetflix => 'Netflix';

  @override
  String get templateDisney => 'Disney+';

  @override
  String get templateSpotify => 'Spotify';

  @override
  String get templateHbo => 'HBO Max';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get wifiQrShowLabel => 'Show QR';

  @override
  String get wifiQrHideLabel => 'Hide QR';

  @override
  String get wifiQrNote => 'Anyone who scans it gets the password.';

  @override
  String get wifiQrUnavailable =>
      'Network or password is missing to generate the QR.';

  @override
  String get filterByCategory => 'By category';

  @override
  String get filterByPerson => 'By person';

  @override
  String get wifiMissingSsid => 'Network name is missing';

  @override
  String get otherCategoryHint =>
      'Add the data you need, such as username, password or code.';

  @override
  String get shortPins => 'Short PINs';

  @override
  String get addFieldSheetTitle => 'Add field';

  @override
  String get fieldNameLabel => 'Field name';

  @override
  String get fieldTypeText => 'Text';

  @override
  String get fieldTypeSecret => 'Secret';

  @override
  String get fieldTypePin => 'PIN';

  @override
  String get fieldTypeEmail => 'Email';

  @override
  String get fieldTypeUrl => 'URL';

  @override
  String get fieldTypePhone => 'Phone';

  @override
  String get markAsSecret => 'Mark as secret';

  @override
  String get deleteFieldConfirmTitle => 'Delete this field?';

  @override
  String get deleteFieldConfirmBody => 'The value of this field will be lost.';

  @override
  String get replaceFieldsTitle => 'Replace fields?';

  @override
  String get replaceFieldsBody =>
      'Current fields will be replaced by the new category ones.';

  @override
  String get fieldMenuLabel => 'Field options';

  @override
  String get recoveryNewerFormat =>
      'This vault was created with a newer version of Llavero. Update the app to open it.';

  @override
  String get recoveryCorrupted =>
      'Could not read the vault. It may be damaged.';

  @override
  String get recoveryUnreadable =>
      'Could not access the vault file. Try again.';

  @override
  String get recoveryMissing => 'The vault was not found on this device.';

  @override
  String get retryLabel => 'Retry';

  @override
  String get startFreshLabel => 'Start from scratch';

  @override
  String get startFreshConfirmTitle => 'Start from scratch?';

  @override
  String get startFreshConfirmBody =>
      'The entries will no longer be accessible from the app. You will need a backup to recover them.';

  @override
  String get startFreshConfirmHint => 'Type ERASE to continue.';

  @override
  String get encryptedBackupSection => 'Encrypted backup';

  @override
  String get plainExportSection => 'Unencrypted export';

  @override
  String get plainExportWarning =>
      'These files show your data without protection. Delete them after use.';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthOk => 'OK';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get backupTip =>
      'Keep it off the phone (for example in your email or in the cloud).';

  @override
  String importEntriesFound(int count) {
    return '$count entries in the backup';
  }

  @override
  String get replaceConfirmBody =>
      'Current entries will be replaced by the backup ones.';

  @override
  String get exportBackupShortLabel => 'Export backup';

  @override
  String get legalPrivacyTitle => 'Privacy policy';

  @override
  String get legalTermsTitle => 'Terms and conditions';

  @override
  String get legalDocumentUnavailable =>
      'The legal document could not be loaded.';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get aboutTagline => 'All offline, all yours';

  @override
  String get aboutParagraph =>
      'Llavero is a family vault for passwords and codes. It keeps your encrypted secrets on your device and works without internet.';

  @override
  String get aboutSecurityCard =>
      'No internet. No tracking. No PIN recovery: make your encrypted backup.';

  @override
  String get aboutBackupAction => 'Make encrypted backup';

  @override
  String get aboutMadeBy => 'Made by Neryad';

  @override
  String get aboutCopyright => '© 2026 Dayern Gomez (Neryad)';

  @override
  String get aboutContact => 'Contact';

  @override
  String get copiedSnackbar => 'Copied';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get onboardingLegalPrefix => 'By continuing you accept the ';

  @override
  String get onboardingLegalJoin => ' and the ';

  @override
  String get onboardingLegalSuffix => '.';
}
