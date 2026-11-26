# Changelog

Todos los cambios notables de Llavero se documentan en este archivo.
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

---

## [FASE B] — 2026-11-26

### Fixed
- Critical C1–C7 y Bug B1–B12 de `AUDIT.md`, con tests por cada ítem.
- Exclusión iCloud al crear/sobrescribir/restaurar; portapapeles con temporizador.
- Re-auth antes de exportar y al desactivar biometría; bloqueo monótono.
- Cambio de PIN atómico con test de fallo intermedio.
- Export claro oculta secretos por tipo/etiqueta; IDs UUID al duplicar.
- Ajustes persistidos; merge/replace al importar; temporales borrados siempre.

### Removed
- Integridad del dispositivo, historial de bóveda y filas de estado en Ajustes.

---

## [Unreleased]

### Added
- **Plan de mejoras cerrado.** Se descartó la sincronización entre
  dispositivos: Llavero es 100 % offline por diseño y la migración se hace con
  respaldo cifrado. Plan final: 19/19 completadas.

- **Mejoras #19 y #20 del plan de mejoras: rutas resueltas.** Se eliminó el
  fallback relativo (`vaultPath` exige inicialización) y se re-resuelve la
  ruta en cada operación por si cambia tras una actualización. 5 tests nuevos.

- **Mejora #18 del plan de mejoras: wiring explícito de desbloqueo.** Los
  métodos `unlockWithPin`/`unlockWithBiometrics` de `AppControllers` esperan
  a que las entradas se carguen antes de navegar. 2 tests nuevos.

- **Mejora #17 del plan de mejoras: soporte de escritorio/web.**
  `PlatformCapabilities` deshabilita biometría y anti-capturas fuera de móvil
  y avisa en web del almacén no seguro; macOS exige deployment target 12.0.
  Builds macOS debug y web release verificados. 4 tests nuevos.

- **Mejora #16 del plan de mejoras: historial local de la bóveda.** Copias
  automáticas antes de cada escritura (máx. 10), pantalla para listar y
  restaurar versiones. 5 tests nuevos.

- **Mejora #15 del plan de mejoras: salud de contraseñas.** Pantalla real en
  `/security-health` con detección de contraseñas débiles y reutilizadas, sin
  revelar nunca los valores. Acceso desde Ajustes. 3 tests nuevos.

- **Mejora #14 del plan de mejoras: exportar secretos con doble confirmación.**
  `includeSecrets` en `ExportService` (por defecto `false`), interruptor en la
  UI y dos diálogos de confirmación para JSON/CSV/PDF. El respaldo cifrado
  sigue siempre sin secretos en claro. 4 tests nuevos.

- **Mejora #13 del plan de mejoras: categorías personalizadas.** Modelo,
  controlador persistente, pantalla de gestión con colores, selector en el
  formulario y nombres ES/EN en listas y detalle. 2 tests nuevos.

- **Mejora #12 del plan de mejoras: búsqueda en notas.** `search()` incluye el
  texto de las notas sin buscar nunca en valores secretos ni en la papelera.
  4 tests nuevos.

- **Mejora #11 del plan de mejoras: purga automática de la papelera.** Al abrir
  la bóveda se eliminan las entradas caducadas (>30 días) y se persiste el
  cambio. 1 test nuevo.

- **Mejora #9 del plan de mejoras: sin re-lectura del archivo.** Los cambios
  guardan una sola vez y notifican a la UI, sin volver a descifrar el archivo.
  2 tests nuevos.

- **Mejora #8 del plan de mejoras: nota sobre anti-capturas en iOS.** El
  ajuste muestra una explicación en ES/EN de que iOS no permite bloquear
  capturas y la app solo oscurece la pantalla. 1 test nuevo.

- **Mejora #7 del plan de mejoras: ofuscación.** Comandos de release con
  `--obfuscate`, `--split-debug-info` y `--strip` documentados en el README;
  builds Android e iOS verificados.

- **Mejora #6 del plan de mejoras: detección de root/jailbreak.** Canal
  `llavero/device_integrity` con heurísticas nativas y aviso informativo en
  Ajustes (ES/EN). 3 tests nuevos; builds Android e iOS verificados.

- **Mejora #5 del plan de mejoras: memoria de Argon2id configurable y medida.**
  `--dart-define=LLAVERO_KDF_MEMORY_KIB=32768` permite bajar a 32 MiB sin
  cambiar el formato. Benchmark real en emulador: 64 MiB → 766 ms, 32 MiB →
  168 ms, 16 MiB → 87 ms; se mantiene 64 MiB por defecto. 4 tests nuevos y
  `tool/bench_kdf_device.dart`.

