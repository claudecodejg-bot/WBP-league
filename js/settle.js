// =============================================
//  Settle up — the running tab, and the log behind it
// =============================================
//  The tab RUNS. Monday's picks are added to what was already owed, and
//  it keeps running until an admin says the money has changed hands —
//  which writes a date to settle_marks and nothing else. The picks are
//  never touched, so a clearing made by mistake can be taken back and
//  every number comes straight back.
//
//  Nothing else here is a write. The money arithmetic is all in SQL —
//  v_pick_results, v_settle_week, v_court_results in add-picks.sql — so
//  this file sums already-settled numbers and never computes one. Two
//  implementations of the same rule is one too many.
//
//  PAIRWISE, NOT MINIMAL
//
//  The transfers are per pair of people, deliberately not the smallest
//  set of payments that would clear the board. Debt simplification
//  produces fewer payments and confusing ones — "why am I paying Dolan
//  when I bet against Ridder?" Everyone can check a pairwise number
//  against the picks they remember making, which matters more here than
//  saving a Venmo. Over several weeks it matters more still, because the
//  log below has to agree with it line by line.

import { supabase, escapeHtml, connectionErrorHtml } from './supabase-client.js?v=2d21059e'
import { CURRENT_SEASON } from './config.js?v=d82921ce'

let _container = null
let _member    = null

let _pairs      = []           // v_settle_week, every night of the season
let _memberNets = []           // v_settle_week_member
let _season     = []           // v_settle_season
let _picks      = []           // v_pick_results — the log
let _courts     = {}           // court_id -> scheduled_courts row
let _nameById   = {}
let _nights     = []           // nights with settled money, newest first

// The last night that counts as paid, or null if the tab has never been
// cleared. _marksOk is false when settle_marks is not in the database
// yet, which is the window between this file shipping and the SQL being
// run: the page has to carry on rather than show a connection error.
let _settledThrough = null
let _marksOk        = false

let _showAll = false           // include already-settled nights in the log

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
  if (!y || !m || !d) return String(iso ?? '')
  return new Date(y, m - 1, d).toLocaleDateString('en-US',
    { weekday: 'short', month: 'short', day: 'numeric' })
}

