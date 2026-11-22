package com.theunderseer.gymcheckin.domain.model

import kotlin.Throws

object MemberValidation {
    fun isValidName(name: String): Boolean = name.trim().isNotEmpty()

    @Throws(IllegalArgumentException::class)
    fun validateName(name: String): String {
        val trimmed = name.trim()
        require(trimmed.isNotEmpty()) { "Client name cannot be empty" }
        return trimmed
    }
}