- **Mejora #4 del plan de mejoras: verificación en dispositivo/build nativo.**
  Guía interactiva `docs/PRUEBAS_DISPOSITIVO.md`, tests de contrato de canales
  (`local_auth`, `share_plus`), instalación y arranque en emulador sin
  excepciones, y builds Android e iOS. El build de iOS detectó 3 errores de
  Swift en el anti-capturas, ya corregidos. 2 tests nuevos.

- **Mejora #3 del plan de mejoras: switch de biometría honesto.** Se
  deshabilita cuando la bóveda está cerrada y muestra una explicación en ES/EN;
  Ajustes escucha ahora los cambios del `LockController`. 2 tests nuevos.
- **Mejora #2 del plan de mejoras: aviso de PIN olvidado.** Banner visible en
  el onboarding y en la creación del PIN (ES/EN) indicando que solo un respaldo
  cifrado permite recuperar los datos. 3 tests nuevos.
- **Mejora #1 del plan de mejoras: cambio de PIN.** Se verifica el PIN actual,
  se valida el nuevo y se re-envuelve la DEK con una KEK nueva y sal nueva, sin
  re-cifrar los datos. Pantalla `/settings/change-pin` y 4 tests nuevos.
  El ajuste `pinLength` pasa a reflejar la longitud real del PIN.

---

## [Fase 9] — 2026-11-26

### Added
- **README completo**: características, arquitectura, modelo de seguridad
  (claves, bloqueo, formato de archivo), instrucciones de uso y de ejecución.
- **Lista honesta de limitaciones**: 13 puntos documentados (sin sync,
  biometría con bóveda abierta, sin cambio de PIN, exportación sin secretos,
  Argon2id en Dart puro, anti-capturas en iOS por overlay, etc.).

### Verification
- `flutter analyze` → sin problemas.
- `flutter test` → **139 pruebas, todas correctas**.

---

## [Fase 8] — 2026-11-26

### Added
- **Animaciones accesibles**: `AnimatedEntryTile` con fundido y desplazamiento
  escalonado, desactivado si el sistema pide reducir movimiento.
- **Accesibilidad**: etiquetas semánticas en tarjetas y búsqueda, iconos
  decorativos excluidos de semántica y tooltips en los botones icono.
- **Revisión ES/EN**: test que verifica que ambos archivos `.arb` tienen las
  mismas claves, textos no vacíos y sus metadatos.
- **Tablets**: el listado usa una rejilla de dos columnas en pantallas anchas;
  el contenido sigue limitado a 720dp.
- **8 tests nuevos** (animación, tablets y localización).

### Verification
- `flutter analyze` → sin problemas.
- `flutter test` → **139 pruebas, todas correctas**.

---

## [Fase 7] — 2026-11-26

### Added
- **Pantalla de ajustes real**: tema, idioma, longitud del PIN, bloqueo
  automático, tiempo en portapapeles y acceso a exportar/importar.
- **Estado de seguridad**: bóveda creada, estado de la biometría, intentos
  fallidos y botón «Bloquear ahora».
- **Bloqueo automático**: `AppLifecycleLock` bloquea la bóveda al pasar a
  segundo plano según el retardo configurado.
- **Bloqueo de capturas**: `ScreenSecurity` con `FLAG_SECURE` en Android y
  overlay oscuro en iOS al detectar captura o grabación.
- **Acceso a ajustes** desde la pantalla de inicio.
- **8 tests nuevos** (canal nativo, ciclo de vida y ajustes).

### Verification
- `flutter analyze` → sin problemas.
- `flutter test` → **131 pruebas, todas correctas**.

---

## [Fase 6] — 2026-11-26

### Added
- **Respaldo cifrado `.llavero`**: exportar e importar con contraseña
  independiente del PIN, usando Argon2id + AES-256-GCM (`BackupCrypto`).
- **Exportación JSON y CSV**: sin valores secretos en claro (`[oculto]`), con
  escapado correcto de comillas en CSV.
- **Exportación PDF**: resumen imprimible con la fuente del proyecto embebida.
- **Pantalla de exportar/importar**: selección de archivo (`file_picker`),
  compartir (`share_plus`) e imprimir (`printing`).
- **`EntriesController.replaceAll`**: importar un respaldo reemplaza la bóveda
  actual y persiste el cambio en el archivo cifrado.
- **8 tests nuevos** (servicio + UI + importación).

### Verification
- `flutter analyze` → sin problemas.
- `flutter test` → **123 pruebas, todas correctas**.

---

## [Fase 5] — 2026-11-26

### Added
- **Pantalla de inicio** con listado de entradas, búsqueda (título, persona,
  etiqueta de campo) y filtro de favoritas.
- **Formulario de entradas** para alta y edición con campos dinámicos, notas,
  categoría, persona y marca de favorita.
