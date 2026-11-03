// =============================================
//  Vinny's Award — who went out after the matches.
//
//  One row per member per night in the `vinnys` table. Everything here
//  is read-only and public; recording attendance lives in results.html
//  behind the admin check.
// =============================================
import { supabase } from './supabase-client.js?v=2d21059e'
import { SEASON_START } from './config.js?v=d82921ce'

// "Forfeit" is a placeholder member used to record a walkover, not a person,
// so it must never appear in a tally of who went out.
export const NOT_A_PERSON = 'Forfeit'

/**
 * Attendance rows for a season, newest night first.
 * Returns [] rather than throwing — the award is a nice-to-have and must
 * never take a page down with it.
 */
export async function fetchVinnys({ since = SEASON_START } = {}) {
  try {
    let q = supabase.from('vinnys').select('played_on, member_id')
    // since: null asks for every season, which the standings page needs so it
    // can scope the tally to whichever season is selected.
    if (since) q = q.gte('played_on', since)
    const { data, error } = await q.order('played_on', { ascending: false })
    if (error) return []
    return data || []
  } catch {
    return []
  }
}

/**
 * Season totals kept by hand for the years before the vinnys table
 * existed. Returns [{ member_id, vinnys_nights }], or [] for a season
 * with none — in which case the per-night rows are the whole story.
 *
 * These are totals rather than rows because there are no nights to hang
 * them on, and because some are halves, which counting rows can never
 * produce.
 */
export async function fetchRecordedTotals(season) {
  try {
    const { data, error } = await supabase
      .from('season_awards')
      .select('member_id, vinnys_nights')
      .eq('season', season)
      .not('vinnys_nights', 'is', null)
    if (error) return []
    return data || []
  } catch {
    return []
  }
}

/** Leaderboard from recorded season totals, same shape as leaderboard(). */
export function boardFromTotals(rows, nameById) {
  return (rows || [])
    .map(r => ({ id: r.member_id, nights: Number(r.vinnys_nights), name: nameById[r.member_id] || '?' }))
    .filter(r => r.nights > 0 && r.name !== NOT_A_PERSON && r.name !== '?')
    .sort((a, b) => b.nights - a.nights || a.name.localeCompare(b.name))
}

/** Nights attended per member: { member_id: count }. */
export function nightsByMember(rows) {
  const out = {}
  for (const r of rows) out[r.member_id] = (out[r.member_id] || 0) + 1
  return out
}

/** Distinct nights that have any attendance recorded. */
export function nightsHeld(rows) {
  return [...new Set(rows.map(r => r.played_on))]
}

/** Member ids marked for one night. */
export function attendeesOn(rows, playedOn) {
  return rows.filter(r => r.played_on === playedOn).map(r => r.member_id)
}

/**
 * Leaderboard, most nights first, ties broken by name so the order is
 * stable between loads. Members on zero are left out.
 */
export function leaderboard(rows, nameById) {
  const counts = nightsByMember(rows)
  return Object.entries(counts)
    .map(([id, nights]) => ({ id, nights, name: nameById[id] || '?' }))
    .filter(r => r.name !== NOT_A_PERSON)
    .sort((a, b) => b.nights - a.nights || a.name.localeCompare(b.name))
}

/**
 * Everyone tied at the top. The award is shared when tied rather than
 * picked arbitrarily — in a 16-person league ties will be common.
 */
export function currentHolders(rows, nameById) {
  const board = leaderboard(rows, nameById)
  if (board.length === 0) return []
  const top = board[0].nights
  return board.filter(r => r.nights === top)
}
