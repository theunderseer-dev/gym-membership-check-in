package com.theunderseer.gymcheckin.data

import com.theunderseer.gymcheckin.domain.model.Member
import com.theunderseer.gymcheckin.domain.model.MemberValidation
import com.theunderseer.gymcheckin.domain.repository.GymRepository
import com.theunderseer.gymcheckin.domain.util.currentDate
import com.theunderseer.gymcheckin.domain.util.currentDatePlusMonths
import com.theunderseer.gymcheckin.domain.util.generateUuid
import kotlinx.datetime.LocalDate

class DefaultGymRepository(
    private val memberDao: MemberDao
) : GymRepository {

    override suspend fun registerMember(name: String, today: LocalDate): Member {
        val trimmedName = MemberValidation.validateName(name)

        val startsOn = today
        val endsOnInclusive = currentDatePlusMonths(startsOn, 1)
        val id = generateUuid()

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
        val trimmedId = id.trim()
        if (trimmedId.isEmpty()) return null
        val entity = memberDao.getMemberById(trimmedId) ?: return null
        return Member(
            id = entity.id,
            name = entity.name,
            startsOn = LocalDate.parse(entity.startsOn),
            endsOnInclusive = LocalDate.parse(entity.endsOnInclusive)
        )
    }
}
