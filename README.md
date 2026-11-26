# Llavero

Bóveda familiar de contraseñas y códigos, **100 % offline** y cifrada.

Llavero guarda tus contraseñas, PINs, Wi-Fis y notas en un único archivo
cifrado que nunca sale del dispositivo. No hay cuentas, no hay nube, no hay
permisos de Internet en la versión de producción.

---

## Características

- **Cifrado fuerte**: Argon2id para derivar la clave del PIN y AES-256-GCM
  para cifrar el contenido. Contextos AAD distintos para cada uso.
- **PIN propio**: 4–8 dígitos, con validación de secuencias, repeticiones y
  PINs comunes. Bloqueo escalonado tras intentos fallidos.
- **Biometría opcional**: huella/rostro como comodidad; el PIN siempre funciona
  como plan B.
- **Búsqueda segura**: por título, persona y etiqueta de campo. **Nunca** por
  el valor de un secreto.
- **Papelera**: los elementos borrados se conservan 30 días y se pueden
  restaurar.
- **Plantillas y generador**: plantillas para Wi-Fi, cuentas web, PINs,
  tarjetas y notas; generador de contraseñas y PINs aleatorios.
- **Exportar/importar**: respaldo cifrado `.llavero`, JSON, CSV y PDF.
- **QR de Wi-Fi**: para entradas Wi-Fi, código QR estándar `WIFI:T:...` que se
  muestra solo al pedirlo y se oculta al bloquear o a los 30 s.
- **Bloqueo automático** al pasar a segundo plano y **bloqueo de capturas**
  de pantalla.
- **Español e inglés**, tema claro/oscuro/sistema y diseño adaptable a tablets.

---

## Arquitectura

```
lib/
  main.dart                  punto de entrada (inicializa controladores)
  app.dart                   MaterialApp, tema, idioma, AppLifecycleLock
  core/
    app_scope.dart           InheritedNotifier con los controladores
    routes/                  rutas con nombre (Navigator, sin go_router)
    security/
      crypto/                KDF (Argon2id/PBKDF2), VaultCrypto, BackupCrypto
      biometric_auth.dart    abstracción sobre local_auth
      key_vault_service.dart crea/abre la bóveda,DEK envuelta
      pin_validator.dart     reglas del PIN
      lockout_policy.dart    castigo escalonado
      secure_store.dart      Keystore/Keychain (+ versión en memoria)
    platform/                canales nativos (backup, capturas)
    theme/                   paleta, tipografía, colores de categoría
    widgets/                 AppScaffold, animación, bloqueo por ciclo de vida
  controllers/               SettingsController, LockController, EntriesController
  data/
    models/                  VaultDocument, VaultEntry, EntryField (inmutables)
    vault_file_system.dart   rutas privadas + escritura atómica
    vault_storage.dart       cifrado/descifrado del archivo
    export_service.dart      respaldos, JSON, CSV, PDF
    entry_templates.dart     plantillas
  features/                  splash, onboarding, lock, home, entries,
                             trash, export_import, settings
test/                          tests unitarios y de widget
```

Los controladores **no importan nada de la interfaz**: solo `foundation.dart`
y la capa de seguridad. Por eso se pueden probar sin montar la app. El estado
se comparte con `AppScope.of(context)`.

No se usa generación de código (`json_serializable`, `freezed`, etc.):
`toJson`, `fromJson` y `copyWith` están escritos a mano.

---

## Modelo de seguridad

### Claves

```
        PIN del usuario
              │
              ▼
     Argon2id (64 MiB, 3 pasadas) ──► KEK
              │                        │
              │                        ▼
              │                  envuelve la DEK
              ▼                        ▼
        DEK aleatoria 256 bits ──► AES-256-GCM ──► bóveda cifrada
```

- La **DEK** es aleatoria y nunca se guarda en claro (salvo una copia en el
  almacén seguro del sistema si se activa la biometría).
- El **PIN nunca se guarda**. Solo la DEK envuelta, la sal y los parámetros.
- **AAD distinto** por contexto: `llavero:dek-wrap:v1`, `llavero:vault:v1`,
  `llavero:backup:v1`. Así un blob no se puede reutilizar en otro sitio.

### Bloqueo por intentos fallidos

| Intentos fallidos | Bloqueo |
|---|---|
| 1–4 | ninguno |
| 5 | 30 s |
| 6 | 1 min |
| 7 | 5 min |
| 8 | 15 min |
| 9 o más | 1 h |

El estado se guarda en el almacén seguro: reiniciar la app no reinicia el
castigo. Mientras está bloqueada, la app **ni siquiera deriva la clave**.

### Archivo de la bóveda

Un solo archivo privado (`llavero/vault.dat`) con un envelope JSON:

```json
{
  "format": "llavero-vault",
  "version": 1,
  "createdAt": "...",
  "payload": "<base64 de AES-256-GCM>"
}
```

La escritura es **atómica**: se escribe en `.tmp` y se renombra. Si el móvil se
apaga a mitad de escritura, el archivo bueno sigue intacto.

Android excluye el archivo de copias de seguridad desde el manifiesto; iOS
marca el archivo con `NSURLIsExcludedFromBackupKey`.

### Decisiones

- **Argon2id por defecto** (benchmark real en host: 381 ms; en emulador
  Android: 766 ms con 64 MiB, 168 ms con 32 MiB) y PBKDF2 como alternativa,
  porque los parámetros viajan en la cabecera y los archivos antiguos siguen
  leyéndose. La memoria se puede ajustar al compilar con
  `--dart-define=LLAVERO_KDF_MEMORY_KIB=32768` sin cambiar el formato.
