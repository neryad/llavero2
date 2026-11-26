import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/core/theme/app_theme.dart';
import 'package:llavero2/core/theme/app_typography.dart';
import 'package:llavero2/core/theme/category_colors.dart';
import 'package:llavero2/core/theme/category_icons.dart';
import 'package:llavero2/core/widgets/category_icon_badge.dart';
import 'package:llavero2/core/widgets/pin_code_input.dart';

void main() {
  test('la fuente de la interfaz se aplica de verdad en claro y oscuro', () {
    expect(AppTheme.light().textTheme.bodyLarge?.fontFamily,
        AppTypography.uiFont);
    expect(AppTheme.dark().textTheme.titleLarge?.fontFamily,
        AppTypography.uiFont);
    expect(AppTypography.mono18.fontFamily, AppTypography.monoFont);
  });

  test('cada categoría por defecto tiene su icono Material', () {
    expect(CategoryIcons.byId(CategoryIds.wifi), Icons.wifi);
    expect(CategoryIcons.byId(CategoryIds.email), Icons.mail_outline);
    expect(CategoryIcons.byId(CategoryIds.streaming),
        Icons.play_circle_outline);
    expect(CategoryIcons.byId(CategoryIds.banking), Icons.account_balance);
    expect(CategoryIcons.byId(CategoryIds.pinCode), Icons.dialpad);
    expect(CategoryIcons.byId(CategoryIds.social), Icons.forum_outlined);
    expect(CategoryIcons.byId(CategoryIds.devices), Icons.router_outlined);
    expect(CategoryIcons.byId(CategoryIds.documents), Icons.badge_outlined);
    expect(CategoryIcons.byId(CategoryIds.other), Icons.category_outlined);
    expect(CategoryIcons.curated.length, 24);
  });

  testWidgets('el badge de categoría es un cuadrado redondeado de 40dp',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CategoryIconBadge(categoryId: 'wifi')),
      ),
    );
    final box = tester.renderObject<RenderBox>(
      find.byType(CategoryIconBadge),
    );
    expect(box.size.width, 40);
    expect(box.size.height, 40);
  });

  testWidgets('el campo PIN muestra exactamente N puntos sin contador',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinCodeInput(length: 8, onCompleted: (_) {}),
        ),
      ),
    );
    // 8 puntos + el TextField invisible.
    expect(find.byType(Container), findsNWidgets(8));
    expect(find.textContaining('/8'), findsNothing);
  });
}
