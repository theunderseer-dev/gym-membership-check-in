package com.theunderseer.gymcheckin.domain.util

import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.plus
import kotlinx.datetime.todayIn

fun currentDate(): LocalDate = Clock.System.todayIn(TimeZone.currentSystemDefault())

fun currentDatePlusMonths(date: LocalDate, months: Int): LocalDate =
    date.plus(months, DateTimeUnit.MONTH)
