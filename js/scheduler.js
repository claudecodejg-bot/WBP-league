// =============================================
//  Match Scheduler — pairing generation logic
// =============================================

import { supabase }                from './supabase-client.js'
import { computeCurrentSeasonStats, isWinner } from './scoring.js'

const SEASON_START   = '2025-10-01'  // current season (25-26) start date
const ITERATIONS     = 2000          // random sampling iterations
const SEASON_END     = new Date('2026-03-30T23:59:59')
const BALANCE_WEIGHT = 3             // penalty per 1-pt team score differential

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
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  // Start from the Monday on or after today
  const day   = today.getDay()
  const start = new Date(today)
  if (day !== 1) {
    const daysUntilMonday = day === 0 ? 1 : (8 - day)
    start.setDate(start.getDate() + daysUntilMonday)
  }

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
  return (data || [])
    .map(r => ({ id: r.member_id, name: r.members?.full_name || '' }))
    .filter(m => m.name)
}

// Count how many matches each member played this season (keyed by member UUID)
async function getSeasonOutings(memberIds) {
  const { data, error } = await supabase
    .from('matches')
    .select('team1_player1, team1_player2, team2_player1, team2_player2')
    .gte('played_on', SEASON_START)

  if (error) throw new Error('Failed to fetch outings: ' + error.message)

  const outings = {}
  memberIds.forEach(id => { outings[id] = 0 })

  for (const m of (data || [])) {
    for (const p of [m.team1_player1, m.team1_player2, m.team2_player1, m.team2_player2]) {
      if (Object.prototype.hasOwnProperty.call(outings, p)) outings[p]++
    }
  }
  return outings
}

// Fetch ALL match history + scores; build partner/opp matrices (UUID-keyed)
// and compute each playing player's season average.
async function buildHistoryAndScores(playerIds) {
  const { data: allMatches, error } = await supabase
    .from('matches')
    .select(
      'team1_player1, team1_player2, team2_player1, team2_player2,' +
      'team1_set1, team1_set2, team1_set3,' +
      'team2_set1, team2_set2, team2_set3,' +
      'played_on'
    )

  if (error) throw new Error('Failed to fetch match history: ' + error.message)

  const idSet         = new Set(playerIds)
  const partnerCount  = {}   // { id: { id: count } }
  const oppCount      = {}   // { id: { id: count } }
  const partnerRecord = {}   // { id: { id: { wins, losses } } }
  const curMatches    = []
  const priorMatches  = []

  // Helpers
  const incMatrix = (matrix, a, b) => {
    if (!idSet.has(a) || !idSet.has(b)) return
    if (!matrix[a]) matrix[a] = {}
    if (!matrix[b]) matrix[b] = {}
    matrix[a][b] = (matrix[a][b] || 0) + 1
    matrix[b][a] = (matrix[b][a] || 0) + 1
  }

  const incRecord = (matrix, a, b, won) => {
    if (!idSet.has(a) || !idSet.has(b)) return
    if (!matrix[a]) matrix[a] = {}
    if (!matrix[b]) matrix[b] = {}
    if (!matrix[a][b]) matrix[a][b] = { wins: 0, losses: 0 }
    if (!matrix[b][a]) matrix[b][a] = { wins: 0, losses: 0 }
    if (won) { matrix[a][b].wins++;  matrix[b][a].wins++  }
    else     { matrix[a][b].losses++; matrix[b][a].losses++ }
  }

  for (const m of (allMatches || [])) {
    const isCurrent = m.played_on >= SEASON_START
    if (isCurrent) curMatches.push(m)
    else           priorMatches.push(m)

    const t1    = [m.team1_player1, m.team1_player2]
    const t2    = [m.team2_player1, m.team2_player2]
    const t1Won = isWinner(
      m.team1_set1, m.team1_set2, m.team1_set3,
      m.team2_set1, m.team2_set2, m.team2_set3
    )

    // partnerCount / oppCount: current season only (drives the pairing algorithm)
    if (isCurrent) {
      incMatrix(partnerCount, t1[0], t1[1])
      incMatrix(partnerCount, t2[0], t2[1])
      for (const a of t1) for (const b of t2) incMatrix(oppCount, a, b)
    }

    // partnerRecord: all-time history (drives the W/L display)
    incRecord(partnerRecord, t1[0], t1[1],  t1Won)
    incRecord(partnerRecord, t2[0], t2[1], !t1Won)
  }

  // Season averages via the shared scoring module
  const scores = {}
  for (const id of playerIds) {
    const stats = computeCurrentSeasonStats(id, curMatches, priorMatches)
    scores[id]  = stats.seasonAvg ?? null
  }

  return { partnerCount, oppCount, partnerRecord, scores }
}

