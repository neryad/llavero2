# Fase 3: Modelos, CRUD y Archivo Cifrado — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement el modelo de datos (VaultDocument, VaultEntry, EntryField), el sistema de archivo cifrado con escritura atómica, y el EntriesController con CRUD completo.

**Architecture:**
- Modelos inmutables en `lib/data/models/` con `toJson`, `fromJson` y `copyWith`.
- Archivo cifrado en un solo archivo (`vault.dat`) con cabecera legible + contenido AES-256-GCM.
- Escritura atómica: escribir en `.tmp` y renombrar para evitar corrupción por apagado.
- `EntriesController` mantiene entradas en memoria mientras la bóveda está abierta, y reescribe el archivo en cada cambio.

**Tech Stack:**
- `cryptography` (Argon2id, AES-256-GCM) — ya implementado en Fase 2.
- `flutter_secure_storage` — para persistir el estado de la bóveda (abierta/cerrada).
- `path_provider` — para obtener la ruta privada del dispositivo.

**Spec:** PROGRESS.md, sección "Fase 3 — Archivo cifrado, modelos y CRUD".

---

## Global Constraints

- **Solo dependencias permitidas:** `cryptography`, `flutter_secure_storage`, `local_auth`, `path_provider`, `share_plus`, `file_picker`, `pdf` + `printing`, `qr_flutter`, `package_info_plus`, `uuid`.
- **Sin generación de código:** todo escrito a mano (modelos, serialización).
- **Offline 100%:** sin `google_fonts`, sin llamadas a red en producción.
- **Android:** `allowBackup="false"`, `fullBackupContent="false"`.
- **iOS:** exclusión de iCloud (`NSURLIsExcludedFromBackupKey`).
- **Idiomas:** ES/EN con `flutter_localizations` + `intl`.
- **Tests:** TDD, mínimo 39 nuevos tests para esta fase.

---

## Review Focus

1. **Entrada con bóveda cerrada:** cualquier operación de CRUD debe fallar si la bóveda no está abierta.
2. **Entrada con campos secretos:** los campos de tipo `secret` o `pin` no se muestran en la UI.
3. **Entrada borrada (papelera):** `deletedAt` no nulo = entrada en papelera, ignorada en búsquedas.
4. **Archivo corrupto/inexistente:** el sistema debe manejar errores de lectura sin exponer secretos.
5. **Clave incorrecta:** al abrir con PIN equivocado, debe fallar sin mostrar el contenido.

---

## Estructura de Archivos

```
lib/data/
  models/
    entry_field.dart      ← NUEVO: modelo EntryField
    vault_entry.dart      ← NUEVO: modelo VaultEntry
    vault_document.dart   ← NUEVO: modelo VaultDocument
  vault_file_system.dart  ← NUEVO: gestión de rutas privadas + escritura atómica
  vault_storage.dart      ← NUEVO: cifrar/descifrar el archivo

lib/controllers/
  entries_controller.dart ← NUEVO: CRUD, búsqueda, papelera

test/
  models_test.dart        ← NUEVO: tests de modelos (ida y vuelta, copyWith)
  vault_storage_test.dart ← NUEVO: tests de cifrado/descifrado
  entries_controller_test.dart ← EXISTENTE: adaptar para tests de CRUD
```

---

## Task 1: EntryField — Modelo de Campo

**Files:**
- Create: `lib/data/models/entry_field.dart`
- Test: `test/models_test.dart` (añadir tests para EntryField)

**Interfaces:**
- Consumes: nada (modelo independiente).
- Produces: `toJson()`, `fromJson(Map<String, dynamic>)`, `copyWith({...})`.

**Especificaciones:**
- Campos: `label` (String), `value` (String), `type` (`EntryFieldType`), `isSecret` (bool).
- Tipos: `text`, `secret`, `url`, `pin`, `email`, `phone`.
- `isSecret` es opcional (null = no forzar ocultamiento).
- Métodos: `toJson()`, `fromJson(Map<String, dynamic>)`, `copyWith({label, value, type, isSecret})`.
- `copyWith` usa indicadores aparte: `clearLabel()`, `clearValue()`, `clearSecret()` para distinguir "no cambiar" de "dejar en blanco".

