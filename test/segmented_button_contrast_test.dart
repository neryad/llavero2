import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/theme/app_palette.dart';
import 'package:llavero2/core/theme/app_theme.dart';

/// Componente de color de 0..1 a 0..255.
int component(double value) => (value * 255.0).round().clamp(0, 255);

/// Contraste WCAG de dos colores opacos (1.0 – 21.0).
double contrastRatio(Color a, Color b) {
  double channel(int value) {
    final c = value / 255;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  double luminance(Color color) => 0.2126 * channel(component(color.r)) +
      0.7152 * channel(component(color.g)) +
      0.0722 * channel(component(color.b));

  final l1 = luminance(a);
  final l2 = luminance(b);
  final light = math.max(l1, l2);
  final dark = math.min(l1, l2);
  return (light + 0.05) / (dark + 0.05);
}

/// Compone un color semitransparente sobre otro opaco.
Color over(Color foreground, Color background) => Color.fromRGBO(
      component(foreground.r * foreground.a + background.r * (1 - foreground.a)),
      component(foreground.g * foreground.a + background.g * (1 - foreground.a)),
      component(foreground.b * foreground.a + background.b * (1 - foreground.a)),
      1,
    );

Widget _segmentedApp(ThemeData theme) => MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: SegmentedButton<int>(
            segments: <ButtonSegment<int>>[
              for (final n in <int>[4, 6, 8])
                ButtonSegment<int>(value: n, label: Text('$n')),
            ],
            selected: const <int>{6},
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );

Future<ButtonStyle> _resolvedSegmentStyle(
  WidgetTester tester,
  ThemeData theme,
) async {
  await tester.pumpWidget(_segmentedApp(theme));
  // El SegmentedButton inyecta su estilo vía TextButtonTheme, no en el
  // TextButton de cada segmento.
  final element = tester.element(find.byType(TextButton).first);
  return TextButtonTheme.of(element).style!;
}

void main() {
  const selected = <WidgetState>{WidgetState.selected};
  const unselected = <WidgetState>{};

  testWidgets('dark: segmento seleccionado usa acento y onAccent con contraste',
      (tester) async {
    final style = await _resolvedSegmentStyle(tester, AppTheme.dark());

    final background = style.backgroundColor!.resolve(selected)!;
    final foreground = style.foregroundColor!.resolve(selected)!;
    final checkIcon = style.iconColor!.resolve(selected)!;

    expect(background, AppPalette.darkAccent);
    expect(foreground, AppPalette.darkOnAccent);
    expect(checkIcon, AppPalette.darkOnAccent);
    expect(contrastRatio(foreground, background), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(checkIcon, background), greaterThanOrEqualTo(4.5));

    // El check real se pinta con el iconColor resuelto.
    final iconColor = IconTheme.of(
      tester.element(find.byIcon(Icons.check)),
    ).color;
    expect(iconColor, AppPalette.darkOnAccent);
    expect(contrastRatio(iconColor!, background), greaterThanOrEqualTo(4.5));

    // La etiqueta seleccionada se pinta con el foreground resuelto.
    final labelColor = DefaultTextStyle.of(
      tester.element(find.text('6')),
    ).style.color;
    expect(labelColor, AppPalette.darkOnAccent);
    expect(contrastRatio(labelColor!, background), greaterThanOrEqualTo(4.5));
  });

  testWidgets('dark: segmento no seleccionado usa texto del tema sobre fondo transparente',
      (tester) async {
    final style = await _resolvedSegmentStyle(tester, AppTheme.dark());
    final theme = AppTheme.dark();

    expect(style.backgroundColor!.resolve(unselected), Colors.transparent);
    expect(style.foregroundColor!.resolve(unselected), AppPalette.darkText);
    expect(style.iconColor!.resolve(unselected), AppPalette.darkText);

    final labelColor = DefaultTextStyle.of(
      tester.element(find.text('4')),
    ).style.color;
    expect(labelColor, AppPalette.darkText);
    expect(
      contrastRatio(labelColor!, theme.colorScheme.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(contrastRatio(labelColor, theme.colorScheme.surfaceDim),
        greaterThanOrEqualTo(4.5));
  });

  testWidgets('light: se mantiene el look anterior y el contraste también cumple',
      (tester) async {
    final style = await _resolvedSegmentStyle(tester, AppTheme.light());

    final background = style.backgroundColor!.resolve(selected)!;
    final foreground = style.foregroundColor!.resolve(selected)!;
    expect(foreground, AppPalette.lightOnAccent);
    expect(contrastRatio(foreground, over(background, AppPalette.lightSurface)),
        greaterThanOrEqualTo(4.5));

    expect(style.foregroundColor!.resolve(unselected), AppPalette.lightText);
    expect(
      contrastRatio(AppPalette.lightText, AppPalette.lightBackground),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('dark: el check del FilterChip seleccionado es legible',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: FilterChip(
            label: const Text('Wi-Fi'),
            selected: true,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.checkmarkColor, isNull); // viene del tema, no del widget
    final theme = Theme.of(tester.element(find.byType(FilterChip)));
    final checkmark = theme.chipTheme.checkmarkColor!;
    final selectedBackground =
        over(theme.chipTheme.selectedColor!, theme.colorScheme.surface);

    expect(checkmark, AppPalette.darkText);
    expect(contrastRatio(checkmark, selectedBackground),
        greaterThanOrEqualTo(4.5));
  });
}
