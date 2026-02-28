// =============================================
//  Admin panel logic
// =============================================

import { supabase } from './supabase-client.js'
import { isWinner, matchScore, fmt } from './scoring.js'
import { loadAdminAvailability } from './availability.js'

let allMembers = []

export async function initAdmin() {
  // Load members for dropdowns
  const { data, error } = await supabase
    .from('members')
    .select('id, full_name')
    .order('full_name')

  if (error || !data) {
    document.getElementById('admin-container').innerHTML =
      '<div class="alert alert-error">Failed to load member list.</div>'
    return
  }
  allMembers = data

  renderMatchForm()
  renderRecentMatches()
  loadAdminAvailability(document.getElementById('admin-avail-container'))
}

// ----- Match Entry Form -----

function memberOptions(excludeIds = []) {
  return allMembers
    .filter(m => !excludeIds.includes(m.id))
    .map(m => `<option value="${m.id}">${m.full_name}</option>`)
    .join('')
}

function renderMatchForm() {
  const container = document.getElementById('match-form-container')
  const opts = allMembers.map(m => `<option value="${m.id}">${m.full_name}</option>`).join('')

  container.innerHTML = `
    <div id="form-alert" class="alert hidden"></div>

    <div class="form-group">
      <label for="week-label">Week Label</label>
      <input type="text" id="week-label" placeholder="e.g. Week of Mar 3" required>
    </div>

    <div class="form-group">
      <label for="played-on">Date Played</label>
      <input type="date" id="played-on" required value="${new Date().toISOString().split('T')[0]}">
    </div>

    <div class="admin-grid" style="margin-bottom:1rem;">
      <div class="team-block">
        <div class="team-block-title">Team 1</div>
        <div class="form-group">
          <label>Player 1</label>
          <select id="t1p1"><option value="">— select —</option>${opts}</select>
        </div>
        <div class="form-group">
          <label>Player 2</label>
          <select id="t1p2"><option value="">— select —</option>${opts}</select>
        </div>
        <div class="form-group">
          <label>Set Scores (games won per set)</label>
          <div class="set-scores-group">
            <div>
              <label style="font-size:0.78rem;color:var(--gray-600)">Set 1</label>
              <input type="number" id="t1s1" min="0" max="7" placeholder="0–7">
            </div>
            <div>
              <label style="font-size:0.78rem;color:var(--gray-600)">Set 2</label>
              <input type="number" id="t1s2" min="0" max="7" placeholder="0–7">
            </div>
            <div>
              <label style="font-size:0.78rem;color:var(--gray-600)">Set 3 (if played)</label>
              <input type="number" id="t1s3" min="0" max="7" placeholder="optional">
            </div>
          </div>
        </div>
      </div>

      <div class="team-block">
        <div class="team-block-title">Team 2</div>
        <div class="form-group">
          <label>Player 1</label>
          <select id="t2p1"><option value="">— select —</option>${opts}</select>
        </div>
        <div class="form-group">
          <label>Player 2</label>
          <select id="t2p2"><option value="">— select —</option>${opts}</select>
        </div>
        <div class="form-group">
          <label>Set Scores (games won per set)</label>
          <div class="set-scores-group">
            <div>
              <label style="font-size:0.78rem;color:var(--gray-600)">Set 1</label>
              <input type="number" id="t2s1" min="0" max="7" placeholder="0–7">
            </div>
            <div>
              <label style="font-size:0.78rem;color:var(--gray-600)">Set 2</label>
              <input type="number" id="t2s2" min="0" max="7" placeholder="0–7">
            </div>
            <div>
              <label style="font-size:0.78rem;color:var(--gray-600)">Set 3 (if played)</label>
              <input type="number" id="t2s3" min="0" max="7" placeholder="optional">
            </div>
          </div>
        </div>
      </div>
    </div>

    <div id="score-preview" class="alert alert-info hidden"></div>

    <button class="btn btn-primary" id="submit-match-btn" style="width:100%">Save Match Result</button>
  `

  // Live preview of computed scores
  const previewInputs = ['t1s1','t1s2','t1s3','t2s1','t2s2','t2s3']
  previewInputs.forEach(id => {
    document.getElementById(id)?.addEventListener('input', updateScorePreview)
  })

  document.getElementById('submit-match-btn').addEventListener('click', submitMatch)
}

function getNum(id) {
  const val = document.getElementById(id)?.value
  if (val === '' || val === null || val === undefined) return null
  const n = parseInt(val, 10)
  return isNaN(n) ? null : n
}

function updateScorePreview() {
  const t1s1 = getNum('t1s1'), t1s2 = getNum('t1s2'), t1s3 = getNum('t1s3')
  const t2s1 = getNum('t2s1'), t2s2 = getNum('t2s2'), t2s3 = getNum('t2s3')

  if (t1s1 === null || t1s2 === null || t2s1 === null || t2s2 === null) return

  const t1score = matchScore(t1s1, t1s2, t1s3, t2s1, t2s2, t2s3)
  const t2score = matchScore(t2s1, t2s2, t2s3, t1s1, t1s2, t1s3)
  const t1won   = isWinner(t1s1, t1s2, t1s3, t2s1, t2s2, t2s3)
  const t2won   = isWinner(t2s1, t2s2, t2s3, t1s1, t1s2, t1s3)

  const preview = document.getElementById('score-preview')
  preview.classList.remove('hidden')
  preview.innerHTML = `
    <strong>Score preview:</strong>
    Team 1 → <strong>${fmt(t1score)}</strong> ${t1won ? '(WIN ✓)' : '(loss)'}
    &nbsp;|&nbsp;
    Team 2 → <strong>${fmt(t2score)}</strong> ${t2won ? '(WIN ✓)' : '(loss)'}
  `
}

