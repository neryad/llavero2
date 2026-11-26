import 'package:flutter/foundation.dart';

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
  })  : _themeMode = initialThemeMode,
        _language = initialLanguage,
        _autoLockDelay = initialAutoLockDelay,
        _blockScreenshots = initialBlockScreenshots,
        _clipboardTimeoutSeconds = initialClipboardTimeoutSeconds,
        _pinLength = initialPinLength;

  AppThemeMode _themeMode;
  AppLanguage _language;
  AutoLockDelay _autoLockDelay;
  bool _blockScreenshots;
  int _clipboardTimeoutSeconds;
  int _pinLength;

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

  void setThemeMode(AppThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
  }

  void setLanguage(AppLanguage value) {
    if (_language == value) return;
    _language = value;
    notifyListeners();
  }

  void setAutoLockDelay(AutoLockDelay value) {
    if (_autoLockDelay == value) return;
    _autoLockDelay = value;
    notifyListeners();
  }

  void setBlockScreenshots(bool value) {
    if (_blockScreenshots == value) return;
    _blockScreenshots = value;
    notifyListeners();
  }

  void setClipboardTimeoutSeconds(int value) {
    if (_clipboardTimeoutSeconds == value) return;
    _clipboardTimeoutSeconds = value;
    notifyListeners();
  }

  void setPinLength(int value) {
    if (_pinLength == value) return;
    _pinLength = value;
    notifyListeners();
  }
}
