// =============================================
//  Picks — the peer-to-peer book for a night's courts
// =============================================
//  Someone offers a side at a price; anyone else takes the other side for
//  part or all of it. Play money, carried on a running tab on settle.html
//  until somebody says it has been paid.
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
import { CURRENT_SEASON } from './config.js?v=d82921ce'
import { fetchWagerAwards, wagerRows, wagerBoards } from './wager-awards.js?v=b8c35a36'

let _container = null
let _member    = null          // { id, full_name, is_admin } or null when signed out

let _courts   = []
let _offers   = []
let _fills    = []
let _results  = {}             // court_id -> winning_side (1, 2 or null)
let _nameById = {}
let _awards   = { picks: [], nets: [] }   // the three season titles

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
  // The season titles ride along: fetchWagerAwards never throws and
  // returns empty on failure, so a title strip that cannot be built
  // costs the board nothing.
  const [courtsRes, membersRes, awards] = await Promise.all([
    supabase.from('scheduled_courts')
      .select('id, season, played_on, week_label, court_no, t1p1, t1p2, t2p1, t2p2, location, start_time, closes_at, status')
      .gte('played_on', today)
      .neq('status', 'void')
      .order('played_on', { ascending: true })
      .order('court_no',  { ascending: true }),
    supabase.from('members').select('id, full_name'),
    fetchWagerAwards(CURRENT_SEASON)
  ])

  if (courtsRes.error)  throw courtsRes.error
  if (membersRes.error) throw membersRes.error

  _awards = awards

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

/**
 * Everything that is going, at the top of the page: the prices still
 * open, and the ones already struck.
 *
 * THIS IS THE BOOK. The court cards below used to carry both as well;
 * they do not any more, because the same bet printed twice on one screen
 * reads as two bets. A court card is now only the place you PUT a price
 * up, and that is what the jump link points at.
 *
 * Because each offer appears exactly once again, the Take control can
 * live here. It could not while the courts also listed prices — two
 * elements answering to take-amt-<offer> is how the wrong number gets
 * read off the wrong input.
 */
function renderLive() {
  const el = document.getElementById('picks-live')
  if (!el) return
  el.innerHTML = renderJump() + renderOpenBoard() + renderAcceptedBoard() + renderTitles()
}

/**
 * The three season titles, in one line under the board, linking to the
 * full tables on the standings page.
 *
 * Deliberately quiet: it is the one thing up here that is not an action,
 * and three lit boxes already have the eye. It is also always drawn,
 * even with every title vacant — "Up for grabs" on all three is the most
 * encouraging state this strip can be in, and hiding it then would hide
 * it exactly when it has the most work to do.
 */
function renderTitles() {
  const rows = wagerRows(_awards, _nameById)
  const { king, action, maker } = wagerBoards(rows)

  const item = (icon, label, board, fmt) => {
    const held = board.leaders.length > 0
    return `<span class="title-strip-item">
      <span class="title-strip-icon" aria-hidden="true">${icon}</span>
      <span class="title-strip-label">${label}</span>
      <span class="title-strip-who${held ? '' : ' title-strip-open'}">${
        held ? board.leaders.map(r => escapeHtml(r.name)).join(' & ') : 'Up for grabs'}</span>
      ${held ? `<span class="title-strip-stat">${fmt(board.leaders)}</span>` : ''}
    </span>`
  }

  return `<a class="title-strip" href="standings.html#wagers">
    ${item('\u{1F451}', 'Wager King',   king,   ls => '+' + money(ls[0].won))}
    ${item('\u{1F3B2}', 'Most Action',  action, ls => money(ls[0].action) + ' matched')}
    ${item('\u{1F4E3}', 'Market Maker', maker,  ls => ls.length === 1
      ? money(ls[0].made) + ' of action'
      // Tied holders share a count but not the money behind it.
      : `${ls[0].offers} market${ls[0].offers === 1 ? '' : 's'} each`)}
    <span class="title-strip-go">Season titles &rarr;</span>
  </a>`
}

/** Courts still taking prices, soonest first. */
function openCourts() {
  return _courts.filter(c => !isClosed(c))
}

/**
 * More than one Monday on the board at once makes "Court 2" ambiguous,
 * so the date joins it. With a single night it would be noise on every
 * card.
 */
function courtLabel(court) {
  const nights = new Set(_courts.map(c => c.played_on))
  const where  = `Court ${court.court_no}`
  return nights.size > 1
    ? `${escapeHtml(prettyDate(court.played_on))} &middot; ${where}`
    : where
}

