import 'package:flutter_test/flutter_test.dart';

import 'package:llavero2/features/export_import/import_actions.dart';
import 'package:llavero2/l10n/generated/app_l10n_es.dart';

void main() {
  test('el fallo de GCM usa un mensaje conjunto y los demás siguen distintos',
      () {
    final l10n = L10nEs();
    expect(
      importMessage(ImportErrorKind.wrongPassword, l10n),
      'Contraseña incorrecta o archivo dañado',
    );
    expect(
      importMessage(ImportErrorKind.invalidFile, l10n),
      isNot('Contraseña incorrecta o archivo dañado'),
    );
    expect(
      importMessage(ImportErrorKind.newerVersion, l10n),
      isNot('Contraseña incorrecta o archivo dañado'),
    );
  });
}
