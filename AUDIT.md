# Auditoría de Llavero — FASE A + FASE B (corregida)

Fecha: 2026-11-26. FASE A: solo lectura. FASE B: todos los ítems Critical y
Bug marcados como ✅ CORREGIDO con tests. Fuentes y limpieza pendientes de la
FASE C/D.

La maqueta `design/llavero-maqueta.html` **no existe** en el repositorio, así
que no se pudo comparar con el diseño de referencia. Los hallazgos de diseño
se basan en el código y en los requisitos indicados.

---

## 🔴 Critical (seguridad / pérdida de datos)

### C1. ✅ CORREGIDO (FASE B) —  La exclusión de iCloud en iOS está implementada pero nunca se llama
- **Archivo:** `lib/core/platform/backup_exclusion.dart:19-27`, nativo en
  `ios/Runner/AppDelegate.swift:155-203`.
- **Qué pasa:** `BackupExclusion.excludeFromBackup()` existe y el canal nativo
  responde, pero ningún código de la app lo invoca (buscado en todo `lib/`).
  En iOS, por defecto los archivos de la carpeta de la app se copian a iCloud:
  el `vault.dat` cifrado estaría saliendo del dispositivo.
- **Propuesta:** llamarlo justo después de crear/sobrescribir el archivo
  (`VaultStorage.save`, tras `writeAtomic`) y al arrancar con la ruta ya
  resuelta (`AppControllers.secure`). Añadir test de que el canal se invoca
  con la ruta correcta. Android ya está cubierto por el manifiesto.

### C2. ✅ CORREGIDO (FASE B) —  El portapapeles no se limpia nunca; el ajuste es decorativo
- **Archivo:** `lib/features/entries/entry_detail_screen.dart:103`;
  `lib/controllers/settings_controller.dart:70,99,128-132`;
  `lib/features/settings/settings_screen.dart:229-235`.
- **Qué pasa:** `Clipboard.setData(text)` copia el secreto y no hay ningún
  temporizador que lo borre. `clipboardTimeoutSeconds` solo se muestra en
  Ajustes; no se usa. El secreto queda disponible para cualquier app incluso
  después de pasar a segundo plano.
- **Propuesta:** tras copiar, programar `Timer(Duration(seconds: timeout), …)`
  que llame a `Clipboard.clear()`/setData vacío; cancelar y limpiar también en
  `AppLifecycleState.paused`/`hidden`. Persistir el ajuste (ver B8). Tests con
  `fakeAsync`.

### C3. ✅ CORREGIDO (FASE B) —  No hay re-autenticación antes de operaciones sensibles
- **Archivo:** `lib/features/export_import/export_import_screen.dart:47-152`
  (exportar backup, JSON, CSV, PDF, exportar con secretos, importar),
  `lib/features/settings/settings_screen.dart:125-130` (desactivar biometría),
  `lib/core/security/key_vault_service.dart:49,164` (`eraseEverything`, sin UI).
- **Qué pasa:** basta con tener la app abierta. La exportación en claro solo
  pide dos diálogos de confirmación, no PIN/huella. Desactivar la biometría es
  un interruptor sin verificación.
- **Propuesta:** helper reutilizable `requireReauth(context)` que pida
  PIN o `local_auth` y devuelva `bool`; llamarlo antes de **toda** exportación
  (especialmente la de secretos en claro), antes de desactivar biometría y
  antes de cualquier "borrar todo". Aplicar la comprobación también en la
  capa de controlador, no solo en la UI.

### C4. ✅ CORREGIDO (FASE B) —  El bloqueo por intentos se puede saltar cambiando la hora del móvil
- **Archivo:** `lib/core/security/lockout_policy.dart:46-106`;
  `lib/core/security/lockout_store.dart:27-49`;
  `lib/controllers/lock_controller.dart:66,107,261-265`.
