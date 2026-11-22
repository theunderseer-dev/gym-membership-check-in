package com.theunderseer.gymcheckin.domain.util

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MemberIdGeneratorTest {

    @Test
    fun generate_hasCorrectFormatAndLength() {
        val id = MemberIdGenerator.generate()
        assertEquals(7, id.length)
        assertEquals('-', id[3])
    }

    @Test
    fun generate_usesOnlyAllowedAlphabet() {
        for (i in 0 until 50) {
            val id = MemberIdGenerator.generate()
            val withoutHyphen = id.replace("-", "")
            assertEquals(6, withoutHyphen.length)
            assertTrue(withoutHyphen.all { it in MemberIdGenerator.ALPHABET })
            // Ensure no ambiguous or excluded chars
            assertFalse(withoutHyphen.contains('I'))
            assertFalse(withoutHyphen.contains('L'))
            assertFalse(withoutHyphen.contains('O'))
            assertFalse(withoutHyphen.contains('U'))
        }
    }

    @Test
    fun generate_producesDistinctIds() {
        val ids = (1..100).map { MemberIdGenerator.generate() }.toSet()
        assertEquals(100, ids.size, "Expected 100 unique IDs")
    }

    @Test
    fun normalize_handlesLowercaseAndHyphen() {
        assertEquals("K7X-9M2", MemberIdGenerator.normalize("k7x-9m2"))
        assertEquals("K7X-9M2", MemberIdGenerator.normalize("K7X-9M2"))
    }

    @Test
    fun normalize_handlesUnformattedInput() {
        assertEquals("K7X-9M2", MemberIdGenerator.normalize("k7x9m2"))
        assertEquals("K7X-9M2", MemberIdGenerator.normalize("K7X9M2"))
    }

    @Test
    fun normalize_handlesSpacesAndWhitespace() {
        assertEquals("K7X-9M2", MemberIdGenerator.normalize("  k7x 9m2  "))
        assertEquals("K7X-9M2", MemberIdGenerator.normalize("   k7x-9m2   "))
    }

    @Test
    fun normalize_replacesAmbiguousChars() {
        // 'O' -> '0', 'I' -> '1', 'L' -> '1'
        assertEquals("K01-91M", MemberIdGenerator.normalize("kol-9im"))
        assertEquals("110-011", MemberIdGenerator.normalize("ilo-oli"))
    }

    @Test
    fun isValid_acceptsValidIds() {
        assertTrue(MemberIdGenerator.isValid("K7X-9M2"))
        assertTrue(MemberIdGenerator.isValid("k7x9m2"))
        assertTrue(MemberIdGenerator.isValid("  k7x 9m2  "))
        assertTrue(MemberIdGenerator.isValid(MemberIdGenerator.generate()))
    }

    @Test
    fun isValid_rejectsInvalidIds() {
        assertFalse(MemberIdGenerator.isValid(""))
        assertFalse(MemberIdGenerator.isValid("   "))
        assertFalse(MemberIdGenerator.isValid("12345")) // too short
        assertFalse(MemberIdGenerator.isValid("1234567")) // too long
        assertFalse(MemberIdGenerator.isValid("K7X-9M!")) // invalid symbol
    }
}
