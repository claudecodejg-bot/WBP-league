// =============================================
//  Match Scheduler — pairing generation logic
// =============================================

import { supabase } from './supabase-client.js'

const CURRENT_SEASON = '25-26'
const ITERATIONS     = 2000   // random sampling iterations for pairing search
const SEASON_END     = new Date('2026-03-30T23:59:59')

// ── Date helpers ────────────────────────────

function getMonday(date) {
  const d   = new Date(date)
  const day = d.getDay()
  const diff = d.getDate() - day + (day === 0 ? -6 : 1)
  d.setDate(diff)
  d.setHours(0, 0, 0, 0)
  return d
}

function toISO(date) {
  return date.toISOString().split('T')[0]
}

export function formatWeekLabel(monday) {
  return monday.toLocaleDateString('en-US', { month: 'long', day: 'numeric' })
}

export function getUpcomingWeeks() {
  const today      = new Date()
  const thisMonday = getMonday(today)
  const start      = new Date(thisMonday)
  start.setDate(start.getDate() + 7)
  if (today.getDay() === 0) start.setDate(start.getDate() + 7)

  const weeks = []
  for (let i = 0; i < 4; i++) {
    const d = new Date(start)
    d.setDate(d.getDate() + i * 7)
    if (d > SEASON_END) break
    weeks.push(d)
  }
  return weeks
}

// ── Data fetching ────────────────────────────

async function getAvailableMembers(weekStart) {
  const { data, error } = await supabase
    .from('availability')
    .select('member_id, members(full_name)')
    .eq('week_start', toISO(weekStart))
    .eq('is_available', true)

  if (error) throw new Error('Failed to fetch availability: ' + error.message)
  return (data || []).map(r => ({ id: r.member_id, name: r.members?.full_name || '' }))
    .filter(m => m.name)
}

async function getSeasonOutings(memberNames) {
  const { data: matches, error } = await supabase
    .from('matches')
    .select('team1_player1, team1_player2, team2_player1, team2_player2')
    .eq('season', CURRENT_SEASON)

  if (error) throw new Error('Failed to fetch season matches: ' + error.message)

  const outings = {}
  memberNames.forEach(n => { outings[n] = 0 })
  for (const m of (matches || [])) {
    for (const p of [m.team1_player1, m.team1_player2, m.team2_player1, m.team2_player2]) {
      if (Object.prototype.hasOwnProperty.call(outings, p)) outings[p]++
    }
  }
  return outings
}

async function buildHistoryMatrices(playerNames) {
  const { data: matches, error } = await supabase
    .from('matches')
    .select('team1_player1, team1_player2, team2_player1, team2_player2')

  if (error) throw new Error('Failed to fetch match history: ' + error.message)

  const nameSet      = new Set(playerNames)
  const partnerCount = {}
  const oppCount     = {}

  const inc = (matrix, a, b) => {
    if (!nameSet.has(a) || !nameSet.has(b)) return
    if (!matrix[a]) matrix[a] = {}
    if (!matrix[b]) matrix[b] = {}
    matrix[a][b] = (matrix[a][b] || 0) + 1
    matrix[b][a] = (matrix[b][a] || 0) + 1
  }

  for (const m of (matches || [])) {
    const t1 = [m.team1_player1, m.team1_player2]
    const t2 = [m.team2_player1, m.team2_player2]
    inc(partnerCount, t1[0], t1[1])
    inc(partnerCount, t2[0], t2[1])
    for (const a of t1) for (const b of t2) inc(oppCount, a, b)
  }

  return { partnerCount, oppCount }
}

// ── Pairing algorithm ────────────────────────

function get(matrix, a, b) {
  return (matrix[a] && matrix[a][b]) || 0
}

// Score a full list of courts — higher is better (more variety)
function scoreAssignment(courts, partnerCount, oppCount) {
  let score = 0
  for (const [[a, b], [c, d]] of courts) {
    score -= get(partnerCount, a, b) * 3   // partner familiarity hurts most
    score -= get(partnerCount, c, d) * 3
    score -= get(oppCount, a, c)           // opponent familiarity hurts less
    score -= get(oppCount, a, d)
    score -= get(oppCount, b, c)
    score -= get(oppCount, b, d)
  }
  return score
}

