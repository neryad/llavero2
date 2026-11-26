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
  String get shareLabel => 'Compartir';

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
  String get includeSecretsLabel => 'Incluir secretos en claro';

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
  String healthSummary(Object count) {
    return 'Contraseñas revisadas: $count';
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
  String get mergeLabel => 'Fusionar';

  @override
  String get replaceLabel => 'Reemplazar todo';

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
}
