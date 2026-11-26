import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:llavero2/controllers/entries_controller.dart';
import 'package:llavero2/core/app_scope.dart';
import 'package:llavero2/core/security/wifi_qr.dart';
import 'package:llavero2/data/models/entry_field.dart';
import 'package:llavero2/data/models/vault_entry.dart';
import 'package:llavero2/data/vault_file_system.dart';
import 'package:llavero2/data/vault_storage.dart';
import 'package:llavero2/features/entries/entry_detail_screen.dart';
import 'package:llavero2/l10n/generated/app_l10n.dart';

VaultEntry _wifi(List<EntryField> fields) => VaultEntry(
      id: 'wifi-1',
      title: 'Wi-Fi de casa',
      categoryId: 'wifi',
      fields: fields,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  group('WifiQr — payload estándar', () {
    test('formato basico WPA', () {
      expect(
        WifiQr.payload(security: 'WPA', ssid: 'MiRed', password: 'secreto'),
        'WIFI:T:WPA;S:MiRed;P:secreto;;',
      );
    });

    test('escapa ; , : \\ y " en red y contrasena', () {
      expect(
        WifiQr.payload(
          security: 'WPA',
          ssid: r'A;B,C:D\E"F',
          password: r'p;q,r:s\t"u',
        ),
        r'WIFI:T:WPA;S:A\;B\,C\:D\\E\"F;P:p\;q\,r\:s\\t\"u;;',
      );
    });

    test('respeta WEP, nopass y contrasena vacia', () {
      expect(
        WifiQr.payload(security: 'WEP', ssid: 'Red', password: 'abc'),
        'WIFI:T:WEP;S:Red;P:abc;;',
      );
      expect(
        WifiQr.payload(security: 'nopass', ssid: 'Abierta', password: ''),
        'WIFI:T:nopass;S:Abierta;P:;;',
      );
    });

    test('normaliza la seguridad a mayusculas', () {
      expect(
        WifiQr.payload(security: 'wpa2', ssid: 'Red', password: 'abc'),
        'WIFI:T:WPA2;S:Red;P:abc;;',
      );
    });

    test('extrae red, contrasena y seguridad de una entrada Wi-Fi', () {
      final entry = _wifi(<EntryField>[
        EntryField(label: 'Red', value: 'MiRed'),
        EntryField(
          label: 'Contraseña',
          value: 'secreto',
          type: EntryFieldType.secret,
        ),
        EntryField(label: 'Seguridad', value: 'WPA2'),
      ]);
      expect(WifiQr.payloadFor(entry), 'WIFI:T:WPA2;S:MiRed;P:secreto;;');
    });

    test('sin campo Seguridad usa WPA por defecto', () {
      final entry = _wifi(<EntryField>[
        EntryField(label: 'SSID', value: 'Red'),
        EntryField(
          label: 'Password',
          value: 'clave',
          type: EntryFieldType.secret,
        ),
      ]);
      expect(WifiQr.payloadFor(entry), 'WIFI:T:WPA;S:Red;P:clave;;');
    });

    test('devuelve null si falta la red o la contrasena', () {
      expect(
        WifiQr.payloadFor(_wifi(<EntryField>[
          EntryField(label: 'Contraseña', value: 'x'),
        ])),
        isNull,
      );
      expect(
        WifiQr.payloadFor(_wifi(<EntryField>[
          EntryField(label: 'Red', value: 'x'),
        ])),
        isNull,
      );
    });
  });

  testWidgets('el QR aparece solo al pedirlo y se oculta a los 30 s',
      (tester) async {
    final entries = EntriesController(
      initialStorage: VaultStorage(
        initialFileSystem: MemoryVaultFileSystem(),
      ),
    );
    await entries.open(SecretKey(List<int>.filled(32, 3)));
    await entries.add(_wifi(<EntryField>[
      EntryField(label: 'Red', value: 'MiRed'),
      EntryField(
        label: 'Contraseña',
        value: 'secreto',
        type: EntryFieldType.secret,
      ),
    ]));
    final controllers = AppControllers(entries: entries);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('es'),
        home: AppScope(
          controllers: controllers,
          child: const EntryDetailScreen(entryId: 'wifi-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsNothing);
    await tester.tap(find.text('Mostrar QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      find.text('Cualquiera que lo escanee obtiene la contraseña.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
  });
}
