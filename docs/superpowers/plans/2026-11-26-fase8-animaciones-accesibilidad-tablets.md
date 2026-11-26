# Fase 8: Animaciones, accesibilidad, iconos, ES/EN y tablets — Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pulir la experiencia: animaciones sutiles, accesibilidad, iconos consistentes, revisión ES/EN y diseño adaptable a tablets.

**Architecture:** Se añaden widgets de animación reutilizables, se auditoría la localización con un test y se adapta el listado de Home a pantallas anchas mediante `LayoutBuilder`.

**Tech Stack:** Flutter (Material 3), `AnimatedList`/`TweenAnimationBuilder`, `Semantics`, `LayoutBuilder`.

**Spec:** PROGRESS.md — "Fase 8 | Animaciones, accesibilidad, iconos, revisión ES/EN, tablets | Pendiente".

---

## Global Constraints

- Solo dependencias permitidas; sin generación de código; offline 100%.
- Idiomas ES/EN con las mismas claves en ambos ARB.
- Respeto por `MediaQuery.disableAnimations` (accesibilidad).
- Áreas táctiles mínimas de 48dp.
- Tests TDD; `flutter analyze` limpio y suite verde.

---

## Review Focus

1. Animaciones desactivadas si el sistema lo pide.
2. Etiquetas semánticas en listas y botones icono.
3. AMBOS idiomas tienen todas las claves.
4. En tablets el contenido no se estira más de 720dp.

---

## Tasks

### Task 1: Animaciones sutiles y accesibles

- Create: `lib/core/widgets/animated_entry_tile.dart`
- Test: `test/animated_entry_tile_test.dart`

- [ ] Entrada animada (fade + slide) que respeta `disableAnimations`.

### Task 2: Accesibilidad e iconos

- Modify: `lib/features/home/home_screen.dart`, `lib/features/entries/*`, `lib/features/trash/*`
- Test: `test/accessibility_test.dart`

- [ ] Semantics en tarjetas, tooltips en botones icono, targets ≥48dp.

### Task 3: Revisión ES/EN

- Create: `test/l10n_completeness_test.dart`

- [ ] Los dos ARB tienen exactamente las mismas claves y no hay valores vacíos.

### Task 4: Diseño de tablets

- Modify: `lib/features/home/home_screen.dart`
- Test: `test/tablet_layout_test.dart`

- [ ] `LayoutBuilder`: rejilla de 2 columnas en pantallas anchas, lista en móvil.

### Task 5: Integración final

- [ ] `flutter analyze` limpio; `flutter test` verde.
- [ ] Actualizar PROGRESS.md y CHANGELOG.md.
- [ ] Commit de la Fase 8 en `master`.
