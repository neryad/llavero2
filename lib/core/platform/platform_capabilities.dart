import 'dart:io';

import 'package:flutter/foundation.dart';

/// Funciones disponibles según la plataforma.
///
/// En móvil (Android/iOS) están todas. En escritorio y web algunas no
/// existen: la interfaz debe deshabilitarlas y explicarlo, en lugar de
/// dejar interruptores que no hacen nada.
class PlatformCapabilities {
  const PlatformCapabilities({
    required this.isMobile,
    required this.isWeb,
    required this.supportsBiometrics,
    required this.supportsScreenshotBlocking,
    required this.hasSecureStorage,
  });

  /// Android o iOS.
  final bool isMobile;

  /// Flutter web.
  final bool isWeb;

  /// `local_auth` solo existe en móvil.
  final bool supportsBiometrics;

  /// `FLAG_SECURE` (Android) o overlay (iOS).
  final bool supportsScreenshotBlocking;

  /// En web el almacén es localStorage, no Keychain/Keystore.
  final bool hasSecureStorage;

  static PlatformCapabilities detect() {
    if (kIsWeb) {
      return const PlatformCapabilities(
        isMobile: false,
        isWeb: true,
        supportsBiometrics: false,
        supportsScreenshotBlocking: false,
        hasSecureStorage: false,
      );
    }
    final mobile = Platform.isAndroid || Platform.isIOS;
    return PlatformCapabilities(
      isMobile: mobile,
      isWeb: false,
      supportsBiometrics: mobile,
      supportsScreenshotBlocking: mobile,
      hasSecureStorage: true,
    );
  }
}
