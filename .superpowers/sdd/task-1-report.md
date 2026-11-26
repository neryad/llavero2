# Task 1 — Fase 4: Onboarding — crear bóveda con PIN

> **Plan:** `docs/superpowers/plans/2026-11-25-fase4-onboarding-pin-biometria-bloqueo.md`
> **Fecha:** 2026-11-25

## Resumen

Implementado el flujo de primera ejecución del onboarding: cuando la app arranca
y todavía **no existe bóveda** (PIN no creado), el usuario llega al onboarding,
escribe su PIN (validación con `PinValidator`), lo confirma y se crea la bóveda
a través del `LockController` → `VaultKeyService.createVault(pin)`.

Al crear la bóveda, el `LockController` pasa a estado **bloqueado** (`hasPin =
true`, lockout reiniciado) para que la pantalla de bloqueo (tarea 2) sea quien
pida el PIN.

## Archivos creados

- `lib/features/onboarding/onboarding_screen.dart` — pantalla de bienvenida del
  onboarding (icono, título, mensaje, CTA "Crear bóveda").
- `lib/features/onboarding/pin_create_screen.dart` — flujo de PIN (fase 1: primer
  PIN validado con `PinValidator`; fase 2: confirmación; al acertar crea la
  bóveda).
- `test/onboarding_test.dart` — tests del flujo de onboarding.

## Archivos modificados

- `lib/controllers/lock_controller.dart`:
  - Nuevo `LockController.createVault(String pin)`: delega en el
    `VaultKeyService.createVault(pin)` y, tras crearla, fija `hasPin = true`,
    `_isLocked = true` y resetea el lockout.
  - Nuevo getter `LockController.initialized`: indica si `initialize()` ya revisó
    si existe bóveda (permite a la UI decidir el flujo sin disparar `initialize`).
- `lib/features/splash/splash_screen.dart` — decide (con el estado del
  `LockController` ya inicializado) entre continuar al onboarding o al flujo
  normal.
- `lib/core/routes/app_routes.dart` — la ruta `/onboarding` ahora sirve
  `OnboardingScreen` (antes caía en `ComingSoonScreen`).
- `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` + regeneración
  (`lib/l10n/generated/*`) — nuevas claves: `onboardingTitle`,
  `onboardingMessage`, `createVaultLabel`, `pinLabel`, `confirmPinLabel`,
  `pinMismatchError`, `pinInvalidError`.

## Tests añadidos (task 1)

En `test/onboarding_test.dart` (sobre un `AppControllers` real con
`FakeVaultKeyService` + `InMemoryLockoutStore` + `MemoryVaultFileSystem`):

1. `onboarding crea la bóveda con un PIN válido` — entra el flujo completo
   (Continuar → onboarding → primer PIN `482913` → validación → confirmación →
   creación) y verifica que `hasVault()` pasa a `true`, `lock.hasPin == true` y
   `lock.isLocked == true`.
2. `onboarding no se muestra si ya existe bóveda` — con bóveda existente el
   onboarding no se muestra.
3. `onboarding rechaza un PIN inválido y no crea la bóveda` — PIN de secuencia
   (`123456`) rechazado con el error correspondiente y sin crear bóveda.

## Verificación

- `flutter analyze` → **sin issues**.
- `flutter test` → **92 pruebas, todas pasando** (89 existentes + 3 nuevas de
  onboarding; ninguna existente se rompió).

## Decisiones de diseño

- El routing splash → onboarding se basa en `lock.initialized && !lock.hasPin`
  para no disparar la lectura del estado antes de tiempo.
- Tras crear el PIN válido y coincidente, `PinCreateScreen` hace
  `Navigator.popUntil` al primer route (vuelve al splash), que ahora ve
  `hasPin == true` y continúa al flujo normal.
- El lock screen (tarea 2) tomará el relevo desde el estado bloqueado que deja el
  onboarding creado.
