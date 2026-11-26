import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../controllers/entries_controller.dart';
import '../controllers/categories_controller.dart';
import '../controllers/lock_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/settings_store.dart';
import '../core/security/biometric_auth.dart';
import '../core/security/key_vault_service.dart';
import '../core/security/lockout_store.dart';
import '../core/security/secure_store.dart';
import '../data/vault_file_system.dart';
import '../data/vault_storage.dart';
import 'platform/screen_security.dart';

/// Agrupa los controladores de la app y avisa a la interfaz cuando alguno
/// de ellos cambia.
///
/// Así los widgets pueden usar un único `AppScope.of(context)` y se
/// redibujan solos cuando, por ejemplo, el usuario cambia el tema o se
/// bloquea la bóveda.
class AppControllers extends ChangeNotifier {
  AppControllers({
    required this.entries,
    SettingsController? settings,
    LockController? lock,
    CategoriesController? initialCategories,
  })  : settings = settings ?? SettingsController(),
        lock = lock ?? LockController(),
        categories = initialCategories ?? CategoriesController(
          store: InMemorySecureStore(),
        ) {
    // Cada controlador hijo notifica a este contenedor.
    this.settings.addListener(_onControllerChanged);
    this.lock.addListener(_onControllerChanged);
    entries.addListener(_onControllerChanged);
    categories.addListener(_onControllerChanged);
  }

  /// Crea los controladores con la seguridad real del dispositivo:
  /// el almacén seguro del sistema (Keystore en Android, Keychain en iOS)
  /// y el archivo cifrado en la carpeta privada de la app.
  static Future<AppControllers> secure() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final store = FlutterSecureStore();
    final fileSystem = PlatformVaultFileSystem(
      packageName: packageInfo.packageName,
    );
    // Resolver la ruta privada y crear el directorio base antes de cualquier
    // escritura (si no, el primer guardado falla con PathNotFoundException).
    await fileSystem.initialize();
    final storage = VaultStorage(initialFileSystem: fileSystem);
    final controllers = AppControllers(
      lock: LockController(
        initialKeyService: SecureStoreVaultKeyService(initialStore: store),
        initialLockoutStore: SecureStoreLockoutStore(store),
        initialBiometricAuth: DeviceBiometricAuth(),
      ),
      settings: SettingsController(store: SecureSettingsStore(store)),
      entries: EntriesController(
        initialStorage: storage,
        idGenerator: () => const Uuid().v4(),
      ),
      initialCategories: CategoriesController(store: store),
    );
    await controllers.settings.initialize();
    await storage.excludeFromBackup();
    await ScreenSecurity.setScreenshotsBlocked(
      controllers.settings.blockScreenshots,
    );
    await controllers.categories.initialize();
    return controllers;
  }

  /// Preferencias del usuario (idioma, tema, seguridad...).
  final SettingsController settings;

  /// Estado del candado.
  final LockController lock;

  /// Entradas de la bóveda.
  final EntriesController entries;

  /// Categorías personalizadas.
  final CategoriesController categories;

  /// Desbloqueo en curso (si se ha iniciado desde este contenedor).
  Future<void>? _pendingUnlock;

  /// Operación de carga de entradas del último desbloqueo.
  ///
  /// La interfaz puede esperarla antes de navegar para que la Home no
  /// aparezca vacía mientras se descifra el archivo.
  Future<void>? get pendingUnlock => _pendingUnlock;

  /// Desbloquea con PIN y espera a que las entradas estén cargadas.
  Future<bool> unlockWithPin(String pin) async {
    final ok = await lock.submitPin(pin);
    if (ok) {
      try {
        await _pendingUnlock;
      } on Object {
        lock.markVaultCorrupted();
        return false;
      }
    }
    return ok;
  }

  Future<bool> unlockWithBiometrics({required String localizedReason}) async {
    final ok = await lock.unlockWithBiometrics(
      localizedReason: localizedReason,
    );
    if (ok) {
      try {
        await _pendingUnlock;
      } on Object {
        lock.markVaultCorrupted();
        return false;
      }
    }
    return ok;
  }

  bool get vaultCorrupted => lock.vaultCorrupted;

  void _onControllerChanged() {
    // Si la bóveda se bloquea (candado), también debemos limpiar las
    // entradas en memoria para que los secretos no sigan "rodando".
    final lock = this.lock;
    if (lock.isLocked) {
      entries.lock();
      _wasLocked = true;
      _pendingUnlock = null;
    } else if (_wasLocked) {
      // Desbloqueo reciente: cargar las entradas con la DEK desenvuelta.
      final dek = lock.unlockedDek;
      if (dek != null) {
        _pendingUnlock = entries.open(dek);
      }
      _wasLocked = false;
    }
    notifyListeners();
  }

  bool _wasLocked = true;

  @override
  void dispose() {
    settings.removeListener(_onControllerChanged);
    lock.removeListener(_onControllerChanged);
    entries.removeListener(_onControllerChanged);
    categories.removeListener(_onControllerChanged);
    settings.dispose();
    lock.dispose();
    entries.dispose();
    categories.dispose();
    super.dispose();
  }
}

/// Permite acceder a los controladores desde cualquier widget.
///
/// ```dart
/// final settings = AppScope.of(context).settings;
/// ```
class AppScope extends InheritedNotifier<AppControllers> {
  const AppScope({
    super.key,
    required AppControllers controllers,
    required super.child,
  }) : super(notifier: controllers);

  /// Devuelve los controladores de la app.
  ///
  /// Lanza una excepción si se llama fuera del `AppScope`, porque eso
  /// significa que la app no está montada como debe.
  static AppControllers of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No se encontró un AppScope en el árbol de widgets.');
    return scope!.notifier!;
  }
}
