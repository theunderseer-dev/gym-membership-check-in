package com.theunderseer.gymcheckin.domain.model

import com.theunderseer.gymcheckin.domain.util.currentDate
import kotlinx.datetime.LocalDate

data class Member(
    val id: String,
    val name: String,
    val startsOn: LocalDate,
    val endsOnInclusive: LocalDate,
    val photoFileName: String? = null
) {
    fun status(today: LocalDate = currentDate()): MembershipStatus =
        if (today <= endsOnInclusive) MembershipStatus.ACTIVE else MembershipStatus.EXPIRED
}
