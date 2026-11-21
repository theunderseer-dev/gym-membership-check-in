package com.theunderseer.gymcheckin

import android.content.Context
import com.theunderseer.gymcheckin.data.AppDatabase
import com.theunderseer.gymcheckin.data.DefaultGymRepository
import com.theunderseer.gymcheckin.domain.repository.GymRepository

interface AppContainer {
    val gymRepository: GymRepository
}

class DefaultAppContainer(private val context: Context) : AppContainer {
    private val database: AppDatabase by lazy {
        AppDatabase.getDatabase(context)
    }

    override val gymRepository: GymRepository by lazy {
        DefaultGymRepository(database.memberDao())
    }
}
