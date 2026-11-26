import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:llavero2/core/security/biometric_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final biometricCalls = <MethodCall>[];
  final shareCalls = <MethodCall>[];

  const biometricChannel = MethodChannel('plugins.flutter.io/local_auth');
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

  setUp(() {
    biometricCalls.clear();
    shareCalls.clear();

    messenger.setMockMethodCallHandler(biometricChannel, (call) async {
      biometricCalls.add(call);
      return true;
    });
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      shareCalls.add(call);
      return 'done';
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(biometricChannel, null);
    messenger.setMockMethodCallHandler(shareChannel, null);
  });

  group('Mejora 4 — Contrato de canales nativos', () {
    test('local_auth pide solo biometría con la razón localizada', () async {
      final auth = DeviceBiometricAuth();

      final ok = await auth.authenticate(localizedReason: 'Abrir Llavero');

      expect(ok, isTrue);
      expect(biometricCalls, hasLength(1));
      expect(biometricCalls.first.method, 'authenticate');
      expect(biometricCalls.first.arguments['localizedReason'], 'Abrir Llavero');
      expect(biometricCalls.first.arguments['biometricOnly'], isTrue);
    });

    test('share_plus envía el archivo a compartir', () async {
      await SharePlus.instance.share(
        ShareParams(files: <XFile>[XFile('/tmp/respaldo.llavero')]),
      );

      expect(shareCalls, hasLength(1));
      expect(shareCalls.first.method, 'share');
      expect(
        shareCalls.first.arguments.toString(),
        contains('respaldo.llavero'),
      );
    });
  });
}
