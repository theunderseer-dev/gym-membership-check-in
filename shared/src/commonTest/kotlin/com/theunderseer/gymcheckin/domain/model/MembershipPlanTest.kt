package com.theunderseer.gymcheckin.domain.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.datetime.LocalDate

class MembershipPlanTest {

    @Test
    fun allPlans_haveExpectedMonthsAndDisplayNames() {
        assertEquals(4, MembershipPlan.entries.size)
        assertEquals(1, MembershipPlan.ONE_MONTH.months)
        assertEquals("1 Month", MembershipPlan.ONE_MONTH.displayName)
        assertEquals(3, MembershipPlan.THREE_MONTHS.months)
        assertEquals("3 Months", MembershipPlan.THREE_MONTHS.displayName)
        assertEquals(6, MembershipPlan.SIX_MONTHS.months)
        assertEquals("6 Months", MembershipPlan.SIX_MONTHS.displayName)
        assertEquals(12, MembershipPlan.TWELVE_MONTHS.months)
        assertEquals("12 Months", MembershipPlan.TWELVE_MONTHS.displayName)
    }

    @Test
    fun calculateEndDate_standardDate_allPlans() {
        val start = LocalDate(2026, 2, 10)
        assertEquals(LocalDate(2026, 3, 10), MembershipPlan.ONE_MONTH.calculateEndDate(start))
        assertEquals(LocalDate(2026, 5, 10), MembershipPlan.THREE_MONTHS.calculateEndDate(start))
        assertEquals(LocalDate(2026, 8, 10), MembershipPlan.SIX_MONTHS.calculateEndDate(start))
        assertEquals(LocalDate(2027, 2, 10), MembershipPlan.TWELVE_MONTHS.calculateEndDate(start))
    }

    @Test
    fun calculateEndDate_endOfMonthClamping() {
        // Non-leap year
        val jan31NonLeap = LocalDate(2026, 1, 31)
        assertEquals(
            LocalDate(2026, 2, 28),
            MembershipPlan.ONE_MONTH.calculateEndDate(jan31NonLeap)
        )
        assertEquals(
            LocalDate(2026, 4, 30),
            MembershipPlan.THREE_MONTHS.calculateEndDate(jan31NonLeap)
        )
        assertEquals(
            LocalDate(2026, 7, 31),
            MembershipPlan.SIX_MONTHS.calculateEndDate(jan31NonLeap)
        )
        assertEquals(
            LocalDate(2027, 1, 31),
            MembershipPlan.TWELVE_MONTHS.calculateEndDate(jan31NonLeap)
        )

        // Leap year
        val jan31Leap = LocalDate(2024, 1, 31)
        assertEquals(LocalDate(2024, 2, 29), MembershipPlan.ONE_MONTH.calculateEndDate(jan31Leap))

        // Leap day + 12 months -> Feb 28 next year
        val feb29Leap = LocalDate(2024, 2, 29)
        assertEquals(
            LocalDate(2025, 2, 28),
            MembershipPlan.TWELVE_MONTHS.calculateEndDate(feb29Leap)
        )
    }

    @Test
    fun calculateEndDate_yearRollover() {
        val nov15 = LocalDate(2026, 11, 15)
        assertEquals(LocalDate(2026, 12, 15), MembershipPlan.ONE_MONTH.calculateEndDate(nov15))
        assertEquals(LocalDate(2027, 2, 15), MembershipPlan.THREE_MONTHS.calculateEndDate(nov15))
        assertEquals(LocalDate(2027, 5, 15), MembershipPlan.SIX_MONTHS.calculateEndDate(nov15))
        assertEquals(LocalDate(2027, 11, 15), MembershipPlan.TWELVE_MONTHS.calculateEndDate(nov15))
    }
}
