package com.theunderseer.gymcheckin.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [MemberEntity::class], version = 2, exportSchema = true)
abstract class AppDatabase : RoomDatabase() {
    abstract fun memberDao(): MemberDao

    companion object {
        @Volatile
        private var instance: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return instance ?: synchronized(this) {
                val created = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "gym_checkin.db"
                )
                    .fallbackToDestructiveMigration(dropAllTables = true)
                    .build()
                instance = created
                created
            }
        }
    }
}
