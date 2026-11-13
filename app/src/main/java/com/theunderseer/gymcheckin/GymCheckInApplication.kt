package com.theunderseer.gymcheckin

import android.app.Application

class GymCheckInApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = DefaultAppContainer(this)
    }
}
