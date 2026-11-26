import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/widgets/animated_entry_tile.dart';

void main() {
  testWidgets('muestra el contenido normalmente', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedEntryTile(index: 0, child: Text('Contenido')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Contenido'), findsOneWidget);
  });

  testWidgets('con animaciones desactivadas no hay Opacity animado',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: const MaterialApp(
          home: Scaffold(
            body: AnimatedEntryTile(index: 2, child: Text('Contenido')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Contenido'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });
}
