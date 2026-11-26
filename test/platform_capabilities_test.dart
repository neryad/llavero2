import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/platform/platform_capabilities.dart';

void main() {
  group('Mejora 17 — Capacidades por plataforma', () {
    test('móvil tiene todas las capacidades', () {
      const mobile = PlatformCapabilities(
        isMobile: true,
        isWeb: false,
        supportsBiometrics: true,
        supportsScreenshotBlocking: true,
        hasSecureStorage: true,
      );

      expect(mobile.supportsBiometrics, isTrue);
      expect(mobile.supportsScreenshotBlocking, isTrue);
      expect(mobile.hasSecureStorage, isTrue);
    });

    test('escritorio no tiene biometría ni anti-capturas', () {
      const desktop = PlatformCapabilities(
        isMobile: false,
        isWeb: false,
        supportsBiometrics: false,
        supportsScreenshotBlocking: false,
        hasSecureStorage: true,
      );

      expect(desktop.supportsBiometrics, isFalse);
      expect(desktop.supportsScreenshotBlocking, isFalse);
      expect(desktop.hasSecureStorage, isTrue);
    });

    test('web además carece de almacén seguro', () {
      const web = PlatformCapabilities(
        isMobile: false,
        isWeb: true,
        supportsBiometrics: false,
        supportsScreenshotBlocking: false,
        hasSecureStorage: false,
      );

      expect(web.isWeb, isTrue);
      expect(web.hasSecureStorage, isFalse);
    });

    test('detección actual es coherente', () {
      final current = PlatformCapabilities.detect();
      if (current.isMobile) {
        expect(current.supportsBiometrics, isTrue);
        expect(current.hasSecureStorage, isTrue);
      }
      if (current.isWeb) {
        expect(current.hasSecureStorage, isFalse);
      }
    });
  });
}
