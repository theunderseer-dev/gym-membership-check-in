package com.theunderseer.gymcheckin.data

import com.theunderseer.gymcheckin.model.Member
import java.time.LocalDate
import java.util.UUID

interface GymRepository {
    suspend fun registerMember(name: String, today: LocalDate = LocalDate.now()): Member
    suspend fun getMemberById(id: String): Member?
}

class DefaultGymRepository(
    private val memberDao: MemberDao
) : GymRepository {

    override suspend fun registerMember(name: String, today: LocalDate): Member {
        val trimmedName = name.trim()
        require(trimmedName.isNotEmpty()) { "Client name cannot be empty" }

        val startsOn = today
        val endsOnInclusive = startsOn.plusMonths(1)
        val id = UUID.randomUUID().toString()

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