- **Qué pasa:** `lockedUntil` es un `DateTime` de reloj de pared. Si el usuario
  adelanta/atrasa la hora del dispositivo, `isLockedOut` se vuelve `false` y
  puede seguir probando PINs. Borrar datos de la app (o reinstalar) también
  limpia el contador: eso **no se puede evitar offline**.
- **Propuesta (mitigación, no solución total):** persistir `failedAttempts`
  junto con un `lastSeenUtc` monótono; al comparar, usar
  `effectiveNow = max(now, lastSeen + 1s)` y actualizar `lastSeen` en cada
  intento. Así回滚ar el reloj no acorta el castigo. Documentar honestamente
  que un atacante con acceso físico/root puede manipular el almacenamiento o
  reinstalar; sin servidor no hay garantía absoluta.

### C5. ✅ CORREGIDO (FASE B) —  Cambio de PIN no atómico: puede dejar la bóveda inabierta
- **Archivo:** `lib/core/security/key_vault_service.dart:133-142`.
- **Qué pasa:** se escriben primero los parámetros KDF nuevos y después la DEK
  envuelta nueva, en dos llamadas separadas. Si la app se corta entre ambas,
  quedan parámetros nuevos + DEK envuelta con los viejos: la DEK ya no se
  desenvolve y **todos los datos son irrecuperables**.
- **Propuesta:** guardar parámetros + DEK envuelta en un único JSON bajo una
  sola clave (`llavero.key_envelope`), o escribir claves temporales y hacer un
  intercambio atómico. Test de simulación de fallo entre escrituras.

### C6. ✅ CORREGIDO (FASE B) —  La exportación "sin secretos" deja campos secretos en claro
- **Archivo:** `lib/data/export_service.dart:112-130` (`_safeDocument` solo
  mira `field.isSecret`).
- **Qué pasa:** un campo de tipo `secret`/`pin`, o etiquetado «Contraseña»,
  «clave», «password», con `isSecret == false` (el formulario permite crearlos
  así) se exporta **en claro** en JSON/CSV/PDF por defecto.
- **Propuesta:** reutilizar el mismo detector de secretos que
  `PasswordHealth._isSecret` (tipo + etiqueta + flag) en `_safeDocument`.
  Test: exportar por defecto un campo tipo `secret` y verificar `[oculto]`.

### C7. ✅ CORREGIDO (FASE B) —  IDs duplicados al duplicar entradas en producción
- **Archivo:** `lib/core/app_scope.dart:59-65` (crea `EntriesController` sin
  `idGenerator`), `lib/controllers/entries_controller.dart:266-267`
  (`idGenerator()` por defecto devuelve siempre `'id-'`).
- **Qué pasa:** todas las copias reciben el mismo ID. Editar/borrar una
  entrada duplicada afecta a todas las que tengan ese ID.
- **Propuesta:** pasar un generador real en `AppControllers.secure()`:
  `idGenerator: () => const Uuid().v4()` (el paquete `uuid` ya está
  permitido). Test de que dos `duplicate()` producen IDs distintos.

---

## 🟠 Bug

### B1. ✅ CORREGIDO (FASE B) —  Archivo corrupto: excepción sin manejar y sin ofrecer recuperación
- **Archivo:** `lib/data/vault_storage.dart:83-125` lanza
  `TamperedDataException`; `lib/controllers/entries_controller.dart:45-59`
  la propaga; `lib/core/app_scope.dart:97-102` la propaga al UI.
- **Qué pasa:** si el archivo está dañado, el desbloqueo termina en pantalla
  roja/error no controlado. Existe `VaultHistory`, pero no se ofrece
  restaurar desde ese punto.
- **Propuesta:** capturar en `AppControllers.unlockWithPin`, exponer un
  estado `vaultCorrupted` y mostrar pantalla con «Restaurar última copia»
  (historial) o «Importar respaldo». Missing file → bóveda vacía (ya OK).

