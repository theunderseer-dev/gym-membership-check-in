package com.theunderseer.gymcheckin.domain.util

import kotlin.random.Random

object MemberIdGenerator {
    /**
     * Crockford's Base32 alphabet: 32 characters, excludes ambiguous characters
     * I, L, O (confused with 1, 0) and U (prevents accidental vulgar words).
     */
    const val ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    const val RAW_LENGTH = 6
    const val FORMATTED_LENGTH = 7 // XXX-XXX

    /**
     * Generates a 6-character Crockford Base32 ID formatted as XXX-XXX (e.g. "K7X-9M2").
     * Total possible combinations: 32^6 = 1,073,741,824 (over 1 billion).
     */
    fun generate(random: Random = Random.Default): String {
        val chars = CharArray(RAW_LENGTH) {
            ALPHABET[random.nextInt(ALPHABET.length)]
        }
        return "${chars[0]}${chars[1]}${chars[2]}-${chars[3]}${chars[4]}${chars[5]}"
    }

    /**
     * Normalizes user input for robust search:
     * - Trims whitespace
     * - Converts to UPPERCASE
     * - Removes existing hyphens and spaces
     * - Replaces 'O' -> '0', 'I' -> '1', 'L' -> '1' (Crockford tolerance)
     * - Formats as XXX-XXX if 6 characters
     */
    fun normalize(input: String): String {
        val cleaned = input.trim()
            .uppercase()
            .replace("-", "")
            .replace(" ", "")
            .replace("O", "0")
            .replace("I", "1")
            .replace("L", "1")

        return if (cleaned.length == RAW_LENGTH) {
            "${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}"
        } else {
            cleaned
        }
    }

    /**
     * Checks if a member ID is valid (either raw 6 chars or formatted XXX-XXX).
     */
    fun isValid(input: String): Boolean {
        val normalized = normalize(input)
        if (normalized.length != FORMATTED_LENGTH || normalized[3] != '-') return false
        val part1 = normalized.substring(0, 3)
        val part2 = normalized.substring(4, 7)
        return part1.all { it in ALPHABET } && part2.all { it in ALPHABET }
    }
}

fun generateMemberId(): String = MemberIdGenerator.generate()
fun normalizeMemberId(input: String): String = MemberIdGenerator.normalize(input)