**Tests:**
- [ ] `test_entry_field_json_roundTrip()` — ida y vuelta JSON.
- [ ] `test_entry_field_unknownType()` — tipo desconocido se ignora en fromJson.
- [ ] `test_entry_field_copyWith()` — copyWith actualiza solo los campos pasados.
- [ ] `test_entry_field_clearLabel()` — clearLabel deja value/type en blanco si no se pasan.
- [ ] `test_entry_field_isSecretHidden()` — secret y pin ocultos por defecto en UI.

---

## Task 2: VaultEntry — Modelo de Entrada

**Files:**
- Create: `lib/data/models/vault_entry.dart`
- Test: `test/models_test.dart` (añadir tests para VaultEntry)

**Interfaces:**
- Consumes: `EntryField`, `DateTime`.
- Produces: `toJson()`, `fromJson(Map<String, dynamic>)`, `copyWith({...})`.

**Especificaciones:**
- Campos: `id` (String, UUID), `title` (String, required), `categoryId` (String),
  `person` (String?, null por defecto), `fields` (`List<EntryField>`),
  `notes` (String, nullable), `isFavorite` (bool, false por defecto),
  `createdAt` (`DateTime`, auto al crear), `updatedAt` (`DateTime`, auto en cambios),
  `deletedAt` (`DateTime?`, null = activa, no nulo = en papelera).
- `copyWith` usa indicadores: `clearPerson()`, `clearDeletedAt()` para distinguir.
- Métodos: `toJson()`, `fromJson(Map<String, dynamic>)`, `copyWith({...})`.
- `isDeleted` getter: devuelve `deletedAt != null`.

**Tests:**
- [ ] `test_vault_entry_json_roundTrip()` — ida y vuelta JSON.
- [ ] `test_vault_entry_copyWith()` — copyWith actualiza solo los campos pasados.
- [ ] `test_vault_entry_clearPerson()` — clearPerson deja person en blanco si no se pasa.
- [ ] `test_vault_entry_isDeleted()` — isDeleted devuelve true si deletedAt != null.
- [ ] `test_vault_entry_fieldsSerialization()` — fields se serializan correctamente.

---

## Task 3: VaultDocument — Modelo de Documento

**Files:**
- Create: `lib/data/models/vault_document.dart`
- Test: `test/models_test.dart` (añadir tests para VaultDocument)

**Interfaces:**
- Consumes: `VaultEntry`, `DateTime`.
- Produces: `toJson()`, `fromJson(Map<String, dynamic>)`, `copyWith({...})`.

**Especificaciones:**
- Campos: `version` (int, 1 por defecto), `entries` (`List<VaultEntry>`).
- Métodos: `toJson()`, `fromJson(Map<String, dynamic>)`, `copyWith({version, entries})`.
- Validación: `entries` no puede estar vacío al crear.

**Tests:**
- [ ] `test_vault_document_json_roundTrip()` — ida y vuelta JSON.
- [ ] `test_vault_document_copyWith()` — copyWith actualiza solo los campos pasados.
- [ ] `test_vault_document_emptyEntries()` — entries vacías no se permiten al crear.
- [ ] `test_vault_document_versionDefault()` — version es 1 por defecto.

---

## Task 4: VaultFileSystem — Gestión de Rutas Privadas y Escritura Atómica

**Files:**
- Create: `lib/data/vault_file_system.dart`
- Test: `test/vault_storage_test.dart` (añadir tests para VaultFileSystem)

**Interfaces:**
- Consumes: `path_provider`, `flutter_secure_storage`.
- Produces: `vaultPath` (String), `saveVault(String path, Uint8List data)`,
  `loadVault(String path)` → `Uint8List?`.

**Especificaciones:**
- **Ruta privada:** Android (`/data/data/<package>/files/llavero/vault.dat`),
  iOS (`Documents/llavero/vault.dat`).
