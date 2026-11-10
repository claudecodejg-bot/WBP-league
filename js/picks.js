// =============================================
//  Picks — the peer-to-peer book for a night's courts
// =============================================
//  Someone offers a side for an amount; anyone else takes the other side
//  for part or all of it. Even money, play money.
//
//  Every write goes through an RPC (post_offer / take_offer /
//  cancel_offer). None of these tables accept an insert from the browser,
//  on purpose: the rules that matter — enough left on the offer, enough in
//  your bankroll, before the court closes, not against your own team —
//  need a row lock and three tables in one transaction, which no RLS
//  policy can express. So the database does the deciding and this file
//  only asks and reports back.
//
//  That also means the error messages below are the ones raised in
//  add-wagers.sql. They are written to be shown to a member as-is.

import { supabase, escapeHtml, connectionErrorHtml } from './supabase-client.js?v=2d21059e'
import { CURRENT_SEASON } from './config.js?v=d82921ce'

let _container = null
let _member    = null          // { id, full_name, is_admin } or null when signed out

let _courts   = []
let _offers   = []
let _fills    = []
let _nameById = {}
let _balance  = null

/** YYYY-MM-DD for today, local time — not UTC, which is a day ahead at night. */
function todayISO() {
  const d   = new Date()
  const pad = n => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

function name(id) {
  return _nameById[id] || 'Unknown'
}

function pair(a, b) {
  return `${name(a)} & ${name(b)}`
}

/** A court is shut once its status moves on, or once its start time passes. */
function isClosed(court) {
  return court.status !== 'open' || new Date(court.closes_at) <= new Date()
}

function sideNames(court, side) {
  return side === 1 ? pair(court.t1p1, court.t1p2) : pair(court.t2p1, court.t2p2)
}

/** Which side the signed-in member is playing on this court, or null. */
function mySide(court) {
  if (!_member) return null
  if (_member.id === court.t1p1 || _member.id === court.t1p2) return 1
  if (_member.id === court.t2p1 || _member.id === court.t2p2) return 2
  return null
}

function money(n) {
  return `$${Number(n).toLocaleString()}`
}

// ── Data ────────────────────────────────────────────────────────────────

async function fetchAll() {
  const today = todayISO()

  // Courts still to come, plus anything from today that may not be settled.
  const [courtsRes, membersRes] = await Promise.all([
    supabase.from('scheduled_courts')
      .select('id, season, played_on, week_label, court_no, t1p1, t1p2, t2p1, t2p2, location, start_time, closes_at, status')
      .gte('played_on', today)
      .order('played_on', { ascending: true })
      .order('court_no',  { ascending: true }),
    supabase.from('members').select('id, full_name')
  ])

  if (courtsRes.error)  throw courtsRes.error
  if (membersRes.error) throw membersRes.error

  _courts   = courtsRes.data || []
  _nameById = Object.fromEntries((membersRes.data || []).map(m => [m.id, m.full_name]))

  const courtIds = _courts.map(c => c.id)
  if (courtIds.length === 0) {
    _offers = []
    _fills  = []
  } else {
    const offersRes = await supabase.from('wager_offers')
      .select('id, court_id, offered_by, side, amount, remaining, status, created_at')
      .in('court_id', courtIds)
      .order('created_at', { ascending: true })
    if (offersRes.error) throw offersRes.error
    _offers = offersRes.data || []

    const offerIds = _offers.map(o => o.id)
    if (offerIds.length === 0) {
      _fills = []
    } else {
      const fillsRes = await supabase.from('wager_fills')
        .select('id, offer_id, taker, amount, outcome, created_at')
        .in('offer_id', offerIds)
        .order('created_at', { ascending: true })
      if (fillsRes.error) throw fillsRes.error
      _fills = fillsRes.data || []
    }
  }

  // Balance comes from the ledger view — there is no stored balance.
  if (_member) {
    const balRes = await supabase.from('v_wager_balances')
      .select('balance')
      .eq('member_id', _member.id)
      .eq('season', CURRENT_SEASON)
      .maybeSingle()
    _balance = balRes.error ? null : (balRes.data?.balance ?? 0)
  } else {
    _balance = null
  }
}

// ── Render ──────────────────────────────────────────────────────────────

function renderBankroll() {
  const el = document.getElementById('picks-bankroll')
  if (!el) return

  if (!_member) {
    el.innerHTML = `<p class="picks-bankroll-note">
      Anyone can read the board. <a href="login.html?next=picks.html">Sign in</a> to make a pick.</p>`
    return
  }
  if (_balance === null) {
    el.innerHTML = `<p class="picks-bankroll-note">Could not read your bankroll.</p>`
    return
  }

  // Money already committed: offers nobody has taken yet, plus matched
  // stakes. Both are out of the balance already, so this is just so the
  // number on screen is explainable.
  const myOffers = _offers.filter(o => o.offered_by === _member.id)
  const open     = myOffers.reduce((n, o) => n + (o.status === 'open' ? o.remaining : 0), 0)

  el.innerHTML = `
    <div class="picks-bankroll">
      <div class="picks-bankroll-figure">
        <span class="picks-bankroll-label">Your bankroll</span>
        <strong>${money(_balance)}</strong>
      </div>
      ${open > 0 ? `<p class="picks-bankroll-note">${money(open)} of that is sitting on offers nobody has taken yet.</p>` : ''}
    </div>`
}

/** The matched bets on one offer, as a sentence each. */
function fillsFor(offerId) {
  return _fills.filter(f => f.offer_id === offerId)
}

function renderOffer(court, offer, closed) {
  const backing = sideNames(court, offer.side)
  const matched = fillsFor(offer.id)
  const taken   = matched.reduce((n, f) => n + f.amount, 0)
  const mine    = _member && offer.offered_by === _member.id
  const myTeam  = mySide(court)

  // Taking this offer means taking the side it is against. If that is the
  // side you're playing on, the database will refuse it, so don't offer a
  // button that cannot work.
  const takingSide  = offer.side === 1 ? 2 : 1
  const wouldBeVsMe = myTeam !== null && myTeam !== takingSide

  const canTake = !closed && _member && !mine && offer.status === 'open'
                  && offer.remaining > 0 && !wouldBeVsMe

  const lines = []
  lines.push(`<div class="pick-offer">
    <div class="pick-offer-head">
      <span class="pick-offer-who">${escapeHtml(name(offer.offered_by))}</span>
      backs <strong>${escapeHtml(backing)}</strong>
      for <strong>${money(offer.amount)}</strong>
    </div>`)

  if (taken > 0) {
    lines.push(`<ul class="pick-matched">` + matched.map(f =>
      `<li>${escapeHtml(name(f.taker))} took ${money(f.amount)} on
        ${escapeHtml(sideNames(court, takingSide))}${
          f.outcome ? ` &middot; <span class="pick-outcome">${f.outcome === 'void' ? 'void' : 'settled'}</span>` : ''
        }</li>`).join('') + `</ul>`)
  }

  if (offer.status === 'open' && offer.remaining > 0) {
    lines.push(`<div class="pick-offer-foot">
      <span class="pick-remaining">${money(offer.remaining)} still open</span>`)

    if (canTake) {
      lines.push(`
        <span class="pick-take">
          <label class="sr-only" for="take-amt-${offer.id}">Amount to take</label>
          <input type="number" id="take-amt-${offer.id}" class="pick-amt"
                 min="1" step="1" max="${offer.remaining}" value="${offer.remaining}"
                 inputmode="numeric">
          <button class="btn btn-sm btn-primary" data-take="${offer.id}">
            Take ${escapeHtml(sideNames(court, takingSide))}
          </button>
        </span>`)
    } else if (wouldBeVsMe && !closed && !mine) {
      // Only worth saying to someone who might otherwise expect a button.
      // On your own offer it reads like a refusal of something you weren't
      // trying to do.
      lines.push(`<span class="pick-blocked">You're playing this court</span>`)
    }

    if (mine && !closed) {
      lines.push(`<button class="btn btn-sm btn-secondary" data-cancel="${offer.id}">Pull back</button>`)
    }
    lines.push(`</div>`)
  } else if (offer.status === 'cancelled' && taken === 0) {
    lines.push(`<div class="pick-offer-foot"><span class="pick-remaining">Pulled back</span></div>`)
  }

  lines.push(`</div>`)
  return lines.join('')
}

function renderCourt(court) {
  const closed  = isClosed(court)
  const offers  = _offers.filter(o => o.court_id === court.id)
  const myTeam  = mySide(court)
  const closeAt = new Date(court.closes_at)
    .toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })

  const book = offers.length
    ? offers.map(o => renderOffer(court, o, closed)).join('')
    : `<p class="pick-empty">No picks on this court yet.</p>`

  // Offering is only possible on your own side if you're playing.
  const offerForm = (!closed && _member)
    ? `<div class="pick-new">
         <span class="pick-new-label">Back a side</span>
         <div class="pick-new-row">
           <label class="sr-only" for="post-amt-${court.id}">Amount to put up</label>
           <input type="number" id="post-amt-${court.id}" class="pick-amt"
                  min="1" step="1" value="20" inputmode="numeric">
           <span class="pick-new-on">on</span>
           ${[1, 2].map(side => (myTeam !== null && myTeam !== side)
             ? ''
             : `<button class="btn btn-sm btn-outline" data-post="${court.id}" data-side="${side}">
                  ${escapeHtml(sideNames(court, side))}
                </button>`).join('')}
         </div>
         ${myTeam !== null
           ? `<p class="pick-new-note">You're playing this court, so you can back your own team but not against it.</p>`
           : ''}
       </div>`
    : ''

  return `
    <article class="pick-court${closed ? ' pick-court-closed' : ''}">
      <header class="pick-court-head">
        <h3>Court ${court.court_no}</h3>
        <span class="pick-court-meta">
          ${escapeHtml(court.start_time || '')}${court.location ? ' &middot; ' + escapeHtml(court.location) : ''}
          ${closed ? ' &middot; <strong>closed</strong>' : ` &middot; closes ${escapeHtml(closeAt)}`}
        </span>
      </header>
      <p class="pick-court-teams">
        <strong>${escapeHtml(sideNames(court, 1))}</strong>
        <span class="pick-vs">vs</span>
        <strong>${escapeHtml(sideNames(court, 2))}</strong>
      </p>
      ${offerForm}
      <div class="pick-book">${book}</div>
    </article>`
}

function render() {
  if (!_courts.length) {
    _container.innerHTML = `
      <div class="empty-state">
        <p>No courts on the board yet.</p>
        <p class="pick-empty">Picks open as soon as the pairings for the next Monday are posted.</p>
      </div>`
    renderBankroll()
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
      <h2 class="pick-night-title">${escapeHtml(night.week_label || night.played_on)}</h2>
      ${night.courts.map(renderCourt).join('')}
    </section>`).join('')

  renderBankroll()
}

