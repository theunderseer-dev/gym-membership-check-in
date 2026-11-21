package com.theunderseer.gymcheckin.domain.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class MemberValidationTest {

    @Test
    fun validateName_returnsTrimmmedName() {
        assertEquals("John Doe", MemberValidation.validateName("  John Doe  "))
    }

    @Test
    fun validateName_returnsNameWithoutLeadingSpaces() {
        assertEquals("Jane", MemberValidation.validateName("   Jane"))
    }

    @Test
    fun validateName_throwsOnEmptyString() {
        assertFailsWith<IllegalArgumentException> {
            MemberValidation.validateName("")
        }
    }

    @Test
    fun validateName_throwsOnBlankString() {
        assertFailsWith<IllegalArgumentException> {
            MemberValidation.validateName("   ")
        }
    }

    @Test
    fun validateName_throwsOnTabsAndNewlines() {
        assertFailsWith<IllegalArgumentException> {
            MemberValidation.validateName("\t\n")
        }
    }
}
