// =============================================
//  Results page logic
// =============================================

import { supabase, connectionErrorHtml } from './supabase-client.js'
import { CURRENT_SEASON } from './config.js'
import { isWinner, matchScore, fmt } from './scoring.js'

// Members + all matches are fetched once and cached, so switching seasons
// re-renders instantly from memory. Pass { refresh: true } after inserting
// a match so the new result shows up.
let _cache = null   // { memberMap, matches } — matches ordered played_on desc

/** Seasons present in the cached match data, newest first. */
export function knownSeasons() {
  return _cache ? [...new Set(_cache.matches.map(m => m.season))].sort().reverse() : []
}

export async function loadResults(season = CURRENT_SEASON, { refresh = false } = {}) {
  const container = document.getElementById('results-container')
  if (refresh) _cache = null

  if (!_cache) {
    container.innerHTML = '<div class="loading-state"><div class="spinner"></div> Loading results…</div>'

    let membersRes, matchesRes
    try {
      [membersRes, matchesRes] = await Promise.all([
        supabase.from('members').select('id, full_name'),
        supabase.from('matches').select('*').order('played_on', { ascending: false })
      ])
    } catch (err) {
      container.innerHTML = connectionErrorHtml()
      return
    }

    if (membersRes.error || matchesRes.error) {
      container.innerHTML = '<div class="alert alert-error">Failed to load results. Please try again.</div>'
      return
    }

    _cache = {
      memberMap: Object.fromEntries(membersRes.data.map(m => [m.id, m.full_name])),
      matches: matchesRes.data
    }
  }

  const memberMap = _cache.memberMap
  const matches = season === 'all'
    ? _cache.matches
    : _cache.matches.filter(m => m.season === season)

  if (matches.length === 0) {
    container.innerHTML = '<p style="color:var(--gray-600);text-align:center;padding:2rem;">No results yet.</p>'
    return
  }

  // Group by key — include season prefix when viewing Entire History
  const weeks = {}
  for (const m of matches) {
    const key = season === 'all' ? `${m.season} — ${m.week_label}` : m.week_label
    if (!weeks[key]) weeks[key] = []
    weeks[key].push(m)
  }

  let html = ''

  for (const [weekLabel, weekMatches] of Object.entries(weeks)) {
    const date = new Date(weekMatches[0].played_on + 'T00:00:00')
    const dateStr = date.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })
    html += `<div class="week-section"><div class="week-label">${weekLabel} &mdash; ${dateStr}</div>`

    for (const m of weekMatches) {
      const t1won = isWinner(m.team1_set1, m.team1_set2, m.team1_set3, m.team2_set1, m.team2_set2, m.team2_set3)
      const t2won = isWinner(m.team2_set1, m.team2_set2, m.team2_set3, m.team1_set1, m.team1_set2, m.team1_set3)

      const t1score = matchScore(m.team1_set1, m.team1_set2, m.team1_set3, m.team2_set1, m.team2_set2, m.team2_set3)
      const t2score = matchScore(m.team2_set1, m.team2_set2, m.team2_set3, m.team1_set1, m.team1_set2, m.team1_set3)

      const t1names = [
        m.team1_player1 && memberMap[m.team1_player1] ? `<a href="player.html?id=${m.team1_player1}" class="player-link">${memberMap[m.team1_player1]}</a>` : null,
        m.team1_player2 && memberMap[m.team1_player2] ? `<a href="player.html?id=${m.team1_player2}" class="player-link">${memberMap[m.team1_player2]}</a>` : null
      ].filter(Boolean).join(' & ')
      const t2names = [
        m.team2_player1 && memberMap[m.team2_player1] ? `<a href="player.html?id=${m.team2_player1}" class="player-link">${memberMap[m.team2_player1]}</a>` : null,
        m.team2_player2 && memberMap[m.team2_player2] ? `<a href="player.html?id=${m.team2_player2}" class="player-link">${memberMap[m.team2_player2]}</a>` : null
      ].filter(Boolean).join(' & ')

      // Build set score string e.g. "6-3, 6-4"
      const sets = []
      if (m.team1_set1 !== null && m.team2_set1 !== null) sets.push(`${m.team1_set1}–${m.team2_set1}`)
      if (m.team1_set2 !== null && m.team2_set2 !== null) sets.push(`${m.team1_set2}–${m.team2_set2}`)
      if (m.team1_set3 !== null && m.team2_set3 !== null) sets.push(`${m.team1_set3}–${m.team2_set3}`)
      const setStr = sets.join(', ')

      html += `
        <div class="match-card">
          <div class="match-team ${t1won ? 'team-won' : 'team-lost'}">
            ${t1won ? '<div class="winner-label">Winner</div>' : ''}
            <div class="match-team-names">${t1names}</div>
            <div class="match-team-score">Match score: ${fmt(t1score)}</div>
          </div>
          <div class="match-score-center">
            <div class="match-sets" style="font-size:0.95rem;font-weight:600;color:var(--gray-800);">${setStr}</div>
          </div>
          <div class="match-team team-right ${t2won ? 'team-won' : 'team-lost'}">
            ${t2won ? '<div class="winner-label">Winner</div>' : ''}
            <div class="match-team-names">${t2names}</div>
            <div class="match-team-score">Match score: ${fmt(t2score)}</div>
          </div>
        </div>
      `
    }

    html += '</div>'
  }

  container.innerHTML = html
}
