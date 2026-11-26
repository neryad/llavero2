package com.example.llavero2

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.view.WindowManager

class MainActivity : FlutterActivity() {

    /**
     * Canales nativos para la seguridad de la bóveda.
     *
     * `llavero/secure_file`: en Android no hay nada que hacer (el manifiesto
     * desactiva la copia de seguridad), solo respondemos.
     *
     * `llavero/screen_security`: FLAG_SECURE evita capturas y grabaciones.
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "llavero/screen_security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setScreenshotsBlocked" -> {
                        val args = call.arguments as? Map<*, *>
                        val blocked = args?.get("blocked") as? Boolean ?: true
                        if (blocked) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
