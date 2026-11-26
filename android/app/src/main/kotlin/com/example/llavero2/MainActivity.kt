package com.example.llavero2

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.content.pm.PackageManager
import android.view.WindowManager
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_SECURE_FILE = "llavero/secure_file"
        private const val CHANNEL_SCREEN = "llavero/screen_security"
        private const val CHANNEL_INTEGRITY = "llavero/device_integrity"

        private val ROOT_PATHS = arrayOf(
            "/system/app/Superuser.apk",
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/data/local/su",
            "/su/bin/su"
        )
    }

    /**
     * Canales nativos para la seguridad de la bóveda.
     *
     * `llavero/secure_file`: en Android no hay nada que hacer (el manifiesto
     * desactiva la copia de seguridad), solo respondemos.
     *
     * `llavero/screen_security`: FLAG_SECURE evita capturas y grabaciones.
     *
     * `llavero/device_integrity`: señales informativas de root.
     */
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

        MethodChannel(messenger, CHANNEL_INTEGRITY)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isCompromised" -> result.success(isRooted())
                    else -> result.notImplemented()
                }
            }
    }

    /** Heurística sencilla: ^señales clásicas de root. Puede dar falsos positivos. */
    private fun isRooted(): Boolean {
        if (ROOT_PATHS.any { File(it).exists() }) return true
        return try {
            packageManager.getAppInfo("com.noshufou.android.su") != null ||
                checkBuildTag()
        } catch (_: Exception) {
            false
        }
    }

    private fun PackageManager.getAppInfo(packageName: String) =
        try {
            getApplicationInfo(packageName, 0)
        } catch (_: PackageManager.NameNotFoundException) {
            null
        }

    private fun checkBuildTag(): Boolean =
        android.os.Build.TAGS?.contains("test-keys", ignoreCase = true) == true
}
