import '../../data/models/entry_field.dart';

/// Decide si un campo guarda un secreto.
///
/// Se usa en tres sitios con la MISMA regla: salud de contraseñas,
/// exportación en claro y pantalla de detalle. Así un campo no puede
/// considerarse secreto en un sitio y público en otro.
abstract final class SecretDetector {
  /// Pistas de etiqueta que indican secreto aunque no se marque la casilla.
  static const Set<String> labelHints = <String>{
    'contraseña',
    'contrasena',
    'password',
    'clave',
    'pin',
    'pass',
    'pwd',
    'secret',
    'secreto',
  };

  static bool isSecret(EntryField field) {
    if (field.isSecret) return true;
    if (field.type.hidesValueByDefault) return true;
    if (field.key == FieldKeys.password || field.key == FieldKeys.pin ||
        field.key == FieldKeys.cvv) {
      return true;
    }
    final label = field.label.toLowerCase().trim();
    if (labelHints.any(label.contains)) return true;
    // Los PIN suelen estar en campos numéricos con etiqueta genérica.
    return false;
  }
}
