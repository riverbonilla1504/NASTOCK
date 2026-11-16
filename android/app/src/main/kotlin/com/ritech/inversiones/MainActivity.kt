package com.ritech.inversiones

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var exportacion: Pair<String, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "inversiones/exportacion"
        ).setMethodCallHandler { llamada, resultado ->
            if (llamada.method != "guardarCsv") {
                resultado.notImplemented()
                return@setMethodCallHandler
            }
            val nombre = llamada.argument<String>("nombre")
            val contenido = llamada.argument<String>("contenido")
            if (nombre == null || contenido == null || exportacion != null) {
                resultado.error("EXPORTACION_INVALIDA", "No se pudo iniciar la exportación.", null)
                return@setMethodCallHandler
            }
            val destino = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "text/csv"
                putExtra(Intent.EXTRA_TITLE, nombre)
            }
            exportacion = contenido to resultado
            try {
                startActivityForResult(destino, CREAR_CSV)
            } catch (error: Exception) {
                exportacion = null
                resultado.error("EXPORTACION_FALLIDA", "No se pudo abrir el selector de archivos.", null)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CREAR_CSV) return
        val (contenido, resultado) = exportacion ?: return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            exportacion = null
            resultado.success(false)
            return
        }
        Thread {
            val guardado = runCatching {
                val salida = checkNotNull(contentResolver.openOutputStream(uri, "wt"))
                salida.bufferedWriter(Charsets.UTF_8).use { it.write(contenido) }
            }.isSuccess
            runOnUiThread {
                exportacion = null
                if (guardado) resultado.success(true)
                else resultado.error("EXPORTACION_FALLIDA", "No se pudo guardar el archivo.", null)
            }
        }.start()
    }

    private companion object {
        const val CREAR_CSV = 1208
    }
}