- **Generador de contraseñas**: longitud configurable, conjuntos activables,
  al menos un carácter de cada conjunto y PIN numérico.
- **Plantillas** de Wi-Fi, cuenta web, PIN, tarjeta y nota.
- **Detalle de entrada** con secretos ocultos por defecto, revelado temporal,
  copia al portapapeles y acciones (editar, duplicar, favorita, papelera).
- **Papelera** con restaurar, borrar para siempre y purga a los 30 días.
- **Test de integración** del flujo completo (crear → ver secreto oculto →
  revelar → papelera → restaurar).

### Fixed
- `EntryFormScreen`: la carga de dependencias se hace en
  `didChangeDependencies` (no en `initState`) para respetar `AppScope`.

### Verification
- `flutter analyze` → sin problemas.
- `flutter test` → **111 pruebas, todas correctas**.

---

## [Fase 4] — 2026-11-26

### Added
- **Onboarding de primera ejecución**: pantalla de bienvenida y creación de PIN
  con validación (4–8 dígitos, sin secuencias/repeticiones/PINs comunes) y
  confirmación. La bóveda se crea con `VaultKeyService.createVault`.
- **Pantalla de bloqueo**: entrada de PIN oculta (`obscureText`), botón de
  desbloqueo biométrico (si está habilitado) y cuenta atrás de bloqueo.
- **Biometría real**: abstracción `BiometricAuth` sobre `local_auth`. La copia
  de la DEK guardada solo se lee **después** de que el sistema confirme
  huella/rostro. El PIN sigue siendo siempre el plan B.
- **Wiring de controladores**: `LockController` → `EntriesController`. Al
  desbloquear se cargan las entradas con la DEK; al bloquear se borran de memoria.
- **Nuevos tests**: onboarding (3), lock screen / biometría / wiring (7).

### Fixed
- `PinCreateScreen`: el campo PIN ahora oculta lo escrito, permite 4–8 dígitos
  y muestra un error si falla la creación de la bóveda.

### Verification
- `flutter analyze` → sin problemas.
- `flutter test` → **99 pruebas, todas correctas**.

---

## [Fase 3] — 2026-11-25

### Added
- **Modelos inmutables**: `VaultDocument`, `VaultEntry`, `EntryField` con
  `toJson`/`fromJson`/`copyWith` manuales (sin generación de código).
- **Archivo cifrado**: bóveda en un solo archivo con envelope JSON
  (`llavero-vault`) + payload AES-256-GCM en base64.
- **Escritura atómica**: `.tmp` + `rename` real del sistema operativo.
- **`EntriesController`**: CRUD completo (add, update, moveToTrash, restore,
  deleteForever, toggleFavorite, duplicate, purgeExpiredTrash), búsqueda por
  título/persona/etiqueta (nunca por secretos), papelera de 30 días.

### Fixed
- Correcciones de code review: escritura atómica real, rutas absolutas sin
  doble prefijo, package name vía `PackageInfo`, igualdad de `VaultEntry`
  completa, estado de bloqueo conectado y validación del envelope.

### Verification
- `flutter analyze` → sin problemas.
- `flutter test` → **89 pruebas, todas correctas**.

---

## [Fase 2] — 2026-11-25

### Added
- **Criptografía**: Argon2id (64 MiB, 3 pasadas) como KDF por defecto y
  PBKDF2-HMAC-SHA256 como alternativa; parámetros serializables en la cabecera.
- **DEK/KEK**: DEK aleatoria de 256 bits envuelta con la KEK derivada del PIN;
  AES-256-GCM con AAD distinto por contexto (`dek-wrap`, `vault`, `backup`).
- **Almacén seguro**: `SecureStore` sobre Keystore/Keychain, con versión en
  memoria para tests.
- **Bloqueo escalonado**: 30 s → 1 min → 5 min → 15 min → 1 h, persistido en
  el almacén seguro; la app no deriva la clave mientras está bloqueada.
- **Respaldo cifrado**: formato `.llavero` con contraseña distinta del PIN.

### Verification
- `flutter analyze` → sin problemas.
- `flutter test` → **50 pruebas, todas correctas**.

---

## [Fase 1] — 2026-11-25

### Added
- Configuración del proyecto Flutter con dependencias mínimas permitidas.
- Tema propio Material 3 (claro/oscuro) y tipografías empaquetadas offline
  (Plus Jakarta Sans + JetBrains Mono).
- Localización ES/EN con `flutter_localizations` + `intl` y cambio instantáneo.
- Navegación con rutas con nombre y `AppScope` (`InheritedNotifier`).
- Exclusión de copias de seguridad en Android e iOS.

### Verification
- `flutter analyze` → sin problemas.
- `flutter test` → **6 pruebas, todas correctas**.
