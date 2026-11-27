# AGENTS.md — reglas permanentes para Llavero

Estas reglas aplican a cualquier trabajo futuro en este repositorio.

## Arquitectura y dependencias

- Usar **state management nativo de Flutter**: `ChangeNotifier` + `InheritedNotifier` (`AppScope`). No añadir Riverpod, Provider, BLoC ni otros gestores.
- **No añadir paquetes nuevos sin preguntar antes** al usuario.
- La app es **100 % offline**: nunca añadir el permiso `INTERNET`, paquetes de red, analítica ni reportadores de fallos.

## Diseño y textos

- Mantener la paleta (`AppPalette`), las fuentes (`AppTypography`: Plus Jakarta Sans y JetBrains Mono) y `AppSpacing`.
- No escribir colores literales ni números mágicos de espaciado en los widgets: leer siempre del tema y de `AppSpacing`.
- Todos los textos visibles para el usuario deben estar en **ambos** archivos ARB (`lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`).

## Datos y migraciones

- Cualquier cambio de formato de datos (bóveda, respaldo o modelos) **debe** incluir una migración y un test que cargue un fixture del formato anterior.
- Antes de migrar, conservar una copia del archivo antiguo. Nunca borrar ni sobrescribir datos del usuario por un error.

## Seguridad y privacidad

- Nunca registrar ni mostrar secretos, PINs ni rutas de archivos en mensajes, logs ni excepciones.
- El código de criptografía, bloqueo por intentos y re-autenticación solo se puede modificar **después de mostrar el plan al usuario** y recibir su aprobación.

## Verificación y cierre

- Antes de dar por terminada cualquier tarea: `flutter analyze`, `flutter test` y `flutter build apk --release` deben pasar.
- Después, hacer commit y entregar el hash del commit.

## Cumplimiento y versionado

- Si cambian textos legales o el tratamiento de datos, actualizar `assets/legal/*` y su fecha "Last updated".
- Subir la versión en `pubspec.yaml` en cada release.

## Comunicación

- Responder al usuario siempre en **español sencillo**.
