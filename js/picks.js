// =============================================
//  Picks — the peer-to-peer book for a night's courts
// =============================================
//  Someone offers a side at a price; anyone else takes the other side for
//  part or all of it. Play money, settled up weekly on settle.html.
//
//  THE PRICE HAS TWO NUMBERS
//
//  An offer says what the poster risks and what the poster wins. "Risk $5
//  to win $10" is 2-1. The taker's end is the exact mirror — risk $10 to
//  win $5 — so there is no third number anywhere in this file and the two
//  ends cannot disagree about the price.
//
//  Everything is in CENTS. A half fill of 2-1 on $5 is $2.50, and a number
//  that can land on a half dollar has no business being stored in whole
//  ones. Only money() and centsFrom() know about dollars.
//
//  NO BANKROLL
//
//  Nothing is held and no balance is checked. A pick is a promise between
//  two people, and after each Monday settle.html works out who owes whom.
//  So the only limits are per-offer: $1–$100 to risk, $1–$500 to win, and
//  odds inside 10-1 either way. Those are enforced in add-picks.sql — the
//  error messages shown below come straight from it.
//
//  Every write goes through an RPC. None of these tables accept an insert
//  from the browser, on purpose: "enough left on the offer, before the
//  court closes, not against your own team" needs a row lock and two
//  tables in one transaction, which no RLS policy can express.

import { supabase, escapeHtml, connectionErrorHtml } from './supabase-client.js?v=2d21059e'

let _container = null
let _member    = null          // { id, full_name, is_admin } or null when signed out

let _courts   = []
let _offers   = []
let _fills    = []
let _results  = {}             // court_id -> winning_side (1, 2 or null)
let _nameById = {}

/** YYYY-MM-DD for today, local time — not UTC, which is a day ahead at night. */
function todayISO() {
  const d   = new Date()
  const pad = n => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

/**
 * Do two clock times mean the same thing? toLocaleTimeString puts a NARROW
 * NO-BREAK SPACE (U+202F) before AM/PM on current ICU, while start_time is
 * typed by hand with an ordinary space, so a plain === quietly says no.
 */
function sameTime(a, b) {
  const norm = s => String(s ?? '').replace(/\s+/gu, ' ').trim().toUpperCase()
  return norm(a) !== '' && norm(a) === norm(b)
}

/** "Monday, November 16" — parsed as local, so it can't slip back a day. */
function prettyDate(iso) {
  const [y, m, d] = String(iso).split('-').map(Number)
  if (!y || !m || !d) return String(iso ?? '')
  return new Date(y, m - 1, d).toLocaleDateString('en-US',
    { weekday: 'long', month: 'long', day: 'numeric' })
}

function name(id) {
  return _nameById[id] || 'Unknown'
}

function pair(a, b) {
  return `${name(a)} & ${name(b)}`
}

function sideNames(court, side) {
  return side === 1 ? pair(court.t1p1, court.t1p2) : pair(court.t2p1, court.t2p2)
}

/**
 * A court is shut once its status moves on, once its start time passes, or
 * once it has a result. The last of those is belt and braces — a result
 * cannot normally land before the close time, since it comes from a match
 * that had not been played yet — but a corrected score or an early entry
 * should not reopen the book on a court whose answer is already on screen.
 */
function isClosed(court) {
  return court.status !== 'open'
      || _results[court.id] != null
      || new Date(court.closes_at) <= new Date()
}

/** Which side the signed-in member is playing on this court, or null. */
function mySide(court) {
  if (!_member) return null
  if (_member.id === court.t1p1 || _member.id === court.t1p2) return 1
  if (_member.id === court.t2p1 || _member.id === court.t2p2) return 2
  return null
}

// ── Money ───────────────────────────────────────────────────────────────

/** Cents to a readable dollar amount. Whole dollars lose the ".00". */
function money(cents) {
  const n = Number(cents) / 100
  return '$' + (Number.isInteger(n)
    ? n.toLocaleString()
    : n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }))
}

