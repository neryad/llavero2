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

- [x] **3. Switch de biometría honesto.** ✅ Completada 2026-11-26 — el switch
  se deshabilita cuando la bóveda está cerrada (sin DEK) y muestra el texto
  «Disponible solo con la bóveda abierta.» en ES/EN. La pantalla ahora escucha
  también los cambios del `LockController`. 2 tests nuevos.

- [x] **4. Tests en dispositivo real.** ✅ Completada 2026-11-26 —
  `flutter build apk --debug` compila el Kotlin (FLAG_SECURE), la app se instaló
  y arrancó en `emulator-5554` sin excepciones en logcat, se añadieron tests de
  contrato de canales (`local_auth`, `share_plus`) y de escritura real en disco,
  `docs/PRUEBAS_DISPOSITIVO.md`. El build de iOS detectó y permitió corregir
  3 errores reales de Swift en el anti-capturas (`primaryWindow` y
  `autoresizingMask`), y ahora `flutter build ios --no-codesign` compila.
  Queda pendiente la ejecución manual interactiva de cada plugin (huella real,
  compartir, imprimir), documentada paso a paso en esa guía.

---

## 🟠 Prioridad 2 — Seguridad y robustez

- [x] **5. Argon2id en Dart puro.** ✅ Completada 2026-11-26 — la memoria es
  configurable con `--dart-define=LLAVERO_KDF_MEMORY_KIB=32768` sin cambiar el
  formato del archivo. Benchmark real en `emulator-5554`: **64 MiB → 766 ms**,
  32 MiB → 168 ms, 16 MiB → 87 ms (todos <2 s), así que se mantiene 64 MiB por
  defecto. 4 tests nuevos + `tool/bench_kdf_device.dart`.

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
| 1 | 4 | 4 |
| 2 | 1 | 5 |
| 3 | 0 | 8 |
| 4 | 0 | 3 |
| **Total** | **5** | **20** |

Última actualización: 2026-11-26 (mejoras #1 a #5 completadas).
