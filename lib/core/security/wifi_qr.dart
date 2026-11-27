import '../../data/models/entry_field.dart';
import '../../data/models/vault_entry.dart';

/// Genera el payload estándar de QR para Wi-Fi:
/// `WIFI:T:<security>;S:<ssid>;P:<password>;;`
abstract final class WifiQr {
  /// Escapa los caracteres reservados por el formato WIFI.
  static String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll(':', r'\:')
      .replaceAll('"', r'\"');

  static String payload({
    required String security,
    required String ssid,
    required String password,
  }) {
    final value = security.trim();
    // El estándar reserva «nopass» en minúsculas; el resto va en mayúsculas.
    final normalized = value.isEmpty
        ? 'WPA'
        : (value.toLowerCase() == 'nopass' ? 'nopass' : value.toUpperCase());
    return 'WIFI:T:$normalized;S:${_escape(ssid)};P:${_escape(password)};;';
  }

  /// Extrae los campos de una entrada Wi-Fi. Devuelve `null` si no hay red
  /// o no hay campo de contraseña (no se inventa un secreto).
  static String? ssidOf(VaultEntry entry) {
    for (final field in entry.fields) {
      final key = field.key ?? FieldKeys.fromLabel(field.label);
      if (key == FieldKeys.ssid && field.value.isNotEmpty) return field.value;
    }
    return null;
  }

  static String? payloadFor(VaultEntry entry) {
    String? password;
    var security = 'WPA';

    for (final field in entry.fields) {
      // La clave estable manda; la etiqueta es solo fallback para entradas
      // creadas en memoria antes de la migración.
      final key = field.key ?? FieldKeys.fromLabel(field.label);
      if (key == FieldKeys.password) {
        password = field.value;
      } else if (key == FieldKeys.security) {
        security = field.value;
      }
    }
    final ssid = ssidOf(entry);
    if (ssid == null) return null;
    // Sin contraseña, el estándar usa T:nopass.
    return payload(
      security: password == null || password.isEmpty ? 'nopass' : security,
      ssid: ssid,
      password: password ?? '',
    );
  }
}