/** Reads a dollar input as whole cents, or null if it isn't a usable amount. */
function centsFrom(id) {
  const raw = document.getElementById(id)?.value
  if (raw == null) return null
  const n = parseFloat(String(raw).replace(/[$,\s]/g, ''))
  if (!Number.isFinite(n) || n <= 0) return null
  return Math.round(n * 100)
}

function gcd(a, b) {
  while (b) { [a, b] = [b, a % b] }
  return a
}

/**
 * "2-1", "3-2", "even money" — the shape people actually say out loud.
 * Falls back to a decimal against 1 when the whole-number ratio would be
 * something nobody could read, like 47-13.
 */
function oddsLabel(riskCents, winCents) {
  if (!riskCents || !winCents) return ''
  if (riskCents === winCents) return 'even money'

  const g = gcd(riskCents, winCents)
  const a = winCents  / g           // what you win
  const b = riskCents / g           // what you risk
  if (a <= 20 && b <= 20) return `${a}-${b}`

  const trim = x => String(Number(x.toFixed(2)))
  return winCents > riskCents
    ? `${trim(winCents / riskCents)}-1`
    : `1-${trim(riskCents / winCents)}`
}

// ── Data ────────────────────────────────────────────────────────────────

async function fetchAll() {
  const today = todayISO()

  // Courts still to come, plus tonight's — which may already have a result.
  const [courtsRes, membersRes] = await Promise.all([
    supabase.from('scheduled_courts')
      .select('id, season, played_on, week_label, court_no, t1p1, t1p2, t2p1, t2p2, location, start_time, closes_at, status')
      .gte('played_on', today)
      .neq('status', 'void')
      .order('played_on', { ascending: true })
      .order('court_no',  { ascending: true }),
    supabase.from('members').select('id, full_name')
  ])

  if (courtsRes.error)  throw courtsRes.error
  if (membersRes.error) throw membersRes.error

  _courts   = courtsRes.data || []
  _nameById = Object.fromEntries((membersRes.data || []).map(m => [m.id, m.full_name]))

  const courtIds = _courts.map(c => c.id)
  _offers  = []
  _fills   = []
  _results = {}
  if (courtIds.length === 0) return

  // The winner is derived from `matches` rather than stored, so it is read
  // the same way as everything else — see v_court_results in add-picks.sql.
  const [offersRes, resultsRes] = await Promise.all([
    supabase.from('wager_offers')
      .select('id, court_id, offered_by, side, risk_cents, win_cents, risk_open_cents, win_open_cents, status, created_at')
      .in('court_id', courtIds)
      .neq('status', 'void')
      // Pulled-back offers are left off the board entirely. cancel_offer
      // only leaves 'cancelled' when nothing was ever matched, so such a
      // row has no fills hanging off it and nobody owes anybody over it —
      // it is just noise between the picks that still stand. An offer
      // pulled back after a PART fill is marked 'filled', not 'cancelled',
      // so it stays: those matched picks are real and still settle.
      .neq('status', 'cancelled')
      .order('created_at', { ascending: true }),
    supabase.from('v_court_results')
      .select('court_id, winning_side')
      .in('court_id', courtIds)
  ])
  if (offersRes.error)  throw offersRes.error
  if (resultsRes.error) throw resultsRes.error

  _offers  = offersRes.data || []
  _results = Object.fromEntries((resultsRes.data || []).map(r => [r.court_id, r.winning_side]))

  const offerIds = _offers.map(o => o.id)
  if (offerIds.length === 0) return

  const fillsRes = await supabase.from('wager_fills')
    .select('id, offer_id, taker, poster_risk_cents, taker_risk_cents, created_at')
    .in('offer_id', offerIds)
    .order('created_at', { ascending: true })
  if (fillsRes.error) throw fillsRes.error
  _fills = fillsRes.data || []
}

// ── Render ──────────────────────────────────────────────────────────────

function renderSignedOutNote() {
  const el = document.getElementById('picks-note')
  if (!el) return
  el.innerHTML = _member ? '' : `<p class="picks-note">
    Anyone can read the board. <a href="login.html?next=picks.html">Sign in</a> to make a pick.</p>`
}

function fillsFor(offerId) {
  return _fills.filter(f => f.offer_id === offerId)
}

