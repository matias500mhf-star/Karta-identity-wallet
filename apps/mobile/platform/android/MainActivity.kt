package com.karta.identity.karta_wallet

import android.app.Activity
import android.content.Intent
import android.content.ClipData
import android.os.Bundle
import android.view.WindowManager
import androidx.core.content.FileProvider
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private var renderer: PdfRenderer? = null
    private var pdfFile: File? = null
    private var exportResult: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        cleanShares()
    }

    private fun cleanShares() {
        File(cacheDir, "karta-shares").listFiles()?.filter {
            System.currentTimeMillis() - it.lastModified() > 3600000
        }?.forEach { it.delete() }
    }

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "karta/documents").setMethodCallHandler { call, result ->
            if (call.method == "shareFile") {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("invalid", "Ficheiro indisponível.", null)
                    return@setMethodCallHandler
                }
                val requestedName = call.argument<String>("name") ?: "documento"
                val mime = call.argument<String>("mime") ?: "application/octet-stream"
                worker.execute {
                    var shared: File? = null
                    try {
                        cleanShares()
                        val dir = File(cacheDir, "karta-shares").apply { mkdirs() }
                        val safeName = requestedName.replace(Regex("[^a-zA-Z0-9._-]"), "_").takeLast(100)
                        val file = File(dir, "${java.util.UUID.randomUUID()}-$safeName")
                        shared = file
                        file.writeBytes(bytes)
                        val uri = FileProvider.getUriForFile(this, "$packageName.karta.files", file)
                        runOnUiThread {
                            try {
                                val send = Intent(Intent.ACTION_SEND).apply {
                                    type = mime
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    clipData = ClipData.newRawUri("KARTA", uri)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                startActivity(Intent.createChooser(send, "Partilhar com…"))
                                // Chooser launch is not proof of delivery.
                                result.success(null)
                                android.os.Handler(mainLooper).postDelayed({ file.delete() }, 3600000)
                            } catch (_: Exception) {
                                file.delete()
                                result.error("share", "Não foi possível abrir a partilha.", null)
                            }
                        }
                    } catch (_: Exception) {
                        shared?.delete()
                        runOnUiThread { result.error("share", "Não foi possível preparar a partilha.", null) }
                    }
                }
            } else if (call.method == "exportFile") {
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
