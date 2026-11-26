# Fase 4: Onboarding, PIN, Biometría y Pantalla de Bloqueo — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el flujo completo de primera ejecución (onboarding para crear PIN), la pantalla de bloqueo con PIN y biometría, y la gestión de bloqueo.

**Architecture:** La lógica de estado ya existe (`LockController`, `VaultKeyService`, `LockoutPolicy`). Fase 4 añade la capa de UI (onboarding, lock screen) y la wiring entre controladores (LockController → EntriesController) para el desbloqueo.

**Tech Stack:** Flutter (Material 3), `local_auth`, `flutter_secure_storage`, `flutter_localizations`, `intl`.

**Spec:** PROGRESS.md — "Fase 4 | Onboarding, PIN, biometría, pantalla de bloqueo | Pendiente".

---

## Global Constraints

- **Solo dependencias permitidas:** `cryptography`, `flutter_secure_storage`, `local_auth`, `path_provider`, `share_plus`, `file_picker`, `pdf` + `printing`, `qr_flutter`, `package_info_plus`, `uuid`.
- **Sin generación de código** para modelos/serialización existentes; mantener el patrón manual.
- **Offline 100%** en release; sin `google_fonts`.
- **Idiomas:** ES/EN con `flutter_localizations`; fallback a español si el idioma del dispositivo no es es/en.
- **PIN:** 4–8 dígitos (6 por defecto, configurable), sin dígitos repetidos/secuencias/comunes, solo dígitos.
- **Bloqueo:** escalonado 30s → 1m → 5m → 15m → 1h; estado en almacén seguro.
- **Biometría:** copia DEK en almacén seguro; solo se lee tras `local_auth` confirma; PIN siempre plan B.
- **Tests:** TDD; suite completa debe pasar (`flutter analyze` limpio + `flutter test`).

---

## Review Focus

1. **Onboarding con PIN ya existente:** no debe mostrarse si ya existe bóveda.
2. **PIN inválido en onboarding:** rechazar triviales/secuencias/repetidos/comunes.
3. **Bloqueo activo:** mientras esté bloqueada, la app no debe derivar clave ni permitir intentos.
4. **Biometría:** solo se intenta tras confirmación `local_auth`; fallo → PIN plan B.

---

## Tasks

### Task 1: Onboarding — crear bóveda con PIN

**Files:**
- Create: `lib/features/onboarding/onboarding_screen.dart`
- Create: `lib/features/onboarding/pin_create_screen.dart`
- Modify: `lib/controllers/lock_controller.dart`

**Interfaces:**
- Consumes: `LockController`, `PinValidator`, `VaultKeyService`.
- Produces: flujo onboarding → `LockController.setHasPin(true)` → `createVault(pin)`.

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('onboarding crea bóveda con PIN válido', (tester) async {
  // ...
  expect(await service.hasVault(), isTrue);
});

testWidgets('onboarding no se muestra si ya existe bóveda', (tester) async {
  // ...
  expect(find.byType(OnboardingScreen), findsNothing);
});
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

### Task 2: Pantalla de bloqueo — PIN + biometría

**Files:**
- Create: `lib/features/lock/lock_screen.dart`
- Modify: `lib/controllers/lock_controller.dart`

**Interfaces:**
- Consumes: `LockController`, `PinValidator`, `LockoutPolicy`.
- Produces: `submitPin`, `unlockWithBiometrics`, estado lockout.

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

### Task 3: Biometría — habilitar/deshabilitar + unlock

**Files:**
- Modify: `lib/controllers/lock_controller.dart`
- Modify: `lib/core/security/key_vault_service.dart` (si falta enable/disable wiring)

**Interfaces:**
- Consumes: `VaultKeyService`, `local_auth`.
- Produces: `enableBiometrics`, `disableBiometrics`, `unlockWithBiometrics`.

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

### Task 4: Integración — wiring LockController → EntriesController + flujo completo

**Files:**
- Modify: `lib/core/app_scope.dart`
- Modify: `lib/controllers/entries_controller.dart`

**Interfaces:**
- Consumes: `LockController`, `EntriesController`, `VaultKeyService`.
- Produces: desbloqueo con DEK → `EntriesController.load(dek)`.

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

## Plan complete and saved to `docs/superpowers/plans/2026-11-25-fase4-onboarding-pin-biometria-bloqueo.md`.

Please review the plan. Which execution approach would you prefer?

- **Subagent-driven** - A fresh subagent implements each task and a fresh reviewer checks it before the next one starts, then a whole-branch review at the end. Most thorough; costs a fresh context per task and per review.
- **Native** - I implement every task myself in this session, the way this harness runs work, then one fresh reviewer on the most capable model checks the whole branch. Cheapest and fastest; no independent review until the end. Runs well with a mid-tier session model, since the plan carries the design.

**For this plan I recommend <one of the two>, because <one sentence from the plan: how much the tasks depend on each other's interfaces, how many there are, what a shipped mistake would cost>. Does the plan capture what you want, and which approach should we use?**