### B2. ✅ CORREGIDO (FASE B) —  Restaurar una versión del historial no es atómico
- **Archivo:** `lib/data/vault_history.dart:70-77` usa `writeAsBytes`
  directo sobre `vault.dat`.
- **Qué pasa:** si falla a mitad, se corrompe el archivo actual (el mismo
  problema ya corregido en `VaultStorage.save`).
- **Propuesta:** escribir en `.tmp` y renombrar, igual que `writeAtomic`.

### B3. ✅ CORREGIDO (FASE B) —  Errores de respaldo poco claros
- **Archivo:** `lib/core/security/crypto/backup_crypto.dart:55-85`;
  `lib/features/export_import/export_import_screen.dart:67-80`.
- **Qué pasa:** un archivo manipulado se informa como «contraseña incorrecta»;
  `base64Decode` sin try/catch lanza `FormatException`; no se valida
  `version`. La UI muestra un único mensaje genérico
  («No se pudo importar el respaldo»).
- **Propuesta:** excepciones distintas (`InvalidBackupPasswordException`,
  `TamperedDataException`, `UnsupportedBackupVersion`), parseo seguro y
  mensajes localizados específicos. Test por cada caso.

### B4. ✅ CORREGIDO (FASE B) —  Importar reemplaza todo sin confirmación ni opción de fusionar
- **Archivo:** `lib/features/export_import/export_import_screen.dart:74`
  (`entries.replaceAll(document)`); requisito de la FASE A: «merge y replace».
- **Qué pasa:** importar un respaldo borra silenciosamente las entradas
  actuales. No hay opción de fusionar ni diálogo de confirmación.
- **Propuesta:** diálogo «Fusionar / Reemplazar», implementar `merge()` en
  `EntriesController` (unión por ID, respaldo manda en conflictos) y
  confirmación antes de reemplazar. Tests de ambos caminos y de
  exportar → borrar todo → importar.

### B5. ✅ CORREGIDO (FASE B) —  Archivos temporales de exportación nunca se borran
- **Archivo:** `lib/features/export_import/export_import_screen.dart:39-45,136-152`.
- **Qué pasa:** JSON/CSV/PDF (con secretos en claro si se activa) se escriben
  en el directorio temporal y quedan allí indefinidamente.
- **Propuesta:** borrar en `finally` tras compartir/imprimir; usar nombre
  impredecible; test de que el archivo ya no existe después.

### B6. ✅ CORREGIDO (FASE B) —  Revelado de secretos: no se oculta solo y usa la etiqueta como clave
- **Archivo:** `lib/features/entries/entry_detail_screen.dart:24-34,97-105,172`.
- **Qué pasa:** no hay temporizador que vuelva a ocultar. `_revealed` se indexa
  por `field.label`, así que dos campos con la misma etiqueta se revelan a la
  vez. Además solo oculta si `field.isSecret`; un campo tipo `secret` con
  `isSecret == false` se muestra en claro.
- **Propuesta:** `Timer` de ~30 s que limpie `_revealed`; clave por índice/ID
  del campo; usar `isSecret || type.hidesValueByDefault || pista de etiqueta`.

### B7. ✅ CORREGIDO (FASE B) —  Editar una entrada no permite quitar la persona
- **Archivo:** `lib/controllers/entries_controller.dart:143`.
- **Qué pasa:** `update()` usa `person: entry.person`; `copyWith` ignora
  `null` salvo que se pase `clearPerson: true`, así que dejar el campo vacío
  no borra el valor anterior.
- **Propuesta:** construir el `copyWith` con `clearPerson: entry.person == null`.

### B8. ✅ CORREGIDO (FASE B) —  Los ajustes no se guardan entre reinicios
- **Archivo:** `lib/controllers/settings_controller.dart:64-138`;
  `lib/core/app_scope.dart:29-33` (controlador por defecto).
