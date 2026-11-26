# Fase 5: Inicio, CRUD de entradas, plantillas, generador y papelera — Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar la interfaz funcional de la bóveda: listado de entradas con búsqueda/filtros, alta y edición, detalle con secretos ocultos, plantillas, generador de contraseñas y papelera.

**Architecture:** La lógica ya existe en `EntriesController` (CRUD, búsqueda, filtros, papelera). Fase 5 añade las pantallas (Home, EntryForm, EntryDetail, Trash) y servicios de apoyo (PasswordGenerator, EntryTemplates) manteniendo el patrón de controladores testeables y `AppScope.of(context)` en la UI.

**Tech Stack:** Flutter (Material 3), controladores `ChangeNotifier`, `flutter_localizations`, `intl`, `uuid`.

**Spec:** PROGRESS.md — "Fase 5 | Inicio, CRUD de entradas, plantillas, generador de contraseñas, papelera | Pendiente".

---

## Global Constraints

- Solo dependencias permitidas; sin generación de código; offline 100%.
- Idiomas ES/EN con fallback a español.
- Los valores `secret`/`pin` se ocultan por defecto en la UI.
- La búsqueda nunca debe mostrar valores de secretos.
- Borrar → papelera (30 días); restaurar y borrar para siempre disponibles.
- Tests TDD; `flutter analyze` limpio y suite verde.

---

## Review Focus

1. **Secretos en pantalla:** ningún valor `secret`/`pin` se muestra en claro por defecto.
2. **Búsqueda:** no debe filtrar por valores secretos.
3. **Papelera:** los elementos borrados no aparecen en el listado normal.
4. **Bóveda cerrada:** las operaciones fallan (StateError).

---

## Tasks

### Task 1: Servicio de generación de contraseñas

- Create: `lib/core/security/password_generator.dart`
- Test: `test/password_generator_test.dart`

- [ ] Generar contraseña aleatoria con longitud configurable y conjuntos de caracteres (mayúsculas, minúsculas, dígitos, símbolos), garantizando al menos un carácter de cada conjunto seleccionado.
- [ ] Generar PIN numérico de N dígitos.

### Task 2: Plantillas de entradas

- Create: `lib/data/entry_templates.dart`
- Test: `test/entry_templates_test.dart`

- [ ] Definir plantillas (Wi-Fi, contraseña web, PIN, tarjeta, nota) que producen una `VaultEntry` con campos y tipos adecuados.

### Task 3: Pantalla Home (listado + búsqueda + filtros)

- Create: `lib/features/home/home_screen.dart` (sustituir placeholder)
- Modify: `lib/core/routes/app_routes.dart`
- Test: `test/home_screen_test.dart`

- [ ] Listar entradas activas; buscar; filtrar por favoritos/categoría/persona.
- [ ] Botón para crear entrada → `/entry/form`.

### Task 4: Formulario de entrada (alta/edición) con generador

- Create: `lib/features/entries/entry_form_screen.dart`
- Modify: `lib/core/routes/app_routes.dart`
- Test: `test/entry_form_screen_test.dart`

- [ ] Crear y editar entradas (título, categoría, persona, campos, notas, favorita).
- [ ] selector de plantilla; botón de generar contraseña.

### Task 5: Detalle de entrada con secretos ocultos

- Create: `lib/features/entries/entry_detail_screen.dart`
- Modify: `lib/core/routes/app_routes.dart`
- Test: `test/entry_detail_screen_test.dart`

- [ ] Ver campos; secretos ocultos con botón de revelar; copiar al portapapeles.
- [ ] Acciones: editar, mover a papelera, favorita, duplicar.

### Task 6: Papelera

- Create: `lib/features/trash/trash_screen.dart`
- Modify: `lib/core/routes/app_routes.dart`
- Test: `test/trash_screen_test.dart`

- [ ] Listar entradas en papelera; restaurar; borrar para siempre; purgar.

### Task 7: Integración y verificación final

- [ ] `flutter analyze` limpio.
- [ ] `flutter test` verde.
- [ ] Actualizar PROGRESS.md y CHANGELOG.md.
- [ ] Commit de la Fase 5 en `master`.
