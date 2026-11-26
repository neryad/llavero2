import 'entry_field.dart';

/// Una entrada de la bóveda (una contraseña, un Wi-Fi, un PIN...).
///
/// Es una clase inmutable: para cambiar algo se crea una copia con
/// [copyWith]. Así no hay sorpresas al compartir objetos entre la interfaz
/// y el almacenamiento.
class VaultEntry {
  const VaultEntry({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
    this.person,
    this.notes = '',
    this.isFavorite = false,
    this.deletedAt,
  });

  /// Identificador único (UUID v4).
  final String id;

  /// Título de la entrada («Wi-Fi de casa»).
  final String title;

  /// Identificador de la categoría (`CategoryIds.wifi`, o el identificador
  /// de una categoría que haya creado el usuario).
  final String categoryId;

  /// A quién pertenece («Mamá», «Abuela», «Casa»...). Puede estar vacío.
  final String? person;

  /// Campos con los datos de la entrada.
  final List<EntryField> fields;

  /// Notas libres.
  final String notes;

  /// Si está marcada como favorita.
  final bool isFavorite;

  /// Cuándo se creó.
  final DateTime createdAt;

  /// Cuándo se modificó por última vez.
  final DateTime updatedAt;

  /// Cuándo se movió a la papelera. Si no es `null`, está eliminada.
  final DateTime? deletedAt;

  /// `true` si la entrada está en la papelera.
  bool get isDeleted => deletedAt != null;

  /// Copia de la entrada con los cambios indicados.
  ///
  /// Para los campos que admiten `null` (person, deletedAt) se usan
  /// indicadores aparte (`clearPerson`, `clearDeletedAt`) porque si no no
  /// se podría distinguir "no cambiar" de "dejar en blanco".
  VaultEntry copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? person,
    bool clearPerson = false,
    List<EntryField>? fields,
    String? notes,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return VaultEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      person: clearPerson ? null : (person ?? this.person),
      fields: fields ?? this.fields,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  /// Convierte la entrada a JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'categoryId': categoryId,
      'person': person,
      'fields': fields.map((field) => field.toJson()).toList(),
      'notes': notes,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
    };
  }

  /// Lee una entrada desde JSON.
  factory VaultEntry.fromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      throw const FormatException('Entrada sin id o título.');
    }
    final rawFields = json['fields'] as List<Object?>? ?? const <Object?>[];
    return VaultEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? 'other',
      person: json['person'] as String?,
      fields: rawFields
          .whereType<Map<Object?, Object?>>()
          .map(
            (field) => EntryField.fromJson(field.cast<String, Object?>()),
          )
          .toList(growable: false),
      notes: json['notes'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: _readDate(json['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _readDate(json['updatedAt']) ?? DateTime.now().toUtc(),
      deletedAt: _readDate(json['deletedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  @override
  bool operator ==(Object other) {
    return other is VaultEntry &&
        other.id == id &&
        other.title == title &&
        other.categoryId == categoryId &&
        other.person == person &&
        other.isFavorite == isFavorite &&
        other.deletedAt == deletedAt &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        _sameFields(other.fields, fields);
  }

  bool _sameFields(List<EntryField> a, List<EntryField> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.label != y.label || x.value != y.value || x.type != y.type || x.isSecret != y.isSecret) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        title,
        categoryId,
        person,
        isFavorite,
        deletedAt,
        notes,
        createdAt,
        updatedAt,
        ...fields.map((f) => Object.hash(f.label, f.value, f.type, f.isSecret)),
      ]);
}