- **Qué pasa:** tema, idioma, retardo de auto-lock, bloqueo de capturas,
  tiempo de portapapeles y longitud de PIN vuelven a los valores por defecto
  al reiniciar. Si el usuario desactivó capturas, al reiniciar vuelven a
  activarse (default `true`).
- **Propuesta:** persistir con `flutter_secure_storage` (ya permitido, sin
  paquetes nuevos) o `SharedPreferences` del SDK; cargar en `secure()`.
  Tests de ida y vuelta.

### B9. ✅ CORREGIDO (FASE B) —  Sin validación de título/campos vacíos ni diálogo de cambios sin guardar
- **Archivo:** `lib/features/entries/entry_form_screen.dart:153-186`.
- **Qué pasa:** se puede guardar una entrada con título vacío y sin campos;
  al salir con datos sin guardar no se avisa.
- **Propuesta:** validar antes de `save`, mostrar error localizado, y
  `WillPopScope`/`PopScope` con diálogo de confirmación cuando `_dirty`.

### B10. ✅ CORREGIDO (FASE B) —  JSON corrupto se convierte silenciosamente en bóveda vacía
- **Archivo:** `lib/data/models/vault_document.dart:31-39`;
  `VaultEntry.fromJson` (`lib/data/models/vault_entry.dart:106-125`).
- **Qué pasa:** si falta `entries` o está mal formado, se devuelve una lista
  vacía sin error: el usuario ve «bóveda vacía» y piensa que perdió todo.
- **Propuesta:** exigir la clave `entries`; lanzar `FormatException` si falta o
  no es lista; validar campos obligatorios de cada entrada. Tests.

### B11. ✅ CORREGIDO (FASE B) —  Argumentos de ruta sin comprobación
- **Archivo:** `lib/core/routes/app_routes.dart:73-77`
  (`routeSettings.arguments as String`).
- **Qué pasa:** una navegación con argumentos ausentes o de otro tipo hace
  crashear la app.
- **Propuesta:** cast seguro (`as? String`) y pantalla de error/retorno si
  no hay ID. Test de ruta sin argumentos.

### B12. ✅ CORREGIDO (FASE B) —  `FLAG_SECURE` se aplica tarde y no recuerda la preferencia al arrancar
- **Archivo:** `android/.../MainActivity.kt:52-67` (se aplica vía MethodChannel
  desde Dart, después de que arranque la UI); `lib/core/app_scope.dart:69-71`.
- **Qué pasa:** durante el splash/recents initial puede verse contenido; si el
  usuario desactivó capturas, al reiniciar vuelve a activarse porque el
  ajuste no se persiste (B8).
- **Propuesta:** aplicar `FLAG_SECURE` en `onCreate` de MainActivity leyendo
  un valor persistido, y solo quitarlo cuando el usuario lo desactive.

---

## 🟡 UX

### U1. Las fuentes del diseño no se aplican (se ve Roboto)
- **Archivo:** `lib/core/theme/app_typography.dart:16-83` — ningún
  `TextStyle` del tema pone `fontFamily`. `pubspec.yaml:81-97` declara bien
  Plus Jakarta Sans y JetBrains Mono.
- **Propuesta:** añadir `fontFamily: uiFont` a todos los estilos de
  `textTheme`, y mantener `monoFont` en secretos/PIN. Test que compruebe
  `ThemeData.textTheme.bodyLarge.fontFamily`.

### U2. Flujo de PIN no coincide con el requisito
- **Archivo:** `pin_create_screen.dart:101-141`, `lock_screen.dart:122-146`,
  `change_pin_screen.dart:84-135`.
- **Qué pasa:** no se elige longitud 4/6/8; el `TextField(maxLength: 8)`
  muestra el contador «n/8»; hay botón de confirmar/desbloquear en vez de
  auto-avance y auto-envío; no hay texto de ayuda «Elige 4, 6 u 8 dígitos…»;
  no hay animación de sacudida cuando se rechaza.
