// =============================================
//  League configuration — single source of truth
//  Update these once per season instead of editing
//  every page individually.
// =============================================

// The active season, in the format stored in the database
// (matches.season and member_seasons.season).
export const CURRENT_SEASON = '2025-26'

// First day of the current season (YYYY-MM-DD string). Used by the
// scheduler to scope "this season" match history.
export const SEASON_START = '2025-10-01'

// Last day of the current season. Availability and the scheduler
// stop showing weeks after this date.
export const SEASON_END = new Date('2026-03-30T23:59:59')

// ── Upcoming season ─────────────────────────────────────────────────────
// Used by the home page welcome/countdown only. These are intentionally
// separate from CURRENT_SEASON above: the site still reports 2025-26 as the
// active season because no 2026-27 matches or member_seasons rows exist yet.
// When the new season's roster is loaded, update CURRENT_SEASON/SEASON_START/
// SEASON_END and these can follow.
export const NEXT_SEASON_LABEL = '2026-27'
export const NEXT_SEASON_START = new Date('2026-10-01T19:00:00')
