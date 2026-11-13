package com.theunderseer.gymcheckin.model

import java.time.LocalDate

enum class MembershipStatus {
    ACTIVE,
    EXPIRED
}

data class Member(
    val id: String,
    val name: String,
    val startsOn: LocalDate,
    val endsOnInclusive: LocalDate
) {
    fun status(today: LocalDate = LocalDate.now()): MembershipStatus {
        return if (!today.isAfter(endsOnInclusive)) {
            MembershipStatus.ACTIVE
        } else {
            MembershipStatus.EXPIRED
        }
    }
}
