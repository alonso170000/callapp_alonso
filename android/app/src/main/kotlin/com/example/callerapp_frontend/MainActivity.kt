package com.example.callerapp_frontend

import android.Manifest
import android.content.pm.PackageManager
import android.provider.CallLog
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "callerapp/call_log"
    private val requestCode = 781

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "latestFor") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_CALL_LOG, Manifest.permission.READ_PHONE_STATE), requestCode)
                    result.error("permission_denied", "Permite acceder al registro de llamadas para obtener la duración real.", null)
                    return@setMethodCallHandler
                }
                val phone = call.argument<String>("phone") ?: ""
                val startedAt = call.argument<Long>("startedAtMs") ?: 0L
                val digits = phone.filter { it.isDigit() }.takeLast(10)
                val cursor = contentResolver.query(
                    CallLog.Calls.CONTENT_URI,
                    arrayOf(CallLog.Calls._ID, CallLog.Calls.NUMBER, CallLog.Calls.DATE, CallLog.Calls.DURATION, CallLog.Calls.TYPE),
                    "${CallLog.Calls.TYPE} = ? AND ${CallLog.Calls.DATE} >= ?",
                    arrayOf(CallLog.Calls.OUTGOING_TYPE.toString(), (startedAt - 60000L).toString()),
                    "${CallLog.Calls.DATE} DESC"
                )
                cursor?.use {
                    while (it.moveToNext()) {
                        val number = it.getString(1)?.filter(Char::isDigit)?.takeLast(10) ?: continue
                        if (number == digits) {
                            result.success(mapOf("id" to it.getLong(0).toString(), "durationSeconds" to it.getLong(3).toInt()))
                            return@setMethodCallHandler
                        }
                    }
                }
                result.success(null)
            }
    }
}
