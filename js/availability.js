// =============================================
//  Availability page logic
// =============================================

import { supabase } from './supabase-client.js'

/**
 * Returns the Monday of the week containing `date`.
 */
function getMonday(date) {
  const d = new Date(date)
  const day = d.getDay()
  const diff = d.getDate() - day + (day === 0 ? -6 : 1)
  d.setDate(diff)
  d.setHours(0, 0, 0, 0)
  return d
}

/**
 * Formats a Date as YYYY-MM-DD for Supabase queries.
 */
function toISO(date) {
  return date.toISOString().split('T')[0]
}

/**
 * Returns a human-readable label for a week starting on `monday`.
 * e.g. "Week of Mar 3 – Mar 9"
 */
function weekLabel(monday) {
  const opts = { month: 'long', day: 'numeric' }
  return monday.toLocaleDateString('en-US', opts)
}

/**
 * Builds the next N upcoming Mondays, always starting from next week's Monday.
 * This ensures availability is always shown for future weeks, not the current week.
 */
const SEASON_END = new Date('2026-03-30T23:59:59')

function upcomingWeeks(count = 4) {
  const today = new Date()
  const thisMonday = getMonday(today)
  const startMonday = new Date(thisMonday)
  startMonday.setDate(startMonday.getDate() + 7) // always next week
  // On Sundays the "next Monday" is only 1 day away — skip an extra week
  if (today.getDay() === 0) startMonday.setDate(startMonday.getDate() + 7)

  const weeks = []
  for (let i = 0; i < count; i++) {
    const d = new Date(startMonday)
    d.setDate(d.getDate() + i * 7)
    if (d > SEASON_END) break
    weeks.push(d)
  }
  return weeks
}

export async function loadAvailability(memberId, isAdmin) {
  const container = document.getElementById('availability-container')
  const weeks = upcomingWeeks(4)
  const weekKeys = weeks.map(toISO)

  // Load existing availability responses for this member
  const { data: existing, error } = await supabase
    .from('availability')
    .select('week_start, is_available, note')
    .eq('member_id', memberId)
    .in('week_start', weekKeys)

  if (error) {
    container.innerHTML = '<div class="alert alert-error">Failed to load availability. Please try again.</div>'
    return
  }

  const existingMap = Object.fromEntries(
    (existing || []).map(r => [r.week_start, r])
  )

  let html = `
    <div class="avail-actions">
      <button class="btn-mark-all" id="mark-all-btn">✓ Mark All Available</button>
    </div>
  `
  for (const monday of weeks) {
    const key = toISO(monday)
    const current = existingMap[key]
    const isAvail = current?.is_available ?? null
    const note    = current?.note ?? ''

    html += `
      <div class="availability-week card">
        <div class="week-header">
          <div class="week-date-label">${weekLabel(monday)}</div>
        </div>
        <div class="avail-toggle">
          <button class="avail-btn ${isAvail === true ? 'selected-yes' : ''}"
                  data-week="${key}" data-val="yes">
            ✓ Available
          </button>
          <button class="avail-btn ${isAvail === false ? 'selected-no' : ''}"
                  data-week="${key}" data-val="no">
            ✗ Not Available
          </button>
        </div>
        <textarea class="avail-note hidden" id="note-${key}" rows="2"
                  placeholder="Optional note (e.g. can only do mornings)">${note}</textarea>
      </div>
    `
  }

  html += `
    <div id="save-status" class="alert hidden"></div>
    <button class="save-btn" id="save-avail-btn">Save Availability</button>
  `
  container.innerHTML = html

  // Show note field when "Available" is selected
  container.querySelectorAll('.avail-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const week = btn.dataset.week
      const val  = btn.dataset.val
      // Update button states
      container.querySelectorAll(`.avail-btn[data-week="${week}"]`).forEach(b => {
        b.classList.remove('selected-yes', 'selected-no')
      })
      btn.classList.add(val === 'yes' ? 'selected-yes' : 'selected-no')
      // Toggle note
      const noteEl = document.getElementById(`note-${week}`)
      if (val === 'yes') noteEl.classList.remove('hidden')
      else noteEl.classList.add('hidden')
    })
    // Show note if already available
    if (btn.dataset.val === 'yes' && btn.classList.contains('selected-yes')) {
      document.getElementById(`note-${btn.dataset.week}`)?.classList.remove('hidden')
    }
  })

  // Mark All Available button
  document.getElementById('mark-all-btn').addEventListener('click', () => {
    container.querySelectorAll('.avail-btn[data-val="yes"]').forEach(btn => btn.click())
  })

  // Save button
  document.getElementById('save-avail-btn').addEventListener('click', async () => {
    const saveBtn  = document.getElementById('save-avail-btn')
    const statusEl = document.getElementById('save-status')
    saveBtn.disabled = true
    saveBtn.textContent = 'Saving…'
    statusEl.classList.add('hidden')

    const upserts = []
    for (const monday of weeks) {
      const key = toISO(monday)
      const selectedBtn = container.querySelector(`.avail-btn[data-week="${key}"].selected-yes, .avail-btn[data-week="${key}"].selected-no`)
      if (!selectedBtn) continue // not answered yet, skip

      const isAvailable = selectedBtn.dataset.val === 'yes'
      const note = document.getElementById(`note-${key}`)?.value.trim() || null

      upserts.push({
        member_id:    memberId,
        week_start:   key,
        is_available: isAvailable,
        note
      })
    }

    if (upserts.length === 0) {
      statusEl.textContent = 'Please select your availability for at least one week.'
      statusEl.className = 'alert alert-info'
      statusEl.classList.remove('hidden')
      saveBtn.disabled = false
      saveBtn.textContent = 'Save Availability'
      return
    }

    const { error } = await supabase
      .from('availability')
      .upsert(upserts, { onConflict: 'member_id,week_start' })

    if (error) {
      statusEl.textContent = 'Error saving. Please try again.'
      statusEl.className = 'alert alert-error'
    } else {
      statusEl.textContent = 'Availability saved!'
      statusEl.className = 'alert alert-success'
    }
    statusEl.classList.remove('hidden')
    saveBtn.disabled = false
    saveBtn.textContent = 'Save Availability'
  })
}

