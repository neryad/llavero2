# Llavero — Progreso

Bóveda familiar de contraseñas y códigos, **100 % offline** y cifrada.
App en Flutter (Android + iOS), en español e inglés.

---

## Fase 1 — Configuración del proyecto ✅

### Qué se ha construido

| Área | Detalle |
|---|---|
| Dependencias | Solo las permitidas: `flutter_localizations` + `intl`, `cryptography`, `flutter_secure_storage`, `local_auth`, `path_provider`, `share_plus`, `file_picker`, `pdf` + `printing`, `qr_flutter`, `package_info_plus`, `uuid`. Sin Riverpod/Provider/Bloc, sin generación de código. |
| Fuentes | Empaquetadas como assets (offline): **Plus Jakarta Sans** 400/500/600/700 y **JetBrains Mono** 400/500 (usadas para secretos, PIN y códigos con cifras tabulares). Sin `google_fonts`. |
| Tema | `ThemeData` propio con `ColorScheme` a medida (Material 3) y un `ThemeExtension` (`CategoryColors`) con el color de cada categoría. Ningún widget escribe colores literales. |
| Tipografía | Escala Display 32/700, Headline 24/700, Title 18/600, Body 16/400, Label 13/600, Mono 18/500. |
| Idiomas | `l10n.yaml` + `app_es.arb` / `app_en.arb`, generadas con `flutter gen-l10n` en `lib/l10n/generated/app_l10n.dart`. El cambio de idioma es instantáneo. |
| Estado | `ChangeNotifier` (`SettingsController`, `LockController`, `EntriesController`) + `InheritedNotifier` `AppScope` (`AppScope.of(context)`). Los controladores **no importan nada de la interfaz**, solo `foundation.dart`, para poder testearlos. |
| Navegación | `Navigator` con rutas con nombre y `onGenerateRoute` (sin `go_router`). |
| Seguridad del APK | `android:allowBackup="false"`, `fullBackupContent="false"` y `dataExtractionRules` que excluyen **todo** de la copia en la nube y de la transferencia entre dispositivos. El manifiesto principal **no pide permiso INTERNET** (solo lo piden las variantes debug y profile, que lo necesitan para el hot reload). |
| iOS | `NSFaceIDUsageDescription` añadida y `platform :ios, '13.0'`. La exclusión de iCloud se hará sobre el archivo de la bóveda en la fase 3. |

### Archivos que importan

```
lib/
  main.dart                       punto de entrada
  app.dart                        MaterialApp + AppScope + tema/idioma
  core/
    app_scope.dart                AppScope (InheritedNotifier)
    routes/app_routes.dart        rutas con nombre
    theme/app_palette.dart        paleta clara/oscura
    theme/app_theme.dart          ThemeData + ThemeExtension
    theme/app_typography.dart     escala tipográfica
    theme/category_colors.dart    colores de categoría
    widgets/app_scaffold.dart     contenedor común (máx. 720dp)
  controllers/                    settings, lock, entries
  features/splash|home|shared/    pantallas de la fase 1
  l10n/app_es.arb, app_en.arb     textos (fuente de la verdad)
test/widget_test.dart             6 pruebas
```

### Cómo probarlo en tu móvil

```bash
flutter devices          # elige el tuyo
flutter run              # o: flutter run -d <id-dispositivo>
```

En la app: splash → **Continuar** → verás los selectores de **tema**
(Sistema/Claro/Oscuro) e **idioma** (Sistema/Español/Inglés), que cambian al
instante, y la paleta de las 9 categorías.

> Nota: esos selectores eran un **andamio temporal** de la fase 1, solo para
> comprobar que el tema y los idiomas funcionan. En la fase 7 los sustituya
> la pantalla de Ajustes real.

---

## Fase 2 — Criptografía, almacén seguro y bloqueo ✅

### Cómo funciona el modelo de claves