// ── Pairing algorithm ────────────────────────

function get(matrix, a, b) {
  return (matrix[a] && matrix[a][b]) || 0
}

// Win-rate bonus for a partner pair using all-time record (min 3 matches)
function winRateBonus(partnerRecord, a, b) {
  const rec   = partnerRecord[a]?.[b]
  if (!rec) return 0
  const total = rec.wins + rec.losses
  if (total < 3) return 0
  return (rec.wins / total - 0.5) * 4  // +2 at 100%, -2 at 0%
}

// Score a full list of courts — higher is better (more variety + better balance)
function scoreAssignment(courts, partnerCount, oppCount, scores, partnerRecord) {
  let score = 0
  for (const [[a, b], [c, d]] of courts) {
    // Variety: penalise familiar partners (current season, 3×) and opponents (1×)
    score -= get(partnerCount, a, b) * 3
    score -= get(partnerCount, c, d) * 3
    score -= get(oppCount, a, c)
    score -= get(oppCount, a, d)
    score -= get(oppCount, b, c)
    score -= get(oppCount, b, d)

    // Balance: penalise team score differential
    const sa = scores[a] ?? 5, sb = scores[b] ?? 5
    const sc = scores[c] ?? 5, sd = scores[d] ?? 5
    const diff = Math.abs((sa + sb) - (sc + sd))
    score -= diff * BALANCE_WEIGHT

    // Win rate: reward pairings with strong all-time W/L record together
    score += winRateBonus(partnerRecord, a, b)
    score += winRateBonus(partnerRecord, c, d)
  }
  return score
}

// For 4 players, choose the best of the 3 possible pairings
function bestPairing(players, partnerCount, oppCount, scores, partnerRecord) {
  const [a, b, c, d] = players
  const options = [
    [[a, b], [c, d]],
    [[a, c], [b, d]],
    [[a, d], [b, c]]
  ]
  let best = null, bestScore = -Infinity
  for (const opt of options) {
    const s = scoreAssignment([opt], partnerCount, oppCount, scores, partnerRecord)
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

function generateOptions(playerIds, partnerCount, oppCount, scores, partnerRecord) {
  const numCourts = Math.floor(playerIds.length / 4)
  const seen      = new Set()
  const results   = []

  for (let iter = 0; iter < ITERATIONS; iter++) {
    const shuffled = shuffle(playerIds)
    const courts   = []
    let totalScore = 0

    for (let i = 0; i < numCourts; i++) {
      const group              = shuffled.slice(i * 4, i * 4 + 4)
      const { pairing, score } = bestPairing(group, partnerCount, oppCount, scores, partnerRecord)
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
  const numCourts  = Math.floor(available.length / 4)
  const numPlaying = numCourts * 4
  const numSitOut  = available.length - numPlaying

  if (numSitOut === 0) {
    return { playing: available, sittingOut: [], tiebreakUsed: false }
  }

  // Sort descending by outings — those with most outings sit out
  const sorted = [...available].sort((a, b) => {
    const diff = (outings[b.id] || 0) - (outings[a.id] || 0)
    return diff !== 0 ? diff : Math.random() - 0.5
  })

  const sittingOut = sorted.slice(0, numSitOut)
  const playing    = sorted.slice(numSitOut)

  const boundaryCount = outings[sorted[numSitOut - 1]?.id] || 0
  const nextCount     = outings[sorted[numSitOut]?.id]     || 0
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

  const memberIds = available.map(m => m.id)
  const outings   = await getSeasonOutings(memberIds)

  const { playing, sittingOut, tiebreakUsed } = determinePlayers(available, outings)

  const playerIds = playing.map(p => p.id)
  const { partnerCount, oppCount, partnerRecord, scores } =
    await buildHistoryAndScores(playerIds)

  const options = generateOptions(playerIds, partnerCount, oppCount, scores, partnerRecord)

  const idToName = Object.fromEntries(available.map(m => [m.id, m.name]))

  return {
    weekStart,
    available,
    playing,
    sittingOut,
    tiebreakUsed,
    outings,
    options,
    idToName,
    scores,
    partnerCount,
    oppCount,
    partnerRecord
  }
}
