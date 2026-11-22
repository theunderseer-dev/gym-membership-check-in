package com.theunderseer.gymcheckin.domain.repository

import com.theunderseer.gymcheckin.domain.model.Member
import com.theunderseer.gymcheckin.domain.model.MembershipPlan
import com.theunderseer.gymcheckin.domain.util.currentDate
import kotlinx.datetime.LocalDate

interface GymRepository {
    suspend fun registerMember(
        name: String,
        plan: MembershipPlan = MembershipPlan.ONE_MONTH,
        today: LocalDate = currentDate()
    ): Member

    suspend fun getMemberById(id: String): Member?
}
