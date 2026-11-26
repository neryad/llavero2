import 'models/entry_field.dart';
import 'models/vault_entry.dart';

/// Plantilla para crear una entrada nueva con campos predefinidos.
class EntryTemplate {
  const EntryTemplate({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.fields,
    this.notes = '',
  });

  /// Identificador estable de la plantilla.
  final String id;

  /// Título por defecto de la entrada creada.
  final String title;

  /// Categoría por defecto.
  final String categoryId;

  /// Campos por defecto (etiqueta, valor vacío, tipo).
  final List<EntryField> fields;

  /// Notas por defecto.
  final String notes;

  /// Crea una entrada con un ID y fechas nuevos.
  VaultEntry create({
    required String id,
    required DateTime now,
    String? title,
  }) {
    return VaultEntry(
      id: id,
      title: title ?? this.title,
      categoryId: categoryId,
      fields: List<EntryField>.from(fields),
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Plantillas disponibles en la app.
abstract final class EntryTemplates {
  static const EntryTemplate wifi = EntryTemplate(
    id: 'wifi',
    title: 'Wi-Fi',
    categoryId: 'wifi',
    fields: <EntryField>[
      EntryField(label: 'Red', value: ''),
      EntryField(label: 'Contraseña', value: '', type: EntryFieldType.secret),
    ],
  );

  static const EntryTemplate website = EntryTemplate(
    id: 'website',
    title: 'Cuenta web',
    categoryId: 'email',
    fields: <EntryField>[
      EntryField(label: 'Usuario', value: ''),
      EntryField(label: 'Contraseña', value: '', type: EntryFieldType.secret),
      EntryField(label: 'Web', value: '', type: EntryFieldType.url),
    ],
  );

  static const EntryTemplate pin = EntryTemplate(
    id: 'pin',
    title: 'PIN',
    categoryId: 'other',
    fields: <EntryField>[
      EntryField(label: 'PIN', value: '', type: EntryFieldType.pin),
    ],
  );

  static const EntryTemplate card = EntryTemplate(
    id: 'card',
    title: 'Tarjeta',
    categoryId: 'other',
    fields: <EntryField>[
      EntryField(label: 'Número', value: ''),
      EntryField(label: 'Caducidad', value: ''),
      EntryField(label: 'CVV', value: '', type: EntryFieldType.secret),
    ],
  );

  static const EntryTemplate note = EntryTemplate(
    id: 'note',
    title: 'Nota',
    categoryId: 'other',
    fields: <EntryField>[],
    notes: '',
  );

  /// Todas las plantillas, en el orden en que se muestran.
  static const List<EntryTemplate> all = <EntryTemplate>[
    wifi,
    website,
    pin,
    card,
    note,
  ];

  /// Busca una plantilla por su identificador.
  static EntryTemplate? byId(String id) {
    for (final template in all) {
      if (template.id == id) return template;
    }
    return null;
  }
}
