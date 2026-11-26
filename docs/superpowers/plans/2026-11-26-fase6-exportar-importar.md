# Fase 6: Exportar/Importar — Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir exportar la bóveda como respaldo cifrado `.llavero`, JSON/CSV y PDF, e importar un respaldo cifrado.

**Architecture:** `BackupCrypto` ya existe (Fase 2). Fase 6 añade `ExportService` (formatos + escritura de archivos) y la UI `ExportImportScreen` con `file_picker`, `share_plus` y `printing`.

**Tech Stack:** `cryptography`, `share_plus`, `file_picker`, `pdf`, `printing`, `path_provider`.

**Spec:** PROGRESS.md — "Fase 6 | Exportar/importar (backup cifrado, CSV/JSON, PDF) | Pendiente".

---

## Global Constraints

- Solo dependencias permitidas; sin generación de código; offline 100%.
- Idiomas ES/EN con fallback a español.
- Los secretos NUNCA se exportan en claro en JSON/CSV/PDF.
- El respaldo `.llavero` usa una contraseña distinta del PIN.
- Tests TDD; `flutter analyze` limpio y suite verde.

---

## Review Focus

1. Secretos en claro en JSON/CSV/PDF → deben aparecer como `[oculto]`.
2. Respaldo cifrado con contraseña errónea → error, sin exponer datos.
3. Importar backup reemplaza la bóveda actual → confirmación.
4. Archivos temporales → se limpian.

---

## Tasks

### Task 1: Servicio de exportación/importación

- Create: `lib/data/export_service.dart`
- Test: `test/export_service_test.dart`

- [ ] Exportar backup cifrado `.llavero` (usa BackupCrypto).
- [ ] Importar backup cifrado y devolver `VaultDocument`.
- [ ] Exportar JSON y CSV sin valores secretos (`[oculto]`).
- [ ] Generar PDF con el mismo contenido (sin secretos).

### Task 2: Pantalla de exportar/importar

- Create: `lib/features/export_import/export_import_screen.dart`
- Modify: `lib/core/routes/app_routes.dart`
- Test: `test/export_import_screen_test.dart`

- [ ] UI con contraseña de respaldo, botones exportar e importar.
- [ ] Compartir archivo (`share_plus`) e imprimir PDF (`printing`).

### Task 3: Integración final

- [ ] `flutter analyze` limpio; `flutter test` verde.
- [ ] Actualizar PROGRESS.md y CHANGELOG.md.
- [ ] Commit de la Fase 6 en `master`.
