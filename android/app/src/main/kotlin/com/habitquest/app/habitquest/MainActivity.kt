package com.habitquest.app.habitquest

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Dynamic app icon (HabitQuest_PRD.md §9): flips which of the 4
 * activity-aliases declared in AndroidManifest.xml is enabled, so the
 * home-screen launcher icon changes without swapping the app itself.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "habitquest/app_icon"

    // Dart-side icon name -> activity-alias android:name suffix. Must match
    // AndroidManifest.xml's <activity-alias> entries exactly.
    private val aliasSuffixes = mapOf(
        "happy" to "IconHappy",
        "neutral" to "IconNeutral",
        "sad" to "IconSad",
        "angry" to "IconAngry",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "setAppIcon") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val suffix = aliasSuffixes[call.argument<String>("icon")]
                if (suffix == null) {
                    result.error("invalid_icon", "Unknown icon name: ${call.argument<String>("icon")}", null)
                    return@setMethodCallHandler
                }
                try {
                    setActiveIcon(suffix)
                    result.success(null)
                } catch (e: Exception) {
                    // Never crash the app over a cosmetic launcher-icon change.
                    result.error("set_icon_failed", e.message, null)
                }
            }
    }

    /** Enables the [activeSuffix] alias and disables the other 3, so only one is ever active. */
    private fun setActiveIcon(activeSuffix: String) {
        for (suffix in aliasSuffixes.values) {
            val state = if (suffix == activeSuffix) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            val component = ComponentName(packageName, "$packageName.$suffix")
            packageManager.setComponentEnabledSetting(component, state, PackageManager.DONT_KILL_APP)
        }
    }
}
