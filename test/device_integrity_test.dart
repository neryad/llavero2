import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/platform/device_integrity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('llavero/device_integrity');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'isCompromised');
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('Mejora 6 — Detección de root/jailbreak', () {
    test('detecta un dispositivo comprometido', () async {
      final result = await DeviceIntegrityChecker.check();
      expect(result, DeviceIntegrity.compromised);
      expect(result.isCompromised, isTrue);
    });

    test('un dispositivo íntegro devuelve intact', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => false);
      final result = await DeviceIntegrityChecker.check();
      expect(result, DeviceIntegrity.intact);
    });

    test('sin plugin nativo no falla y asume íntegro', () async {
      messenger.setMockMethodCallHandler(channel, null);
      final result = await DeviceIntegrityChecker.check();
      expect(result, DeviceIntegrity.intact);
    });
  });
}
