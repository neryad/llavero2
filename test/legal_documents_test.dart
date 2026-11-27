import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/features/legal/legal_document.dart';

void main() {
  group('assets legales', () {
    test('los cuatro documentos están declarados en pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final name in <String>[
        'privacy_es.md',
        'privacy_en.md',
        'terms_es.md',
        'terms_en.md',
      ]) {
        expect(pubspec, contains('assets/legal/$name'));
      }
    });

    test('cargan en ambos idiomas con los datos exactos', () async {
      final privacyEs = await rootBundle.loadString('assets/legal/privacy_es.md');
      final privacyEn = await rootBundle.loadString('assets/legal/privacy_en.md');
      final termsEs = await rootBundle.loadString('assets/legal/terms_es.md');
      final termsEn = await rootBundle.loadString('assets/legal/terms_en.md');

      for (final text in <String>[
        privacyEs,
        privacyEn,
        termsEs,
        termsEn,
      ]) {
        expect(text, contains('Dayern Gomez (Neryad)'));
        expect(text, contains('neryadg@gmail.com'));
        expect(text, contains('© 2026 Dayern Gomez (Neryad)'));
        expect(text, contains('2026-11-27'));
      }
      expect(termsEs, contains('República Dominicana'));
      expect(termsEn, contains('Dominican Republic'));
    });

    test('el fallback de idioma es inglés', () {
      expect(
        legalAssetPath(LegalDocumentKind.privacy, 'es'),
        'assets/legal/privacy_es.md',
      );
      expect(
        legalAssetPath(LegalDocumentKind.terms, 'de'),
        'assets/legal/terms_en.md',
      );
      expect(
        legalAssetPath(LegalDocumentKind.terms, ''),
        'assets/legal/terms_en.md',
      );
    });
  });

  group('renderizador', () {
    test('convierte encabezados, viñetas, párrafos y negrita', () {
      final blocks = LegalMarkdown.parse(
        '# Título\n\nUna frase **importante** aquí.\n\n'
        '## Apartado\n\n- Primero\n- Segundo\n',
      );
      expect(blocks.map((b) => b.kind), <LegalBlockKind>[
        LegalBlockKind.heading1,
        LegalBlockKind.paragraph,
        LegalBlockKind.heading2,
        LegalBlockKind.bullet,
        LegalBlockKind.bullet,
      ]);
      expect(blocks.first.text, 'Título');
      expect(blocks[1].text, 'Una frase **importante** aquí.');
      final spans = LegalMarkdown.spans('Una frase **importante** aquí.');
      expect(spans, hasLength(3));
      expect(spans[1].text, 'importante');
      expect(spans[1].style?.fontWeight, FontWeight.bold);
    });

    testWidgets('el visor muestra encabezados y viñetas seleccionables',
        (tester) async {
      const markdown = '# Política de privacidad\n\n- Primero\n- Segundo\n';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LegalDocumentView(markdown: markdown)),
        ),
      );
      await tester.pump();

      final headingFinder = find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            widget.textSpan?.toPlainText() == 'Política de privacidad',
      );
      expect(headingFinder, findsOneWidget);
      final heading = tester.widget<SelectableText>(headingFinder);
      expect(
        heading.style?.fontSize,
        Theme.of(tester.element(find.byType(Scaffold)))
            .textTheme
            .headlineSmall
            ?.fontSize,
      );
      expect(find.textContaining('• '), findsWidgets);
      expect(find.byType(SelectableText), findsWidgets);
      await tester.pumpAndSettle();
    });
  });
}
