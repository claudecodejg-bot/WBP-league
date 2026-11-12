// =============================================
//  Settle up — who owes whom after a night
// =============================================
//  The week resets; the site remembers. After each Monday this works out
//  what the transfers would be if the picks had been for real money, and
//  then everyone is square again. There is no running tab to carry, which
//  is the whole reason the picks board has no bankroll in it.
//
//  Nothing here is a write, with one exception: an admin can void a court
//  whose result cannot be matched to the pairing people bet on. Everything
//  else is derived in SQL — see v_settle_week and v_court_results in
//  add-picks.sql — so this file does no money arithmetic at all. Two
//  implementations of the same rule is one too many.
//
//  PAIRWISE, NOT MINIMAL
//
//  The transfers are per pair of people, deliberately not the smallest set
//  of payments that would clear the board. Debt simplification produces
//  fewer payments and confusing ones — "why am I paying Dolan when I bet
//  against Ridder?" Everyone can check a pairwise number against the picks
//  they remember making, which matters more here than saving a Venmo.

import { supabase, escapeHtml, connectionErrorHtml } from './supabase-client.js?v=2d21059e'
import { CURRENT_SEASON } from './config.js?v=d82921ce'

let _container = null
let _member    = null

let _pairs      = []           // v_settle_week
let _memberNets = []           // v_settle_week_member
let _season     = []           // v_settle_season
let _unresolved = []           // v_pick_results rows with no winner yet
let _nameById   = {}
let _nights     = []
let _showing    = null         // played_on being shown

function name(id) {
  return _nameById[id] || 'Unknown'
}

function money(cents) {
  const n = Math.abs(Number(cents)) / 100
  return '$' + (Number.isInteger(n)
    ? n.toLocaleString()
    : n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }))
}

/** A date string as "Mon, Nov 10" — parsed as local, not UTC. */
function prettyDate(iso) {
  const [y, m, d] = String(iso).split('-').map(Number)
  return new Date(y, m - 1, d).toLocaleDateString('en-US',
    { weekday: 'short', month: 'short', day: 'numeric' })
}

