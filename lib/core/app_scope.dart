import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../controllers/entries_controller.dart';
import '../controllers/lock_controller.dart';
import '../controllers/settings_controller.dart';
import '../core/security/key_vault_service.dart';
import '../core/security/biometric_auth.dart';
import '../core/security/lockout_store.dart';
import '../core/security/secure_store.dart';
import '../data/vault_file_system.dart';
import '../data/vault_storage.dart';

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
  })  : settings = settings ?? SettingsController(),
        lock = lock ?? LockController() {
    // Cada controlador hijo notifica a este contenedor.
    this.settings.addListener(_onControllerChanged);
    this.lock.addListener(_onControllerChanged);
    entries.addListener(_onControllerChanged);
  }

  /// Crea los controladores con la seguridad real del dispositivo:
  /// el almacén seguro del sistema (Keystore en Android, Keychain en iOS)
  /// y el archivo cifrado en la carpeta privada de la app.
  static Future<AppControllers> secure() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final store = FlutterSecureStore();
    return AppControllers(
      lock: LockController(
        initialKeyService: SecureStoreVaultKeyService(initialStore: store),
        initialLockoutStore: SecureStoreLockoutStore(store),
        initialBiometricAuth: DeviceBiometricAuth(),
      ),
      entries: EntriesController(
        initialStorage: VaultStorage(
          initialFileSystem: PlatformVaultFileSystem(packageName: packageInfo.packageName),
        ),
      ),
    );
  }

  /// Preferencias del usuario (idioma, tema, seguridad...).
  final SettingsController settings;

  /// Estado del candado.
  final LockController lock;

  /// Entradas de la bóveda.
  final EntriesController entries;

  void _onControllerChanged() {
    // Si la bóveda se bloquea (candado), también debemos limpiar las
    // entradas en memoria para que los secretos no sigan "rodando".
    final lock = this.lock;
    if (lock.isLocked) {
      entries.lock();
      _wasLocked = true;
    } else if (_wasLocked) {
      // Desbloqueo reciente: cargar las entradas con la DEK desenvuelta.
      final dek = lock.unlockedDek;
      if (dek != null) {
        entries.load(dek);
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
    settings.dispose();
    lock.dispose();
    entries.dispose();
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
