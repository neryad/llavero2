/// Categoría creada por el usuario.
class VaultCategory {
  const VaultCategory({
    required this.id,
    required this.name,
    required this.colorId,
    this.iconName,
  });

  final String id;
  final String name;

  /// ID de una categoría por defecto cuyo color queremos reutilizar.
  final String colorId;

  /// Icono elegido (codePoint en string) o null para el genérico.
  final String? iconName;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'colorId': colorId,
        'iconName': iconName,
      };

  factory VaultCategory.fromJson(Map<String, Object?> json) => VaultCategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        colorId: json['colorId'] as String? ?? 'other',
        iconName: json['iconName'] as String?,
      );

  VaultCategory copyWith({
    String? name,
    String? colorId,
    String? iconName,
    bool clearIcon = false,
  }) =>
      VaultCategory(
        id: id,
        name: name ?? this.name,
        colorId: colorId ?? this.colorId,
        iconName: clearIcon ? null : (iconName ?? this.iconName),
      );

  @override
  bool operator ==(Object other) =>
      other is VaultCategory &&
      other.id == id &&
      other.name == name &&
      other.colorId == colorId &&
      other.iconName == iconName;

  @override
  int get hashCode => Object.hash(id, name, colorId, iconName);
}