function renderOffer(court, offer, closed) {
  const backing = sideNames(court, offer.side)
  const matched = fillsFor(offer.id)
  const mine    = _member && offer.offered_by === _member.id
  const myTeam  = mySide(court)
  const won     = _results[court.id] ?? null

  // Taking this offer means taking the side it is against. If that is the
  // side you're playing on, the database will refuse it, so don't offer a
  // button that cannot work.
  const takingSide  = offer.side === 1 ? 2 : 1
  const wouldBeVsMe = myTeam !== null && myTeam !== takingSide
  const openToTake  = offer.status === 'open' && offer.win_open_cents > 0

  const canTake = !closed && _member && !mine && openToTake && !wouldBeVsMe
  const odds    = oddsLabel(offer.risk_cents, offer.win_cents)

  const out = []
  out.push(`<div class="pick-offer">
    <div class="pick-offer-head">
      <span class="pick-offer-who">${escapeHtml(name(offer.offered_by))}</span>
      backs <strong>${escapeHtml(backing)}</strong>
      &mdash; risks ${money(offer.risk_cents)} to win ${money(offer.win_cents)}
      <span class="pick-odds">${escapeHtml(odds)}</span>
    </div>`)

  if (matched.length > 0) {
    out.push(`<ul class="pick-matched">` + matched.map(f => {
      // Who came out on top of this one. Same rule as v_pick_results: the
      // poster's side winning means the poster collects.
      let tail = ''
      if (won !== null) {
        const posterWon = won === offer.side
        const winner    = posterWon ? offer.offered_by : f.taker
        const amount    = posterWon ? f.taker_risk_cents : f.poster_risk_cents
        tail = ` &middot; <span class="pick-outcome">${escapeHtml(name(winner))} +${money(amount)}</span>`
      }
      return `<li>${escapeHtml(name(f.taker))} risked ${money(f.taker_risk_cents)}
        to win ${money(f.poster_risk_cents)} on
        ${escapeHtml(sideNames(court, takingSide))}${tail}</li>`
    }).join('') + `</ul>`)
  }

  if (openToTake) {
    out.push(`<div class="pick-offer-foot">
      <span class="pick-remaining">${money(offer.win_open_cents)} of the other side still open</span>`)

    if (canTake) {
      // Default to the lot. The function fills whatever is left rather than
      // failing, so an over-ask is harmless either way.
      const dflt = (offer.win_open_cents / 100).toFixed(2).replace(/\.00$/, '')
      out.push(`
        <span class="pick-take">
          <label class="sr-only" for="take-amt-${offer.id}">Amount to risk</label>
          <span class="pick-dollar">$</span>
          <input type="number" id="take-amt-${offer.id}" class="pick-amt"
                 min="1" step="0.01" max="${dflt}" value="${dflt}" inputmode="decimal">
          <button class="btn btn-sm btn-primary" data-take="${offer.id}">
            Take ${escapeHtml(sideNames(court, takingSide))}
          </button>
        </span>`)
    } else if (wouldBeVsMe && !closed && !mine) {
      // Only worth saying to someone who might otherwise expect a button.
      out.push(`<span class="pick-blocked">You're playing this court</span>`)
    }

    if (mine && !closed) {
      out.push(`<button class="btn btn-sm btn-secondary" data-cancel="${offer.id}">Pull back</button>`)
    }
    out.push(`</div>`)
  } else if (matched.length > 0) {
    // Every other offer says how much is open, so one that says nothing
    // reads as unfinished. Deliberately not "matched in full": an offer
    // pulled back after a part fill ends up here too, and the row cannot
    // tell the two apart.
    out.push(`<div class="pick-offer-foot"><span class="pick-remaining">Nothing left to take</span></div>`)
  }

  out.push(`</div>`)
  return out.join('')
}

/**
 * The form for putting a side up. Two amounts rather than an odds box:
 * "risk 5 to win 10" is how the price gets said out loud, and it cannot be
 * read the wrong way round the way a bare "2-1" can.
 */
