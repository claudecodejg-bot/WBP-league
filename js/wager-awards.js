// =============================================
//  ROCK'n'Roll Wagers — the three season titles
// =============================================
//  Wager King     most won over the season
//  Most Action    most money matched, either end of it
//  Market Maker   most money matched on offers YOU put up
//
//  NO NEW SQL. All three come out of v_pick_results and v_settle_season,
//  which already exist and are already readable with the public key — so
//  nothing here has to be run against the database before it works. A
//  season is a few hundred fills at most, so summing them in the browser
//  costs nothing and saves a view that would need maintaining.
//
//  WHY THESE THREE
//
//  Wager King on its own rewards one lucky Monday. Most Action rewards
//  being in the mix, and counts MATCHED money only — a price nobody took
//  is not action, which is also what stops anyone posting $100 a court
//  every week to win a title nobody could take him up on. Market Maker
//  is the one that keeps a board alive at all: putting up a price good
//  enough that somebody wanted it.
//
//  An unsettled bet still counts towards Action and Market Maker. The
//  money is on the line from the moment it is matched, and waiting for
//  Monday's score to say so would make both boards go quiet exactly when
//  the most is riding. Only Wager King waits for results, because until
//  there is one nobody has won anything.

import { supabase } from './supabase-client.js?v=2d21059e'

/**
 * { picks, nets } for a season, or empty arrays if either query fails.
 * Never throws: an award must not take the standings down with it.
 */
export async function fetchWagerAwards(season) {
  try {
    const [picksRes, netsRes] = await Promise.all([
      supabase.from('v_pick_results')
        .select('offer_id, poster, taker, poster_risk_cents, taker_risk_cents')
        .eq('season', season),
      supabase.from('v_settle_season')
        .select('member_id, net_cents')
        .eq('season', season)
    ])
    return {
      picks: picksRes.error ? [] : (picksRes.data || []),
      nets:  netsRes.error  ? [] : (netsRes.data  || [])
    }
  } catch {
    return { picks: [], nets: [] }
  }
}

/** Cents to a readable dollar amount. Whole dollars lose the ".00". */
export function money(cents) {
  const n = Math.abs(Number(cents)) / 100
  return '$' + (Number.isInteger(n)
    ? n.toLocaleString()
    : n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }))
}

/**
 * One row per member who has had a bet matched this season, carrying all
 * three numbers. Returned unsorted — each board sorts it its own way.
 */
export function wagerRows({ picks, nets }, nameById) {
  const by = new Map()
  const row = id => {
    if (!by.has(id)) {
      by.set(id, {
        id,
        name:   nameById[id] || null,
        won:    0,      // net cents for the season
        action: 0,      // own stake across every matched bet
        made:   0,      // stake matched on offers this member posted
        bets:   0,      // matched bets, either end
        offers: new Set()  // distinct offers of theirs that got taken
      })
    }
    return by.get(id)
  }

  for (const p of picks) {
    // A poster risks what they said they'd risk; the taker's stake is
    // the mirror. Both are already decided and stored on the fill, so
    // there is no arithmetic here to get wrong.
    const poster = row(p.poster)
    poster.action += p.poster_risk_cents
    poster.made   += p.poster_risk_cents
    poster.bets   += 1
    poster.offers.add(p.offer_id)

    const taker = row(p.taker)
    taker.action += p.taker_risk_cents
    taker.bets   += 1
  }

  // Settled money only, and only for people who already have a row: a
  // net with no matched bet behind it cannot happen, but a member who
  // has never bet should not appear on a board at zero.
  for (const n of nets) {
    if (by.has(n.member_id)) by.get(n.member_id).won = n.net_cents
  }

  return [...by.values()]
    // A name that will not resolve would render as a blank row.
    .filter(r => r.name)
    .map(r => ({ ...r, offers: r.offers.size }))
}

/**
 * The three boards, each sorted and with its leaders worked out.
 * `leaders` is a list because two people can tie, and a title shared is
 * still a title.
 */
export function wagerBoards(rows) {
  const board = (key, keep) => {
    const sorted = [...rows]
      .filter(keep)
      .sort((a, b) => b[key] - a[key] || a.name.localeCompare(b.name))
    const top = sorted.length ? sorted[0][key] : 0
    return { rows: sorted, top, leaders: sorted.filter(r => r[key] === top) }
  }

  return {
    // Being down on the season is not a title, so a board of losses has
    // no king. Everyone still appears in the table below it.
    king:   board('won',    r => r.won > 0),
    action: board('action', r => r.action > 0),
    maker:  board('made',   r => r.made > 0)
  }
}
