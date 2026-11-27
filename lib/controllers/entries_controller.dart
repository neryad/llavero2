import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../data/models/entry_field.dart';
import '../data/models/vault_entry.dart';
import '../data/models/vault_document.dart';
import '../data/vault_storage.dart';

/// Controlador que gestiona las entradas de la bóveda.
///
/// Mantiene las entradas en memoria mientras la bóveda está abierta, y
/// reescribe el archivo cifrado en cada cambio.
///
/// NO importa nada de la interfaz (solo `foundation.dart`), así que se puede
/// testear con `flutter test` sin montar la app.
class EntriesController extends ChangeNotifier {
  EntriesController({
    required VaultStorage initialStorage,
    SecretKey? initialKey,
    DateTime Function()? clock,
    String Function()? idGenerator,
  })  : _storage = initialStorage,
        _pinKey = initialKey,
        _clock = clock ?? DateTime.now {
    _idGeneratorFn = idGenerator ?? () => 'id-';
  }

  final VaultStorage _storage;
  SecretKey? _pinKey;
  final DateTime Function() _clock;
  String Function()? _idGeneratorFn;
  String Function() get idGenerator => _idGeneratorFn ?? () => 'id-';

  /// Entradas en memoria mientras la bóveda está abierta.
  final List<VaultEntry> _entries = <VaultEntry>[];

  /// Si la bóveda está abierta.
  bool _isOpen = false;

  /// Duración de retención de la papelera (30 días).
  static const Duration trashRetention = Duration(days: 30);

  /// Obtiene las entradas actuales desde el archivo.
  Future<void> load(SecretKey key) async {
    _pinKey = key;
    final document = await _storage.load(key);
    if (document == null) {
      // No hay bóveda.
      _entries.clear();
    } else {
      // Filtrar las entradas activas (no en papelera).
      _entries
        ..clear()
        ..addAll(document.entries.toList(growable: false));
    }
    _isOpen = true;
    notifyListeners();
  }

  /// Conserva el archivo actual como `vault.damaged-<fecha>` para recuperarlo.
  Future<void> renameVaultAsDamaged() => _storage.renameVaultAsDamaged();

  /// Abre la bóveda, carga las entradas y purga la papelera caducada.
  ///
  /// Es el入口 que usa `AppControllers` al desbloquear: así la papelera se
  /// limpia sin que el usuario tenga que abrir su pantalla.
  Future<void> open(SecretKey key) async {
    await load(key);
    await purgeExpiredTrash();
  }

  /// Cierra la bóveda y borra las entradas de memoria.
  void lock() {
    if (!_isOpen) return;
    _isOpen = false;
    _entries.clear();
    notifyListeners();
  }

  /// Fusiona entradas importadas por ID: las del respaldo mandan en conflictos.
  Future<void> merge(VaultDocument document) async {
    if (!_isOpen) throw StateError('La bóveda está cerrada.');
    for (final incoming in document.entries) {
      final index = _entries.indexWhere((e) => e.id == incoming.id);
      if (index == -1) {
        _entries.add(incoming);
      } else {
        _entries[index] = incoming;
      }
    }
    await _saveToStorage();
  }

  /// Reemplaza todas las entradas por las de un documento importado.
  Future<void> replaceAll(VaultDocument document) async {
    if (!_isOpen) {
      throw StateError('La bóveda está cerrada.');
    }
    _entries
      ..clear()
      ..addAll(document.entries);
    await _saveToStorage();
  }

  /// Obtiene las entradas activas.
  List<VaultEntry> get entries {
    return _entries.where((e) => !e.isDeleted).toList(growable: false);
  }

  /// `true` si no hay entradas activas.
  bool get isEmpty => entries.isEmpty;

  /// Obtener las entradas favoritas.
  List<VaultEntry> get favorites {
    return _entries
        .where((e) => e.isFavorite && !e.isDeleted)
        .toList(growable: false);
  }

  /// Obtener las entradas en papelera.
  List<VaultEntry> get trashed {
    return _entries.where((e) => e.isDeleted).toList(growable: false);
  }

  /// Obtener todas las entradas (activas y en papelera).
  List<VaultEntry> get allEntries => _entries;

  /// Añadir una nueva entrada.
  Future<void> add(VaultEntry entry) async {
    if (!_isOpen) {
      throw StateError('La bóveda está cerrada.');
    }

    // Añadir a memoria.
    _entries.add(entry);

    // Guardar en archivo.
    await _saveToStorage();
  }

  /// Actualizar una entrada existente.
  Future<void> update(VaultEntry entry) async {
    if (!_isOpen) {
      throw StateError('La bóveda está cerrada.');
    }

    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      throw StateError('La entrada no existe.');
    }

    final current = _entries[index];
    final updated = entry.copyWith(
      id: current.id,
      createdAt: current.createdAt,
      clearPerson: entry.person == null,
    ).copyWith(
      title: entry.title,
      categoryId: entry.categoryId,
      person: entry.person,
      fields: entry.fields,
      notes: entry.notes,
      isFavorite: entry.isFavorite,
      updatedAt: _clock(),
    );

    // Reemplazar en memoria.
    _entries[index] = updated;

