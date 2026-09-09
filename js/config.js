// =============================================
//  League configuration — single source of truth
//  Update these once per season instead of editing
//  every page individually.
// =============================================

// The active season, in the format stored in the database
// (matches.season and member_seasons.season).
export const CURRENT_SEASON = '2026-27'

// First day of the current season (YYYY-MM-DD string). Used by the
// scheduler to scope "this season" match history.
// 2026-27 opens Monday 21 September 2026.
export const SEASON_START = '2026-09-21'

// Last day of the current season. Availability and the scheduler
// stop showing weeks after this date. (Last Monday of March 2027.)
export const SEASON_END = new Date('2027-03-29T23:59:59')

// ── Availability window ─────────────────────────────────────────────────
// Which Mondays the availability page collects responses for right now.
// The season runs through March, but we only ask people to commit a few
// weeks ahead. Extend AVAILABILITY_END when you want the next block of
// weeks to open up.
export const AVAILABILITY_START = '2026-09-21'
export const AVAILABILITY_END   = '2026-10-26'   // last Monday in October

// Weeks played before the season officially counts. Matches in these weeks
// are warm-ups; we still collect availability so courts can be organised.
// Listed as YYYY-MM-DD Mondays.
export const UNOFFICIAL_WEEKS = ['2026-09-21', '2026-09-28']

// ── Season opener ───────────────────────────────────────────────────────
// Drives the countdown on the home page.
export const NEXT_SEASON_LABEL = '2026-27'
export const NEXT_SEASON_START = new Date('2026-09-21T19:00:00')

// ── First-place eligibility ─────────────────────────────────────────────
// To hold top spot a player must have played at least 4 matches and have
// played within the past 6 weeks. That check is dormant until this date:
// early in the season nobody has four matches yet, so applying it would
// demote leaders for no meaningful reason. From January it starts to mean
// something — by then anyone near the top has had a full run of Mondays.
export const ELIGIBILITY_START = new Date('2027-01-01T00:00:00')
