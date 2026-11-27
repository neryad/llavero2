import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/routes/app_routes.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/legal/legal_document.dart';
import 'package:llavero2/features/settings/about_screen.dart';
import 'package:llavero2/features/settings/settings_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

AppControllers _controllers() => AppControllers(
      entries: EntriesController(
        initialStorage: VaultStorage(
          initialFileSystem: MemoryVaultFileSystem(),
        ),
      ),
    );

Widget _app(Widget child) {
  final controllers = _controllers();
  return MaterialApp(
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    locale: const Locale('es'),
    onGenerateRoute: AppRoutes.onGenerateRoute,
    builder: (context, widget) => AppScope(
      controllers: controllers,
      child: widget ?? const SizedBox.shrink(),
    ),
    home: child,
  );
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.first);
  await tester.pump();
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Llavero',
      packageName: 'com.example.llavero2',
      version: '1.2.3',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  testWidgets('muestra la versión del paquete', (tester) async {
    await tester.pumpWidget(_app(const AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Versión 1.2.3 (7)'), findsOneWidget);
    expect(find.text('Todo offline, todo tuyo'), findsOneWidget);
    expect(find.text('Hecho por Neryad'), findsOneWidget);
    expect(
      find.text('© 2026 Dayern Gomez (Neryad)'),
      findsOneWidget,
    );
  });

  testWidgets('las filas legales abren el documento correcto', (tester) async {
    await tester.pumpWidget(_app(const AboutScreen()));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Política de privacidad'));
    await tester.tap(find.text('Política de privacidad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LegalDocumentScreen), findsOneWidget);
  });

  testWidgets('el botón de copiar pone la URL completa y avisa', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = call.arguments['text'] as String?;
        }
        return null;
      },
    );

    await tester.pumpWidget(_app(const AboutScreen()));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byIcon(Icons.copy_outlined));
    await tester.tap(find.byIcon(Icons.copy_outlined).first);
    await tester.pumpAndSettle();

    expect(copied, 'neryadg@gmail.com');
    expect(find.text('Copiado'), findsOneWidget);
  });

  testWidgets('Ajustes abre la pantalla Acerca de', (tester) async {
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();
    final aboutTile = find.widgetWithText(ListTile, 'Acerca de');
    await scrollTo(tester, aboutTile);
    await tester.tap(aboutTile);
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
  });
}