```
        PIN del usuario
              │
              ▼
     KDF lento (Argon2id)  ──►  KEK (clave que envuelve)
              │                        │
              │                        ▼
              │                  envuelve la DEK
              │                        │
              ▼                        ▼
        DEK (256 bits, aleatoria) ──► AES-256-GCM ──► bóveda cifrada
```

- La **DEK** (clave de cifrado de los datos) es aleatoria y de 256 bits.
- La **KEK** se deriva del PIN con un KDF lento y sal aleatoria.
- En el dispositivo solo se guarda la DEK **envuelta**, la sal y los
  parámetros del KDF. **El PIN nunca se guarda** y la DEK nunca se guarda
  en claro (salvo la copia biométrica, que está en el almacén seguro del
  sistema).

### Decisión sobre el KDF (benchmark real)

`tool/bench_kdf.dart` mide los costes en este equipo:

| Algoritmo | Coste medido |
|---|---|
| PBKDF2-HMAC-SHA256, 100 000 iteraciones | 317 ms |
| PBKDF2-HMAC-SHA256, 600 000 iteraciones | 1 838 ms |
| **Argon2id (64 MiB, 3 pasadas, 1 hilo)** | **381 ms** |
| AES-256-GCM (64 KiB) | 11 ms |

**Decisión: Argon2id por defecto** (64 MiB, 3 pasadas, 1 hilo). Es más rápido
que PBKDF2 con 600 000 iteraciones *y* mucho más resistente a ataques con GPU
o ASIC, que es el riesgo real de una app de contraseñas. PBKDF2-HMAC-SHA256
con 600 000 iteraciones queda implementado como alternativa, porque los
parámetros del KDF se guardan en la cabecera de los archivos: si mañana
cambiamos de algoritmo, los archivos antiguos siguen leyéndose.

> Aviso honesto: el paquete `cryptography` que podemos usar aquí implementa
> todo en Dart puro (el accelerate nativo venía en `cryptography_flutter`,
> que no está en la lista de paquetes permitidos). En un móvil de gama baja
> esto puede multiplicar los tiempos por 3-5. Argon2id sigue siendo la mejor
> opción; si en pruebas reales resultara lento, se puede bajar la memoria a
> 32 MiB sin tocar nada más.

### Bloqueo por intentos fallidos

| Intento fallido | Bloqueo |
|---|---|
| 1-4 | ninguno (solo cuenta) |
| 5 | 30 s |
| 6 | 1 min |
| 7 | 5 min |
| 8 | 15 min |
| 9 o más | 1 h |

- El estado (intentos + hora de fin) **se guarda en el almacén seguro**, así
  que reiniciar la app no borra el castigo.
- Mientras está bloqueada, la app **ni siquiera deriva la clave**: un
  atacante no puede gastar la CPU del móvil probando PINs.
- El PIN correcto borra el contador.

### PIN

- 4 a 8 dígitos (6 por defecto, configurable en Ajustes).
- Se rechazan: dígitos repetidos (000000), secuencias (123456, 654321) y los
  PINs más usados del mundo.
- Solo dígitos.

### Formato del respaldo cifrado (`.llavero`)

Cabecera en claro (formato, versión, fecha, parámetros del KDF) + contenido
cifrado con una clave derivada de **una contraseña de respaldo**, distinta del
PIN. Por eso un respaldo se puede importar en otro móvil sin conocer el PIN
original.

### Archivos que importan

```
lib/core/security/
  crypto/kdf.dart               Argon2id / PBKDF2 + parámetros serializables
  crypto/vault_crypto.dart      AES-256-GCM, wrap/unwrap de la DEK
  crypto/backup_crypto.dart     formato del archivo .llavero
  crypto/crypto_errors.dart     errores (sin datos sensibles en los mensajes)
  pin_validator.dart            reglas del PIN
  lockout_policy.dart           castigo escalonado + estado persistible
  lockout_store.dart            persistencia del bloqueo
  secure_store.dart             Keystore / Keychain (+ versión en memoria)
  key_vault_service.dart        crear bóveda, abrir con PIN, copia biométrica
lib/controllers/lock_controller.dart   intentos, bloqueo, cuenta atrás
tool/bench_kdf.dart             benchmark del KDF (herramienta de desarrollo)
```

