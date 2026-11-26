package com.example.llavero2

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    /**
     * Canal nativo para los detalles de seguridad del archivo de la bóveda.
     *
     * En Android no hay nada que hacer: el manifiesto ya desactiva la copia
     * de seguridad (`android:allowBackup="false"` más `dataExtractionRules`),
     * así que el archivo de la bóveda nunca sale del dispositivo.
     *
     * Aquí solo respondemos para que la app no se quede esperando.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "llavero/secure_file")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "excludeFromBackup" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }
}
