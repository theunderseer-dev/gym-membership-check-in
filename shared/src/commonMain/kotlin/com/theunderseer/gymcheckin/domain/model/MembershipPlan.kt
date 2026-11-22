package com.theunderseer.gymcheckin.domain.model

import com.theunderseer.gymcheckin.domain.util.currentDate
import com.theunderseer.gymcheckin.domain.util.currentDatePlusMonths
import kotlinx.datetime.LocalDate

enum class MembershipPlan(
    val months: Int,
    val displayName: String
) {
    ONE_MONTH(1, "1 Month"),
    THREE_MONTHS(3, "3 Months"),
    SIX_MONTHS(6, "6 Months"),
    TWELVE_MONTHS(12, "12 Months");

    fun calculateEndDate(startDate: LocalDate = currentDate()): LocalDate =
        currentDatePlusMonths(startDate, months)
}