function renderOfferForm(court, myTeam) {
  const sides = [1, 2].filter(side => myTeam === null || myTeam === side)

  return `<div class="pick-new">
    <span class="pick-new-label">Back a side</span>
    <div class="pick-new-row">
      <label class="pick-field">
        <span>I risk</span>
        <span class="pick-dollar">$</span>
        <input type="number" id="post-risk-${court.id}" class="pick-amt" data-preview="${court.id}"
               min="1" max="100" step="0.01" value="20" inputmode="decimal">
      </label>
      <label class="pick-field">
        <span>to win</span>
        <span class="pick-dollar">$</span>
        <input type="number" id="post-win-${court.id}" class="pick-amt" data-preview="${court.id}"
               min="1" max="500" step="0.01" value="20" inputmode="decimal">
      </label>
      <span class="pick-new-on">on</span>
      ${sides.map(side => `
        <button class="btn btn-sm btn-outline" data-post="${court.id}" data-side="${side}">
          ${escapeHtml(sideNames(court, side))}
        </button>`).join('')}
    </div>
    <p class="pick-preview" id="post-preview-${court.id}"></p>
    ${myTeam !== null
      ? `<p class="pick-new-note">You're playing this court, so you can back your own team but not against it.</p>`
      : ''}
  </div>`
}

/** Spells out both ends of the price being typed, so nobody has to guess. */
function updatePreview(courtId) {
  const el = document.getElementById(`post-preview-${courtId}`)
  if (!el) return

  const risk = centsFrom(`post-risk-${courtId}`)
  const win  = centsFrom(`post-win-${courtId}`)
  if (!risk || !win) { el.textContent = ''; return }

  const odds = oddsLabel(risk, win)
  el.textContent =
    `${odds === 'even money' ? 'Even money' : odds} — you win ${money(win)} if your side takes it,` +
    ` and pay ${money(risk)} if it doesn't.` +
    ` Whoever takes the other end risks ${money(win)} to win ${money(risk)}.`
}

function renderCourt(court) {
  const closed  = isClosed(court)
  const offers  = _offers.filter(o => o.court_id === court.id)
  const myTeam  = mySide(court)
  const won     = _results[court.id] ?? null
  const closeAt = new Date(court.closes_at)
    .toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })

  const book = offers.length
    ? offers.map(o => renderOffer(court, o, closed)).join('')
    : `<p class="pick-empty">No picks on this court yet.</p>`

  let state
  if (won !== null) {
    state = ` &middot; <strong>${escapeHtml(sideNames(court, won))} won</strong>`
  } else if (closed) {
    state = ' &middot; <strong>closed</strong>'
  } else if (sameTime(closeAt, court.start_time)) {
    // The board normally closes at first serve, so printing the same time
    // twice ("7:00 PM · Woodway · closes 7:00 PM") just reads as a mistake.
    // The page subtitle already says when it closes.
    state = ''
  } else {
    state = ` &middot; closes ${escapeHtml(closeAt)}`
  }

  return `
    <article class="pick-court${closed ? ' pick-court-closed' : ''}">
      <header class="pick-court-head">
        <h3>Court ${court.court_no}</h3>
        <span class="pick-court-meta">
          ${escapeHtml(court.start_time || '')}${court.location ? ' &middot; ' + escapeHtml(court.location) : ''}${state}
        </span>
      </header>
      <p class="pick-court-teams">
        <strong>${escapeHtml(sideNames(court, 1))}</strong>
        <span class="pick-vs">vs</span>
        <strong>${escapeHtml(sideNames(court, 2))}</strong>
      </p>
      ${(!closed && _member) ? renderOfferForm(court, myTeam) : ''}
      <div class="pick-book">${book}</div>
    </article>`
}

function render() {
  renderSignedOutNote()

  if (!_courts.length) {
    _container.innerHTML = `
      <div class="empty-state">
        <p>No courts on the board yet.</p>
        <p class="pick-empty">Picks open as soon as the pairings for the next Monday are posted.</p>
      </div>`
    return
  }

  // Group by night. Usually one, but a schedule posted two weeks out works.
  const nights = []
  for (const court of _courts) {
    let night = nights.find(n => n.played_on === court.played_on)
    if (!night) {
      night = { played_on: court.played_on, week_label: court.week_label, courts: [] }
      nights.push(night)
    }
    night.courts.push(court)
  }

  _container.innerHTML = nights.map(night => `
    <section class="pick-night">
      <h2 class="pick-night-title">${escapeHtml(night.week_label || '')}${
        night.week_label
          ? `<span class="pick-night-date">${escapeHtml(prettyDate(night.played_on))}</span>`
          : escapeHtml(prettyDate(night.played_on))
      }</h2>
      ${night.courts.map(renderCourt).join('')}
    </section>`).join('')

  for (const court of _courts) updatePreview(court.id)
}