// ── Actions ─────────────────────────────────────────────────────────────

function amountFrom(id) {
  const input = document.getElementById(id)
  const n     = parseInt(input?.value, 10)
  return Number.isFinite(n) && n > 0 ? n : null
}

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
  flash._t = window.setTimeout(() => { el.hidden = true }, 6000)
}

async function onPost(courtId, side) {
  const amount = amountFrom(`post-amt-${courtId}`)
  if (!amount) return flash('Put in an amount first.')

  const { error } = await supabase.rpc('post_offer', {
    p_court_id: courtId,
    p_side:     side,
    p_amount:   amount
  })
  if (error) return flash(error.message)

  flash('Offer posted — somebody has to take it now.', 'success')
  await refresh()
}

async function onTake(offerId) {
  const asked = amountFrom(`take-amt-${offerId}`)
  if (!asked) return flash('Put in an amount first.')

  const { data, error } = await supabase.rpc('take_offer', {
    p_offer_id: offerId,
    p_amount:   asked
  })
  if (error) return flash(error.message)

  // The function fills whatever is left rather than failing, so the amount
  // that actually went on can be less than the one asked for — say so.
  const filled = Number(data)
  flash(filled < asked
    ? `Only ${money(filled)} was left on that offer, so that's what you took.`
    : `You're on for ${money(filled)}.`, 'success')
  await refresh()
}

async function onCancel(offerId) {
  const { data, error } = await supabase.rpc('cancel_offer', { p_offer_id: offerId })
  if (error) return flash(error.message)

  flash(Number(data) > 0
    ? `${money(data)} back in your bankroll. Anything already taken stays live.`
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
}
