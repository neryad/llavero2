# Fase 7: Ajustes, estado de seguridad, bloqueo automático y capturas — Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar la pantalla de ajustes real, el estado de seguridad, el bloqueo automático al pasar a segundo plano y el bloqueo de capturas de pantalla.

**Architecture:** `SettingsController` ya tiene tema, idioma, `autoLockDelay`, `blockScreenshots`, `clipboardTimeout` y `pinLength`. Fase 7 añade la UI de ajustes, un observador de ciclo de vida para el bloqueo automático y un canal nativo para las capturas.

**Tech Stack:** Flutter (Material 3), `WidgetsBindingObserver`, `MethodChannel`, Android `FLAG_SECURE`, iOS overlay de captura.

**Spec:** PROGRESS.md — "Fase 7 | Ajustes, estado de seguridad, bloqueo automático, capturas bloqueadas | Pendiente".

---

## Global Constraints

- Solo dependencias permitidas; sin generación de código; offline 100%.
- Idiomas ES/EN con fallback a español.
- PIN siempre plan B aunque haya biometría.
- Tests TDD; `flutter analyze` limpio y suite verde.

---

## Review Focus

1. Bloqueo automático: al pasar a segundo plano con retardo `immediately`, se bloquea.
2. Capturas: `blockScreenshots` activa el canal nativo (FLAG_SECURE).
3. Biometría: solo se activa si hay bóveda abierta (DEK).
4. PIN length: 4–8, se guarda en ajustes.

---

## Tasks

### Task 1: Canal nativo de seguridad de pantalla

- Create: `lib/core/platform/screen_security.dart`
- Modify: `android/.../MainActivity.kt`, `ios/.../AppDelegate.swift`
- Test: `test/screen_security_test.dart`

- [ ] `ScreenSecurity.setScreenshotsBlocked(bool)` vía MethodChannel, tolerante a `MissingPluginException`.

### Task 2: Bloqueo automático por ciclo de vida

- Create: `lib/core/widgets/app_lifecycle_lock.dart`
- Test: `test/app_lifecycle_lock_test.dart`

- [ ] Observar el ciclo de vida; al pasar a segundo plano, bloquear según `AutoLockDelay`.

### Task 3: Pantalla de ajustes real

- Create: `lib/features/settings/settings_screen.dart`
- Modify: `lib/core/routes/app_routes.dart`
- Test: `test/settings_screen_test.dart`

- [ ] Tema, idioma, retardo de bloqueo, longitud PIN, biometría, capturas, estado de seguridad, export/import.

### Task 4: Integración final

- [ ] `flutter analyze` limpio; `flutter test` verde.
- [ ] Actualizar PROGRESS.md y CHANGELOG.md.
- [ ] Commit de la Fase 7 en `master`.
