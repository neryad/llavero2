import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/security/secure_store.dart';
import '../core/theme/category_colors.dart';
import '../data/models/vault_category.dart';

/// Gestiona las categorías personalizadas de la bóveda.
///
/// Las categorías por defecto (`CategoryIds`) no se guardan: están siempre
/// disponibles. Aquí solo viven las que crea el usuario.
class CategoriesController extends ChangeNotifier {
  CategoriesController({required this._store});

  final SecureStore _store;
  final List<VaultCategory> _custom = <VaultCategory>[];

  /// IDs de las categorías por defecto, en orden de muestra.
  static const List<String> defaultIds = <String>[
    CategoryIds.wifi,
    CategoryIds.email,
    CategoryIds.streaming,
    CategoryIds.banking,
    CategoryIds.pinCode,
    CategoryIds.social,
    CategoryIds.devices,
    CategoryIds.documents,
    CategoryIds.other,
  ];

  /// Categorías personalizadas (copia para que no se puedan mutar).
  List<VaultCategory> get custom => List<VaultCategory>.unmodifiable(_custom);

  /// Busca una categoría por ID (solo entre las personalizadas).
  VaultCategory? byId(String id) {
    for (final category in _custom) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Carga las categorías guardadas.
  Future<void> initialize() async {
    final raw = await _store.read(SecureStoreKeys.categories);
    _custom.clear();
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<Object?>;
        _custom.addAll(
          decoded
              .whereType<Map<Object?, Object?>>()
              .map(
                (json) => VaultCategory.fromJson(json.cast<String, Object?>()),
              )
              .where((category) => category.id.isNotEmpty),
        );
      } on FormatException {
        // Datos corruptos: empezamos con la lista vacía.
      }
    }
    notifyListeners();
  }

  /// Crea una categoría personalizada.
  Future<VaultCategory> add({
    required String name,
    String colorId = CategoryIds.other,
  }) async {
    final category = VaultCategory(
      id: 'cat-${const Uuid().v4()}',
      name: name.trim(),
      colorId: colorId,
    );
    _custom.add(category);
    await _persist();
    return category;
  }

  /// Actualiza el nombre o el color de una categoría.
  Future<void> update(VaultCategory category) async {
    final index = _custom.indexWhere((c) => c.id == category.id);
    if (index == -1) return;
    _custom[index] = category;
    await _persist();
  }

  /// Borra una categoría personalizada.
  Future<void> remove(String id) async {
    _custom.removeWhere((c) => c.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    await _store.write(
      SecureStoreKeys.categories,
      jsonEncode(_custom.map((c) => c.toJson()).toList()),
    );
    notifyListeners();
  }
}
