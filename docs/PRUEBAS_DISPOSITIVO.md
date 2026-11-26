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

## 8. Registro de errores

Durante todas las pruebas, vigilar el log:

```bash
adb -s emulator-5554 logcat -d -t 300 | grep -i -E "exception|flutter|llavero" | tail -50
```

No deben aparecer `PathNotFoundException`, `MissingPluginException` ni
errores de `MethodChannel`.