- **Escritura atómica:** escribir en `vault.dat.tmp`, luego renombrar a `vault.dat`.
- **Lectura:** leer directamente de `vault.dat`.
- **Error handling:** si el archivo no existe, devolver null.

**Tests:**
- [ ] `test_vault_file_system_path()` — ruta correcta en Android/iOS.
- [ ] `test_vault_file_system_saveLoad()` — guardar y cargar funciona.
- [ ] `test_vault_file_system_atomicWrite()` — escribir en .tmp y renombrar.
- [ ] `test_vault_file_system_nonExistent()` — archivo no existe, devuelve null.
- [ ] `test_vault_file_system_corrupted()` — archivo corrupto, lanza Exception.

---

## Task 5: VaultStorage — Cifrado y Descifrado del Archivo

**Files:**
- Create: `lib/data/vault_storage.dart`
- Test: `test/vault_storage_test.dart` (añadir tests para VaultStorage)

**Interfaces:**
- Consumes: `VaultDocument`, `KeyVaultService` (Fase 2), `EntryField`.
- Produces: `Uint8List` (blob cifrado), descifra `Uint8List` → `VaultDocument`.

**Especificaciones:**
- **Cabecera legible:** formato, versión, fecha, parámetros del KDF (JSON).
- **Contenido cifrado:** JSON de entries → Uint8List AES-256-GCM con DEK.
- **AAD:** contexto distinto para cada cifrado (`dek-wrap`, `vault`, `backup`).
- **Nonce:** aleatorio para cada cifrado.

**Tests:**
- [ ] `test_vault_storage_roundTrip()` — guardar y cargar es idempotente.
- [ ] `test_vault_storage_wrongKey()` — clave incorrecta falla sin exponer datos.
- [ ] `test_vault_storage_manipulated()` — contenido manipulado detectado (tag GCM).
- [ ] `test_vault_storage_truncated()` — blob truncado falla.
- [ ] `test_vault_storage_headerSerialization()` — cabecera se serializa correctamente.

---

## Task 6: EntriesController — Controlador de Entradas (CRUD)

**Files:**
- Create/Modify: `lib/controllers/entries_controller.dart`
- Test: `test/entries_controller_test.dart` (adaptar y añadir tests de CRUD)

**Interfaces:**
- Consumes: `VaultStorage`, `LockController` (Fase 2), `SettingsController`.
- Produces: entradas en memoria, métodos CRUD.

**Especificaciones:**
- **Estado:** `entries` (`List<VaultEntry>`), `_isLocked` (bool).
- **Inicialización:** leer archivo al abrir la bóveda, borrar memoria al cerrar.
- **CRUD:** `add(VaultEntry)`, `update(String id, VaultEntry)`,
  `moveToTrash(String id)`, `restore(String id)`, `deleteForever(String id)`,
  `toggleFavorite(String id)`, `duplicate(VaultEntry)`, `purgeExpiredTrash()`.
- **Búsqueda:** por `title`, `person` y etiqueta de campo (`EntryFieldType`).
  **Nunca** por valor de un secreto.
- **Filtros:** `favorites`, `trashed`, `persons`, `categoryIds`.
- **Persistencia:** reescribir archivo en cada cambio, borrar memoria al cerrar.

**Tests:**
- [ ] `test_entries_controller_add()` — añadir entrada, se guarda en archivo.
- [ ] `test_entries_controller_update()` — actualizar entrada, se guarda en archivo.
- [ ] `test_entries_controller_moveToTrash()` — mover a papelera, deletedAt != null.
- [ ] `test_entries_controller_restore()` — restaurar de papelera, deletedAt = null.
- [ ] `test_entries_controller_deleteForever()` — borrar de papelera permanentemente.
- [ ] `test_entries_controller_toggleFavorite()` — alternar favorito.
- [ ] `test_entries_controller_duplicate()` — duplicar entrada con nuevo ID.
- [ ] `test_entries_controller_purgeExpiredTrash()` — borrar entradas > 30 días.
- [ ] `test_entries_controller_searchTitle()` — buscar por título (incluye en valor).
- [ ] `test_entries_controller_searchPerson()` — buscar por persona (en campos).
- [ ] `test_entries_controller_searchLabel()` — buscar por etiqueta de campo.
- [ ] `test_entries_controller_searchNoSecrets()` — no buscar en valores secretos.
- [ ] `test_entries_controller_trashedFilter()` — filtro trashed ignora deletedAt = null.
- [ ] `test_entries_controller_locked()` — operaciones fallan si la bóveda está cerrada.