async function submitMatch() {
  const alertEl = document.getElementById('form-alert')
  alertEl.classList.add('hidden')

  const weekLabel = document.getElementById('week-label').value.trim()
  const playedOn  = document.getElementById('played-on').value
  const t1p1 = document.getElementById('t1p1').value
  const t1p2 = document.getElementById('t1p2').value
  const t2p1 = document.getElementById('t2p1').value
  const t2p2 = document.getElementById('t2p2').value
  const t1s1 = getNum('t1s1'), t1s2 = getNum('t1s2'), t1s3 = getNum('t1s3')
  const t2s1 = getNum('t2s1'), t2s2 = getNum('t2s2'), t2s3 = getNum('t2s3')

  // Validate
  if (!weekLabel) return showFormError('Please enter a week label.')
  if (!playedOn)  return showFormError('Please enter the date played.')
  if (!t1p1 || !t1p2) return showFormError('Please select both players for Team 1.')
  if (!t2p1 || !t2p2) return showFormError('Please select both players for Team 2.')
  if (new Set([t1p1, t1p2, t2p1, t2p2]).size !== 4)
    return showFormError('Each player can only appear once per match.')
  if (t1s1 === null || t1s2 === null || t2s1 === null || t2s2 === null)
    return showFormError('Please enter at least Sets 1 and 2 for both teams.')

  const btn = document.getElementById('submit-match-btn')
  btn.disabled = true
  btn.textContent = 'Saving…'

  const { error } = await supabase.from('matches').insert({
    week_label: weekLabel,
    played_on:  playedOn,
    team1_player1: t1p1, team1_player2: t1p2,
    team2_player1: t2p1, team2_player2: t2p2,
    team1_set1: t1s1, team1_set2: t1s2, team1_set3: t1s3,
    team2_set1: t2s1, team2_set2: t2s2, team2_set3: t2s3
  })

  btn.disabled = false
  btn.textContent = 'Save Match Result'

  if (error) {
    showFormError('Error saving match. Please try again.')
    return
  }

  // Success — clear scores, show message
  alertEl.textContent = 'Match saved successfully!'
  alertEl.className = 'alert alert-success'
  alertEl.classList.remove('hidden')
  ;['t1s1','t1s2','t1s3','t2s1','t2s2','t2s3'].forEach(id => {
    const el = document.getElementById(id)
    if (el) el.value = ''
  })
  document.getElementById('score-preview').classList.add('hidden')
  renderRecentMatches()
}

function showFormError(msg) {
  const alertEl = document.getElementById('form-alert')
  alertEl.textContent = msg
  alertEl.className = 'alert alert-error'
  alertEl.classList.remove('hidden')
}

// ----- Recent Matches -----

async function renderRecentMatches() {
  const container = document.getElementById('recent-matches-container')
  container.innerHTML = '<div class="loading-state"><div class="spinner"></div> Loading…</div>'

  const { data: matches, error } = await supabase
    .from('matches')
    .select('*')
    .order('played_on', { ascending: false })
    .limit(10)

  if (error) {
    container.innerHTML = '<div class="alert alert-error">Failed to load recent matches.</div>'
    return
  }

  if (!matches || matches.length === 0) {
    container.innerHTML = '<p style="color:var(--gray-600);font-size:0.9rem;">No matches yet.</p>'
    return
  }

  const memberMap = Object.fromEntries(allMembers.map(m => [m.id, m.full_name]))

  let html = `
    <table style="width:100%;border-collapse:collapse;font-size:0.85rem;">
      <thead>
        <tr style="background:var(--green-dark);color:#fff;">
          <th style="padding:0.5rem 0.75rem;text-align:left;">Week</th>
          <th style="padding:0.5rem 0.75rem;text-align:left;">Team 1</th>
          <th style="padding:0.5rem 0.75rem;text-align:center;">Sets</th>
          <th style="padding:0.5rem 0.75rem;text-align:left;">Team 2</th>
          <th style="padding:0.5rem 0.75rem;text-align:center;">Action</th>
        </tr>
      </thead>
      <tbody>
  `

  for (const m of matches) {
    const t1names = [memberMap[m.team1_player1], memberMap[m.team1_player2]].filter(Boolean).join(' & ')
    const t2names = [memberMap[m.team2_player1], memberMap[m.team2_player2]].filter(Boolean).join(' & ')
    const sets = []
    if (m.team1_set1 !== null) sets.push(`${m.team1_set1}–${m.team2_set1}`)
    if (m.team1_set2 !== null) sets.push(`${m.team1_set2}–${m.team2_set2}`)
    if (m.team1_set3 !== null) sets.push(`${m.team1_set3}–${m.team2_set3}`)

    html += `
      <tr style="border-bottom:1px solid var(--gray-200);">
        <td style="padding:0.5rem 0.75rem;">${m.week_label}</td>
        <td style="padding:0.5rem 0.75rem;">${t1names}</td>
        <td style="padding:0.5rem 0.75rem;text-align:center;">${sets.join(', ')}</td>
        <td style="padding:0.5rem 0.75rem;">${t2names}</td>
        <td style="padding:0.5rem 0.75rem;text-align:center;">
          <button class="btn btn-danger" style="padding:0.25rem 0.65rem;font-size:0.8rem;"
                  onclick="deleteMatch('${m.id}')">Delete</button>
        </td>
      </tr>
    `
  }

  html += '</tbody></table>'
  container.innerHTML = html
}

// Exposed globally for inline onclick
window.deleteMatch = async function(id) {
  if (!confirm('Delete this match? This cannot be undone.')) return
  const { error } = await supabase.from('matches').delete().eq('id', id)
  if (error) alert('Failed to delete match.')
  else renderRecentMatches()
}
