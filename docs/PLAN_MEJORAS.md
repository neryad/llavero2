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

- [x] **6. Detección de root/jailbreak.** ✅ Completada 2026-11-26 — canal
  `llavero/device_integrity` con heurísticas en Kotlin (rutas `su`, build tags)
  y Swift (Cydia, MobileSubstrate, sandbox roto). Aviso informativo en Ajustes,
  en ES/EN. 3 tests nuevos y builds nativos verificados. Es solo una señal,
  nunca una barrera.

- **Ofuscación del binario** (`flutter build --obfuscate`). ✅ Completada
  2026-11-26 — se documentaron los comandos de release con `--obfuscate`,
  `--split-debug-info` y `--strip` para Android e iOS; ambos builds se
  verificaron. Los símbolos se guardan fuera del repositorio en
  `build/symbols/`.

- [x] **8. Aclarar el anti-capturas de iOS en la UI.** ✅ Completada
  2026-11-26 — el ajuste «Bloquear capturas» muestra en iOS la nota
  «no se pueden bloquear: la app solo oscurece la pantalla», en ES/EN.
  1 test nuevo.

- [x] **9. Evitar la re-lectura del archivo en cada cambio.** ✅ Completada
  2026-11-26 — `_saveToStorage()` ya no vuelve a cargar/descifrar el archivo;
  tras guardar solo notifica a la interfaz. La memoria es la fuente de verdad
  y se elimina la ventana de divergencia. 2 tests nuevos.

---

## 🟡 Prioridad 3 — Funcionalidad

- [~] **10. Sincronización entre dispositivos.** ⏸️ Diferida por decisión del
  usuario 2026-11-26: contradice el principio «100 % offline» de Llavero.
  El flujo manual exportar/importar con respaldo cifrado ya cubre la
  migración. No se implementará sin rediseñar el modelo de seguridad.

- [x] **11. Purga automática de la papelera** al abrir la bóveda. ✅ Completada
  2026-11-26 — `EntriesController.open()` carga y llama a `purgeExpiredTrash()`;
  `AppControllers` lo usa al desbloquear. Tests nuevos.

- [x] **12. Búsqueda en notas** (sin incluir secretos). ✅ Completada
  2026-11-26 — `search()` incluye las notas; se mantiene la regla de no buscar
  en valores secretos ni en la papelera. 4 tests nuevos.

- [x] **13. Categorías personalizadas.** ✅ Completada 2026-11-26 —
  `VaultCategory` + `CategoriesController` con persistencia en el almacén
  seguro, pantalla de gestión (crear/editar/borrar con paleta de colores),
  selector en el formulario y nombres traducidos en Home/detalle. No se puede
  borrar una categoría en uso. 2 tests nuevos.

- [x] **14. Opción de exportar secretos en claro.** ✅ Completada 2026-11-26 —
  `ExportService` acepta `includeSecrets` (por defecto `false`), la pantalla
  tiene un interruptor y pide **dos confirmaciones** antes de exportar JSON,
  CSV o PDF con secretos. El respaldo `.llavero` sigue siempre cifrado.
  4 tests nuevos.

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
| 2 | 3 | 5 |
| 3 | 4 | 8 |
| 4 | 0 | 3 |
| **Total** | **13** | **20** |

Última actualización: 2026-11-26 (13 completadas, 1 diferida).
