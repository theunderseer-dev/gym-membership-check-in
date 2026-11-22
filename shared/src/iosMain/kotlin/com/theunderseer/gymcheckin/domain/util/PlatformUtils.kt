package com.theunderseer.gymcheckin.domain.util

import platform.Foundation.NSUUID

actual fun generateUuid(): String = NSUUID().UUIDString()