- **Propuesta:** segmented 4/6/8 (default 6),dots exactos, `counterText: ''`,
  auto-submit al último dígito, helper localizado, shake en error. Cambiar
  longitud desde Ajustes debe pedir el PIN actual primero.

### U3. Iconos de categoría genéricos
- **Archivos:** `home_screen.dart:166-171`, `entry_detail_screen.dart:81-84`,
  `categories_screen.dart`, selector de categoría en `entry_form_screen.dart:220-240`.
- **Qué pasa:** se usa siempre `Icons.key_rounded`; no hay iconos por
  categoría, no hay rejilla visual (hay dropdown) y las tarjetas no muestran
  «persona · categoría».
- **Propuesta:** añadir iconos Material por categoría (wifi, mail_outline,
  play_circle_outline, account_balance, dialpad, forum_outlined,
  router_outlined, badge_outlined, category_outlined), render de 40dp con
  radio 12 y color al 20 %, y rejilla de 3 columnas en el formulario.

### U4. Formulario de entrada
- **Archivo:** `lib/features/entries/entry_form_screen.dart:199-305`.
- **Qué pasa:** `DropdownButton` en vez de rejilla; `CheckboxListTile` en vez
  de Switch; no hay chips de plantillas Streaming (Netflix, Disney+); el
  botón Guardar queda al final del scroll (no siempre visible); no hay handle
  de reordenación junto al campo; el botón dado (dice) no tiene semántica
  específica; las etiquetas `labelText` se solapan con el borde del campo.
- **Propuesta:** ver Phases C.2/C.4 del encargo.

### U5. Home no tiene las secciones pedidas
- **Archivo:** `lib/features/home/home_screen.dart:68-136`.
- **Qué pasa:** hay un `SegmentedButton` Todas/Favoritas en vez de secciones
  «Favoritas / Todas»; no hay chips de filtro por categoría ni por persona;
  el icono de papelera no tiene etiqueta visible; no hay banner de recordatorio
  de respaldo.
- **Propuesta:** implementar secciones y chips, y banner localizado.

### U6. Ajustes desorganizados y filas de estado
- **Archivo:** `lib/features/settings/settings_screen.dart:64-243`.
- **Qué pasa:** todo en una lista: «Estado de seguridad», «Bóveda creada»,
  «Integridad del dispositivo», «Intentos fallidos», historial, health…
  Falta la agrupación «Seguridad / Herramientas / Apariencia / Acerca de» y
  la etiqueta «Desbloqueo biométrico».
- **Propuesta:** reagrupar y mover/quitar filas de estado (ver L3).

### U7. Pantalla de bienvenida sin selector de idioma
- **Archivo:** `lib/features/onboarding/onboarding_screen.dart:23-68`.
- **Qué pasa:** no hay selector ES/EN; el botón no es de ancho completo.
- **Propuesta:** añadir `SegmentedButton<AppLanguage>` y botón `SizedBox(width: double.infinity)`.

### U8. Estados vacíos sin ilustración ni acción
- **Archivos:** `home_screen.dart:102-103`, `trash_screen.dart`,
  `categories_screen.dart`, `security_health_screen.dart`.
- **Qué pasa:** solo texto; no hay ilustración pequeña ni CTA.
- **Propuesta:** widget reutilizable `EmptyState(icono, texto, acción)`.

### U9. Márgenes y radios inconsistentes
- **Archivos:** `app_scaffold.dart:16` (padding 16), `app_theme.dart:12-15`
  (card 16, control 28), `inputDecorationTheme` (radius 16).
- **Qué pasa:** el margin horizontal pedido es 24dp; las hojas/diálogos usan
  20–24dp; `notes` usa el mismo `InputDecorationTheme` (tiene radio 16, OK).
- **Propuesta:** unificar margin a 24dp y revisar diálogos/bottom sheets.

### U10. Textos hardcoded en el PDF
- **Archivo:** `lib/data/export_service.dart:93-101` — «Llavero»,
  «Categoría:», «Persona:», «Notas:» no traducidos.
