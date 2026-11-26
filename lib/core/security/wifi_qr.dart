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

  static String _normalize(String label) {
    const accents = 'áéíóúñüÁÉÍÓÚÑÜ';
    const plain = 'aeiounuAEIOUNU';
    var result = label.trim().toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], plain[i]);
    }
    return result;
  }

  /// Extrae los campos de una entrada Wi-Fi. Devuelve `null` si no hay red
  /// o no hay campo de contraseña (no se inventa un secreto).
  static String? payloadFor(VaultEntry entry) {
    String? ssid;
    String? password;
    var security = 'WPA';

    for (final field in entry.fields) {
      final label = _normalize(field.label);
      if (<String>{'red', 'ssid', 'network', 'nombre de red'}.contains(label)) {
        ssid = field.value;
      } else if (<String>{'contrasena', 'password', 'clave', 'pass'}
          .contains(label)) {
        password = field.value;
      } else if (<String>{'seguridad', 'security', 'tipo de seguridad'}
          .contains(label)) {
        security = field.value;
      }
    }
    if (ssid == null || ssid.isEmpty || password == null) return null;
    return payload(security: security, ssid: ssid, password: password);
  }
}
