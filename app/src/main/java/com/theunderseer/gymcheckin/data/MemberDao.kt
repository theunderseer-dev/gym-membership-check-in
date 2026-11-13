package com.theunderseer.gymcheckin.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface MemberDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(member: MemberEntity)

    @Query("SELECT * FROM members WHERE id = :id")
    suspend fun getMemberById(id: String): MemberEntity?

    @Query("SELECT * FROM members ORDER BY createdAt DESC")
    fun getAllMembers(): Flow<List<MemberEntity>>
}
