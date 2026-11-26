import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/platform/screen_security.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('llavero/screen_security');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Task 7 — Seguridad de pantalla', () {
    test('invoca el canal con blocked=true', () async {
      await ScreenSecurity.setScreenshotsBlocked(true);

      expect(calls, hasLength(1));
      expect(calls.first.method, 'setScreenshotsBlocked');
      expect(calls.first.arguments['blocked'], isTrue);
    });

    test('invoca el canal con blocked=false', () async {
      await ScreenSecurity.setScreenshotsBlocked(false);

      expect(calls.first.arguments['blocked'], isFalse);
    });

    test('sin implementación nativa no falla', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      await ScreenSecurity.setScreenshotsBlocked(true);
      // No lanza excepción.
    });
  });
}