### Pruebas

`flutter analyze` → sin problemas. `flutter test` → **50 pruebas, todas
correctas** (6 de la fase 1 + 44 nuevas):

- Cripto: ida y vuelta del cifrado, nonce aleatorio, DEK de 256 bits, clave
  equivocada, contenido manipulado, blob truncado.
- DEK: envolver/desenvolver con PIN correcto, PIN incorrecto, blob manipulado.
- Respaldo: ida y vuelta, contraseña incorrecta, cabecera con los parámetros
  del KDF.
- PIN: válidos, demasiado cortos/largos, triviales, con letras.
- Bloqueo: castigo escalonado, cuenta atrás, persistencia tras "reiniciar",
  que no se reintente el PIN mientras está bloqueada, limpieza al acertar.

### Cómo probarlo en tu móvil

En esta fase **todavía no hay interfaz** de PIN (llega en la fase 4), así que
en el móvil solo comprobarás que la app arranca sin errores y que la fase 1
sigue igual. La lógica criptográfica está cubierta por los tests: puedes
verlos en detalle con

```bash
flutter test test/crypto_test.dart test/lockout_test.dart test/pin_validator_test.dart
```

o ver el benchmark del KDF con

```bash
dart run tool/bench_kdf.dart
```

---

## Fase 3 — Archivo cifrado, modelos y CRUD ✅

### El modelo de datos

```
VaultDocument (version, entries)
  └── VaultEntry (id, title, categoryId, person?, fields[], notes,
                  isFavorite, createdAt, updatedAt, deletedAt?)
        └── EntryField (label, value, type, isSecret)
```

- `EntryFieldType`: `text`, `secret`, `url`, `pin`, `email`, `phone`.
  Los tipos `secret` y `pin` se ocultan solos aunque el archivo no lo diga.
- Todo son **clases inmutables** con `toJson`, `fromJson` y `copyWith`
  escritos a mano (sin generación de código).
- `copyWith` usa indicadores aparte (`clearPerson`, `clearDeletedAt`) para
  poder distinguir "no cambiar" de "dejar en blanco".
- `deletedAt` no nulo = entrada en la papelera. La papelera dura 30 días.

### El archivo de la bóveda

- **Un solo archivo**, en la carpeta privada de la app
  (`Application Support/llavero/vault.dat`). En Android queda dentro de
  `/data/data/<paquete>` y en iOS dentro de `Library`.
- Se guarda **cifrado con AES-256-GCM** usando la DEK.
- El archivo es un JSON con cabecera legible (formato, versión, fecha) y el
  contenido cifrado en base64.
- **Escritura atómica**: se escribe en `vault.dat.tmp` y se renombra
  encima. Si el móvil se apaga a mitad de la escritura, el archivo bueno
  sigue intacto (nunca queda a medias).

### Exclusión de las copias del sistema

- **Android**: ya estaba resuelto en el manifiesto (`allowBackup="false"` +
  `dataExtractionRules`).
- **iOS**: por defecto iCloud copia todo lo que hay en la carpeta de la app.
  Ahora hay un **canal nativo** (`llavero/secure_file`) que marca el archivo
  con `NSURLIsExcludedFromBackupKey` la primera vez que se crea. En Android
  el mismo canal responde que no hace falta nada.

### El controlador de entradas

`EntriesController` (sin imports de interfaz, testeable):

- Mantiene las entradas **en memoria** mientras la app está desbloqueada.
- CRUD: `add`, `update`, `moveToTrash`, `restore`, `deleteForever`,
  `toggleFavorite`, `duplicate`, `purgeExpiredTrash`.
