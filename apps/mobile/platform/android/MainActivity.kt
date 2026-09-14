package com.karta.identity.karta_wallet

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private var renderer: PdfRenderer? = null
    private var pdfFile: File? = null
    private var exportResult: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "karta/documents").setMethodCallHandler { call, result ->
            if (call.method == "exportFile") {
                if (exportResult != null) {
                    result.error("busy", "Já existe uma exportação em curso.", null)
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("invalid", "Ficheiro indisponível.", null)
                    return@setMethodCallHandler
                }
                exportResult = result
                exportBytes = bytes
                try {
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = call.argument<String>("mime") ?: "application/octet-stream"
                        putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "documento")
                    }
                    startActivityForResult(intent, 7104)
                } catch (_: Exception) {
                    exportResult = null
                    exportBytes = null
                    result.error("export", "Não foi possível escolher o destino.", null)
                }
            } else if (call.method in listOf("openPdf", "renderPdf", "closePdf")) {
                worker.execute {
                    try {
                        val value: Any? = when (call.method) {
                            "openPdf" -> {
                                closePdf()
                                val bytes = call.argument<ByteArray>("bytes") ?: error("Ficheiro indisponível")
                                val file = File.createTempFile("karta-view-", ".pdf", cacheDir)
                                pdfFile = file
                                file.writeBytes(bytes)
                                val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                                try { renderer = PdfRenderer(descriptor) }
                                catch (e: Exception) { descriptor.close(); closePdf(); throw e }
                                // The renderer owns the open descriptor; remove the temporary pathname now.
                                file.delete()
                                renderer!!.pageCount
                            }
                            "renderPdf" -> {
                                val pdf = renderer ?: error("Leitor fechado")
                                val index = call.argument<Int>("page") ?: 0
                                pdf.openPage(index).use { page ->
                                    val scale = minOf(1600.0 / page.width, 2200.0 / page.height)
                                    val bitmap = Bitmap.createBitmap(
                                        maxOf(1, (page.width * scale).toInt()),
                                        maxOf(1, (page.height * scale).toInt()), Bitmap.Config.ARGB_8888)
                                    try {
                                        bitmap.eraseColor(Color.WHITE)
                                        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                        ByteArrayOutputStream().use { output ->
                                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
                                            output.toByteArray()
                                        }
                                    } finally { bitmap.recycle() }
                                }
                            }
                            else -> { closePdf(); null }
                        }
                        runOnUiThread { result.success(value) }
                    } catch (_: Exception) {
                        runOnUiThread { result.error("pdf", "Não foi possível ler o PDF. Pode estar danificado ou protegido por palavra-passe.", null) }
                    }
                }
            } else result.notImplemented()
        }
    }

    private fun closePdf() {
        renderer?.close()
        renderer = null
        pdfFile?.delete()
        pdfFile = null
    }

    @Deprecated("Android activity result compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 7104) return
        val result = exportResult ?: return
        val bytes = exportBytes
        exportResult = null
        exportBytes = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) {
            result.success(false)
            return
        }
        worker.execute {
            try {
                val output = contentResolver.openOutputStream(uri) ?: error("Destino indisponível")
                output.use { it.write(bytes) }
                runOnUiThread { result.success(true) }
            } catch (_: Exception) {
                runOnUiThread { result.error("export", "Não foi possível guardar a cópia no destino escolhido.", null) }
            }
        }
    }

    override fun onDestroy() {
        exportResult?.error("closed", "Exportação interrompida.", null)
        exportResult = null
        exportBytes = null
        worker.execute { closePdf() }
        worker.shutdown()
        super.onDestroy()
    }
}