/** Down to the first court you can actually post on. */
function renderJump() {
  if (!_member) return ''
  const first = openCourts()[0]
  if (!first) return ''

  return `<a class="picks-jump" href="#court-${escapeHtml(first.id)}">
    <span class="picks-jump-dot" aria-hidden="true"></span>
    Place your bets
    <span class="picks-jump-arrow" aria-hidden="true">&darr;</span>
  </a>`
}

/**
 * Open prices. Uncapped on purpose: this is now the ONLY place a bet can
 * be taken, so a cap would hide money that is genuinely going.
 */
function renderOpenBoard() {
  const live = _offers
    .filter(o => o.status === 'open' && o.win_open_cents > 0)
    .map(o => ({ offer: o, court: _courts.find(c => c.id === o.court_id) }))
    .filter(x => x.court && !isClosed(x.court))
    // Biggest first: the one worth reading first.
    .sort((x, y) => y.offer.win_open_cents - x.offer.win_open_cents)

  // A box of chasing lights around the words "nothing available" is
  // worse than no box.
  if (!live.length) return ''

  const rows = live.map(({ offer, court }) => {
    // Name the side a TAKER ends up on, with the taker's two numbers.
    const takingSide = offer.side === 1 ? 2 : 1
    const risk   = offer.win_open_cents
    const win    = offer.risk_open_cents
    const mine   = _member && offer.offered_by === _member.id
    const myTeam = mySide(court)
    // Playing this court? You can only ever be on your own team.
    const blocked = myTeam !== null && myTeam !== takingSide
    const dflt    = (risk / 100).toFixed(2).replace(/\.00$/, '')

    let action = ''
    if (mine) {
      action = `<span class="live-bet-act">
        <span class="live-bet-note">yours</span>
        <button class="btn btn-sm btn-secondary" data-cancel="${offer.id}">Pull back</button>
      </span>`
    } else if (blocked) {
      action = `<span class="live-bet-note">You're on the other side</span>`
    } else if (_member) {
      action = `<span class="live-bet-act">
        <label class="sr-only" for="take-amt-${offer.id}">Amount to risk</label>
        <span class="live-bet-dollar">$</span>
        <input type="number" id="take-amt-${offer.id}" class="pick-amt"
               min="1" step="0.01" max="${dflt}" value="${dflt}" inputmode="decimal">
        <button class="btn btn-sm btn-primary" data-take="${offer.id}">Take it</button>
      </span>`
    }

    return `<li class="live-bet">
      <div class="live-bet-card">
        <span class="live-bet-team">${escapeHtml(sideNames(court, takingSide))}</span>
        <span class="live-bet-price">${money(risk)} to win ${money(win)}</span>
        <span class="pick-odds">${escapeHtml(oddsLabel(risk, win))}</span>
        <span class="live-bet-from">${courtLabel(court)}${
          mine ? '' : ' &middot; from ' + escapeHtml(name(offer.offered_by))}</span>
        ${action}
      </div>
    </li>`
  }).join('')

  return `
    <section class="live-board">
      <div class="live-board-inner">
        <h2 class="live-board-title">
          <span class="live-board-dot" aria-hidden="true"></span>
          Up for grabs
          <span class="live-board-count">${live.length} going</span>
        </h2>
        <ul class="live-board-list">${rows}</ul>
      </div>
    </section>`
}

/**
 * Bets already struck, in their own livery. Navy where the open board is
 * charcoal and the posting panel is green: three lit boxes on a page
 * only work if no two of them are the same colour.
 */
