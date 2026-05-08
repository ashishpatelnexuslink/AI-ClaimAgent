package com.nexuslink.draudita.claim_ai

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterFragmentActivity() {
    private val downloadsChannel = "claim_ai/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> handleSaveToDownloads(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleSaveToDownloads(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("UNSUPPORTED", "Requires Android 10 (API 29) or newer", null)
            return
        }
        val srcPath = call.argument<String>("srcPath")
        val fileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
        if (srcPath.isNullOrEmpty() || fileName.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "srcPath and fileName are required", null)
            return
        }
        val src = File(srcPath)
        if (!src.exists()) {
            result.error("SRC_NOT_FOUND", "Source file does not exist", null)
            return
        }

        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
        if (uri == null) {
            result.error("INSERT_FAILED", "MediaStore insert returned null", null)
            return
        }
        try {
            resolver.openOutputStream(uri).use { output ->
                if (output == null) throw IllegalStateException("openOutputStream returned null")
                FileInputStream(src).use { input -> input.copyTo(output) }
            }
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            result.success(uri.toString())
        } catch (e: Exception) {
            // Roll back the row we created so a half-written file isn't left behind.
            resolver.delete(uri, null, null)
            result.error("WRITE_FAILED", e.message, null)
        }
    }
}