// For 4 players, choose the best of the 3 possible pairings
function bestPairing(players, partnerCount, oppCount) {
  const [a, b, c, d] = players
  const options = [
    [[a, b], [c, d]],
    [[a, c], [b, d]],
    [[a, d], [b, c]]
  ]
  let best = null, bestScore = -Infinity
  for (const opt of options) {
    const s = scoreAssignment([opt], partnerCount, oppCount)
    if (s > bestScore) { bestScore = s; best = opt }
  }
  return { pairing: best, score: bestScore }
}

// Fisher-Yates shuffle
function shuffle(arr) {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

// Canonical key for deduplication
function assignmentKey(courts) {
  return courts
    .map(([t1, t2]) => {
      const s1 = [...t1].sort().join('+')
      const s2 = [...t2].sort().join('+')
      return [s1, s2].sort().join(' vs ')
    })
    .sort()
    .join(' | ')
}

function generateOptions(players, partnerCount, oppCount) {
  const numCourts = Math.floor(players.length / 4)
  const seen      = new Set()
  const results   = []

  for (let iter = 0; iter < ITERATIONS; iter++) {
    const shuffled = shuffle(players)
    const courts   = []
    let totalScore = 0

    for (let i = 0; i < numCourts; i++) {
      const group        = shuffled.slice(i * 4, i * 4 + 4)
      const { pairing, score } = bestPairing(group, partnerCount, oppCount)
      courts.push(pairing)
      totalScore += score
    }

    const key = assignmentKey(courts)
    if (!seen.has(key)) {
      seen.add(key)
      results.push({ courts, score: totalScore })
      results.sort((a, b) => b.score - a.score)
      if (results.length > 3) results.pop()
    }

    if (results.length >= 3 && iter > 600) break
  }

  return results
}

// ── Sit-out logic ─────────────────────────────

function determinePlayers(available, outings) {
  const numCourts    = Math.floor(available.length / 4)
  const numPlaying   = numCourts * 4
  const numSitOut    = available.length - numPlaying

  if (numSitOut === 0) {
    return { playing: available, sittingOut: [], tiebreakUsed: false }
  }

  // Sort descending by outings — those with most outings sit out
  // Random tiebreaker preserves fairness
  const sorted = [...available].sort((a, b) => {
    const diff = (outings[b.name] || 0) - (outings[a.name] || 0)
    return diff !== 0 ? diff : Math.random() - 0.5
  })

  const sittingOut = sorted.slice(0, numSitOut)
  const playing    = sorted.slice(numSitOut)

  // Tiebreak used if boundary players share the same outing count
  const boundaryCount = outings[sorted[numSitOut - 1]?.name] || 0
  const nextCount     = outings[sorted[numSitOut]?.name]     || 0
  const tiebreakUsed  = boundaryCount === nextCount

  return { playing, sittingOut, tiebreakUsed }
}

// ── Main export ───────────────────────────────

export async function generateSchedule(weekStart) {
  const available = await getAvailableMembers(weekStart)

  if (available.length === 0) {
    return { error: 'No availability responses yet for this week.' }
  }
  if (available.length < 4) {
    return { error: `Only ${available.length} player(s) available — need at least 4 to schedule a court.` }
  }

  const names   = available.map(m => m.name)
  const outings = await getSeasonOutings(names)

  const { playing, sittingOut, tiebreakUsed } = determinePlayers(available, outings)

  const playerNames = playing.map(p => p.name)
  const { partnerCount, oppCount } = await buildHistoryMatrices(playerNames)

  const options = generateOptions(playerNames, partnerCount, oppCount)

  return {
    weekStart,
    available,
    playing,
    sittingOut,
    tiebreakUsed,
    outings,
    options
  }
}