- **`intl` fijado en `^0.20.2`** por compatibilidad con Flutter 3.44.
- Sin `google_fonts`: las fuentes están empaquetadas como assets.

---

## Cómo ejecutar

Requiere Flutter 3.44 o superior (Dart ^3.12.2).

```bash
flutter pub get
flutter run                 # en el dispositivo o emulador conectado
```

Para comprobar que todo sigue bien:

```bash
flutter analyze             # debe decir "No issues found!"
flutter test                # 228 pruebas
```

Para generar las traducciones después de tocar los `.arb`:

```bash
flutter gen-l10n
```

Para generar una release ofuscada (los símbolos se guardan fuera del repo):

```bash
flutter build apk --release --obfuscate \
  --split-debug-info=build/symbols/android --strip
flutter build ios --release --no-codesign --obfuscate \
  --split-debug-info=build/symbols/ios
```

`build/symbols/` no se versiona: guárdalo en un lugar seguro si necesitas
leer stacks de crash de una release.

Estructura de idiomas: `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`.
Un test verifica que ambos tienen exactamente las mismas claves.

---

## Uso

1. Al abrir por primera vez, elige un PIN y confírmalo.
2. Añade entradas desde el botón **+**. Puedes usar plantillas y el generador.
3. Busca por título, persona o etiqueta; filtra por categoría, persona y
   favoritas desde la Home.
4. Ajusta tema, idioma, longitud del PIN, bloqueo automático y capturas desde
   **Ajustes**. Para cambiar el PIN real usa **Cambiar PIN**.
5. Exporta un respaldo cifrado desde **Exportar / importar** y guarda la
   contraseña del respaldo en un lugar seguro: **no se puede recuperar**.

---

## Limitaciones honestas

Estas son carencias reales de la versión actual, no detalles menores:

1. **Sin sincronización (por diseño)**: la bóveda vive en un solo dispositivo.
   Para pasarla a otro, exporta un respaldo cifrado e impórtalo allí.
2. **La biometría solo se activa con la bóveda abierta**: hace falta la DEK
   para guardar su copia en el almacén seguro del sistema.
3. **Reloj del dispositivo**: el bloqueo por intentos fallidos guarda el tiempo
   restante y la última marca de hora; reiniciar el móvil **no** lo reinicia,
   pero si se adelanta el reloj el castigo puede agotarse antes. Si se retrasa,
   no se acorta. Sin servidor no se puede demostrar la hora real. Borrar los
   datos de la app o reinstalar también borra el estado del bloqueo.
4. **La longitud del PIN se cambia dentro de «Cambiar PIN»**, nunca desde
   Ajustes: primero se verifica el PIN actual, luego se elige 4/6/8 y se
   reenvuelve la DEK de forma atómica. El selector de Ajustes se eliminó.
5. **Portapapeles en segundo plano**: la limpieza es "best effort". Android 10+
   e iOS restringen manipular el portapapeles desde una app en segundo plano;
   al pasar a segundo plano se intenta, pero no se garantiza.
6. **iCloud no verificado en dispositivo real**: el archivo se marca con
   `NSURLIsExcludedFromBackupKey`, pero no se ha comprobado en un iPhone/iPad
   con iCloud activo; solo está verificado que compila.
7. **JSON, CSV y PDF omiten secretos por defecto** (`[oculto]`). Existe una
   opción «Incluir secretos en claro» con dos confirmaciones; el respaldo
   `.llavero` sigue siempre cifrado con la contraseña del respaldo.
8. **La búsqueda incluye títulos, personas, etiquetas y notas**, pero nunca
   valores secretos.
9. **La papelera se purga al abrir la bóveda** y también con el botón «Vaciar
   papelera»; no hay un servicio en segundo plano que lo haga.
10. **Argon2id se ejecuta en Dart puro** (`cryptography`, sin aceleración
    nativa). En móviles de gama baja el desbloqueo puede tardar 1–2 s; bajar la
    memoria a 32 MiB es una opción sin cambiar el formato del archivo.
11. **Anti-capturas en iOS es un overlay**, no un bloqueo del sistema. En
    Android sí se usa `FLAG_SECURE`.
12. **Sin detección de root/jailbreak ni ofuscación por defecto**: los datos
    están protegidos en reposo, pero la app no se defiende de un dispositivo
    comprometido. Los comandos de release con `--obfuscate` están documentados.
13. **Verificación en hardware pendiente**: los plugins (`local_auth`,
    `file_picker`, `share_plus`, `printing`) se probaron con mocks y canales
    simulados, y los builds nativos compilan, pero falta la ejecución
    interactiva en un teléfono real. La guía está en
    [docs/PRUEBAS_DISPOSITIVO.md](docs/PRUEBAS_DISPOSITIVO.md).
14. **Soporte móvil principal**: hay carpetas `web/` y `macos/` del template,
    pero el flujo de seguridad (Keystore/Keychain, capturas) está pensado para
    Android e iOS; el release universal de macOS falla por empaquetado.

---

## Estado del proyecto

Todas las fases planificadas están completadas (1–9), con la auditoría (A/B),
las mejoras de diseño (C) y la limpieza final (D) cerradas. El historial de
cambios por fase está en [CHANGELOG.md](CHANGELOG.md), el detalle de decisiones
en [PROGRESS.md](PROGRESS.md) y la checklist manual en
[docs/PRUEBAS_DISPOSITIVO.md](docs/PRUEBAS_DISPOSITIVO.md).

Licencia: uso personal / privado. `publish_to: none` en `pubspec.yaml`.