- **Reescribe el archivo en cada cambio**. La memoria solo se actualiza
  *después* de guardar bien, así que el archivo y la memoria nunca se
  contradicen.
- Al cerrar la bóveda (`lock()`) **borra las entradas de la memoria**: los
  secretos no se quedan rondando por la app.
- Búsqueda por **título, persona y etiqueta** de campo. **Nunca** por el
  valor de un campo: si un secreto se pudiera encontrar por su texto, la
  pantalla de búsqueda sería una puerta trasera.
- Filtros derivados: `favorites`, `trashed`, `persons`, `categoryIds`.

### Archivos que importan

```
lib/data/
  models/entry_field.dart      campo (etiqueta, valor, tipo, secreto)
  models/vault_entry.dart      entrada
  models/vault_document.dart   el documento completo
  vault_file_system.dart       ruta privada + escritura atómica
  vault_storage.dart           cifrar/descifrar el archivo
lib/core/platform/backup_exclusion.dart   canal nativo iOS/Android
lib/controllers/entries_controller.dart   CRUD + búsqueda + papelera
ios/Runner/AppDelegate.swift   excluye el archivo de la copia de iCloud
android/.../MainActivity.kt    canal equivalente (no-op)
```

### Pruebas

`flutter analyze` → sin problemas. `flutter test` → **89 pruebas, todas
correctas** (50 anteriores + 39 nuevas):

- Modelos: ida y vuelta a JSON, tipos desconocidos, `copyWith` con campos
  nulos, documentos con varias entradas.
- Archivo: ida y vuelta, **el archivo no contiene los secretos en claro**,
  otra clave no lo lee, manipulación detectada, archivo inexistente.
- CRUD: crear, editar, papelera, restaurar, borrar, favorita, duplicar,
  purga a los 30 días, cierre (borra memoria), blocage con la bóveda cerrada.
- Búsqueda: por título, persona y etiqueta; **nunca por el valor de un
  secreto**; ignora la papelera.
- Persistencia: los cambios sobreviven a "reiniciar la app"; el archivo se
  reescribe en cada cambio.

### Cómo probarlo en tu móvil

Aún no hay interfaz de entradas (llega en la fase 5), así que la app se ve
igual que en la fase 2. Lo que sí se puede comprobar es que **no se rompe
nada** y que el archivo cifrado aparece en el disco:

```bash
# Android: ver el archivo de la bóveda
adb shell run-as com.example.llavero2 ls files/llavero/
```

Para probar el CRUD sin tocar la interfaz:

```bash
flutter test test/entries_controller_test.dart test/vault_storage_test.dart test/models_test.dart
```

---

## Fases siguientes

| Fase | Contenido | Estado |
|---|---|---|
| 1 | Configuración, tema, fuentes, idiomas, rutas, `AppScope` | ✅ Hecho |
| 2 | Criptografía, almacén seguro, bloqueo por intentos | ✅ Hecho |
| 3 | Archivo cifrado, modelos, `EntriesController` con CRUD | ✅ Hecho |
| 4 | Onboarding, PIN, biometría, pantalla de bloqueo | ✅ Hecho |
| 5 | Inicio, CRUD de entradas, plantillas, generador de contraseñas, papelera | ✅ Hecho |
| 6 | Exportar/importar (backup cifrado, CSV/JSON, PDF) | ✅ Hecho |
| 7 | Ajustes, estado de seguridad, bloqueo automático, capturas bloqueadas | ✅ Hecho |
| 8 | Animaciones, accesibilidad, iconos, revisión ES/EN, tablets | ✅ Hecho |
| 9 | README y lista honesta de limitaciones | ✅ Hecho |

## Fase 4 — Completada ✅

### Qué se construyó

