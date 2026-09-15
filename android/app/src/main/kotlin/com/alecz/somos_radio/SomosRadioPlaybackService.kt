package com.alecz.somos_radio

import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService

class SomosRadioPlaybackService : MediaSessionService() {
    private var mediaSession: MediaSession? = null

    override fun onCreate() {
        super.onCreate()

        val player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build(),
                true,
            )
        }

        mediaSession = MediaSession.Builder(this, player).build()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? = mediaSession

    override fun onDestroy() {
        mediaSession?.run {
            player.release()
            release()
        }
        mediaSession = null
        super.onDestroy()
    }

    companion object {
        fun stationItem(
            slug: String,
            streamUrl: String,
            title: String,
            city: String,
            artworkUrl: String?,
        ): MediaItem {
            val metadata = MediaMetadata.Builder()
                .setTitle(title)
                .setArtist(city.ifBlank { "Chiapas" })
                .setAlbumTitle("Somos Radio Chiapas")
                .setIsPlayable(true)
                .apply {
                    if (!artworkUrl.isNullOrBlank()) {
                        setArtworkUri(android.net.Uri.parse(artworkUrl))
                    }
                }
                .build()

            return MediaItem.Builder()
                .setMediaId(slug)
                .setUri(streamUrl)
                .setMediaMetadata(metadata)
                .build()
        }
    }
}
