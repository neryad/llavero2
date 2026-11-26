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
  String get vaultCreatedStatus => 'Bóveda creada';

  @override
  String get noVaultStatus => 'Sin bóveda';

  @override
  String get biometricsStatusOn => 'Biometría activada';

  @override
  String get biometricsStatusOff => 'Biometría desactivada';

  @override
  String get failedAttemptsLabel => 'Intentos fallidos';

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
  String get deviceIntegrityLabel => 'Integridad del dispositivo';

  @override
  String get deviceOkStatus => 'Dispositivo íntegro';

  @override
  String get compromisedDeviceWarning =>
      'Este dispositivo parece estar rooteado o jailbreakeado. Tus secretos pueden estar en riesgo.';
}