| Área | Detalle |
|---|---|
| **Onboarding** | Pantalla de primera ejecución + crear PIN (validar + confirmar) → crear bóveda. |
| **Pantalla de bloqueo** | Entrada de PIN oculta, botón biométrico (si habilitado), cuenta atrás de bloqueo. |
| **Biometría** | `BiometricAuth` con `local_auth`: la copia de la DEK solo se lee tras confirmar huella/rostro. PIN siempre plan B. |
| **Wiring** | `LockController` → `EntriesController`: al desbloquear carga las entradas con la DEK; al bloquear, borra la memoria. |

### Archivos creados

```
lib/core/security/biometric_auth.dart      ← BiometricAuth + DeviceBiometricAuth
lib/features/onboarding/                   ← onboarding_screen.dart, pin_create_screen.dart
lib/features/lock/lock_screen.dart         ← pantalla de bloqueo
test/onboarding_test.dart                  ← 3 tests de onboarding
test/lock_screen_test.dart                 ← 7 tests de bloqueo/biometría/wiring
```

### Decisiones

- El PIN de onboarding permite **4–8 dígitos** (el ajuste `pinLength` no limita el campo).
- La biometría se habilita desde `LockController.setBiometricsEnabled`, que requiere la bóveda abierta (DEK disponible); la UI de ajustes llegará en la Fase 7.

### Pruebas

`flutter analyze` → sin problemas. `flutter test` → **99 pruebas, todas correctas**.

---

## Fase 5 — Completada ✅

### Qué se construyó

| Área | Detalle |
|---|---|
| **Home** | Listado de entradas con búsqueda (título/persona/etiqueta) y filtro de favoritas; acceso a papelera y alta de entradas. |
| **Formulario** | Alta y edición de entradas: título, persona, categoría, notas, favorita y campos dinámicos (etiqueta/valor/tipo/secreto). |
| **Generador** | `PasswordGenerator`: contraseñas aleatorias (4 conjuntos, garantiza uno de cada) y PIN numérico. |
| **Plantillas** | Wi-Fi, cuenta web, PIN, tarjeta y nota. |
| **Detalle** | Campos con secretos ocultos, revelado temporal y copia al portapapeles; editar, duplicar, favorita, papelera. |
| **Papelera** | Restaurar, borrar para siempre y purga de entradas caducadas (30 días). |

### Archivos creados

```
lib/core/security/password_generator.dart   ← generador de contraseñas y PINs
lib/data/entry_templates.dart               ← plantillas de entradas
lib/features/home/home_screen.dart          ← listado real (antes placeholder)
lib/features/entries/entry_form_screen.dart ← alta/edición
lib/features/entries/entry_detail_screen.dart ← detalle con secretos ocultos
lib/features/trash/trash_screen.dart        ← papelera
test/password_generator_test.dart           ← 6 tests
test/entry_templates_test.dart              ← 5 tests
test/fase5_flow_test.dart                   ← test de integración del flujo
```

### Pruebas

`flutter analyze` → sin problemas. `flutter test` → **111 pruebas, todas correctas**.

---

## Fase 6 — Completada ✅

### Qué se construyó

| Área | Detalle |
|---|---|
| **Respaldo cifrado** | `.llavero` con contraseña distinta del PIN (Argon2id + AES-GCM); exportar e importar. |
| **JSON / CSV** | Exportación en claro pero **sin valores secretos** (`[oculto]`). |
| **PDF** | Resumen imprimible con fuente embebida (sin avisos de Unicode). |
| **UI** | Pantalla de exportar/importar con `file_picker`, `share_plus` y `printing`. |
| **`replaceAll`** | Importar reemplaza la bóveda actual y persiste el cambio. |

### Archivos creados

```
lib/data/export_service.dart                        ← backup cifrado + JSON/CSV/PDF
lib/features/export_import/export_import_screen.dart ← pantalla de exportar/importar
test/export_service_test.dart                       ← 7 tests
test/export_import_screen_test.dart                 ← 1 test de UI
```

