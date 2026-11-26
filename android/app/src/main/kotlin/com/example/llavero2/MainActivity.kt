package com.example.llavero2

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_SECURE_FILE = "llavero/secure_file"
        private const val CHANNEL_SCREEN = "llavero/screen_security"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Seguro por defecto DESDE EL PRIMER FRAME: así ni el splash ni el
        // app switcher pueden mostrar contenido antes de que Dart decida.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, CHANNEL_SECURE_FILE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "excludeFromBackup" -> result.success(null)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(messenger, CHANNEL_SCREEN)
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