function renderAcceptedBoard() {
  const byOffer = Object.fromEntries(_offers.map(o => [o.id, o]))

  const rows = _fills
    .map(f => {
      const offer = byOffer[f.offer_id]
      const court = offer && _courts.find(c => c.id === offer.court_id)
      return court ? { fill: f, offer, court } : null
    })
    .filter(Boolean)

  if (!rows.length) return ''

  // Grouped by court, in the order the courts themselves run — _courts
  // comes back sorted by night and then court number, so walking it is
  // what keeps the two halves of the page in the same order.
  const groups = []
  for (const court of _courts) {
    const mine = rows.filter(r => r.court.id === court.id)
    if (mine.length) groups.push({ court, rows: mine })
  }

  const body = groups.map(({ court, rows: inCourt }) => {
    const won = _results[court.id] ?? null

    // CONSOLIDATED BY SIDE, not one card per fill. A card per fill names
    // only the taker and leaves the other end as "v Grills", which says
    // who he is but not which team he is on — and it prints the same
    // poster once for every person who took him. Two columns, a team
    // each, with every backer and what they have on it, answers "who is
    // on which side" in one look.
    // Two figures per name, not one. The stake alone reads as the payout
    // to anyone glancing, and at these odds it usually isn't: a $10 bet
    // taken at 2-1 against collects $5. Each end risks its own number
    // and collects the other's, so one bet is the same pair swapped.
    const stakes = { 1: new Map(), 2: new Map() }
    const bump = (side, id, risk, win) => {
      const at = stakes[side].get(id) || { risk: 0, win: 0 }
      at.risk += Number(risk) || 0
      at.win  += Number(win)  || 0
      stakes[side].set(id, at)
    }

    for (const { fill, offer } of inCourt) {
      const takerSide = offer.side === 1 ? 2 : 1
      bump(offer.side, offer.offered_by, fill.poster_risk_cents, fill.taker_risk_cents)
      bump(takerSide,  fill.taker,       fill.taker_risk_cents,  fill.poster_risk_cents)
    }

    const riding = [1, 2].reduce((sum, side) =>
      sum + [...stakes[side].values()].reduce((a, b) => a + b.risk, 0), 0)

    const sides = [1, 2].map(side => {
      const backers = [...stakes[side].entries()]
        .map(([id, at]) => ({ id, name: name(id), risk: at.risk, win: at.win }))
        // Most on it first; the name breaks a tie so the order is stable.
        .sort((a, b) => b.risk - a.risk || a.name.localeCompare(b.name))

      const outcome = won === null ? '' : (won === side ? ' taken-side-won' : ' taken-side-lost')
      // What this whole side collects between them. Only worth a line
      // when more than one name is on it — with one it just repeats the
      // row underneath.
      const pays = backers.reduce((sum, b) => sum + b.win, 0)

      return `
        <section class="taken-side${outcome}">
          <h4 class="taken-side-team">${escapeHtml(sideNames(court, side))}</h4>
          ${backers.length > 1
            ? `<p class="taken-side-pays">Pays ${money(pays)} between them</p>`
            : ''}
          <ul class="taken-list">
            ${backers.map(b => `<li class="taken-row${
              _member && b.id === _member.id ? ' taken-row-mine' : ''}">
              <span class="taken-who">${escapeHtml(b.name)}</span>
              <span class="taken-amt">${money(b.risk)}
                <span class="taken-win">to win ${money(b.win)}</span>
              </span>
            </li>`).join('')}
          </ul>
        </section>`
    }).join('')

    return `<div class="live-board-group">
      <h3 class="live-board-group-title">${courtLabel(court)}
        <span class="live-board-group-sum">${money(riding)} riding</span>
      </h3>
      <div class="taken-sides">${sides}</div>
    </div>`
  }).join('')

  return `
    <section class="live-board live-board-taken">
      <div class="live-board-inner">
        <h2 class="live-board-title">
          <span class="live-board-dot" aria-hidden="true"></span>
          Accepted wagers!
          <span class="live-board-count">${rows.length} on the line</span>
        </h2>
        ${body}
      </div>
    </section>`
}

/**
 * The form for putting a side up. Two amounts rather than an odds box:
 * "risk 5 to win 10" is how the price gets said out loud, and it cannot be
 * read the wrong way round the way a bare "2-1" can.
 */
function renderOfferForm(court, myTeam) {
  const sides = [1, 2].filter(side => myTeam === null || myTeam === side)

  return `<div class="pick-new">
    <div class="pick-new-inner">
      <div class="pick-new-row">
        <span class="pick-new-label">
          <span class="pick-new-dot" aria-hidden="true"></span>
          Place your bets!
        </span>
        <label class="pick-field">
          <span>I risk</span>
          <span class="pick-dollar">$</span>
          <input type="number" id="post-risk-${court.id}" class="pick-amt" data-preview="${court.id}"
                 min="1" max="100" step="0.01" value="5" inputmode="decimal">
        </label>
        <label class="pick-field">
          <span>to win</span>
          <span class="pick-dollar">$</span>
          <input type="number" id="post-win-${court.id}" class="pick-amt" data-preview="${court.id}"
                 min="1" max="500" step="0.01" value="5" inputmode="decimal">
        </label>
        <span class="pick-new-on">on</span>
        ${sides.map(side => `
          <button class="btn btn-sm btn-outline" data-post="${court.id}" data-side="${side}">
            ${escapeHtml(sideNames(court, side))}
          </button>`).join('')}
      </div>
      <p class="pick-preview" id="post-preview-${court.id}"></p>
      ${myTeam !== null
        ? `<p class="pick-new-note">You're playing &mdash; you can only back your own team.</p>`
        : ''}
    </div>
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
    `${odds === 'even money' ? 'Even money' : odds} — win ${money(win)} or pay ${money(risk)}.` +
    ` They risk ${money(win)} to win ${money(risk)}.`
}