    // Guardar en archivo.
    await _saveToStorage();
  }

  /// Mover una entrada a la papelera.
  Future<void> moveToTrash(String id) async {
    if (!_isOpen) {
      throw StateError('La bóveda está cerrada.');
    }

    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw StateError('La entrada no existe.');
    }

    final entry = _entries[index];
    final trashed = entry.copyWith(deletedAt: _clock()).copyWith(
      updatedAt: _clock(),
    );

    // Reemplazar en memoria.
    _entries[index] = trashed;

    // Guardar en archivo.
    await _saveToStorage();
  }

  /// Restaurar una entrada de la papelera.
  Future<void> restore(String id) async {
    if (!_isOpen) {
      throw StateError('La bóveda está cerrada.');
    }

    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw StateError('La entrada no existe.');
    }

    final entry = _entries[index];
    if (entry.deletedAt == null) {
      throw StateError('La entrada no está en la papelera.');
    }

    final restored = entry.copyWith(clearDeletedAt: true).copyWith(
      updatedAt: _clock(),
    );

    // Reemplazar en memoria.
    _entries[index] = restored;

    // Guardar en archivo.
    await _saveToStorage();
  }

  /// Borrar una entrada para siempre (de la papelera).
  Future<void> deleteForever(String id) async {
    if (!_isOpen) {
      throw StateError('La bóveda está cerrada.');
    }

    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw StateError('La entrada no existe.');
    }

    // Eliminar de memoria.
    _entries.removeAt(index);

    // Guardar en archivo.
    await _saveToStorage();
  }

  /// Alternar favorito.
  Future<void> toggleFavorite(String id) async {
    if (!_isOpen) {
      throw StateError('La bóveda está cerrada.');
    }

    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw StateError('La entrada no existe.');
    }

    final entry = _entries[index];
    final updated = entry.copyWith(isFavorite: !entry.isFavorite).copyWith(
      updatedAt: _clock(),
    );

    // Reemplazar en memoria.
    _entries[index] = updated;

    // Guardar en archivo.
    await _saveToStorage();
  }

  /// Duplicar una entrada.
  Future<void> duplicate(String id) async {
    if (!_isOpen) {
      throw StateError('La bóveda está cerrada.');
    }

    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw StateError('La entrada no existe.');
    }

    final original = _entries[index];
    final now = _clock();

    // Crear copia con nuevo ID.
    final copy = VaultEntry(
      id: idGenerator(),
      title: '${original.title} (copia)',
      categoryId: original.categoryId,
      person: original.person,
      fields: List<EntryField>.from(original.fields),
      notes: original.notes,
      isFavorite: false,
      createdAt: original.createdAt,
      updatedAt: now,
      deletedAt: null,
    );

    // Añadir a memoria.
    _entries.add(copy);

    // Guardar en archivo.
    await _saveToStorage();
  }

  /// Purgar entradas de la papelera que llevan más de 30 días.
  Future<void> purgeExpiredTrash() async {
    if (!_isOpen) {
      throw StateError('La bóveda está cerrada.');
    }

    final now = _clock();
    final cutoff = now.subtract(trashRetention);

    // Filtrar entradas que deben ser purgadas.
    final toPurge = <VaultEntry>[];
    for (final entry in _entries) {
      if (entry.isDeleted && entry.deletedAt!.isBefore(cutoff)) {
        toPurge.add(entry);
      }
    }

    // Eliminar de memoria.
    for (final entry in toPurge) {
      _entries.removeWhere((e) => e.id == entry.id);
    }

    // Guardar en archivo.
    await _saveToStorage();
  }

  /// Buscar entradas por término (título, persona, etiqueta de campo o notas).
  ///
  /// **Nunca** busca en el valor de un campo secreto: la búsqueda no debe
  /// convertirse en una puerta trasera para leer secretos.
  List<VaultEntry> search(String term) {
    final active = entries;
    if (term.trim().isEmpty) return active;

    final lowerTerm = term.toLowerCase();
    final results = <VaultEntry>[];

    for (final entry in active) {
      // Buscar en título.
      if (entry.title.toLowerCase().contains(lowerTerm)) {
        results.add(entry);
        continue;
      }

      // Buscar en persona.
      if (entry.person != null &&
          entry.person!.toLowerCase().contains(lowerTerm)) {
        results.add(entry);
        continue;
      }

      // Buscar en notas (nunca secretas, son texto libre del usuario).
      if (entry.notes.toLowerCase().contains(lowerTerm)) {
        results.add(entry);
        continue;
      }

      // Buscar en etiquetas de campos (no en valores secretos).
      for (final field in entry.fields) {
        if (!field.isSecret && field.label.toLowerCase().contains(lowerTerm)) {
          results.add(entry);
          break;
        }
      }
    }

    return results;
  }

  /// Obtener las personas que tienen entradas.
  List<String> get persons {
    final names = <String>{};
    for (final entry in _entries) {
      if (entry.person != null) names.add(entry.person!);
    }
    final list = names.toList()..sort();
    return list;
  }

  /// Obtener las categorías que tienen entradas.
  List<String> get categoryIds {
    final ids = <String>{};
    for (final entry in _entries) {
      ids.add(entry.categoryId);
    }
    final list = ids.toList()..sort();
    return list;
  }

  /// Guardar el estado actual en el archivo.
  ///
  /// La memoria ya contiene el estado correcto (todas las mutaciones la
  /// actualizan antes de llegar aquí), así que no se vuelve a leer ni a
  /// descifrar el archivo: eso era innecesario y podía introducir una
  /// ventana en la que memoria y disco divergieran.
  /// Tras guardar se notifica a la interfaz para que se redibuje.
  Future<void> _saveToStorage() async {
    final document = VaultDocument(
      entries: _entries.toList(growable: false),
    );
    await _storage.save(document, _pinKey!);
    notifyListeners();
  }
}