// ── Actions ─────────────────────────────────────────────────────────────

async function refresh() {
  await fetchAll()
  render()
}

/** Shows a short message above the board and clears it after a moment. */
function flash(message, kind = 'error') {
  const el = document.getElementById('picks-flash')
  if (!el) return
  el.className   = `alert alert-${kind}`
  el.textContent = message
  el.hidden      = false
  window.clearTimeout(flash._t)
  flash._t = window.setTimeout(() => { el.hidden = true }, 7000)
}

async function onPost(courtId, side) {
  const risk = centsFrom(`post-risk-${courtId}`)
  const win  = centsFrom(`post-win-${courtId}`)
  if (!risk) return flash('Put in what you want to risk.')
  if (!win)  return flash('Put in what you want to win.')

  const { error } = await supabase.rpc('post_offer', {
    p_court_id:   courtId,
    p_side:       side,
    p_risk_cents: risk,
    p_win_cents:  win
  })
  if (error) return flash(error.message)

  flash(risk === win
    ? `Up at even money — ${money(risk)}. Somebody has to take it now.`
    : `Up at ${oddsLabel(risk, win)} — you risk ${money(risk)} to win ${money(win)}.`, 'success')
  await refresh()
}

async function onTake(offerId) {
  const asked = centsFrom(`take-amt-${offerId}`)
  if (!asked) return flash('Put in what you want to risk.')

  const { data, error } = await supabase.rpc('take_offer', {
    p_offer_id:   offerId,
    p_risk_cents: asked
  })
  if (error) return flash(error.message)

  // The function fills whatever is left rather than failing, and absorbs a
  // sub-dollar sliver rather than leaving it, so what actually went on can
  // differ from what was asked for in either direction. Say what happened.
  const risked = Number(data?.taker_risk_cents ?? 0)
  const toWin  = Number(data?.poster_risk_cents ?? 0)

  flash(risked !== asked
    ? `${money(risked)} was what was left on that offer, so that's what you're on for — risking ${money(risked)} to win ${money(toWin)}.`
    : `You're on — risking ${money(risked)} to win ${money(toWin)}.`, 'success')
  await refresh()
}

async function onCancel(offerId) {
  const { data, error } = await supabase.rpc('cancel_offer', { p_offer_id: offerId })
  if (error) return flash(error.message)

  flash(Number(data) > 0
    ? `Pulled back the ${money(data)} nobody had taken. Anything already matched stays live.`
    : 'Nothing left to pull back.', 'success')
  await refresh()
}

// ── Entry point ─────────────────────────────────────────────────────────

/**
 * Renders the board into `container`. `member` is the signed-in member or
 * null — the board is readable either way, which is the point: the guys who
 * aren't playing are half the action.
 */
export async function loadPicks(container, member) {
  _container = container
  _member    = member || null

  try {
    await fetchAll()
    render()
  } catch (err) {
    _container.innerHTML = connectionErrorHtml()
    return
  }

  // One delegated listener for the whole board, so it survives every
  // re-render without rebinding.
  _container.addEventListener('click', async event => {
    const post   = event.target.closest('[data-post]')
    const take   = event.target.closest('[data-take]')
    const cancel = event.target.closest('[data-cancel]')

    if (post)   { event.preventDefault(); await onPost(post.dataset.post, Number(post.dataset.side)) }
    if (take)   { event.preventDefault(); await onTake(take.dataset.take) }
    if (cancel) { event.preventDefault(); await onCancel(cancel.dataset.cancel) }
  })

  _container.addEventListener('input', event => {
    const field = event.target.closest('[data-preview]')
    if (field) updatePreview(field.dataset.preview)
  })
}
