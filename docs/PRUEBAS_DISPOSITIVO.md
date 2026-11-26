# Pruebas en dispositivo real

Los tests automatizados cubren la lógica con mocks, pero varios plugins solo
se pueden validar en hardware. Esta guía se ejecuta en un Android o iOS real
(y también sirve con emulador).

**Antes de empezar:** `flutter pub get` y `flutter run -d <id>`.

Dispositivos detectados en este entorno: `emulator-5554` (Android 17),
`macos` y `chrome`.

---

## 1. Escritura de la bóveda (crítico)

El bug `PathNotFoundException: vault.dat.tmp` solo apareció aquí.

1. Abrir la app y crear el PIN si es la primera vez.
2. Desbloquear y añadir una entrada con un campo secreto.
3. Comprobar que no hay excepciones y que la entrada aparece al reiniciar.
4. Verificar el archivo en Android:

   ```bash
   adb shell run-as com.example.llavero2 ls -la files/llavero/
   adb shell run-as com.example.llavero2 cat files/llavero/vault.dat
   ```

   Debe existir `vault.dat` y **no** debe contener los secretos en claro.
5. Repetir el paso 2 varias veces: no debe quedar ningún `vault.dat.tmp`.

---

## 2. `local_auth` (biometría)

1. Desbloquear con el PIN.
2. Ir a Ajustes → activar «Biometría» (el switch solo está activo con la
   bóveda abierta).
3. Bloquear y volver a abrir: pulsar «Desbloquear con biometría».
4. El sistema debe pedir huella/rostro **una sola vez**.
5. Rechazar la biometría: debe volver al PIN sin abrir la bóveda.
6. Reiniciar el móvil: la biometría sigue disponible; el PIN también.

---

## 3. `file_picker` (importar respaldo)

1. Exportar un respaldo `.llavero` y enviarlo al dispositivo.
2. Ajustes → Exportar/importar → Importar respaldo → elegir el archivo.
3. Escribir la contraseña correcta: debe aparecer «Respaldo importado».
4. Repetir con contraseña incorrecta: debe aparecer «No se pudo importar» y
   **no** debe cambiar la bóveda actual.

---

## 4. `share_plus` (exportar)

1. Exportar respaldo / JSON / CSV.
2. Compartir con otra app (por ejemplo, Gmail o Archivos).
3. Comprobar que el archivo llega con el nombre correcto
   (`llavero-<timestamp>.llavero`, `.json` o `.csv`).
4. En iOS, verificar el `share sheet` en iPad (debe anclarse al botón).

---

## 5. `printing` (PDF)

1. Exportar PDF desde Ajustes → Exportar/importar.
2. Comprobar que el diálogo de impresión muestra el documento con los
   títulos y campos, y que **no** aparecen los valores secretos (`[oculto]`).
3. En Android e iOS, verificar que se puede guardar como PDF.

---

## 6. Capturas de pantalla

**Android:** con «Bloquear capturas» activo, intentar capturar pantalla.
Debe fallar o dar una imagen negra.

**iOS:** hacer una captura: debe aparecer brevemente un overlay negro. Es una
limitación de iOS (no existe el equivalente a `FLAG_SECURE`).

---

## 7. Bloqueo automático y ciclo de vida

1. Ajustes → «Bloqueo automático» → «Inmediato».
2. Desbloquear, ir a Home y pasar a segundo plano.
3. Volver: debe pedir el PIN de nuevo.
4. Repetir con «30 segundos»: al volver antes de 30 s no debe pedir PIN;
   después de 30 s, sí.

---

## 8. Checklist de diseño y resistencia (Phase D)

Marca cada casilla con el dispositivo real o el emulador que estés usando.

### 9.1 Longitudes de PIN 4 / 6 / 8

- [ ] Crear la bóveda desde cero con **4** dígitos: se ven 4 puntos, el último
      dígito envía solo y la confirmación pide otros 4.
- [ ] Repetir con **6** (valor por defecto) y con **8**.
- [ ] Desbloquear con cada PIN y comprobar que el número de puntos coincide.
- [ ] Cambiar el PIN desde Ajustes a cada una de las tres longitudes y
      verificar que el PIN antiguo deja de abrir.
- [ ] Un PIN inválido (secuencia, repetido, común) muestra su mensaje y sacude.

### 9.2 Modo oscuro en todas las pantallas

- [ ] Splash / bienvenida (selector ES-EN y botón ancho).
- [ ] Creación de PIN y pantalla de bloqueo.
- [ ] Home (secciones, chips de filtro, banner de respaldo, estados vacíos).
- [ ] Formulario de entrada (rejilla de categorías, chips Streaming, campos,
      interruptor «Secreto», botón Guardar).
- [ ] Detalle, papelera, categorías y salud de contraseñas.
- [ ] Exportar/importar y todos los grupos de Ajustes.
- [ ] En cada `SegmentedButton`: el segmento seleccionado tiene fondo ámbar y
      texto/check oscuro; el no seleccionado tiene texto claro y borde visible.
- [ ] `FilterChip` seleccionado: el check se ve claro sobre el fondo oscuro.

### 9.3 Escala de fuente al 200 %

- [ ] Ajustes del sistema → tamaño de fuente / texto al **200 %**.
- [ ] Recorrer todas las pantallas: nada se corta, solapa ni queda fuera.
- [ ] Foco especial en el PIN, la rejilla de categorías, los chips y el botón
      Guardar del formulario.

### 9.4 Rotación

- [ ] Girar el dispositivo a horizontal y volver en cada pantalla.
- [ ] La entrada/estado no se pierde y no aparecen desbordes.

### 9.5 Pantalla pequeña

- [ ] Probar con un emulador de **320 dp** de ancho (o el móvil más pequeño).
- [ ] Los segmentados de 4/6/8, tema e idioma caben sin recortarse.
- [ ] Las filas de Ajustes mantienen la columna de icono y el desplegable de
      «Tiempo en el portapapeles» es visible.
- [ ] El botón Guardar sigue visible sin tener que ocultar el teclado.

### 9.6 Ciclo completo: exportar → borrar → importar

1. Crear una entrada con un secreto reconocible y anotarlo.
2. Ajustes → Exportar/importar → exportar respaldo `.llavero` con contraseña;
   guardar el archivo fuera del dispositivo.
3. Comprobar que el archivo **no** contiene el secreto en claro.
4. **Borrar la app por completo**: desinstalar y reinstalar (o «Borrar datos»
   desde Ajustes del sistema). No basta con borrar solo `vault.dat`.
5. Crear un PIN nuevo en la reinstallación; la bóveda debe estar vacía.
6. Importar el respaldo con la contraseña correcta: aparecen todas las entradas
   y el secreto se ve igual que antes.
7. Repetir el paso 6 con contraseña incorrecta: debe fallar sin sobrescribir la
   bóveda actual.
8. Reiniciar el móvil: las entradas siguen ahí y el PIN nuevo sigue abriendo.

---

## 9. Registro de errores

Durante todas las pruebas, vigilar el log:

```bash
adb -s emulator-5554 logcat -d -t 300 | grep -i -E "exception|flutter|llavero" | tail -50
```

No deben aparecer `PathNotFoundException`, `MissingPluginException` ni
errores de `MethodChannel`.
