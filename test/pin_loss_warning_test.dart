import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/l10n/generated/app_l10n.dart';
import 'package:llavero2/features/onboarding/onboarding_screen.dart';
import 'package:llavero2/features/onboarding/pin_create_screen.dart';

Future<void> pumpWithLocale(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

const warning =
    'Si olvidas el PIN, no hay forma de recuperarlo. Solo podrás restaurar tus datos desde un respaldo cifrado.';

void main() {
  group('Mejora 2 — Aviso de PIN olvidado', () {
    testWidgets('aparece en el onboarding antes de crear la bóveda',
        (tester) async {
      await pumpWithLocale(tester, const OnboardingScreen());

      expect(find.text(warning), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('sigue visible en la pantalla de creación del PIN',
        (tester) async {
      await pumpWithLocale(tester, const PinCreateScreen());

      expect(find.text(warning), findsOneWidget);
    });

    testWidgets('se traduce al inglés', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: OnboardingScreen()),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'If you forget your PIN, it cannot be recovered. You will only be able to restore your data from an encrypted backup.',
        ),
        findsOneWidget,
      );
    });
  });
}