/**
 * A court card is now only two things: who is playing, and the panel
 * where you put a price up. The prices themselves — open and accepted
 * alike — live in the board at the top of the page. They used to be in
 * both places, and the same bet printed twice on one screen reads as
 * two bets.
 */
function renderCourt(court) {
  const closed  = isClosed(court)
  const myTeam  = mySide(court)
  const won     = _results[court.id] ?? null
  const closeAt = new Date(court.closes_at)
    .toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })

  // Dim the side that lost rather than only crowning the winner, so a
  // finished court reads at a glance without anybody doing the names.
  const teams = [1, 2].map(side => {
    const outcome = won === null ? '' : (won === side ? ' pick-team-won' : ' pick-team-lost')
    return `<span class="pick-team${outcome}">${escapeHtml(sideNames(court, side))}</span>`
  }).join('<span class="pick-vs">vs</span>')

  let state
  if (won !== null) {
    // Not "X won": the winning name is marked and the loser is dimmed,
    // so saying it here would be a third printing of the same fact.
    state = ' &middot; <strong>final</strong>'
  } else if (closed) {
    state = ' &middot; <strong>closed</strong>'
  } else if (sameTime(closeAt, court.start_time)) {
    // The board normally closes at first serve, so printing the same time
    // twice ("7:00 PM · Woodway · closes 7:00 PM") just reads as a mistake.
    // The "?" at the top of the page says so once, in words.
    state = ''
  } else {
    state = ` &middot; closes ${escapeHtml(closeAt)}`
  }

  return `
    <article class="pick-court${closed ? ' pick-court-closed' : ''}"
             id="court-${escapeHtml(court.id)}">
      <header class="pick-court-head">
        <h3>Court ${court.court_no}</h3>
        <span class="pick-court-meta">
          ${escapeHtml(court.start_time || '')}${court.location ? ' &middot; ' + escapeHtml(court.location) : ''}${state}
        </span>
      </header>
      <p class="pick-court-teams">${teams}</p>
      ${(!closed && _member) ? renderOfferForm(court, myTeam) : ''}
    </article>`
}

/**
 * "Week 6 · Monday, November 16" — unless the label IS the date, which is
 * what the scheduler actually writes ("Monday, November 16, 2026"). Adding
 * the date beside that one printed it twice and read as a bug, which is
 * how it was found: on the live board, with the first real week on it.
 */
function nightHeading(night) {
  const label  = String(night.week_label || '').trim()
  const pretty = prettyDate(night.played_on)
  const key    = t => t.toLowerCase().replace(/[^a-z0-9]+/g, '')

  if (!label)                      return escapeHtml(pretty)
  if (key(label).includes(key(pretty))) return escapeHtml(label)

  return escapeHtml(label) +
    `<span class="pick-night-date">${escapeHtml(pretty)}</span>`
}

function render() {
  renderSignedOutNote()
  renderLive()

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
      <h2 class="pick-night-title">${nightHeading(night)}</h2>
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

  // On the DOCUMENT, not on the container. The board is two separate
  // elements now — the Take and Pull back buttons live in #picks-live at
  // the top of the page, the posting panels in #picks-container below —
  // and a listener bound to one of them silently ignores every click in
  // the other. Delegating from the document covers both and still
  // survives every re-render without rebinding.
  document.addEventListener('click', async event => {
    const post   = event.target.closest('[data-post]')
    const take   = event.target.closest('[data-take]')
    const cancel = event.target.closest('[data-cancel]')

    if (post)   { event.preventDefault(); await onPost(post.dataset.post, Number(post.dataset.side)) }
    if (take)   { event.preventDefault(); await onTake(take.dataset.take) }
    if (cancel) { event.preventDefault(); await onCancel(cancel.dataset.cancel) }
  })

  document.addEventListener('input', event => {
    const field = event.target.closest('[data-preview]')
    if (field) updatePreview(field.dataset.preview)
  })
}
