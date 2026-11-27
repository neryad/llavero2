/// Tipo de un campo de una entrada.
///
/// Define cómo se muestra el valor y qué tipo de teclado conviene usar.
enum EntryFieldType {
  text,
  secret,
  url,
  pin,
  email,
  phone;

  String get name {
    switch (this) {
      case EntryFieldType.text:
        return 'text';
      case EntryFieldType.secret:
        return 'secret';
      case EntryFieldType.url:
        return 'url';
      case EntryFieldType.pin:
        return 'pin';
      case EntryFieldType.email:
        return 'email';
      case EntryFieldType.phone:
        return 'phone';
    }
  }

  static EntryFieldType fromName(String? name) {
    for (final type in EntryFieldType.values) {
      if (type.name == name) return type;
    }
    return EntryFieldType.text;
  }

  bool get hidesValueByDefault =>
      this == EntryFieldType.secret || this == EntryFieldType.pin;
}

/// Claves estables de los campos de las plantillas. No dependen del idioma.
abstract final class FieldKeys {
  static const String ssid = 'ssid';
  static const String password = 'password';
  static const String security = 'security';
  static const String pin = 'pin';
  static const String username = 'username';
  static const String url = 'url';
  static const String number = 'number';
  static const String expiry = 'expiry';
  static const String cvv = 'cvv';

  /// Etiquetas históricas (ES/EN) mapeadas a su clave para migrar entradas
  /// antiguas que no guardaban `key`.
  static const Map<String, String> legacyLabels = <String, String>{
    'red': ssid,
    'ssid': ssid,
    'network': ssid,
    'nombre de red': ssid,
    'wifi name': ssid,
    'contraseña': password,
    'contrasena': password,
    'password': password,
    'clave': password,
    'pass': password,
    'pwd': password,
    'seguridad': security,
    'security': security,
    'pin': pin,
    'codigo': pin,
    'usuario': username,
    'username': username,
    'user': username,
    'web': url,
    'url': url,
    'sitio': url,
    'numero': number,
    'number': number,
    'caducidad': expiry,
    'expiry': expiry,
    'cvv': cvv,
  };

  static String? fromLabel(String label) {
    var value = label.trim().toLowerCase();
    const accents = 'áéíóúñüÁÉÍÓÚÑÜ';
    const plain = 'aeiounuAEIOUNU';
    for (var i = 0; i < accents.length; i++) {
      value = value.replaceAll(accents[i], plain[i]);
    }
    return legacyLabels[value];
  }
}

/// Un campo (etiqueta + valor) dentro de una entrada.
class EntryField {
  const EntryField({
    required this.label,
    required this.value,
    this.type = EntryFieldType.text,
    this.isSecret = false,
    this.key,
  });

  /// Clave estable e independiente del idioma (`ssid`, `password`, ...).
  /// `null` en campos creados a mano antes de la migración.
  final String? key;

  final String label;
  final String value;
  final EntryFieldType type;
  final bool isSecret;

  EntryField copyWith({
    String? key,
    String? label,
    String? value,
    EntryFieldType? type,
    bool? isSecret,
    bool clearKey = false,
    bool clearLabel = false,
    bool clearValue = false,
    bool clearSecret = false,
  }) {
    return EntryField(
      key: clearKey ? null : (key ?? this.key),
      label: clearLabel ? '' : (label ?? this.label),
      value: clearValue ? '' : (value ?? this.value),
      type: type ?? this.type,
      isSecret: clearSecret ? false : (isSecret ?? this.isSecret),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key,
      'label': label,
      'value': value,
      'type': type.name,
      'isSecret': isSecret,
    };
  }

  factory EntryField.fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String?;
    final type = EntryFieldType.fromName(typeName);
    final label = json['label'] as String? ?? '';
    final storedKey = json['key'] as String?;
    return EntryField(
      // Migración de archivos antiguos: deducimos la clave de la etiqueta.
      key: (storedKey != null && storedKey.isNotEmpty)
          ? storedKey
          : FieldKeys.fromLabel(label),
      label: label,
      value: json['value'] as String? ?? '',
      type: type,
      isSecret: (json['isSecret'] as bool?) ?? type.hidesValueByDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EntryField &&
        other.key == key &&
        other.label == label &&
        other.value == value &&
        other.type == type &&
        other.isSecret == isSecret;
  }

  @override
  int get hashCode => Object.hash(key, label, value, type, isSecret);
}
