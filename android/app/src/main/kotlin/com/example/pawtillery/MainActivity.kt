package com.example.pawtillery

import android.content.Context
import android.net.wifi.WifiManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private var soundEffects: SoundEffects? = null

    // Play on Wi-Fi: many phones drop broadcast packets (the room beacon)
    // unless an app holds a multicast lock. See lib/services/wifi_lock.dart.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        soundEffects = SoundEffects(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pawtillery/wifi")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquireMulticast" -> {
                        acquireMulticast()
                        result.success(null)
                    }
                    "releaseMulticast" -> {
                        releaseMulticast()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // During a match the screen stays on. See
        // lib/services/screen_awake.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pawtillery/screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "keepOn") {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun acquireMulticast() {
        if (multicastLock?.isHeld == true) return
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        multicastLock = wifi.createMulticastLock("pawtillery-lan").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseMulticast() {
        multicastLock?.let { if (it.isHeld) it.release() }
        multicastLock = null
    }

    override fun onDestroy() {
        releaseMulticast()
        soundEffects?.release()
        soundEffects = null
        super.onDestroy()
    }
}
