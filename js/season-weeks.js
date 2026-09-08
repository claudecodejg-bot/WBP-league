// =============================================
//  Which Mondays the league is currently planning for
// =============================================
// Single source of truth shared by the availability page and the scheduler.
// They must agree: if the scheduler offers a week that availability never
// collected responses for, it finds nobody available and produces an empty
// schedule.

import { AVAILABILITY_START, AVAILABILITY_END, UNOFFICIAL_WEEKS } from './config.js'

/** Formats a Date as YYYY-MM-DD (local date, not UTC). */
export function toISODate(date) {
  const pad = n => String(n).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

/**
 * Every Monday still to come inside the configured window: from
 * AVAILABILITY_START (or the coming Monday, once the window has opened)
 * through AVAILABILITY_END inclusive.
 *
 * Opening up more weeks is a one-line change to AVAILABILITY_END in
 * config.js — no code change here.
 */
export function upcomingWeeks() {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  // The Monday on or after today.
  const day = today.getDay()
  const nextMonday = new Date(today)
  if (day !== 1) {
    nextMonday.setDate(nextMonday.getDate() + (day === 0 ? 1 : 8 - day))
  }

  const windowStart = new Date(AVAILABILITY_START + 'T00:00:00')
  const windowEnd   = new Date(AVAILABILITY_END   + 'T00:00:00')

  // Whichever comes later: the window opening, or this coming week.
  const cursor = nextMonday > windowStart ? nextMonday : windowStart

  const weeks = []
  while (cursor <= windowEnd) {
    weeks.push(new Date(cursor))
    cursor.setDate(cursor.getDate() + 7)
  }
  return weeks
}

/** True if the given Monday is one of the pre-season warm-up weeks. */
export function isUnofficialWeek(monday) {
  return UNOFFICIAL_WEEKS.includes(toISODate(monday))
}
