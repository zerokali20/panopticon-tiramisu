package com.example.panopticon

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.panopticon/audio_loopback"
    private val SCREEN_RECORD_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startLoopbackCapture") {
                startMediaProjectionRequest()
                result.success(null)
            } else if (call.method == "stopLoopbackCapture") {
                val serviceIntent = Intent(this, AudioCaptureService::class.java)
                serviceIntent.action = "STOP_CAPTURE"
                startService(serviceIntent)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startMediaProjectionRequest() {
        val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(mediaProjectionManager.createScreenCaptureIntent(), SCREEN_RECORD_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == SCREEN_RECORD_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val serviceIntent = Intent(this, AudioCaptureService::class.java).apply {
                    putExtra("code", resultCode)
                    putExtra("data", data)
                    action = "START_CAPTURE"
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

}
