package com.alecz.somos_radio

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.alecz.somos_radio/media3"
        private const val EVENT_CHANNEL = "com.alecz.somos_radio/media3_events"
        private const val DEVICE_CHANNEL = "com.alecz.somos_radio/device"
    }

    private var controllerFuture: ListenableFuture<MediaController>? = null
    private var mediaController: MediaController? = null
    private var eventSink: EventChannel.EventSink? = null

    private val playerListener = object : Player.Listener {
        override fun onEvents(player: Player, events: Player.Events) = publishState(player)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceKey" -> {
                        val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                        if (androidId.isNullOrBlank()) {
                            result.error("DEVICE_ID", "No se pudo obtener la identidad del dispositivo", null)
                        } else {
                            result.success("android:$androidId")
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    mediaController?.let(::publishState)
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playChannel" -> {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("INVALID_ARGS", "Missing station data", null)
                            return@setMethodCallHandler
                        }
                        withController(result) { controller ->
                            controller.setMediaItem(
                                SomosRadioPlaybackService.stationItem(
                                    slug = args["slug"]?.toString().orEmpty(),
                                    streamUrl = args["stream_url"]?.toString().orEmpty(),
                                    title = args["name"]?.toString().orEmpty(),
                                    city = args["city"]?.toString().orEmpty(),
                                    artworkUrl = args["artwork_url"]?.toString(),
                                ),
                            )
                            controller.prepare()
                            controller.play()
                            null
                        }
                    }
                    "play" -> withController(result) { it.play(); null }
                    "pause" -> withController(result) { it.pause(); null }
                    "stop" -> withController(result) {
                        it.stop()
                        it.clearMediaItems()
                        null
                    }
                    "state" -> withController(result) { stateMap(it) }
                    else -> result.notImplemented()
                }
            }

        connectController()
    }

    private fun connectController() {
        if (controllerFuture != null) return
        val token = SessionToken(this, ComponentName(this, SomosRadioPlaybackService::class.java))
        controllerFuture = MediaController.Builder(this, token).buildAsync().also { future ->
            future.addListener({
                try {
                    mediaController = future.get().also {
                        it.addListener(playerListener)
                        publishState(it)
                    }
                } catch (_: Exception) {
                    eventSink?.error("MEDIA3_CONNECT", "No se pudo conectar con el reproductor", null)
                }
            }, mainExecutor)
        }
    }

    private fun withController(result: MethodChannel.Result, action: (MediaController) -> Any?) {
        val current = mediaController
        if (current != null) {
            try {
                result.success(action(current))
            } catch (error: Exception) {
                result.error("MEDIA3_ERROR", error.message, null)
            }
            return
        }

        val future = controllerFuture
        if (future == null) {
            connectController()
            result.error("MEDIA3_CONNECT", "El reproductor todavía no está listo", null)
            return
        }

        future.addListener({
            try {
                val controller = future.get()
                mediaController = controller
                result.success(action(controller))
            } catch (error: Exception) {
                result.error("MEDIA3_ERROR", error.message, null)
            }
        }, mainExecutor)
    }

    private fun publishState(player: Player) {
        eventSink?.success(stateMap(player))
    }

    private fun stateMap(player: Player): Map<String, Any?> {
        val item: MediaItem? = player.currentMediaItem
        return mapOf(
            "playing" to player.isPlaying,
            "playback_state" to player.playbackState,
            "media_id" to item?.mediaId,
            "title" to item?.mediaMetadata?.title?.toString(),
            "artist" to item?.mediaMetadata?.artist?.toString(),
            "artwork_url" to item?.mediaMetadata?.artworkUri?.toString(),
        )
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val updatesChannel = NotificationChannel(
            "somos_radio_updates",
            "Avisos de Somos Radio",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Notificaciones, promociones y avisos de Somos Radio"
            enableVibration(true)
        }
        manager.createNotificationChannel(updatesChannel)
    }

    override fun onDestroy() {
        mediaController?.removeListener(playerListener)
        mediaController = null
        controllerFuture?.let(MediaController::releaseFuture)
        controllerFuture = null
        super.onDestroy()
    }
}
