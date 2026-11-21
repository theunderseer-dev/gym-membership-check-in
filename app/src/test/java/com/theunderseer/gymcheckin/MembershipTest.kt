package com.theunderseer.gymcheckin

import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.EncodeHintType
import com.google.zxing.NotFoundException
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import com.theunderseer.gymcheckin.domain.model.Member
import com.theunderseer.gymcheckin.domain.model.MembershipStatus
import com.theunderseer.gymcheckin.domain.util.currentDatePlusMonths
import com.theunderseer.gymcheckin.qr.QrCodeUtils
import kotlinx.datetime.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class MembershipTest {

    @Test
    fun testDateCalculation_standardDate() {
        // 2 February -> 2 March
        val startsOn = LocalDate(2026, 2, 2)
        val endsOn = currentDatePlusMonths(startsOn, 1)
        assertEquals(LocalDate(2026, 3, 2), endsOn)
    }

    @Test
    fun testDateCalculation_endOfMonth_nonLeapYear() {
        // 31 January -> 28 February (2026 is non-leap)
        val startsOn = LocalDate(2026, 1, 31)
        val endsOn = currentDatePlusMonths(startsOn, 1)
        assertEquals(LocalDate(2026, 2, 28), endsOn)
    }

    @Test
    fun testDateCalculation_endOfMonth_leapYear() {
        // 31 January -> 29 February (2024 is leap)
        val startsOn = LocalDate(2024, 1, 31)
        val endsOn = currentDatePlusMonths(startsOn, 1)
        assertEquals(LocalDate(2024, 2, 29), endsOn)
    }

    @Test
    fun testMembershipStatus_inclusiveExpiration() {
        val startsOn = LocalDate(2026, 2, 2)
        val endsOnInclusive = LocalDate(2026, 3, 2)
        val member = Member(
            id = "test-id",
            name = "Test Member",
            startsOn = startsOn,
            endsOnInclusive = endsOnInclusive
        )

        // Day before expiration
        assertEquals(MembershipStatus.ACTIVE, member.status(LocalDate(2026, 3, 1)))

        // Exact day of expiration (inclusive) -> ACTIVE
        assertEquals(MembershipStatus.ACTIVE, member.status(LocalDate(2026, 3, 2)))

        // Day after expiration -> EXPIRED
        assertEquals(MembershipStatus.EXPIRED, member.status(LocalDate(2026, 3, 3)))
    }

    @Test
    fun testNameTrimming() {
        val rawName = "   John Doe   "
        val trimmed = rawName.trim()
        assertEquals("John Doe", trimmed)
    }

    @Test
    fun testEmptyNameValidation() {
        val rawName = "    "
        val trimmed = rawName.trim()
        assertEquals(true, trimmed.isEmpty())
    }

    @Test
    fun testQrCodeRoundTrip() {
        val testId = "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"
        val hints = mapOf(
            EncodeHintType.MARGIN to 1,
            EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M
        )
        val bitMatrix = QRCodeWriter().encode(testId, BarcodeFormat.QR_CODE, 256, 256, hints)
        val width = bitMatrix.width
        val height = bitMatrix.height

        val pixels = IntArray(width * height)
        for (y in 0 until height) {
            val offset = y * width
            for (x in 0 until width) {
                pixels[offset + x] = if (bitMatrix.get(x, y)) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
            }
        }

        val source = RGBLuminanceSource(width, height, pixels)
        val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
        val reader = QRCodeReader()
        val result = reader.decode(binaryBitmap)

        assertEquals(testId, result.text)
    }

    @Test
    fun testNonQrImage_throwsNotFoundException() {
        val width = 100
        val height = 100
        val pixels = IntArray(width * height) { 0xFFFFFFFF.toInt() }
        val source = RGBLuminanceSource(width, height, pixels)
        val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
        val reader = QRCodeReader()

        assertThrows(NotFoundException::class.java) {
            reader.decode(binaryBitmap)
        }
    }
}
