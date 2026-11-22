package com.theunderseer.gymcheckin.data

import com.theunderseer.gymcheckin.domain.model.Member
import com.theunderseer.gymcheckin.domain.model.MemberValidation
import com.theunderseer.gymcheckin.domain.model.MembershipPlan
import com.theunderseer.gymcheckin.domain.repository.GymRepository
import com.theunderseer.gymcheckin.domain.util.generateMemberId
import com.theunderseer.gymcheckin.domain.util.normalizeMemberId
import kotlinx.datetime.LocalDate

class DefaultGymRepository(
    private val memberDao: MemberDao
) : GymRepository {

    override suspend fun registerMember(
        name: String,
        plan: MembershipPlan,
        today: LocalDate
    ): Member {
        val trimmedName = MemberValidation.validateName(name)

        val startsOn = today
        val endsOnInclusive = plan.calculateEndDate(startsOn)
        val id = generateMemberId()

        val entity = MemberEntity(
            id = id,
            name = trimmedName,
            startsOn = startsOn.toString(),
            endsOnInclusive = endsOnInclusive.toString()
        )
        memberDao.insert(entity)

        return Member(
            id = entity.id,
            name = entity.name,
            startsOn = startsOn,
            endsOnInclusive = endsOnInclusive
        )
    }

    override suspend fun getMemberById(id: String): Member? {
        val normalizedId = normalizeMemberId(id)
        if (normalizedId.isEmpty()) return null
        val entity = memberDao.getMemberById(normalizedId) ?: return null
        return Member(
            id = entity.id,
            name = entity.name,
            startsOn = LocalDate.parse(entity.startsOn),
            endsOnInclusive = LocalDate.parse(entity.endsOnInclusive)
        )
    }
}
