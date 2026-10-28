package com.example.callerapp_frontend

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.CallLog
import android.provider.DocumentsContract
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "callerapp/call_log"
    private val cubeChannelName = "callerapp/cube_acr"
    private val requestCode = 781
    private val cubeFolderRequestCode = 782
    private var cubeFolderResult: MethodChannel.Result? = null

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, cubeChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFolder" -> {
                        cubeFolderResult = result
                        startActivityForResult(
                            Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                            ),
                            cubeFolderRequestCode,
                        )
                    }
                    "listRecordings" -> {
                        val treeUri = call.argument<String>("treeUri")
                        if (treeUri == null) {
                            result.error("invalid_folder", "La carpeta de Cube ACR no es válida.", null)
                        } else {
                            result.success(listCubeRecordings(Uri.parse(treeUri)))
                        }
                    }
                    "copyRecording" -> {
                        val source = call.argument<String>("uri")
                        val name = call.argument<String>("name")
                        if (source == null || name == null) {
                            result.error("invalid_audio", "La grabación seleccionada no es válida.", null)
                        } else {
                            try {
                                val directory = java.io.File(filesDir, "call_audio")
                                directory.mkdirs()
                                val target = java.io.File(directory, "${System.currentTimeMillis()}_$name")
                                contentResolver.openInputStream(Uri.parse(source))!!.use { input ->
                                    target.outputStream().use { output -> input.copyTo(output) }
                                }
                                result.success(mapOf("path" to target.absolutePath))
                            } catch (error: Exception) {
                                result.error("copy_failed", "No se pudo copiar la grabación.", error.message)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != cubeFolderRequestCode) return
        val result = cubeFolderResult ?: return
        cubeFolderResult = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            result.success(mapOf("uri" to uri.toString(), "name" to DocumentsContract.getTreeDocumentId(uri).substringAfterLast(':')))
        } catch (error: SecurityException) {
            result.error("folder_permission", "No se pudo conservar el acceso a la carpeta.", error.message)
        }
    }

    private fun listCubeRecordings(treeUri: Uri): List<Map<String, String>> {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
        val values = mutableListOf<Map<String, String>>()
        contentResolver.query(
            childrenUri,
            arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1) ?: continue
                if (!name.endsWith(".amr", ignoreCase = true)) continue
                values.add(mapOf(
                    "uri" to DocumentsContract.buildDocumentUriUsingTree(treeUri, id).toString(),
                    "name" to name,
                ))
            }
        }
        return values
    }
}
