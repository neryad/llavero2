import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/controllers/settings_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/widgets/adaptive_segmented.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/home/home_screen.dart';
import 'package:llavero2/features/settings/settings_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

AppControllers _controllers({AppLanguage language = AppLanguage.spanish}) =>
    AppControllers(
      entries: EntriesController(
        initialStorage: VaultStorage(
          initialFileSystem: MemoryVaultFileSystem(),
        ),
      ),
      settings: SettingsController(initialLanguage: language),
    );

Widget _app({
  required Widget child,
  required AppControllers controllers,
  double scale = 1,
  Locale locale = const Locale('es'),
}) =>
    MaterialApp(
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: locale,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: const Size(320, 640),
          textScaler: TextScaler.linear(scale),
        ),
        child: AppScope(controllers: controllers, child: widget!),
      ),
      home: child,
    );

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('tema e idioma van a ancho completo con etiqueta de una línea',
      (tester) async {
    await tester.pumpWidget(_app(
      child: const SettingsScreen(),
      controllers: _controllers(),
    ));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byType(SegmentedButton<AppThemeMode>));

    final segmented = tester.widget<SegmentedButton<AppThemeMode>>(
      find.byType(SegmentedButton<AppThemeMode>),
    );
    expect(segmented.expandedInsets, EdgeInsets.zero);
    for (final segment in segmented.segments) {
      expect(segment.label, isA<FittedBox>());
      final text = (segment.label as FittedBox).child as Text;
      expect(text.maxLines, 1);
    }
    expect(find.byType(SegmentedButton<AppLanguage>), findsOneWidget);
  });

  testWidgets('en inglés caben System / Light / Dark sin envolver', (tester) async {
    await tester.pumpWidget(_app(
      child: const SettingsScreen(),
      controllers: _controllers(language: AppLanguage.english),
      locale: const Locale('en'),
    ));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('System'));

    expect(find.text('System'), findsNWidgets(2));
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con fuente al 200 % se usa lista vertical de opciones',
      (tester) async {
    await tester.pumpWidget(_app(
      child: const SettingsScreen(),
      controllers: _controllers(),
      scale: 2,
    ));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byType(RadioListTile<AppThemeMode>));

    expect(find.byType(SegmentedButton<AppThemeMode>), findsNothing);
    expect(find.byType(SegmentedButton<AppLanguage>), findsNothing);
    expect(find.byType(RadioListTile<AppThemeMode>), findsNWidgets(3));
    expect(find.byType(RadioListTile<AppLanguage>), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('el selector de longitud del PIN también se adapta', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData.fromView(tester.view).copyWith(
            size: const Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: AdaptiveSegmented<int>(
            values: const <int>[4, 6, 8],
            labels: const <String>['4', '6', '8'],
            selected: 6,
            onChanged: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.byType(SegmentedButton<int>), findsNothing);
    expect(find.byType(RadioListTile<int>), findsNWidgets(3));
  });

  testWidgets('los chips de Home no desbordan a 320dp con fuente 200%',
      (tester) async {
    await tester.pumpWidget(_app(
      child: const HomeScreen(),
      controllers: _controllers(),
      scale: 2,
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
