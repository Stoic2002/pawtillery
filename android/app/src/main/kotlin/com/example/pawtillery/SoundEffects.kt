package com.example.pawtillery

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.File

/**
 * Sound effects played straight from a SoundPool, with the channel on a
 * background task queue: playing a sound never waits on (or holds up) the
 * Android main thread, which also handles touches. The audio plugin ran
 * every call on that thread, and bursts of blasts stalled it for up to a
 * second (see docs/decisions.md). See lib/services/audio_service.dart.
 */
class SoundEffects(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val pool: SoundPool = SoundPool.Builder()
        .setMaxStreams(16)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build(),
        )
        .build()

    /** Sound id of each Flutter asset loaded. */
    private val ids = HashMap<String, Int>()

    private val channel = MethodChannel(
        messenger,
        "pawtillery/sfx",
        StandardMethodCodec.INSTANCE,
        messenger.makeBackgroundTaskQueue(),
    )

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "load" -> {
                val asset = call.argument<String>("asset")
                if (asset == null) {
                    result.error("args", "asset missing", null)
                    return
                }
                try {
                    load(asset)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("load", e.message, null)
                }
            }
            "play" -> {
                val id = ids[call.argument<String>("asset")]
                val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                if (id != null) pool.play(id, volume, volume, 1, 0, 1f)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Copies the asset out of the APK (it may be compressed there) and
     * loads it. Copied afresh each launch, so an update's new sound is
     * never shadowed by an old copy.
     */
    private fun load(asset: String) {
        if (ids.containsKey(asset)) return
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
        val file = File(context.cacheDir, "sfx-" + asset.substringAfterLast('/'))
        context.assets.open(key).use { input ->
            file.outputStream().use { input.copyTo(it) }
        }
        ids[asset] = pool.load(file.path, 1)
    }

    fun release() {
        channel.setMethodCallHandler(null)
        pool.release()
    }
}
