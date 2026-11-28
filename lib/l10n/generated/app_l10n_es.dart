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

  @override
  String get vaultCreationError =>
      'No se pudo crear la bóveda. Inténtalo de nuevo.';

  @override
  String get unlockLabel => 'Desbloquear';

  @override
  String get biometricUnlockLabel => 'Desbloquear con biometría';

  @override
  String get wrongPinError => 'PIN incorrecto. Inténtalo de nuevo.';

  @override
  String get lockedOutMessage =>
      'Demasiados intentos fallidos. Espera antes de volver a intentarlo.';

  @override
  String get biometricReason => 'Usa tu huella o rostro para abrir Llavero.';

  @override
  String get searchHint => 'Buscar';

  @override
  String get allEntriesLabel => 'Todas';

  @override
  String get favoritesFilterLabel => 'Favoritas';

  @override
  String get addEntryLabel => 'Añadir entrada';

  @override
  String get emptyVaultMessage =>
      'Tu bóveda está vacía. Añade tu primera entrada.';

  @override
  String get trashLabel => 'Papelera';

  @override
  String get newEntryLabel => 'Nueva entrada';

  @override
  String get editEntryLabel => 'Editar entrada';

  @override
  String get titleFieldLabel => 'Título';

  @override
  String get categoryFieldLabel => 'Categoría';

  @override
  String get personFieldLabel => 'Persona';

  @override
  String get notesFieldLabel => 'Notas';

  @override
  String get fieldsLabel => 'Campos';

  @override
  String get addFieldLabel => 'Añadir campo';

  @override
  String get labelFieldLabel => 'Etiqueta';

  @override
  String get valueFieldLabel => 'Valor';

  @override
  String get secretFieldLabel => 'Secreto';

  @override
  String get templateFieldLabel => 'Plantilla';

  @override
  String get generateLabel => 'Generar';

  @override
  String get saveLabel => 'Guardar';

  @override
  String get favoriteLabel => 'Favorita';

  @override
  String get revealLabel => 'Mostrar';

  @override
  String get hideLabel => 'Ocultar';

  @override
  String get copyLabel => 'Copiar';

  @override
  String get moveToTrashLabel => 'Mover a papelera';

  @override
  String get duplicateLabel => 'Duplicar';

  @override
  String get entryNotFound => 'Entrada no encontrada';

  @override
  String get emptyTrashMessage => 'La papelera está vacía.';

  @override
  String get restoreLabel => 'Restaurar';

  @override
  String get deleteForeverLabel => 'Borrar para siempre';

  @override
  String get purgeTrashLabel => 'Vaciar papelera';

  @override
  String get exportImportTitle => 'Exportar / importar';

  @override
  String get backupPasswordLabel => 'Contraseña del respaldo';

  @override
  String get backupWarning => 'Guarda esta contraseña: no se puede recuperar.';

  @override
  String get exportBackupLabel => 'Exportar respaldo (.llavero)';

  @override
  String get importBackupLabel => 'Importar respaldo';

  @override
  String get exportPdfLabel => 'Exportar PDF';

  @override
  String get exportJsonLabel => 'Exportar JSON';

  @override
  String get exportCsvLabel => 'Exportar CSV';

  @override
  String get printLabel => 'Imprimir';

  @override
  String get importSuccess => 'Respaldo importado correctamente.';

  @override
  String get importError => 'No se pudo importar el respaldo.';

  @override
  String get securityStatusLabel => 'Estado de seguridad';

  @override
  String get pinLengthSettingLabel => 'Longitud del PIN';

  @override
  String get autoLockSettingLabel => 'Bloqueo automático';

  @override
  String get autoLockImmediately => 'Inmediato';

  @override
  String get autoLock30Seconds => '30 segundos';

  @override
  String get autoLock1Minute => '1 minuto';

  @override
  String get autoLock5Minutes => '5 minutos';

  @override
  String get blockScreenshotsSettingLabel => 'Bloquear capturas';

  @override
  String get clipboardTimeoutSettingLabel => 'Tiempo en el portapapeles';

  @override
  String get lockNowLabel => 'Bloquear ahora';

  @override
  String get changePinLabel => 'Cambiar PIN';

  @override
  String get currentPinLabel => 'PIN actual';

  @override
  String get newPinLabel => 'Nuevo PIN';

  @override
  String get confirmNewPinLabel => 'Confirmar nuevo PIN';

  @override
  String get pinChangedSuccess => 'PIN cambiado correctamente.';

  @override
  String get wrongCurrentPin => 'El PIN actual no es correcto.';

  @override
  String get pinLossWarning =>
      'Si olvidas el PIN, no hay forma de recuperarlo. Solo podrás restaurar tus datos desde un respaldo cifrado.';

  @override
  String get biometricsNeedsUnlock => 'Disponible solo con la bóveda abierta.';

  @override
  String get screenshotsIosNote =>
      'En iOS no se pueden bloquear las capturas: la app solo oscurece la pantalla al detectarlas.';

  @override
  String get categoriesLabel => 'Categorías';

  @override
  String get newCategoryLabel => 'Nueva categoría';

  @override
  String get editCategoryLabel => 'Editar categoría';

  @override
  String get categoryNameLabel => 'Nombre';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryInUse => 'No se puede borrar: hay entradas que la usan.';

  @override
  String get categoryWifi => 'Wi-Fi';

  @override
  String get categoryEmail => 'Correo';

  @override
  String get categoryStreaming => 'Streaming';

  @override
  String get categoryBanking => 'Banca';

  @override
  String get categoryPin => 'PIN';

  @override
  String get categorySocial => 'Redes sociales';

  @override
  String get categoryDevices => 'Dispositivos';

  @override
  String get categoryDocuments => 'Documentos';

  @override
  String get categoryOther => 'Otras';

  @override
  String get noCustomCategories => 'Todavía no has creado categorías.';

  @override
  String get includeSecretsLabel => 'Incluir secretos en texto plano';

  @override
  String get secretsExportWarning =>
      'Los secretos se guardarán sin cifrar. Cualquiera que lea el archivo podrá verlos.';

  @override
  String get secretsExportConfirm =>
      '¿Confirmas que quieres exportar los secretos en claro?';

  @override
  String get exportAnywayLabel => 'Sí, exportar';

  @override
  String get securityHealthLabel => 'Salud de contraseñas';

  @override
  String healthSummary(int entries, int problems) {
    return '$entries entradas revisadas, $problems problemas';
  }

  @override
  String get weakPasswords => 'Contraseñas débiles';

  @override
  String get reusedPasswords => 'Contraseñas repetidas';

  @override
  String get allGood => 'Todo en orden: no hay avisos.';

  @override
  String get biometricsNotSupported =>
      'La biometría solo está disponible en móvil.';

  @override
  String get screenshotsNotSupported =>
      'El bloqueo de capturas solo está disponible en móvil.';

  @override
  String get webStorageWarning =>
      'En la web los datos se guardan en el navegador, no en un almacén seguro del sistema. Usa la app móvil para mayor seguridad.';

  @override
  String get noSecretsToCheck =>
      'No hay campos secretos todavía. Marca la casilla «Secreto» en los campos de tus entradas para que se revisen.';

  @override
  String healthAllGood(Object count) {
    return '$count contraseñas revisadas, sin avisos.';
  }

  @override
  String get defaultCategoriesLabel => 'Categorías por defecto';

  @override
  String get customCategoriesLabel => 'Tus categorías';

  @override
  String get vaultCorruptedMessage =>
      'No se pudo leer la bóveda. Puede estar dañada. Importa un respaldo para recuperar tus datos.';

  @override
  String get reauthTitle => 'Confirma tu identidad';

  @override
  String get reauthPinLabel => 'PIN';

  @override
  String get reauthBiometricLabel => 'Usar biometría';

  @override
  String get reauthFailed => 'No se pudo confirmar.';

  @override
  String get importModeTitle => '¿Cómo quieres importar?';

  @override
  String get mergeLabel => 'Combinar';

  @override
  String get replaceLabel => 'Reemplazar';

  @override
  String get importConfirm => 'Esto puede sobrescribir tus datos actuales.';

  @override
  String get titleRequired => 'Escribe un título.';

  @override
  String get fieldsRequired => 'Añade al menos un campo.';

  @override
  String get unsavedChangesTitle => '¿Descartar los cambios?';

  @override
  String get unsavedChangesMessage => 'Tienes cambios sin guardar.';

  @override
  String get discardLabel => 'Descartar';

  @override
  String get invalidBackupFile =>
      'El archivo de respaldo no es válido o está dañado.';

  @override
  String get invalidBackupPassword =>
      'La contraseña del respaldo no es correcta.';

  @override
  String get unsupportedBackupVersion =>
      'El respaldo es de una versión más nueva.';

  @override
  String get exportTempError =>
      'No se pudo preparar el archivo para compartir.';

  @override
  String get categoryIconLabel => 'Icono';

  @override
  String get pinLengthHelp =>
      'Elige 4, 6 u 8 dígitos. Más dígitos, más seguridad.';

  @override
  String get pinTooShort => 'El PIN es demasiado corto.';

  @override
  String get pinTooLong => 'El PIN es demasiado largo.';

  @override
  String get pinNotDigits => 'El PIN solo puede tener dígitos.';

  @override
  String get pinRepeated => 'El PIN tiene todos los dígitos iguales.';

  @override
  String get pinSequential => 'El PIN es una secuencia (123456). Elige otro.';

  @override
  String get pinTooCommon => 'Ese PIN es muy común. Elige otro.';

  @override
  String get confirmPinHelp => 'Repite el PIN para confirmarlo.';

  @override
  String get backupReminderTitle => 'Haz una copia de seguridad';

  @override
  String get backupReminderBody =>
      'Tu bóveda solo vive en este dispositivo. Exporta un respaldo cifrado.';

  @override
  String get emptyFavorites => 'Todavía no tienes favoritas.';

  @override
  String get emptyCategories => 'Todavía no tienes categorías.';

  @override
  String get emptyHealth => 'No hay contraseñas que revisar todavía.';

  @override
  String get emptyAction => 'Añadir la primera';

  @override
  String get favoritesSection => 'Favoritas';

  @override
  String get allSection => 'Todas';

  @override
  String get aboutLabel => 'Acerca de';

  @override
  String get aboutText =>
      'Llavero — bóveda offline y cifrada. Hecho para familias.';

  @override
  String get biometricSettingLabel => 'Desbloqueo biométrico';

  @override
  String get securityLabel => 'Seguridad';

  @override
  String get toolsLabel => 'Herramientas';

  @override
  String get appearanceLabel => 'Apariencia';

  @override
  String get templateNetflix => 'Netflix';

  @override
  String get templateDisney => 'Disney+';

  @override
  String get templateSpotify => 'Spotify';

  @override
  String get templateHbo => 'HBO Max';

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String get wifiQrShowLabel => 'Mostrar QR';

  @override
  String get wifiQrHideLabel => 'Ocultar QR';

  @override
  String get wifiQrNote => 'Cualquiera que lo escanee obtiene la contraseña.';

  @override
  String get wifiQrUnavailable =>
      'Faltan la red o la contraseña para generar el QR.';

  @override
  String get filterByCategory => 'Por categoría';

  @override
  String get filterByPerson => 'Por persona';

  @override
  String get wifiMissingSsid => 'Falta el nombre de red';

  @override
  String get otherCategoryHint =>
      'Añade los datos que necesites, como usuario, contraseña o código.';

  @override
  String get shortPins => 'PIN cortos';

  @override
  String get addFieldSheetTitle => 'Añadir campo';

  @override
  String get fieldNameLabel => 'Nombre del campo';

  @override
  String get fieldTypeText => 'Texto';

  @override
  String get fieldTypeSecret => 'Secreto';

  @override
  String get fieldTypePin => 'PIN';

  @override
  String get fieldTypeEmail => 'Correo';

  @override
  String get fieldTypeUrl => 'URL';

  @override
  String get fieldTypePhone => 'Teléfono';

  @override
  String get markAsSecret => 'Marcar como secreto';

  @override
  String get deleteFieldConfirmTitle => '¿Eliminar este campo?';

  @override
  String get deleteFieldConfirmBody => 'El valor de este campo se perderá.';

  @override
  String get replaceFieldsTitle => '¿Reemplazar los campos?';

  @override
  String get replaceFieldsBody =>
      'Los campos actuales se sustituirán por los de la nueva categoría.';

  @override
  String get fieldMenuLabel => 'Opciones del campo';

  @override
  String get recoveryNewerFormat =>
      'Esta bóveda se creó con una versión más nueva de Llavero. Actualiza la app para abrirla.';

  @override
  String get recoveryCorrupted =>
      'No se pudo leer la bóveda. Puede estar dañada.';

  @override
  String get recoveryUnreadable =>
      'No se pudo acceder al archivo de la bóveda. Inténtalo de nuevo.';

  @override
  String get recoveryMissing => 'No se encontró la bóveda en este dispositivo.';

  @override
  String get retryLabel => 'Reintentar';

  @override
  String get startFreshLabel => 'Empezar de cero';

  @override
  String get startFreshConfirmTitle => '¿Empezar de cero?';

  @override
  String get startFreshConfirmBody =>
      'Las entradas dejarán de ser accesibles desde la app. Necesitarás una copia de seguridad para recuperarlas.';

  @override
  String get startFreshConfirmHint => 'Escribe BORRAR para continuar.';

  @override
  String get encryptedBackupSection => 'Copia de seguridad cifrada';

  @override
  String get plainExportSection => 'Exportar sin cifrar';

  @override
  String get plainExportWarning =>
      'Estos archivos muestran tus datos sin protección. Bórralos después de usarlos.';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get passwordStrengthWeak => 'Débil';

  @override
  String get passwordStrengthOk => 'Aceptable';

  @override
  String get passwordStrengthStrong => 'Fuerte';

  @override
  String get backupTip =>
      'Guárdala fuera del teléfono (por ejemplo en tu correo o en la nube).';

  @override
  String importEntriesFound(int count) {
    return '$count entradas en el respaldo';
  }

  @override
  String get replaceConfirmBody =>
      'Las entradas actuales serán reemplazadas por las del respaldo.';

  @override
  String get exportBackupShortLabel => 'Exportar copia';

  @override
  String get legalPrivacyTitle => 'Política de privacidad';

  @override
  String get legalTermsTitle => 'Términos y condiciones';

  @override
  String get legalDocumentUnavailable =>
      'No se pudo cargar el documento legal.';

  @override
  String aboutVersion(String version, String build) {
    return 'Versión $version ($build)';
  }

  @override
  String get aboutTagline => 'Todo offline, todo tuyo';

  @override
  String get aboutParagraph =>
      'Llavero es una bóveda familiar de contraseñas y códigos. Guarda tus secretos cifrados en tu dispositivo y funciona sin internet.';

  @override
  String get aboutSecurityCard =>
      'Sin internet. Sin rastreo. Sin recuperación del PIN: haz tu copia cifrada.';

  @override
  String get aboutBackupAction => 'Hacer copia cifrada';

  @override
  String get aboutMadeBy => 'Hecho por Neryad';

  @override
  String get aboutCopyright => '© 2026 Dayern Gomez (Neryad)';

  @override
  String get aboutContact => 'Contacto';

  @override
  String get copiedSnackbar => 'Copiado';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get onboardingLegalPrefix => 'Al continuar aceptas los ';

  @override
  String get onboardingLegalJoin => ' y la ';

  @override
  String get onboardingLegalSuffix => '.';

  @override
  String get invalidBackupPasswordOrFile =>
      'Contraseña incorrecta o archivo dañado';

  @override
  String get biometricHelper =>
      'Cualquier huella o rostro registrado en este teléfono podrá abrir Llavero.';
}
