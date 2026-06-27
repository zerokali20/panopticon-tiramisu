package com.example.panopticon

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.app.Activity
import kotlin.concurrent.thread

class AudioCaptureService : Service() {

    private var mediaProjection: MediaProjection? = null
    private var audioRecord: AudioRecord? = null
    private var isRecording = false

    // Initialize JNI functions
    external fun pushAudioDataToCpp(audioData: FloatArray, numFrames: Int)

    companion object {
        init {
            System.loadLibrary("panopticon_audio")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "START_CAPTURE") {
            startForegroundNotification()

            val resultCode = intent.getIntExtra("code", Activity.RESULT_CANCELED)
            val data = intent.getParcelableExtra<Intent>("data")

            if (data != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
                startAudioCapture()
            }
        } else if (intent?.action == "STOP_CAPTURE") {
            stopCapture()
            stopSelf()
        }

        return START_NOT_STICKY
    }

    private fun startForegroundNotification() {
        val channelId = "audio_capture_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Audio Capture",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Panopticon Audio Monitoring")
            .setContentText("Monitoring system audio for threats...")
            .setSmallIcon(android.R.drawable.ic_dialog_info) // using standard android icon
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(1, notification)
        }
    }

    private fun startAudioCapture() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || mediaProjection == null) return

        val config = AudioPlaybackCaptureConfiguration.Builder(mediaProjection!!)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
            .build()

        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
            .setSampleRate(16000)
            .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
            .build()

        val minBufferSize = AudioRecord.getMinBufferSize(
            16000,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_FLOAT
        )

        audioRecord = AudioRecord.Builder()
            .setAudioSource(android.media.MediaRecorder.AudioSource.MIC)
            .setAudioFormat(format)
            .setBufferSizeInBytes(minBufferSize * 2)
            .build()

        audioRecord?.startRecording()
        isRecording = true

        thread {
            // Buffer size in floats (e.g. 480 frames to match RNNOISE_FRAME_SIZE)
            val floatBuffer = FloatArray(480)
            
            while (isRecording) {
                val readStatus = audioRecord?.read(floatBuffer, 0, floatBuffer.size, AudioRecord.READ_BLOCKING) ?: 0
                if (readStatus > 0) {
                    try {
                        pushAudioDataToCpp(floatBuffer, readStatus)
                    } catch (e: UnsatisfiedLinkError) {
                        e.printStackTrace()
                    }
                }
            }
        }
    }

    private fun stopCapture() {
        isRecording = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        mediaProjection?.stop()
        mediaProjection = null
    }
}
