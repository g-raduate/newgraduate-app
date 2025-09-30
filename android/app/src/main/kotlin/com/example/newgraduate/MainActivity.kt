package com.example.newgraduate

import android.view.WindowManager
import android.provider.Settings
import android.hardware.display.DisplayManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PRIVACY_CHANNEL = "privacy_guard"
    private val SECURITY_CHANNEL = "security_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Privacy Guard Channel (للحماية الموجودة)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRIVACY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureFlag" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        runOnUiThread {
                            if (enabled) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Security Channel (للكشف عن التهديدات الجديدة)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDeveloperModeEnabled" -> {
                        val isDeveloperMode = checkDeveloperMode()
                        result.success(isDeveloperMode)
                    }
                    "isScreenMirroring" -> {
                        val isScreenMirroring = checkScreenMirroring()
                        result.success(isScreenMirroring)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkDeveloperMode(): Boolean {
        return try {
            // فحص إعدادات المطور
            val adbEnabled = Settings.Secure.getInt(
                contentResolver,
                Settings.Global.ADB_ENABLED, 0
            ) == 1

            // فحص إعدادات التطوير الأخرى
            val developmentSettingsEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                Settings.Secure.getInt(
                    contentResolver,
                    Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
                ) == 1
            } else {
                false
            }

            adbEnabled || developmentSettingsEnabled
        } catch (e: Exception) {
            false
        }
    }

    private fun checkScreenMirroring(): Boolean {
        return try {
            val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            val displays = displayManager.displays

            // إذا كان هناك أكثر من شاشة واحدة، فقد يكون هناك عرض للشاشة
            displays.size > 1
        } catch (e: Exception) {
            false
        }
    }
}