- **Propuesta:** pasar `L10n` al servicio o generar el PDF desde la UI con
  textos localizados.

### U11. Rotación / escalado de fuente 200% / pantallas pequeñas
- **Archivo:** `home_screen.dart:104-132` (grid 2 columnas desde 600dp con
  `childAspectRatio: 3.2`).
- **Riesgo:** con fuente al 200 % las tarjetas pueden desbordarse; no hay
  tests de golden ni de `MediaQuery.textScaler`. Verificar en Phases C/D.

---

## 🧹 Cleanup

### L1. Código muerto en el validador de PIN
- **Archivo:** `lib/core/security/pin_validator.dart:54-73` — `expectedLength`
  no afecta al resultado (las dos ramas devuelven `ok`).
- **Propuesta:** quitar el parámetro o usarlo de verdad en la Fase C.

### L2. `BackupExclusion` es código muerto
- Ver C1. O se conecta o se elimina; en ese caso hay que documentar que iOS
  copiará la bóveda a iCloud (inaceptable para el propuesto «100 % offline»).

### L3. Funciones NO solicitadas en el spec original
| Función | Qué hace | Código / paquetes | Recomendación |
|---|---|---|---|
| Integridad del dispositivo (root/jailbreak) | Muestra «Dispositivo íntegro» o aviso rojo | `core/platform/device_integrity.dart`, canales `llavero/device_integrity` en Kotlin/Swift; sin paquetes nuevos | **Quitar u ocultar**: es informativa, engaña al usuario y no es barrera. |
| Historial de bóveda | Copia antes de cada escritura, 10 versiones, restaurar | `data/vault_history.dart`, `dart:io`, `path_provider`, pantalla `/settings/history` | **Quitar u ocultar**; además B2 es un riesgo de corrupción. Si se conserva, arreglar B2. |
| Fila «Bóveda creada» | Estado informativo en Ajustes | `settings_screen.dart:70-75` | **Quitar**: no aporta acción. |
| Fila «Intentos fallidos» | Muestra el contador | `settings_screen.dart:132-137`, `LockController.failedAttempts` | **Quitar u ocultar**: la política de bloqueo sí es del spec, mostrar el número no. |
| Salud de contraseñas | Detecta débiles/repetidas | `core/security/password_health.dart`, pantalla `/security-health` | El «estado de seguridad» sí estaba en la Fase 7; la pantalla completa no estaba especificada. **Conservar solo si el usuario la quiere**. |
| Categorías personalizadas | CRUD de categorías, colores, 24 iconos previstos | `VaultCategory`, `CategoriesController`, pantalla propia | El spec decía «categorías que el usuario podrá crear más adelante». **No era requisito actual**: valorar ocultar. |
| Exportar secretos en claro | Interruptor + doble confirmación | `ExportService.includeSecrets`, diálogos | **Quitar**: contradice «100 % offline y cifrado». Si se conserva, re-auth (C3). |
| Búsqueda en notas | `search()` incluye `notes` | `entries_controller.dart:337-341` | Spec decía título/persona/etiqueta. **Quitar o documentar**. |
| Cambio de PIN | Pantalla `/settings/change-pin` | `VaultKeyService.changePin` | No estaba en el spec original, pero es una mejora razonable. **Conservar con re-auth** (ya pide PIN actual). |
| Purga automática al abrir | `open()` purga papelera | `entries_controller.dart:61-68` | Papelera de 30 días sí era del spec; purga al abrir no. **Conservar**, es benigno. |
| Soporte escritorio/web y ofuscación | `PlatformCapabilities`, builds ofuscados, Podfile/macOS | mejoras #17, #7 | No estaban en el spec. **Conservar pero documentar**. |

### L4. Dependencia sin usar
- **`qr_flutter: ^4.1.0`** en `pubspec.yaml:49`: no aparece en `lib/`. Quitar.

