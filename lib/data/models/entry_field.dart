/// Tipo de un campo de una entrada.
///
/// Define cómo se muestra el valor y qué tipo de teclado conviene usar.
enum EntryFieldType {
  /// Texto normal.
  text,

  /// Secreto (contraseña, PIN): se muestra oculto hasta que el usuario
  /// decide verlo.
  secret,

  /// Dirección web.
  url,

  /// Código numérico (PIN de la puerta, del router...).
  pin,

  /// Correo electrónico.
  email,

  /// Teléfono.
  phone;

  /// Nombre estable (se guarda en el archivo cifrado).
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

  /// Lee el tipo a partir de su nombre.
  ///
  /// Si el archivo contiene un tipo que esta versión no conoce, se trata
  /// como texto normal en lugar de romper la app.
  static EntryFieldType fromName(String? name) {
    for (final type in EntryFieldType.values) {
      if (type.name == name) return type;
    }
    return EntryFieldType.text;
  }

  /// `true` si el valor debe ocultarse por defecto.
  bool get hidesValueByDefault =>
      this == EntryFieldType.secret || this == EntryFieldType.pin;
}

/// Un campo (etiqueta + valor) dentro de una entrada.
///
/// Ejemplos: «Red» = «Casa», «Contraseña» = «••••••» (secreto).
class EntryField {
  const EntryField({
    required this.label,
    required this.value,
    this.type = EntryFieldType.text,
    this.isSecret = false,
  });

  /// Texto que explica de qué es el campo («Contraseña», «Usuario»...).
  final String label;

  /// El valor en claro. Solo existe en memoria mientras la app está abierta
  /// y desbloqueada.
  final String value;

  /// Tipo de dato, para decidir cómo mostrarlo.
  final EntryFieldType type;

  /// Si el valor debe ocultarse hasta que el usuario lo revele.
  final bool isSecret;

  /// Copia del campo con los cambios indicados.
  ///
  /// Para los campos que admiten `null` (label, value, isSecret) se usan
  /// indicadores aparte (`clearLabel`, `clearValue`, `clearSecret`) porque
  /// si no no se podría distinguir "no cambiar" de "dejar en blanco".
  EntryField copyWith({
    String? label,
    String? value,
    EntryFieldType? type,
    bool? isSecret,
    bool clearLabel = false,
    bool clearValue = false,
    bool clearSecret = false,
  }) {
    return EntryField(
      label: clearLabel ? '' : (label ?? this.label),
      value: clearValue ? '' : (value ?? this.value),
      type: type ?? this.type,
      isSecret: clearSecret ? false : (isSecret ?? this.isSecret),
    );
  }

  /// Convierte el campo a JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'label': label,
      'value': value,
      'type': type.name,
      'isSecret': isSecret,
    };
  }

  /// Lee un campo desde JSON.
  factory EntryField.fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String?;
    final type = EntryFieldType.fromName(typeName);
    return EntryField(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      type: type,
      // Si el tipo ya es secreto (PIN), también lo ocultamos aunque el
      // archivo no lo diga.
      isSecret: (json['isSecret'] as bool?) ?? type.hidesValueByDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EntryField &&
        other.label == label &&
        other.value == value &&
        other.type == type &&
        other.isSecret == isSecret;
  }

  @override
  int get hashCode => Object.hash(label, value, type, isSecret);
}
