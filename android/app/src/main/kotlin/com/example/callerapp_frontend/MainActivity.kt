package com.example.callerapp_frontend

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.CallLog
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "callerapp/call_log"
    private val cubeChannelName = "callerapp/cube_acr"
    private val requestCode = 781
    private val cubeFolderRequestCode = 782
    private val cubeAudioRequestCode = 783
    private var cubeFolderResult: MethodChannel.Result? = null
    private var cubeAudioResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "latestFor" -> {
                        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_CALL_LOG, Manifest.permission.READ_PHONE_STATE), requestCode)
                            result.error("permission_denied", "Permite acceder al registro de llamadas para obtener la duración real.", null)
                            return@setMethodCallHandler
                        }
                        val phone = call.argument<String>("phone") ?: ""
                        val windowStart = call.argument<Long>("startedAtMs") ?: 0L
                        val now = System.currentTimeMillis()
                        val digits = phone.filter { it.isDigit() }.takeLast(10)
                        val cursor = contentResolver.query(
                            CallLog.Calls.CONTENT_URI,
                            arrayOf(CallLog.Calls._ID, CallLog.Calls.NUMBER, CallLog.Calls.DATE, CallLog.Calls.DURATION, CallLog.Calls.TYPE),
                            "${CallLog.Calls.TYPE} = ? AND ${CallLog.Calls.DATE} >= ? AND ${CallLog.Calls.DATE} <= ?",
                            arrayOf(
                                CallLog.Calls.OUTGOING_TYPE.toString(),
                                (windowStart - 5000L).toString(),
                                (now + 5000L).toString(),
                            ),
                            "${CallLog.Calls.DATE} DESC"
                        )
                        cursor?.use {
                            while (it.moveToNext()) {
                                val number = it.getString(1)?.filter(Char::isDigit)?.takeLast(10) ?: continue
                                if (number == digits) {
                                    result.success(mapOf(
                                        "id" to it.getLong(0).toString(),
                                        "startedAtMs" to it.getLong(2),
                                        "durationSeconds" to it.getLong(3).toInt(),
                                    ))
                                    return@setMethodCallHandler
                                }
                            }
                        }
                        result.success(null)
                    }
                    "isCallActive" -> {
                        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
                            result.error("permission_denied", "Permite acceder al estado del teléfono para detectar la llamada.", null)
                            return@setMethodCallHandler
                        }
                        result.success(isCallInProgress())
                    }
                    else -> result.notImplemented()
                }
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
                    "pickRecording" -> {
                        cubeAudioResult = result
                        startActivityForResult(
                            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "audio/*"
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            },
                            cubeAudioRequestCode,
                        )
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

    /**
     * Devuelve si hay una llamada activa. Se usa para no descartar una sesión
     * cuando el usuario vuelve a la app mientras sigue hablando.
     */
    private fun isCallInProgress(): Boolean = try {
        val telephony = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
        @Suppress("DEPRECATION")
        val state = telephony.callState
        state != TelephonyManager.CALL_STATE_IDLE
    } catch (error: SecurityException) {
        false
    } catch (error: Exception) {
        false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == cubeAudioRequestCode) {
            val result = cubeAudioResult ?: return
            cubeAudioResult = null
            val uri = data?.data
            if (resultCode != RESULT_OK || uri == null) {
                result.success(null)
                return
            }
            val name = contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            } ?: "grabacion_${System.currentTimeMillis()}"
            result.success(mapOf("uri" to uri.toString(), "name" to name))
            return
        }
        if (requestCode == cubeFolderRequestCode) {
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
    }

    private fun listCubeRecordings(treeUri: Uri): List<Map<String, Any>> {
        val values = mutableListOf<Map<String, Any>>()
        val rootId = DocumentsContract.getTreeDocumentId(treeUri)
        collectCubeRecordings(treeUri, rootId, values, mutableSetOf())
        return values
    }

    private fun collectCubeRecordings(
        treeUri: Uri,
        parentId: String,
        values: MutableList<Map<String, Any>>,
        visited: MutableSet<String>,
    ) {
        if (!visited.add(parentId) || values.size >= 2000) return
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            parentId,
        )
        contentResolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1) ?: continue
                val mimeType = cursor.getString(2)
                if (mimeType == DocumentsContract.Document.MIME_TYPE_DIR) {
                    collectCubeRecordings(treeUri, id, values, visited)
                    continue
                }
                val extension = name.substringAfterLast('.', "").lowercase()
                if (extension !in setOf("amr", "m4a", "mp3", "wav", "aac", "ogg", "3gp", "opus")) continue
                values.add(mapOf(
                    "uri" to DocumentsContract.buildDocumentUriUsingTree(treeUri, id).toString(),
                    "name" to name,
                    "modifiedAtMs" to cursor.getLong(3),
                ))
            }
        }
    }
}