function todayISO() {
  const d   = new Date()
  const pad = n => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

/**
 * Is this night on the open tab? ISO dates compare correctly as strings,
 * so no Date objects and no timezone to get wrong.
 */
function isOpen(playedOn) {
  return !_settledThrough || String(playedOn) > _settledThrough
}

/** The two names on one side of a court. */
function sideNames(court, side) {
  if (!court) return ''
  return side === 1
    ? `${name(court.t1p1)} & ${name(court.t1p2)}`
    : `${name(court.t2p1)} & ${name(court.t2p2)}`
}

// ── Data ────────────────────────────────────────────────────────────────

async function fetchAll() {
  const [pairsRes, netsRes, seasonRes, membersRes, picksRes, courtsRes, marksRes] =
    await Promise.all([
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
      // Every matched pick of the season — the log, and the source of
      // the "waiting on a result" list, which is the same rows with no
      // winner on them.
      supabase.from('v_pick_results')
        .select('fill_id, court_id, played_on, court_no, poster, taker, poster_side, ' +
                'poster_risk_cents, taker_risk_cents, winner, amount_cents')
        .eq('season', CURRENT_SEASON)
        .order('played_on', { ascending: false }),
      // For the side a taker actually backed. The view carries the court
      // id but not its four players.
      supabase.from('scheduled_courts')
        .select('id, t1p1, t1p2, t2p1, t2p2')
        .eq('season', CURRENT_SEASON),
      supabase.from('settle_marks')
        .select('settled_through, created_at')
        .eq('season', CURRENT_SEASON)
        .order('settled_through', { ascending: false })
        .limit(1)
    ])

  for (const res of [pairsRes, netsRes, seasonRes, membersRes, picksRes, courtsRes]) {
    if (res.error) throw res.error
  }

  _pairs      = pairsRes.data   || []
  _memberNets = netsRes.data    || []
  _season     = seasonRes.data  || []
  _picks      = picksRes.data   || []
  _nameById   = Object.fromEntries((membersRes.data || []).map(m => [m.id, m.full_name]))
  _courts     = Object.fromEntries((courtsRes.data  || []).map(c => [c.id, c]))

  // Deliberately NOT fatal. If add-settle-marks.sql has not been run the
  // table is missing and this errors; the tab then simply runs from the
  // start of the season, which is the right answer for a league that has
  // never cleared it.
  _marksOk = !marksRes.error
  _settledThrough = _marksOk ? (marksRes.data?.[0]?.settled_through ?? null) : null

  _nights = [...new Set(_memberNets.map(r => r.played_on))].sort().reverse()
}

/** Matched picks on a night that has been and gone with no result. */
function unresolved() {
  const today = todayISO()
  return _picks.filter(p => p.winner === null && p.played_on < today)
}

// ── The tab ─────────────────────────────────────────────────────────────

/**
 * Every open night's pairwise totals added together.
 *
 * v_settle_week drops a pair that came out level on a given night, which
 * is safe to sum over: a dropped row would have contributed nothing.
 * A pair that is level ACROSS the weeks has to be dropped here instead,
 * or the tab would list a transfer of nothing.
 */
function runningPairs() {
  const byPair = new Map()

  for (const p of _pairs) {
    if (!isOpen(p.played_on)) continue
    const key = `${p.a}|${p.b}`
    const row = byPair.get(key)
    if (row) row.a_net_cents += p.a_net_cents
    else byPair.set(key, { ...p })
  }

  return [...byPair.values()].filter(p => p.a_net_cents !== 0)
}

/** Each player's net over the open nights. */
function runningNets() {
  const byMember = new Map()
  for (const r of _memberNets) {
    if (!isOpen(r.played_on)) continue
    byMember.set(r.member_id, (byMember.get(r.member_id) || 0) + r.net_cents)
  }
  return [...byMember.entries()].map(([member_id, net_cents]) => ({ member_id, net_cents }))
}

function openNights() {
  return _nights.filter(isOpen)
}

function renderTab() {
  const nights = openNights()
  const rows   = runningPairs()

  const since = _settledThrough
    ? `Since ${escapeHtml(prettyDate(_settledThrough))}`
    : 'Everything so far'
  const count = nights.length === 1 ? '1 night' : `${nights.length} nights`

  let body
  if (!nights.length) {
    // Two different nothings. Before the first result of the season there
    // is nothing to settle; after a clearing there is nothing LEFT. Saying
    // "since the tab was cleared" when it never has been is a small lie
    // that makes the whole page look like it is guessing.
    body = `<p class="settle-empty">${_settledThrough
      ? 'All square. Nothing has been played since the tab was cleared.'
      : 'Nothing has settled yet. This fills in once a Monday has a score on it.'}</p>`
  } else if (!rows.length) {
    body = `<p class="settle-empty">Everyone has come out level &mdash; nothing to move.</p>`
  } else {
    // Biggest first: the ones people will actually talk about.
    const sorted = [...rows].sort((x, y) =>
      Math.abs(y.a_net_cents) - Math.abs(x.a_net_cents))

    body = `<ul class="settle-transfers">${sorted.map(p => {
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

  // Only an admin, only once there is a night to clear, and only when the
  // table is actually there to write to.
  const canClear = _member?.is_admin && _marksOk && nights.length > 0
  const clearBtn = canClear
    ? `<button class="btn btn-sm btn-secondary" data-paid="${escapeHtml(nights[0])}">
         Everyone&rsquo;s paid up
       </button>`
    : ''
  const undoBtn = (_member?.is_admin && _marksOk && _settledThrough)
    ? `<button class="btn-link" data-unmark="1">Undo last clearing</button>`
    : ''

  return `<section class="settle-section">
    <div class="settle-head">
      <h2>The tab</h2>
      <span class="settle-since">${since}${nights.length ? ` &middot; ${count}` : ''}</span>
    </div>
    ${body}
    ${renderStandings()}
    ${(clearBtn || undoBtn)
      ? `<div class="settle-actions">${clearBtn}${undoBtn}</div>`
      : ''}
  </section>`
}

/** Where everyone stands on the open tab — the "am I up?" glance. */
function renderStandings() {
  const rows = runningNets()
    .filter(r => r.net_cents !== 0)
    .sort((x, y) => y.net_cents - x.net_cents)

  if (!rows.length) return ''

  return `<table class="data-table settle-table">
    <thead><tr><th>Player</th><th class="num">On the tab</th></tr></thead>
    <tbody>${rows.map(r => `<tr${_member && r.member_id === _member.id ? ' class="settle-row-mine"' : ''}>
      <td>${escapeHtml(name(r.member_id))}</td>
      <td class="num ${r.net_cents > 0 ? 'settle-up' : 'settle-down'}">
        ${r.net_cents > 0 ? '+' : '&minus;'}${money(r.net_cents)}
      </td></tr>`).join('')}</tbody>
  </table>`
}

// ── The log ─────────────────────────────────────────────────────────────

/**
 * Every matched pick, newest night first. This is the evidence behind
 * the tab: each line is one bet, and the amounts on it add up to the
 * transfers above.
 *
 * A taker always backs the opposite side to the poster, so the side is
 * derived rather than stored — there is no third place for it to be
 * wrong.
 */
function renderLog() {
  const settledNights = _nights.filter(n => !isOpen(n))
  const picks = _picks.filter(p => _showAll || isOpen(p.played_on))

  // Built before the empty check, not inside the branch that draws rows:
  // the moment the tab is cleared every night is hidden, and a toggle that
  // only exists when something is showing is a door that locks behind you.
  const toggle = settledNights.length
    ? `<button class="btn-link" data-showall="${_showAll ? '0' : '1'}">
         ${_showAll
           ? 'Hide settled nights'
           : `Show the ${settledNights.length} settled night${settledNights.length === 1 ? '' : 's'}`}
       </button>`
    : ''

  if (!picks.length) {
    return `<section class="settle-section">
      <div class="settle-head"><h2>The log</h2>${toggle}</div>
      <p class="settle-empty">${settledNights.length
        ? 'Every night so far is settled.'
        : 'No picks have been matched yet.'}</p>
    </section>`
  }

  // Group by night, newest first.
  const nights = []
  for (const p of picks) {
    let night = nights.find(n => n.played_on === p.played_on)
    if (!night) { night = { played_on: p.played_on, picks: [] }; nights.push(night) }
    night.picks.push(p)
  }
  nights.sort((x, y) => (x.played_on < y.played_on ? 1 : -1))

  const body = nights.map(night => {
    const settled = !isOpen(night.played_on)
    const rows = [...night.picks]
      .sort((x, y) => (x.court_no || 0) - (y.court_no || 0))
      .map(p => {
        const court      = _courts[p.court_id]
        const takerSide  = p.poster_side === 1 ? 2 : 1
        const backed     = sideNames(court, takerSide)

        let out
        if (p.winner === null) {
          // A pick on a Monday still to come is riding, not stuck. Only
          // one on a night that has been and gone is waiting on anything,
          // and that is the case the panel above is about.
          out = `<span class="settle-log-out settle-log-pending">${
            p.played_on >= todayISO() ? 'riding' : 'no result yet'}</span>`
        } else {
          const won = p.winner === p.taker
          out = `<span class="settle-log-out ${won ? 'settle-up' : 'settle-down'}">
            ${escapeHtml(name(p.winner))} +${money(p.amount_cents)}</span>`
        }

        const mine = _member && (p.taker === _member.id || p.poster === _member.id)
        return `<li class="settle-log-row${mine ? ' settle-log-mine' : ''}">
          <span class="settle-log-court">C${p.court_no ?? '?'}</span>
          <span class="settle-log-what">
            <strong>${escapeHtml(name(p.taker))}</strong>${backed
              ? ` on <strong>${escapeHtml(backed)}</strong>` : ''},
            ${money(p.taker_risk_cents)} to win ${money(p.poster_risk_cents)},
            v ${escapeHtml(name(p.poster))}
          </span>
          ${out}
        </li>`
      }).join('')

    return `<div class="settle-log-night${settled ? ' settle-log-night-settled' : ''}">
      <h3 class="settle-log-date">${escapeHtml(prettyDate(night.played_on))}${
        settled ? ' <span class="settle-log-paid">paid</span>' : ''}</h3>
      <ul class="settle-log-list">${rows}</ul>
    </div>`
  }).join('')

  return `<section class="settle-section">
    <div class="settle-head">
      <h2>The log</h2>
      ${toggle}
    </div>
    ${body}
  </section>`
}

// ── The rest of the page ────────────────────────────────────────────────

function renderSeason() {
  if (!_season.length) return ''
  const rows = [..._season].sort((x, y) => y.net_cents - x.net_cents)

  return `<section class="settle-section">
    <h2>Season so far</h2>
    <p class="settle-sub">Every night of ${escapeHtml(CURRENT_SEASON)}, paid or not.
      Clearing the tab squares the debt; it doesn't erase the scoreboard.</p>
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
 * Voiding is the honest answer — the picks were made on a pairing that
 * did not take the court — and only an admin can.
 */
function renderUnresolved() {
  const open = unresolved()
  if (!open.length) return ''

  const courts = new Map()
  for (const r of open) {
    if (!courts.has(r.court_id)) courts.set(r.court_id, { ...r, picks: 0 })
    courts.get(r.court_id).picks += 1
  }

  return `<section class="settle-section settle-unresolved">
    <h2>Waiting on a result</h2>
    <p class="settle-sub">
      These courts have picks on them but no recorded result with the same
      four players in the same two partnerships &mdash; a fill-in, or the
      pairs swapped at the courts. They are not on the tab. Once a score is
      entered for the pairing people actually bet on they settle themselves;
      if that pairing never took the court, it needs voiding.
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
  if (!_nights.length && !_picks.length) {
    _container.innerHTML = `
      <div class="empty-state">
        <p>Nothing on the tab yet.</p>
        <p class="settle-empty">This fills in after the first Monday with picks on
          the <a href="picks.html">board</a>.</p>
      </div>`
    return
  }

  _container.innerHTML = `
    ${renderTab()}
    ${renderUnresolved()}
    ${renderLog()}
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
  await refresh()
}

async function onMarkPaid(through) {
  // A court with no result yet is not on the tab. Clear past it and it
  // never will be: a score entered next week lands on a night that is
  // already marked paid, and that money silently disappears instead of
  // appearing on anyone's total. So the clearing waits — and the way
  // out of it is one click away in the panel above, which is exactly
  // what Void it is for.
  const stuck = unresolved().filter(p => p.played_on <= through)
  if (stuck.length) {
    const courts = new Set(stuck.map(p => p.court_id))
    return flash(
      `${courts.size} court${courts.size === 1 ? '' : 's'} up there still ` +
      `${courts.size === 1 ? 'has' : 'have'} picks with no result — ` +
      `${stuck.length} of them. Enter the score or void the court first, or that ` +
      `money never lands on anybody's tab.`)
  }

  const nights = openNights()
  if (!confirm(
    `Clear the tab through ${prettyDate(through)}?\n\n` +
    `${nights.length} night${nights.length === 1 ? '' : 's'} come off the running total. ` +
    `No picks are changed, and this can be undone.`)) return

  const { error } = await supabase.rpc('settle_mark_paid', {
    p_season:  CURRENT_SEASON,
    p_through: through
  })
  if (error) return flash(error.message)

  flash(`Cleared through ${prettyDate(through)}. The tab starts again from the next Monday.`,
        'success')
  await refresh()
}

async function onUnmark() {
  const { data, error } = await supabase.rpc('settle_unmark', { p_season: CURRENT_SEASON })
  if (error) return flash(error.message)

  flash(data
    ? `Put back. The tab runs from after ${prettyDate(data)} again.`
    : 'Put back. The tab runs from the start of the season again.', 'success')
  await refresh()
}

async function refresh() {
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

  // One delegated listener for the whole page, so it survives every
  // re-render without rebinding.
  _container.addEventListener('click', async event => {
    const kill    = event.target.closest('[data-void]')
    const paid    = event.target.closest('[data-paid]')
    const unmark  = event.target.closest('[data-unmark]')
    const showall = event.target.closest('[data-showall]')

    if (kill)   { event.preventDefault(); await onVoid(kill.dataset.void) }
    if (paid)   { event.preventDefault(); await onMarkPaid(paid.dataset.paid) }
    if (unmark) { event.preventDefault(); await onUnmark() }
    if (showall) {
      event.preventDefault()
      _showAll = showall.dataset.showall === '1'
      render()
    }
  })
}
