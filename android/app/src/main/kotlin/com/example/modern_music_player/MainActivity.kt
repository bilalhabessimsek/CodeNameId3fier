package com.example.modern_music_player

import android.media.MediaPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private var mediaPlayer: MediaPlayer? = null
    private val CHANNEL = "com.example.modern_music_player/midi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val path = call.argument<String>("path")
                    playMidi(path)
                    result.success(null)
                }
                "pause" -> {
                    pauseMidi()
                    result.success(null)
                }
                "resume" -> {
                    resumeMidi()
                    result.success(null)
                }
                "stop" -> {
                    stopMidi()
                    result.success(null)
                }
                "getDuration" -> {
                    result.success(mediaPlayer?.duration ?: 0)
                }
                "getPosition" -> {
                    result.success(mediaPlayer?.currentPosition ?: 0)
                }
                "seek" -> {
                    val position = call.argument<Int>("position") ?: 0
                    mediaPlayer?.seekTo(position)
                    result.success(null)
                }
                "isPlaying" -> {
                    result.success(mediaPlayer?.isPlaying ?: false)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playMidi(path: String?) {
        if (path == null) return
        stopMidi()
        try {
            mediaPlayer = MediaPlayer().apply {
                setDataSource(path)
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun pauseMidi() {
        mediaPlayer?.pause()
    }

    private fun resumeMidi() {
        mediaPlayer?.start()
    }

    private fun stopMidi() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }

    override fun onDestroy() {
        stopMidi()
        super.onDestroy()
    }
}