### L5. Documentación
- `README.md` y `PROGRESS.md` describen 9 fases + mejoras; `PLAN_MEJORAS.md`
  está cerrado 19/19. Mantener tras los cambios de las fases B/C/D.

---

## ✅ Verificado correcto (sin hallazgos)

- Manifiesto release: **sin permiso INTERNET**; `allowBackup="false"`,
  `fullBackupContent="false"`, `dataExtractionRules` con `exclude` de todos los
  dominios (`android/app/src/main/AndroidManifest.xml`,
  `res/xml/data_extraction_rules.xml`). INTERNET solo en debug/profile.
- `FLAG_SECURE` se aplica y se puede quitar desde Ajustes
  (`MainActivity.kt:52-67`, `settings_screen.dart:37-41`) — con la salvedad B12.
- La DEK nunca se guarda en claro: solo envuelta (`key_vault_service.dart:72-95`);
  la copia biométrica vive en el almacén seguro (`secure_store.dart:38-41`).
- El PIN no se guarda ni se imprime: no hay `print`/`debugPrint` con secretos
  en `lib/` (solo en la herramienta de benchmark `tool/bench_kdf.dart`).
- Biometría: `local_auth` con `biometricOnly: true`, PIN como plan B, y copia
  de DEK solo tras autenticar (`biometric_auth.dart:22-32`,
  `lock_controller.dart:134-163`). Si cambia la biometría del dispositivo,
  `authenticate` falla y el PIN sigue funcionando.
- Bloqueo escalonado y persistente tras reinicio/force-close: sí
  (`lockout_policy.dart`, `lockout_store.dart`, `LockController.initialize`).
  Salvedad: C4 (reloj) y borrado de datos.
- Escritura atómica de la bóveda: `.tmp` + `rename` (`vault_file_system.dart:99-106`).
- Respaldo cifrado con contraseña distinta del PIN, AAD propio, tag GCM
  (`backup_crypto.dart`, `vault_crypto.dart`). Salvedades: B3, B4, B5.
- Papelera: 30 días, restaurar, borrar para siempre (`entries_controller.dart`).
- Duplicar crea copia con título «(copia)» — pero con el ID duplicado (C7).
- Búsqueda **no** coincide con valores secretos: `search()` solo mira
  título, persona, notas y etiquetas (`entries_controller.dart:316-353`).
- Auto-lock: inmediato/30 s/1 min/5 min al pasar a segundo plano y bloqueo en
  arranque en frío; botón «Bloquear ahora» limpia memoria
  (`app_lifecycle_lock.dart`, `lock_controller.dart:195-200`, `app.dart`).
- Back después de bloquear no muestra contenido de la bóveda: se navega a
  `/lock` con `pushNamedAndRemoveUntil` (`app.dart:46-55`).
- Los 140 strings de ES y EN coinciden clave por clave (verificado con script).
- El cambio de idioma es instantáneo dentro de la sesión
  (`LlaveroApp` usa `ListenableBuilder` sobre `settings`). Salvedad: B8.

---

## FASE B — Resumen de correcciones y cobertura de tests

