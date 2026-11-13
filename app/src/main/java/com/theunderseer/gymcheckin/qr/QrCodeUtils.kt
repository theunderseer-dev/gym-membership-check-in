package com.theunderseer.gymcheckin.qr

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.util.Log
import android.widget.Toast
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.core.content.FileProvider
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.EncodeHintType
import com.google.zxing.NotFoundException
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.GlobalHistogramBinarizer
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import java.io.File
import java.io.FileOutputStream

sealed interface ImageDecodeResult {
    data class Success(val text: String) : ImageDecodeResult
    data object NoQrFound : ImageDecodeResult
    data class Error(val message: String) : ImageDecodeResult
}

object QrCodeUtils {

    fun generateQrBitmap(content: String, sizePx: Int = 512): Bitmap {
        val hints = mapOf(
            EncodeHintType.MARGIN to 1,
            EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M
        )
        val bitMatrix = QRCodeWriter().encode(content, BarcodeFormat.QR_CODE, sizePx, sizePx, hints)
        val width = bitMatrix.width
        val height = bitMatrix.height
        val pixels = IntArray(width * height)
        for (y in 0 until height) {
            val offset = y * width
            for (x in 0 until width) {
                pixels[offset + x] = if (bitMatrix.get(x, y)) Color.BLACK else Color.WHITE
            }
        }
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
        return bitmap
    }

    fun shareQrBitmap(context: Context, qrBitmap: Bitmap, memberId: String, memberName: String) {
        try {
            val cardsDir = File(context.cacheDir, "cards")
            if (!cardsDir.exists()) {
                cardsDir.mkdirs()
            }
            val file = File(cardsDir, "qr_${memberId}.png")
            FileOutputStream(file).use { out ->
                qrBitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, "Gym Check-in: $memberName")
                putExtra(Intent.EXTRA_TEXT, "Member: $memberName\nID: $memberId")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(shareIntent, "Share QR Code").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(chooser)
        } catch (e: Exception) {
            Log.e("QrCodeUtils", "Failed to share QR", e)
            Toast.makeText(context, "Failed to share: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    fun decodeQrFromUri(context: Context, uri: Uri): ImageDecodeResult {
        val bitmap = try {
            context.contentResolver.openInputStream(uri)?.use { stream ->
                BitmapFactory.decodeStream(stream)
            }
        } catch (e: Exception) {
            Log.e("QrCodeUtils", "Could not open image file: ${e.message}", e)
            return ImageDecodeResult.Error("Could not read image")
        }

        if (bitmap == null) {
            return ImageDecodeResult.Error("Could not read image")
        }

        return try {
            val width = bitmap.width
            val height = bitmap.height
            val pixels = IntArray(width * height)
            bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

            val source = RGBLuminanceSource(width, height, pixels)
            val hints = mapOf(
                DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE),
                DecodeHintType.TRY_HARDER to java.lang.Boolean.TRUE
            )
            val reader = QRCodeReader()

            val decodedText = try {
                val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
                reader.decode(binaryBitmap, hints).text
            } catch (_: NotFoundException) {
                try {
                    val fallbackBitmap = BinaryBitmap(GlobalHistogramBinarizer(source))
                    reader.decode(fallbackBitmap, hints).text
                } catch (_: NotFoundException) {
                    null
                }
            }

            if (!decodedText.isNullOrEmpty()) {
                ImageDecodeResult.Success(decodedText)
            } else {
                ImageDecodeResult.NoQrFound
            }
        } catch (e: Exception) {
            Log.e("QrCodeUtils", "Failed to decode QR: ${e.message}", e)
            ImageDecodeResult.NoQrFound
        }
    }
}

class QrCodeAnalyzer(
    private val onQrCodeScanned: (String) -> Unit
) : ImageAnalysis.Analyzer {

    private val reader = QRCodeReader()
    private val hints = mapOf(
        DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE),
        DecodeHintType.TRY_HARDER to java.lang.Boolean.TRUE
    )

    @Volatile
    private var isScanning = true

    fun setScanningEnabled(enabled: Boolean) {
        isScanning = enabled
    }

    override fun analyze(image: ImageProxy) {
        if (!isScanning) {
            image.close()
            return
        }

        try {
            val plane = image.planes[0]
            val buffer = plane.buffer
            val rowStride = plane.rowStride
            val pixelStride = plane.pixelStride
            val width = image.width
            val height = image.height

            val yBytes = ByteArray(width * height)
            var destIndex = 0
            for (row in 0 until height) {
                buffer.position(row * rowStride)
                if (pixelStride == 1) {
                    buffer.get(yBytes, destIndex, width)
                    destIndex += width
                } else {
                    for (col in 0 until width) {
                        yBytes[destIndex++] = buffer.get()
                        if (pixelStride > 1 && col < width - 1) {
                            buffer.position(buffer.position() + pixelStride - 1)
                        }
                    }
                }
            }

            val rotationDegrees = image.imageInfo.rotationDegrees
            val (rotatedBytes, rotWidth, rotHeight) = rotateYuv(yBytes, width, height, rotationDegrees)

            val source = PlanarYUVLuminanceSource(
                rotatedBytes,
                rotWidth,
                rotHeight,
                0,
                0,
                rotWidth,
                rotHeight,
                false
            )
            val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
            val result = reader.decode(binaryBitmap, hints)
            val text = result?.text
            if (!text.isNullOrEmpty()) {
                isScanning = false
                onQrCodeScanned(text)
            }
        } catch (_: NotFoundException) {
            // Normal when QR code is not in frame
        } catch (e: Exception) {
            Log.d("QrCodeAnalyzer", "Decode failed: ${e.message}")
        } finally {
            reader.reset()
            image.close()
        }
    }

    private fun rotateYuv(
        data: ByteArray,
        width: Int,
        height: Int,
        rotationDegrees: Int
    ): Triple<ByteArray, Int, Int> {
        return when (rotationDegrees) {
            90 -> {
                val rotated = ByteArray(data.size)
                for (y in 0 until height) {
                    for (x in 0 until width) {
                        rotated[x * height + (height - y - 1)] = data[y * width + x]
                    }
                }
                Triple(rotated, height, width)
            }
            180 -> {
                val rotated = ByteArray(data.size)
                val total = width * height
                for (i in 0 until total) {
                    rotated[total - 1 - i] = data[i]
                }
                Triple(rotated, width, height)
            }
            270 -> {
                val rotated = ByteArray(data.size)
                for (y in 0 until height) {
                    for (x in 0 until width) {
                        rotated[(width - x - 1) * height + y] = data[y * width + x]
                    }
                }
                Triple(rotated, height, width)
            }
            else -> Triple(data, width, height)
        }
    }
}
