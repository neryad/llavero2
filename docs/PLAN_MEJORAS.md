# Plan de mejoras — Llavero

Lista viva de limitaciones y mejoras pendientes, ordenadas por prioridad.
Cada ítem se marca con `[x]` cuando está implementado y verificado.

**Regla:** se trabaja en el orden indicado. Al completar un ítem se actualiza
este archivo y se hace commit.

---

## 🔴 Prioridad 1 — Deuda que se debe corregir

- [x] **1. Cambio de PIN.** ✅ Completada 2026-11-26 — `VaultKeyService.changePin`
  re-envuelve la DEK con una KEK nueva y sal nueva (sin re-cifrar los datos);
  `LockController.changePin` y la pantalla `/settings/change-pin` validan el
  PIN actual, el nuevo y su confirmación. El ajuste `pinLength` se actualiza
  con la longitud real del nuevo PIN. 4 tests nuevos.

- [x] **2. Aviso de PIN olvidado en el onboarding.** ✅ Completada 2026-11-26 —
  banner `PinLossWarning` en la pantalla de onboarding y en la creación del PIN,
  en ES/EN, indicando que solo un respaldo cifrado permite recuperar los datos.
  3 tests nuevos.

- [ ] **3. Switch de biometría honesto.** Deshabilitarlo (o avisar) cuando la
  bóveda esté cerrada: hoy `setBiometricsEnabled(true)` no hace nada y el
  usuario cree que lo activó.

- [ ] **4. Tests en dispositivo real.** `local_auth`, `file_picker`,
  `share_plus`, `printing` y escritura en almacenamiento; los bugs reales
  (como el `PathNotFoundException`) solo aparecen en hardware.

---

## 🟠 Prioridad 2 — Seguridad y robustez

- [ ] **5. Argon2id en Dart puro** (sin aceleración nativa permitida). Medir en
  gama baja; si tarda >2 s, bajar a 32 MiB (no cambia el formato del archivo).

- [ ] **6. Detección de root/jailbreak** conadvertencia opcional.

- [ ] **7. Ofuscación del binario** (`flutter build --obfuscate`).

- [ ] **8. Aclarar en la UI que el anti-capturas de iOS es un overlay**, no un
  bloqueo del sistema como `FLAG_SECURE`.

- [ ] **9. Evitar la re-lectura del archivo en cada cambio** en
  `EntriesController._saveToStorage()` (guarda y luego descifra de nuevo).

---

## 🟡 Prioridad 3 — Funcionalidad

- [ ] **10. Sincronización entre dispositivos** ( hoy solo migración manual
  con respaldo cifrado).

- [ ] **11. Purga automática de la papelera** al desbloquear o al iniciar.

- [ ] **12. Búsqueda en notas** (sin incluir secretos).

- [ ] **13. Categorías personalizadas** (los IDs ya son cadenas).

- [ ] **14. Opción de exportar secretos en claro** con doble confirmación
  (por defecto siguen siendo `[oculto]`).

- [ ] **15. Pantalla real de "security health"** (ruta `/security-health` hoy
  es `ComingSoon`): contraseñas débiles, repetidas o antiguas.

- [ ] **16. Historial/versiones locales de la bóveda** para recuperar borrados
  antes de los 30 días de papelera.

- [ ] **17. Soporte real de escritorio/web** (hoy solo móvil).

---

## 🔧 Prioridad 4 — Calidad interna

- [ ] **18. Wiring explícito de desbloqueo.** `AppControllers` lanza
  `entries.load()` sin `await`; añadir `unlockWithDek()` que devuelva `Future`
  y esperarlo en `LockController`/UI.

- [ ] **19. Inicializar siempre el directorio con `path_provider`.** El fallback
  de iOS sigue siendo relativo (`Documents/llavero/vault.dat`).

- [ ] **20. Re-resolver la ruta si cambia el directorio de la app** tras una
  actualización.

---

## Progreso

| Prioridad | Completadas | Totales |
|---|---|---|
| 1 | 2 | 4 |
| 2 | 0 | 5 |
| 3 | 0 | 8 |
| 4 | 0 | 3 |
| **Total** | **2** | **20** |

Última actualización: 2026-11-26 (mejoras #1 y #2 completadas).