### Pruebas

`flutter analyze` → sin problemas. `flutter test` → **123 pruebas, todas correctas**.

---

## Fase 7 — Completada ✅

### Qué se construyó

| Área | Detalle |
|---|---|
| **Ajustes** | Pantalla real con tema, idioma, longitud PIN, retardo de bloqueo, tiempo de portapapeles y acceso a exportar/importar. |
| **Estado de seguridad** | Bóveda creada, biometría activada, intentos fallidos y botón «Bloquear ahora». |
| **Bloqueo automático** | `AppLifecycleLock` observa el ciclo de vida y bloquea al pasar a segundo plano según el retardo elegido. |
| **Capturas** | `ScreenSecurity` con canal nativo: `FLAG_SECURE` en Android y overlay en iOS. |

### Archivos creados/modificados

```
lib/core/platform/screen_security.dart        ← MethodChannel de capturas
lib/core/widgets/app_lifecycle_lock.dart      ← bloqueo por ciclo de vida
lib/features/settings/settings_screen.dart    ← ajustes reales
android/.../MainActivity.kt                    ← FLAG_SECURE
ios/.../AppDelegate.swift                      ← overlay anti-capturas
test/screen_security_test.dart                ← 3 tests
test/app_lifecycle_lock_test.dart             ← 1 test
test/settings_screen_test.dart                ← 4 tests
```

### Pruebas

`flutter analyze` → sin problemas. `flutter test` → **131 pruebas, todas correctas**.

---

## Fase 8 — Completada ✅

### Qué se construyó

| Área | Detalle |
|---|---|
| **Animaciones** | `AnimatedEntryTile` (fundido + desplazamiento escalonado) que respeta `MediaQuery.disableAnimations`. |
| **Accesibilidad** | Semántica en tarjetas y campos de búsqueda, iconos decorativos excluidos, tooltips en botones y estrella con etiqueta. |
| **Iconos** | Uso consistente de Material Icons en todas las pantallas. |
| **ES/EN** | Test que garantiza que ambos ARB tienen las mismas claves, textos no vacíos y metadatos `@`. |
| **Tablets** | `LayoutBuilder` en Home: rejilla de dos columnas desde 600dp; el contenido sigue limitado a 720dp. |

### Archivos creados/modificados

```
lib/core/widgets/animated_entry_tile.dart         ← animación accesible
lib/features/home/home_screen.dart                ← Semantics + layout adaptable
test/animated_entry_tile_test.dart                ← 2 tests
test/tablet_layout_test.dart                      ← 3 tests
test/l10n_completeness_test.dart                  ← 3 tests
```

### Pruebas

`flutter analyze` → sin problemas. `flutter test` → **139 pruebas, todas correctas**.

---

## Decisiones y notas

- **Idioma por defecto**: si el móvil está en un idioma que no es es/en, se
  muestra español (`localeResolutionCallback` en `lib/app.dart`). Es una
  línea fácil de cambiar si prefieres inglés.
- **`intl` está fijado en `^0.20.2`** porque es la versión que exige el SDK
  de Flutter 3.44 (`flutter_localizations`).
- **Categorías**: los identificadores de categoría son cadenas
  (`CategoryIds`) y no un `enum`, porque el usuario podrá crear categorías
  nuevas más adelante.
- **Biometría**: la copia de la DEK para biometría vive en el almacén seguro
  del sistema y **solo se lee después** de que `local_auth` confirme la
  huella/rostro. Así el usuario ve un único aviso biométrico (el del propio
  sistema) y el PIN sigue funcionando siempre como plan B.
- **AAD (datos extra)**: cada cifrado lleva un contexto distinto
  (`dek-wrap`, `vault`, `backup`). Así una DEK envuelta no se puede reutilizar
  como si fuera el contenido de la bóveda.
- **La biometría aún no está cableada**: `local_auth` se usa en la fase 4.
