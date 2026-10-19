package com.example.pawtillery

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null

    // Play on Wi-Fi: many phones drop broadcast packets (the room beacon)
    // unless an app holds a multicast lock. See lib/services/wifi_lock.dart.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
        super.onDestroy()
    }
}
