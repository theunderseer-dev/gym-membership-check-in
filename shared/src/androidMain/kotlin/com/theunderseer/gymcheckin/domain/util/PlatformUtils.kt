package com.theunderseer.gymcheckin.domain.util

import java.util.UUID

actual fun generateUuid(): String = UUID.randomUUID().toString()