| Ítem | Fix | Test que lo cubre |
|---|---|---|
| C1 | `VaultStorage.save` y `AppControllers.secure` llaman a `BackupExclusion`; nativo iOS registra la llamada | `test/phase_b_security_test.dart` → «C1: VaultStorage.save pide excluir…» |
| C2 | `ClipboardService` limpia tras timeout y al background (best effort) | `test/phase_b_security_test.dart` → «C2: ClipboardService limpia…» |
| C3 | `requireReauth()` antes de exportar; `verifyPin` y `setBiometricsEnabled(reauthenticated:)` | «C3: verifyPin y setBiometricsEnabled exigen re-auth» |
| C4 | `LockoutState` guarda tiempo restante + `lastSeenMicros`; reloj hacia atrás no acorta | «C4: reloj hacia atrás no acorta el bloqueo» |
| C5 | `_writeKeyEnvelope` escribe temporales y solo intercambia si todo salió bien | «C5: fallo a mitad del cambio de PIN…» |
| C6 | `SecretDetector` compartido por export/health/detail | `test/phase_b_data_test.dart` → «C6: exportar sin secretos oculta…» |
| C7 | `idGenerator: () => Uuid().v4()` en producción | «C7: dos duplicados en producción tienen IDs distintos» |
| B1 | `vaultCorrupted` en `LockController`/`AppControllers` + pantalla con importar | «B1: archivo corrupto marca vaultCorrupted sin lanzar» |
| B2 | Función eliminada junto con el historial | «B2: la ruta del historial eliminado ya no existe» |
| B3 | Nuevas excepciones + validación de versión/formato/base64 | «B3: errores de respaldo son distintos» |
| B4 | `merge()` + diálogo Fusionar/Reemplazar | «B4: merge conserva entradas y replace las sustituye» |
| B5 | `ExportTempFile.use()` borra en `finally` | «B5: el archivo temporal se borra incluso si falla…» |
| B6 | Reveal por índice, timer 30 s, `SecretDetector` | «B6: el detector trata secretos por tipo y etiqueta» |
| B7 | `clearPerson: entry.person == null` | «B7: editar sin persona la elimina» |
| B8 | `SettingsController(store:)` + `initialize()` con `SecureSettingsStore` | «B8: los ajustes sobreviven a un reinicio…» |
| B9 | Validación de título/campos + `PopScope` | «B9: el formulario valida título y campos vacíos» |
| B10 | `VaultDocument.fromJson` y `VaultEntry.fromJson` validan | «B10: JSON sin entradas lanza FormatException» |
| B11 | Cast seguro en `onGenerateRoute` | «B11: ruta sin argumentos no crashea» |
| B12 | `FLAG_SECURE` en `onCreate` + canal desde Dart | «B12: el canal de capturas aplica y quita FLAG_SECURE» |

### Limitaciones honestas

- **Reloj**: el cambio de hora hacia atrás ya no acorta el castigo, pero adelantar
  la hora sí puede acortarlo; sin un servidor de tiempo no se puede impedir.
  Un atacante con root o que reinstale la app puede borrar el estado: eso es
  imposible de evitar en una app 100 % offline.
- **Portapapeles**: Android 10+ y iOS restringen manipular el portapapeles desde
  segundo plano. La limpieza al background es *best effort*; la garantía real
  es el temporizador mientras la app está activa.
- **C5**: el intercambio usa claves temporales en el mismo almacén seguro; una
  interrupción entre las dos escrituras finales puede dejar el par antiguo o el
  nuevo, nunca una mezcla.

### Cómo verificar la exclusión de iCloud (C1)

1. Instalar en un iPhone real con `flutter run` y crear la bóveda.
2. Abrir la consola de Xcode / Console.app y buscar `Llavero: vault excluida de iCloud`.
   Debe aparecer al crear la bóveda y tras cada cambio guardado.
3. Ajustes → iCloud → Copia de iCloud → Administrar almacenamiento → este iPhone:
   Llavero no debe aparecer como app con datos en la copia.
4. Restaurar una copia de iCloud en otro dispositivo: el archivo `vault.dat` de
   Llavero no debe estar presente.
5. Automatizado: el test C1 intercepta el `MethodChannel` y comprueba la ruta.

### Cómo verificar FLAG_SECURE (B12)

`adb shell dumpsys window com.example.llavero2 | grep FLAG_SECURE` debe mostrar
la flag incluso antes de que Dart termine de arrancar.

---

## Orden sugerido para la FASE B

1. C1, C5, C7 (pérdida/fuga de datos).
2. C2, C3, C4 (portapapeles, re-auth, reloj).
3. C6.
4. B1–B12.
5. Solo después: FASE C (diseño) y FASE D (limpieza según aprobación).