/**
 * Returns current season members: those in member_seasons for 2025-26
 * plus any members explicitly included (e.g. Rockman with 0 outings).
 */
async function getCurrentSeasonMembers() {
  const [seasonRes, extraRes] = await Promise.all([
    supabase.from('member_seasons').select('member_id').eq('season', '2025-26'),
    supabase.from('members').select('id').eq('full_name', 'Rockman')
  ])
  const ids = [
    ...(seasonRes.data || []).map(r => r.member_id),
    ...(extraRes.data || []).map(r => r.id)
  ]
  const { data } = await supabase
    .from('members').select('id, full_name').in('id', ids).order('full_name')
  return data || []
}

/**
 * Tally view: shown to all members — aggregate counts + names per week.
 */
export async function loadAvailabilityTally(container) {
  const weeks = upcomingWeeks(4)
  const weekKeys = weeks.map(toISO)

  const members = await getCurrentSeasonMembers()
  const memberMap = Object.fromEntries(members.map(m => [m.id, m.full_name]))

  const { data: avail, error } = await supabase
    .from('availability')
    .select('member_id, week_start, is_available')
    .in('week_start', weekKeys)
    .in('member_id', members.map(m => m.id))

  if (error) {
    container.innerHTML = '<div class="alert alert-error">Failed to load tally.</div>'
    return
  }

  let html = '<h2 class="tally-title">League Availability</h2>'
  for (const monday of weeks) {
    const key = toISO(monday)
    const weekAvail = (avail || []).filter(a => a.week_start === key)
    const yesNames = weekAvail.filter(a => a.is_available).map(a => memberMap[a.member_id]).filter(Boolean)
    const noNames  = weekAvail.filter(a => !a.is_available).map(a => memberMap[a.member_id]).filter(Boolean)
    const respondedIds = new Set(weekAvail.map(a => a.member_id))
    const pending = members.filter(m => !respondedIds.has(m.id)).length

    html += `
      <div class="tally-week card">
        <div class="tally-week-label">${weekLabel(monday)}</div>
        <div class="tally-rows">
          <div class="tally-yes">✓ ${yesNames.length} available${yesNames.length ? ': ' + yesNames.join(', ') : ''}</div>
          ${noNames.length ? `<div class="tally-no">✗ ${noNames.length} not available: ${noNames.join(', ')}</div>` : ''}
          <div class="tally-pending">? ${pending} no response</div>
        </div>
      </div>
    `
  }
  container.innerHTML = html
}

/**
 * Admin view: loads all members' availability for upcoming weeks.
 */
export async function loadAdminAvailability(container, weekCount = 4) {
  const weeks = upcomingWeeks(weekCount)
  const weekKeys = weeks.map(toISO)

  const [members, availRes] = await Promise.all([
    getCurrentSeasonMembers(),
    supabase.from('availability').select('member_id, week_start, is_available, note').in('week_start', weekKeys)
  ])

  if (availRes.error) {
    container.innerHTML += '<div class="alert alert-error">Failed to load availability data.</div>'
    return
  }

  const availMap = {}
  for (const a of availRes.data) {
    availMap[`${a.member_id}_${a.week_start}`] = a
  }

  let html = `
    <table class="avail-grid">
      <thead>
        <tr>
          <th>Player</th>
          ${weeks.map(w => `<th>${weekLabel(w)}</th>`).join('')}
        </tr>
      </thead>
      <tbody>
  `

  for (const m of members) {
    html += `<tr><td>${m.full_name}</td>`
    for (const monday of weeks) {
      const key = `${m.id}_${toISO(monday)}`
      const a = availMap[key]
      if (!a) {
        html += `<td class="avail-pending">No response</td>`
      } else if (a.is_available) {
        html += `<td class="avail-yes">✓ Yes${a.note ? ` <span style="color:var(--gray-600);font-weight:400">— ${a.note}</span>` : ''}</td>`
      } else {
        html += `<td class="avail-no">✗ No</td>`
      }
    }
    html += '</tr>'
  }

  html += '</tbody></table>'
  container.innerHTML += html
}
