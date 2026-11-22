package com.theunderseer.gymcheckin.domain.model

import kotlinx.datetime.LocalDate
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class MemberTest {

    private fun member(
        startsOn: LocalDate,
        endsOnInclusive: LocalDate,
        id: String = "test-id",
        name: String = "Test User"
    ) = Member(id = id, name = name, startsOn = startsOn, endsOnInclusive = endsOnInclusive)

    @Test
    fun status_isActive_whenTodayBeforeExpiry() {
        val m = member(
            startsOn = LocalDate(2025, 1, 1),
            endsOnInclusive = LocalDate(2025, 2, 1)
        )
        assertEquals(MembershipStatus.ACTIVE, m.status(today = LocalDate(2025, 1, 15)))
    }

    @Test
    fun status_isActive_whenTodayEqualsExpiry() {
        val expiry = LocalDate(2025, 2, 1)
        val m = member(startsOn = LocalDate(2025, 1, 1), endsOnInclusive = expiry)
        assertEquals(MembershipStatus.ACTIVE, m.status(today = expiry))
    }

    @Test
    fun status_isExpired_whenTodayAfterExpiry() {
        val m = member(
            startsOn = LocalDate(2025, 1, 1),
            endsOnInclusive = LocalDate(2025, 2, 1)
        )
        assertEquals(MembershipStatus.EXPIRED, m.status(today = LocalDate(2025, 2, 2)))
    }

    @Test
    fun status_handlesLeapYearBoundary() {
        // Feb 29 2024 is valid (leap year)
        val m = member(
            startsOn = LocalDate(2024, 1, 29),
            endsOnInclusive = LocalDate(2024, 2, 29)
        )
        assertEquals(MembershipStatus.ACTIVE, m.status(today = LocalDate(2024, 2, 29)))
        assertEquals(MembershipStatus.EXPIRED, m.status(today = LocalDate(2024, 3, 1)))
    }

    @Test
    fun member_canHavePhotoFileName() {
        val m = Member(
            id = "id1",
            name = "Jane",
            startsOn = LocalDate(2025, 1, 1),
            endsOnInclusive = LocalDate(2025, 2, 1),
            photoFileName = "photo_id1.jpg"
        )
        assertEquals("photo_id1.jpg", m.photoFileName)
    }

    @Test
    fun member_photoFileNameIsNullByDefault() {
        val m = member(startsOn = LocalDate(2025, 1, 1), endsOnInclusive = LocalDate(2025, 2, 1))
        assertEquals(null, m.photoFileName)
    }
}
