// =============================================
//  Scoring calculations — shared across pages
// =============================================

/**
 * Determines if team1 won based on head-to-head set comparison.
 * Wins the match by winning 2 out of 3 sets (more games in a set = win that set).
 */
export function isWinner(t1s1, t1s2, t1s3, t2s1, t2s2, t2s3) {
  const sets = [[t1s1, t2s1], [t1s2, t2s2]]
  if (t1s3 != null && t2s3 != null) sets.push([t1s3, t2s3])
  const setsWon = sets.filter(([a, b]) => a != null && b != null && a > b).length
  return setsWon >= 2
}

/**
 * Adjusts a single set score for scoring purposes:
 * - 7-6 (tiebreak): winner gets 6, loser gets 5.5
 * - 7-x (won with 7, not a tiebreak): capped at 6
 * - All other scores: unchanged
 */
function adjustedSetScore(myScore, oppScore) {
  if (myScore == null || oppScore == null) return null
  if (myScore === 7 && oppScore === 6) return 6    // tiebreak win
  if (myScore === 6 && oppScore === 7) return 5.5  // tiebreak loss
  if (myScore === 7) return 6                       // won with 7 (e.g. 7-5), cap at 6
  return myScore
}

/**
 * Calculates the per-match score for team1.
 * Set scores are adjusted for 7s before averaging.
 * Win:  average of adjusted set scores + 2 bonus points
 * Loss: average of adjusted set scores
 */
export function matchScore(t1s1, t1s2, t1s3, t2s1, t2s2, t2s3) {
  const adj = [
    adjustedSetScore(t1s1, t2s1),
    adjustedSetScore(t1s2, t2s2),
    adjustedSetScore(t1s3, t2s3)
  ].filter(s => s != null)
  if (adj.length === 0) return null
  const avg = adj.reduce((a, b) => a + b, 0) / adj.length
  const won = isWinner(t1s1, t1s2, t1s3, t2s1, t2s2, t2s3)
  return won ? avg + 2 : avg
}

/**
 * Computes the season average from an array of per-match scores.
 * Formula: AVERAGE − (MAX + MIN − 2×AVERAGE) / COUNT
 * Matches your spreadsheet formula exactly.
 */
export function seasonAverage(scores) {
  const valid = scores.filter(s => s != null)
  if (valid.length === 0) return null
  if (valid.length === 1) return valid[0]
  const n   = valid.length
  const sum = valid.reduce((a, b) => a + b, 0)
  const avg = sum / n
  const max = Math.max(...valid)
  const min = Math.min(...valid)
  return avg - (max + min - 2 * avg) / n
}

/**
 * Formats a number to 2 decimal places, or '—' if null.
 */
export function fmt(value) {
  if (value == null) return '—'
  return Number(value).toFixed(2)
}

/**
 * Internal helper: returns scored match entries for a member sorted by
 * played_on date ascending. Each entry: { score, won, played_on }.
 */
function getPlayerMatchEntries(memberId, matches) {
  const entries = []
  for (const m of matches) {
    const onTeam1 = m.team1_player1 === memberId || m.team1_player2 === memberId
    const onTeam2 = m.team2_player1 === memberId || m.team2_player2 === memberId
    if (!onTeam1 && !onTeam2) continue
    let score, won
    if (onTeam1) {
      score = matchScore(m.team1_set1, m.team1_set2, m.team1_set3, m.team2_set1, m.team2_set2, m.team2_set3)
      won   = isWinner(m.team1_set1, m.team1_set2, m.team1_set3, m.team2_set1, m.team2_set2, m.team2_set3)
    } else {
      score = matchScore(m.team2_set1, m.team2_set2, m.team2_set3, m.team1_set1, m.team1_set2, m.team1_set3)
      won   = isWinner(m.team2_set1, m.team2_set2, m.team2_set3, m.team1_set1, m.team1_set2, m.team1_set3)
    }
    if (score == null) continue
    entries.push({ score, won, played_on: m.played_on })
  }
  return entries.sort((a, b) => (a.played_on < b.played_on ? -1 : 1))
}

/**
 * Computes current-season stats using a rolling-4 average.
 *
 * If a player has fewer than 4 matches in currentSeasonMatches, their season
 * average is padded with the most recent scores from priorMatches to reach 4
 * total (matching the spreadsheet's early-season convention).
 *
 * matchesPlayed / wins / losses always reflect the current season only.
 */
export function computeCurrentSeasonStats(memberId, currentSeasonMatches, priorMatches) {
  const cur       = getPlayerMatchEntries(memberId, currentSeasonMatches)
  const wins      = cur.filter(e => e.won).length
  const losses    = cur.filter(e => !e.won).length
  const curScores = cur.map(e => e.score)

  let avgScores = curScores
  if (curScores.length < 4) {
    const needed = 4 - curScores.length
    const prior  = getPlayerMatchEntries(memberId, priorMatches)
    const pad    = prior.slice(-needed).map(e => e.score)
    avgScores    = [...pad, ...curScores]
  }

  return {
    memberId,
    matchesPlayed: curScores.length,
    wins,
    losses,
    matchScores:   curScores,
    seasonAvg:     seasonAverage(avgScores),
    usingRolling4: curScores.length < 4
  }
}

/**
 * Given all matches and a member id, computes that member's stats.
 */
export function computeMemberStats(memberId, matches) {
  const scores = []
  let wins = 0, losses = 0

  for (const m of matches) {
    const onTeam1 = m.team1_player1 === memberId || m.team1_player2 === memberId
    const onTeam2 = m.team2_player1 === memberId || m.team2_player2 === memberId
    if (!onTeam1 && !onTeam2) continue

    let score
    if (onTeam1) {
      score = matchScore(m.team1_set1, m.team1_set2, m.team1_set3, m.team2_set1, m.team2_set2, m.team2_set3)
      if (score == null) continue
      if (isWinner(m.team1_set1, m.team1_set2, m.team1_set3, m.team2_set1, m.team2_set2, m.team2_set3)) wins++
      else losses++
    } else {
      score = matchScore(m.team2_set1, m.team2_set2, m.team2_set3, m.team1_set1, m.team1_set2, m.team1_set3)
      if (score == null) continue
      if (isWinner(m.team2_set1, m.team2_set2, m.team2_set3, m.team1_set1, m.team1_set2, m.team1_set3)) wins++
      else losses++
    }
    scores.push(score)
  }

  return {
    memberId,
    matchesPlayed: scores.length,
    wins,
    losses,
    matchScores: scores,
    seasonAvg: seasonAverage(scores)
  }
}