function todayISO() {
  const d   = new Date()
  const pad = n => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

// ── Data ────────────────────────────────────────────────────────────────

async function fetchAll() {
  const [pairsRes, netsRes, seasonRes, membersRes, openRes] = await Promise.all([
    supabase.from('v_settle_week')
      .select('played_on, a, b, a_name, b_name, a_net_cents')
      .eq('season', CURRENT_SEASON),
    supabase.from('v_settle_week_member')
      .select('played_on, member_id, net_cents')
      .eq('season', CURRENT_SEASON),
    supabase.from('v_settle_season')
      .select('member_id, net_cents, nights')
      .eq('season', CURRENT_SEASON),
    supabase.from('members').select('id, full_name'),
    // Matched picks with no result yet. A past night still showing these
    // means a court could not be tied to a recorded match — the four
    // recorded players differ from the four scheduled, whether through a
    // fill-in or a partner swap — and somebody has to decide, not guess.
    supabase.from('v_pick_results')
      .select('court_id, played_on, court_no, poster, taker, poster_risk_cents, taker_risk_cents')
      .eq('season', CURRENT_SEASON)
      .is('winner', null)
  ])

  for (const res of [pairsRes, netsRes, seasonRes, membersRes, openRes]) {
    if (res.error) throw res.error
  }

  _pairs      = pairsRes.data   || []
  _memberNets = netsRes.data    || []
  _season     = seasonRes.data  || []
  _nameById   = Object.fromEntries((membersRes.data || []).map(m => [m.id, m.full_name]))
  _unresolved = (openRes.data   || []).filter(r => r.played_on < todayISO())

  _nights = [...new Set(_memberNets.map(r => r.played_on))].sort().reverse()
  if (!_showing || !_nights.includes(_showing)) _showing = _nights[0] || null
}

// ── Render ──────────────────────────────────────────────────────────────

function renderPicker() {
  if (_nights.length <= 1) return ''
  return `<div class="settle-picker">
    <label for="settle-night">Night</label>
    <select id="settle-night">
      ${_nights.map(n => `<option value="${escapeHtml(n)}"${n === _showing ? ' selected' : ''}>
        ${escapeHtml(prettyDate(n))}</option>`).join('')}
    </select>
  </div>`
}

/** The transfers for one night, each as a sentence with a direction. */
function renderTransfers(night) {
  const rows = _pairs.filter(p => p.played_on === night)
  if (!rows.length) {
    return `<p class="settle-empty">Everyone came out level that night &mdash; nothing to move.</p>`
  }

  // Biggest first: the ones people will actually talk about.
  const sorted = [...rows].sort((x, y) =>
    Math.abs(y.a_net_cents) - Math.abs(x.a_net_cents))

  return `<ul class="settle-transfers">${sorted.map(p => {
    // a_net_cents positive means b pays a.
    const payer = p.a_net_cents > 0 ? p.b_name : p.a_name
    const payee = p.a_net_cents > 0 ? p.a_name : p.b_name
    const mine  = _member && (p.a === _member.id || p.b === _member.id)
    return `<li class="settle-transfer${mine ? ' settle-transfer-mine' : ''}">
      <span class="settle-payer">${escapeHtml(payer)}</span>
      <span class="settle-arrow" aria-hidden="true">&rarr;</span>
      <span class="settle-payee">${escapeHtml(payee)}</span>
      <strong class="settle-amount">${money(p.a_net_cents)}</strong>
    </li>`
  }).join('')}</ul>`
}

/** Where each player finished for the night. */
function renderNightTable(night) {
  const rows = _memberNets
    .filter(r => r.played_on === night)
    .sort((x, y) => y.net_cents - x.net_cents)

  if (!rows.length) return ''

  return `<table class="data-table settle-table">
    <thead><tr><th>Player</th><th class="num">Night</th></tr></thead>
    <tbody>${rows.map(r => `<tr${_member && r.member_id === _member.id ? ' class="settle-row-mine"' : ''}>
      <td>${escapeHtml(name(r.member_id))}</td>
      <td class="num ${r.net_cents > 0 ? 'settle-up' : r.net_cents < 0 ? 'settle-down' : ''}">
        ${r.net_cents > 0 ? '+' : r.net_cents < 0 ? '&minus;' : ''}${money(r.net_cents)}
      </td></tr>`).join('')}</tbody>
  </table>`
}

function renderSeason() {
  if (!_season.length) return ''
  const rows = [..._season].sort((x, y) => y.net_cents - x.net_cents)

  return `<section class="settle-section">
    <h2>Season so far</h2>
    <p class="settle-sub">Settling weekly squares the debt. It doesn't erase the scoreboard.</p>
    <table class="data-table settle-table">
      <thead><tr><th>Player</th><th class="num">Nights</th><th class="num">Net</th></tr></thead>
      <tbody>${rows.map(r => `<tr${_member && r.member_id === _member.id ? ' class="settle-row-mine"' : ''}>
        <td>${escapeHtml(name(r.member_id))}</td>
        <td class="num">${r.nights}</td>
        <td class="num ${r.net_cents > 0 ? 'settle-up' : r.net_cents < 0 ? 'settle-down' : ''}">
          ${r.net_cents > 0 ? '+' : r.net_cents < 0 ? '&minus;' : ''}${money(r.net_cents)}
        </td></tr>`).join('')}</tbody>
    </table>
  </section>`
}

/**
 * Courts that were played but whose picks cannot be settled, because no
 * recorded match has the same four players in the same two partnerships.
 * A fill-in does this, and so does the same four swapping partners.
 * Voiding is the honest answer — the picks were made on a pairing that did
 * not take the court — and only an admin can.
 */
function renderUnresolved() {
  if (!_unresolved.length) return ''

  const courts = new Map()
  for (const r of _unresolved) {
    if (!courts.has(r.court_id)) {
      courts.set(r.court_id, { ...r, picks: 0 })
    }
    courts.get(r.court_id).picks += 1
  }

  return `<section class="settle-section settle-unresolved">
    <h2>Waiting on a result</h2>
    <p class="settle-sub">
      These courts have picks on them but no recorded result with the same
      four players in the same two partnerships &mdash; a fill-in, or the
      pairs swapped at the courts. They are not in any number above. Once a
      score is entered for the pairing people actually bet on they settle
      themselves; if that pairing never took the court, it needs voiding.
    </p>
    <ul class="settle-open-list">
      ${[...courts.values()].map(c => `<li>
        <span>${escapeHtml(prettyDate(c.played_on))} &middot; Court ${c.court_no}
          &middot; ${c.picks} pick${c.picks === 1 ? '' : 's'}</span>
        ${_member?.is_admin
          ? `<button class="btn btn-sm btn-secondary" data-void="${c.court_id}">Void it</button>`
          : ''}
      </li>`).join('')}
    </ul>
  </section>`
}

function render() {
  if (!_nights.length && !_unresolved.length) {
    _container.innerHTML = `
      <div class="empty-state">
        <p>Nothing to settle yet.</p>
        <p class="settle-empty">This fills in after the first Monday with picks on
          the <a href="picks.html">board</a>.</p>
      </div>
      ${renderSeason()}`
    return
  }

  const night = _showing
  _container.innerHTML = `
    ${night ? `<section class="settle-section">
      <div class="settle-head">
        <h2>${escapeHtml(prettyDate(night))}</h2>
        ${renderPicker()}
      </div>
      ${renderTransfers(night)}
      ${renderNightTable(night)}
    </section>` : ''}
    ${renderUnresolved()}
    ${renderSeason()}`
}

// ── Actions ─────────────────────────────────────────────────────────────

function flash(message, kind = 'error') {
  const el = document.getElementById('settle-flash')
  if (!el) return
  el.className   = `alert alert-${kind}`
  el.textContent = message
  el.hidden      = false
  window.clearTimeout(flash._t)
  flash._t = window.setTimeout(() => { el.hidden = true }, 7000)
}

async function onVoid(courtId) {
  const { data, error } = await supabase.rpc('void_court', { p_court_id: courtId })
  if (error) return flash(error.message)

  const n = Number(data)
  flash(`Voided. ${n} pick${n === 1 ? '' : 's'} struck off — nobody owes anybody on that court.`,
        'success')
  await fetchAll()
  render()
}

// ── Entry point ─────────────────────────────────────────────────────────

export async function loadSettle(container, member) {
  _container = container
  _member    = member || null

  try {
    await fetchAll()
    render()
  } catch (err) {
    _container.innerHTML = connectionErrorHtml()
    return
  }

  _container.addEventListener('click', async event => {
    const kill = event.target.closest('[data-void]')
    if (kill) { event.preventDefault(); await onVoid(kill.dataset.void) }
  })

  _container.addEventListener('change', event => {
    if (event.target.id === 'settle-night') {
      _showing = event.target.value
      render()
    }
  })
}
