package com.theunderseer.gymcheckin.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "members")
data class MemberEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val startsOn: String, // ISO-8601 YYYY-MM-DD
    val endsOnInclusive: String, // ISO-8601 YYYY-MM-DD
    val createdAt: Long = System.currentTimeMillis()
)