---

## Task 7: Integración y Tests Completos

**Files:**
- Modify: `test/models_test.dart` (consolidar tests de modelos)
- Modify: `test/vault_storage_test.dart` (consolidar tests de almacenamiento)
- Modify: `test/entries_controller_test.dart` (añadir tests de integración)

**Especificaciones:**
- **Total: 39 nuevos tests** (6 Fase 1 + 33 Fase 3).
- **Modelos:** ida y vuelta JSON, tipos desconocidos, copyWith con campos nulos.
- **Archivo:** ida y vuelta, secretos no en claro, clave incorrecta, manipulación.
- **CRUD:** crear, editar, papelera, restaurar, borrar, favorita, duplicar, purga.
- **Búsqueda:** por título/persona/etiqueta; nunca por valor secreto; ignora papelera.
- **Persistencia:** cambios sobreviven a "reiniciar", archivo se reescribe en cada cambio.

**Tests:**
- [ ] `test_models_all()` — ejecutar todos los tests de modelos.
- [ ] `test_vault_storage_all()` — ejecutar todos los tests de almacenamiento.
- [ ] `test_entries_controller_integration()` — test completo de flujo CRUD.

---

## Plan de Ejecución (Recomendado: Subagent-driven)

### Orden sugerido:
1. Task 1 (EntryField) — modelo más simple, base para los demás.
2. Task 2 (VaultEntry) — depende de EntryField.
3. Task 3 (VaultDocument) — depende de VaultEntry.
4. Task 4 (VaultFileSystem) — infraestructura para guardar/cargar.
5. Task 5 (VaultStorage) — depende de VaultFileSystem y Fase 2.
6. Task 6 (EntriesController) — depende de todos los anteriores.
7. Task 7 (Integración y Tests Completos) — consolidar y verificar todo.

### Por qué subagent-driven:
- Las tareas dependen de interfaces definidas en tareas anteriores.
- Cada tarea tiene sus propios tests que deben pasar antes de la siguiente.
- Es más seguro para no romper el código existente.

---

## Checklist de Verificación Final

- [ ] `flutter analyze` → sin problemas.
- [ ] `flutter test` → 39+ tests nuevos, todos pasan.
- [ ] **Modelos:** inmutables, `copyWith` correcto, serialización idempotente.
- [ ] **Archivo:** cifrado AES-256-GCM, cabecera legible, escritura atómica.
- [ ] **Secretos:** no se exponen en el archivo ni en la búsqueda.
- [ ] **Papelera:** 30 días de retención, purga automática.
- [ ] **Bloqueo:** operaciones fallan si la bóveda está cerrada (Fase 2).

---

## Notas para el Desarrollador

- **No uses `json_serializable`:** todo a mano.
- **Usa `copyWith` con cuidado:** los campos nulos deben distinguirse de "no cambiar".
- **Nonce aleatorio:** genera un nuevo nonce para cada cifrado.
- **AAD:** usa contexto distinto para `dek-wrap`, `vault` y `backup`.
- **Tests de integración:** crea un archivo `.llavero` de prueba con varias entradas.

---

**Plan completo y guardado en `docs/superpowers/plans/2026-11-25-fase3-modelos-crud-y-archivo-cifrado.md`.**

¿Quieres que implemente este plan ahora? Elige:
- **Subagent-driven:** Un subagent implementa cada tarea y un revisor la verifica antes de continuar.
- **Native:** Yo implemento todas las tareas en esta sesión, luego un revisor verifica la rama completa.

**Recomendado: Subagent-driven**, porque las tareas dependen de interfaces en secuencia y un error en una tarea podría romper la siguiente.