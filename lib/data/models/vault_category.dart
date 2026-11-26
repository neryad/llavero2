/// Categoría creada por el usuario.
///
/// Las categorías por defecto viven en `CategoryIds`; esta clase representa
/// solo las personalizadas, que se guardan en el almacén seguro (no son
/// secretas, pero así viajan con el resto de ajustes).
class VaultCategory {
  const VaultCategory({
    required this.id,
    required this.name,
    required this.colorId,
  });

  final String id;
  final String name;

  /// ID de una categoría por defecto cuyo color queremos reutilizar.
  final String colorId;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'colorId': colorId,
      };

  factory VaultCategory.fromJson(Map<String, Object?> json) => VaultCategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        colorId: json['colorId'] as String? ?? 'other',
      );

  VaultCategory copyWith({String? name, String? colorId}) => VaultCategory(
        id: id,
        name: name ?? this.name,
        colorId: colorId ?? this.colorId,
      );

  @override
  bool operator ==(Object other) =>
      other is VaultCategory &&
      other.id == id &&
      other.name == name &&
      other.colorId == colorId;

  @override
  int get hashCode => Object.hash(id, name, colorId);
}
