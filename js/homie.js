// =============================================
//  Paddle Homie Award — who makes themselves available most.
//
//  The availability table is private, so the totals come from the
//  paddle_homie() database function, which runs as its definer and
//  returns counts per member and nothing else. See add-paddle-homie.sql.
// =============================================
import { supabase } from './supabase-client.js?v=2d21059e'

/**
 * [{ member_id, weeks_available }] for a season, or [] if the function
 * isn't there yet. Never throws — the award must not take the standings
 * down with it.
 */
export async function fetchPaddleHomie(season) {
  try {
    const { data, error } = await supabase.rpc('paddle_homie', { p_season: season })
    if (error) return []
    return data || []
  } catch {
    return []
  }
}

/** Most weeks first, ties broken by name so the order is stable. */
export function homieBoard(rows, nameById) {
  return (rows || [])
    .map(r => ({ id: r.member_id, weeks: r.weeks_available, name: nameById[r.member_id] || '?' }))
    .filter(r => r.weeks > 0 && r.name !== '?')
    .sort((a, b) => b.weeks - a.weeks || a.name.localeCompare(b.name))
}
