import 'package:flutter/foundation.dart';

import 'settings_store.dart';

/// Tema que elige el usuario.
///
/// Lo guardamos como enum propio (y no como `ThemeMode` de Material) para que
/// los controladores no dependan de la interfaz: la capa de UI convierte
/// este valor en el `ThemeMode` que entiende Flutter.
enum AppThemeMode {
  /// Sigue al sistema operativo.
  system,

  /// Siempre claro.
  light,

  /// Siempre oscuro.
  dark,
}

/// Idioma de la interfaz.
enum AppLanguage {
  /// Sigue al idioma del sistema.
  system,

  /// Español.
  spanish,

  /// Inglés.
  english,
}

/// Tiempo que la app espera antes de bloquearse sola.
enum AutoLockDelay {
  /// Se bloquea en cuanto la app pasa a segundo plano.
  immediately,

  /// 30 segundos.
  thirtySeconds,

  /// 1 minuto.
  oneMinute,

  /// 5 minutos.
  fiveMinutes;

  /// Duración real de este retardo.
  Duration get duration {
    switch (this) {
      case AutoLockDelay.immediately:
        return Duration.zero;
      case AutoLockDelay.thirtySeconds:
        return const Duration(seconds: 30);
      case AutoLockDelay.oneMinute:
        return const Duration(minutes: 1);
      case AutoLockDelay.fiveMinutes:
        return const Duration(minutes: 5);
    }
  }
}

/// Preferencias del usuario.
///
/// Este controlador NO importa nada de la interfaz (solo `foundation.dart`),
/// así que se puede probar con `flutter test` sin levantar la app.
class SettingsController extends ChangeNotifier {
  SettingsController({
    AppThemeMode initialThemeMode = AppThemeMode.system,
    AppLanguage initialLanguage = AppLanguage.system,
    AutoLockDelay initialAutoLockDelay = AutoLockDelay.immediately,
    bool initialBlockScreenshots = true,
    int initialClipboardTimeoutSeconds = 30,
    int initialPinLength = 6,
    this._store,
  })  : _themeMode = initialThemeMode,
        _language = initialLanguage,
        _autoLockDelay = initialAutoLockDelay,
        _blockScreenshots = initialBlockScreenshots,
        _clipboardTimeoutSeconds = initialClipboardTimeoutSeconds,
        _pinLength = initialPinLength;

  final SettingsStore? _store;
  AppThemeMode _themeMode;
  AppLanguage _language;
  AutoLockDelay _autoLockDelay;
  bool _blockScreenshots;
  int _clipboardTimeoutSeconds;
  int _pinLength;
  DateTime? _lastBackupAt;

  /// Tema elegido por el usuario.
  AppThemeMode get themeMode => _themeMode;

  /// Idioma elegido por el usuario.
  AppLanguage get language => _language;

  /// Retardo de bloqueo automático.
  AutoLockDelay get autoLockDelay => _autoLockDelay;

  /// Si se bloquean las capturas de pantalla (activado por defecto).
  bool get blockScreenshots => _blockScreenshots;

  /// Segundos que el texto copiado permanece en el portapapeles.
  int get clipboardTimeoutSeconds => _clipboardTimeoutSeconds;

  /// Número de dígitos del PIN (4 a 8).
  int get pinLength => _pinLength;

  /// Fecha del último respaldo cifrado correcto (solo la fecha, nunca la clave).
  DateTime? get lastBackupAt => _lastBackupAt;

  /// Carga los ajustes guardados (llamado al arrancar).
  Future<void> initialize() async {
    final values = await _store?.load();
    if (values == null) return;
    _themeMode = _read(values['themeMode'], AppThemeMode.values, _themeMode);
    _language = _read(values['language'], AppLanguage.values, _language);
    _autoLockDelay = _read(
      values['autoLockDelay'],
      AutoLockDelay.values,
      _autoLockDelay,
    );
    _blockScreenshots = values['blockScreenshots'] as bool? ?? _blockScreenshots;
    _clipboardTimeoutSeconds =
        values['clipboardTimeoutSeconds'] as int? ?? _clipboardTimeoutSeconds;
    _pinLength = values['pinLength'] as int? ?? _pinLength;
    final savedBackup = values['lastBackupAt'] as String?;
    _lastBackupAt =
        savedBackup == null ? null : DateTime.tryParse(savedBackup)?.toUtc();
    notifyListeners();
  }

  static T _read<T>(Object? value, List<T> values, T fallback) {
    final index = value as int?;
    if (index == null || index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  Future<void> _persist() async {
    await _store?.save(<String, Object?>{
      'themeMode': _themeMode.index,
      'language': _language.index,
      'autoLockDelay': _autoLockDelay.index,
      'blockScreenshots': _blockScreenshots,
      'clipboardTimeoutSeconds': _clipboardTimeoutSeconds,
      'pinLength': _pinLength,
      'lastBackupAt': _lastBackupAt?.toUtc().toIso8601String(),
    });
  }

  void setThemeMode(AppThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    _persist();
    notifyListeners();
  }

  void setLanguage(AppLanguage value) {
    if (_language == value) return;
    _language = value;
    _persist();
    notifyListeners();
  }

  void setAutoLockDelay(AutoLockDelay value) {
    if (_autoLockDelay == value) return;
    _autoLockDelay = value;
    _persist();
    notifyListeners();
  }

  void setBlockScreenshots(bool value) {
    if (_blockScreenshots == value) return;
    _blockScreenshots = value;
    _persist();
    notifyListeners();
  }

  void setClipboardTimeoutSeconds(int value) {
    if (_clipboardTimeoutSeconds == value) return;
    _clipboardTimeoutSeconds = value;
    _persist();
    notifyListeners();
  }

  void setPinLength(int value) {
    if (_pinLength == value) return;
    _pinLength = value;
    _persist();
    notifyListeners();
  }

  /// Guarda solo cuándo se hizo el último respaldo, nunca su contraseña.
  Future<void> setLastBackupAt(DateTime value) async {
    _lastBackupAt = value.toUtc();
    await _persist();
    notifyListeners();
  }
}
