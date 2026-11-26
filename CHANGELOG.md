# Changelog

Todos los cambios notables de Llavero se documentan en este archivo.
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [Unreleased]

### Added
- (Nada por ahora.)

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
