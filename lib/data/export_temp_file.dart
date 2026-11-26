import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Crea un archivo temporal para compartir e IMPRIMIR y lo borra siempre.
abstract final class ExportTempFile {
  static Future<void> use(
    List<int> bytes,
    String extension,
    Future<void> Function(File file) action,
  ) async {
    final dir = await getTemporaryDirectory();
    final name =
        'llavero-${DateTime.now().microsecondsSinceEpoch}.$extension';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    try {
      await action(file);
    } finally {
      if (await file.exists()) await file.delete();
    }
  }
}
