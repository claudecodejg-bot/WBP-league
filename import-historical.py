#!/usr/bin/env python3
"""
Import historical paddle tennis match data from Excel into Supabase.

Usage:
  python3 import-historical.py

Reads: /Users/claudecodejg/Documents/Claude Projects/Paddle Project/Historical Scores.xlsx
Writes: historical-members.sql and historical-data.sql

Run BOTH sql files in order in the Supabase SQL editor:
  1. historical-members.sql  (adds any new historical-only members)
  2. historical-data.sql     (inserts historical match records)
"""

import openpyxl
import re
import sys
from datetime import datetime, timedelta

# ── Config ──────────────────────────────────────────────────────────────────

EXCEL_PATH = '/Users/claudecodejg/Documents/Claude Projects/Paddle Project/Historical Scores.xlsx'

# Approximate season start dates (Week 1). Adjust if you know the exact dates.
SEASON_STARTS = {
    '2023-24': datetime(2023, 10, 16),
    '2022-23': datetime(2022, 10, 17),
    '2021-22': datetime(2021, 10, 18),
}

# Members already in the current-season Supabase table.
# If a historical player's name is NOT here, they'll get an INSERT in historical-members.sql.
# Names are matched case-insensitively and by last name.
CURRENT_MEMBERS = [
    'Ridder', 'Grills', 'Adams', 'Walsh', "D'Acunto", 'McGurren',
    'Dolan', 'Luecke', 'Rayhill', 'Brown', 'Jonson', 'Smith',
    'Dolcetti', 'Napolitano', 'Rockman', 'Baum',
    # Guests
    'Alpetkin', 'Davidson', 'Officer', 'Moyers', 'Bennett',
]

# ── Score parsing ────────────────────────────────────────────────────────────

def decode_score(val):
    """
    Excel auto-converted score strings like '6/2/6' into dates.
    Reverse that: datetime(2006,6,2) -> [6,2,6], datetime(2026,4,3) -> [4,3].
    Also handles raw strings like '7/0/1' and tiebreak notation '6(4)/7/6'.
    Returns list of ints or None.
    """
    if val is None:
        return None
    if isinstance(val, datetime):
        if val.year == 2026:
            # 2-set score: month=set1, day=set2
            return [val.month, val.day]
        else:
            # 3-set score: month=set1, day=set2, year%100=set3
            return [val.month, val.day, val.year % 100]
    if isinstance(val, str):
        val = val.strip()
        # Strip tiebreak notation: '6(4)' -> '6', '7(7)' -> '7'
        val = re.sub(r'\(\d+\)', '', val)
        # Handle apostrophe typo as slash
        val = val.replace("'", '/')
        parts = val.split('/')
        try:
            return [int(p) for p in parts if p.strip()]
        except ValueError:
            return None
    return None

def infer_opp_score(our_score):
    """Estimate opponent's score in a set from our score."""
    if our_score >= 7:
        return 5   # tiebreak
    elif our_score == 6:
        return 3   # typical win
    elif our_score == 5:
        return 7   # typical loss (7-5)
    elif our_score == 0:
        return 6
    else:
        return 6   # any low score -> opponent won 6

def scores_to_sets(scores):
    """
    Given one team's set scores, return (t1s1, t1s2, t1s3, t2s1, t2s2, t2s3)
    by inferring the opponent's scores.
    """
    s = (scores or [])
    t1 = [s[i] if i < len(s) else None for i in range(3)]
    t2 = [infer_opp_score(t1[i]) if t1[i] is not None else None for i in range(3)]
    return t1[0], t1[1], t1[2], t2[0], t2[1], t2[2]

def combine_scores(t1_scores, t2_scores):
    """
    Combine known scores from both perspectives into a 6-tuple.
    Prefer t2's own reported scores over inferred ones.
    """
    t1 = (t1_scores or [])
    t2 = (t2_scores or [])
    n = max(len(t1), len(t2))

    t1s = [t1[i] if i < len(t1) else None for i in range(n)]
    t2s = [t2[i] if i < len(t2) else None for i in range(n)]

    # Fill in any missing values by inference
    for i in range(n):
        if t1s[i] is not None and t2s[i] is None:
            t2s[i] = infer_opp_score(t1s[i])
        elif t2s[i] is not None and t1s[i] is None:
            t1s[i] = infer_opp_score(t2s[i])

    # Pad/truncate to 3 sets
    while len(t1s) < 3:
        t1s.append(None)
        t2s.append(None)

    return t1s[0], t1s[1], t1s[2], t2s[0], t2s[1], t2s[2]

# ── Excel parsing ────────────────────────────────────────────────────────────

def parse_section(ws, start_row, end_row):
    """Parse one season section. Returns (season_label, player_data dict)."""
    rows = list(ws.iter_rows(min_row=start_row, max_row=end_row, values_only=True))
    season_label = str(rows[0][0])

    # Row 2 (index 1) has week headers
    header = rows[1]
    weeks = {}  # week_label -> col_index
    for col_idx, val in enumerate(header):
        if val and str(val).startswith('Week'):
            weeks[str(val)] = col_idx

    # Rows 3+ are player data
    player_data = {}   # player_name -> {week_label -> {'opponent': str, 'scores': list}}
    player_vs   = set()  # players with 'vs' rows (on opposing teams)

    for row in rows[2:]:
        player = row[0]
        if not player:
            continue

        week1_val = row[2] if len(row) > 2 else None
        if week1_val == 'vs':
            player_vs.add(player)

        matches_for_player = {}
        for week_label, col_idx in weeks.items():
            if col_idx >= len(row):
                continue
            opponent = row[col_idx]
            if not opponent or opponent == 'vs':
                continue
            score_raw = row[col_idx + 1] if col_idx + 1 < len(row) else None
            scores = decode_score(score_raw)
            matches_for_player[week_label] = {
                'opponent': str(opponent).strip(),
                'scores': scores,
            }

        if matches_for_player:
            player_data[player] = matches_for_player

    return season_label, weeks, player_data, player_vs

# ── Match reconstruction ─────────────────────────────────────────────────────

def parse_opponent_names(opp_str):
    """'D\'Acunto/Baum' -> ['D\'Acunto', 'Baum']"""
    parts = opp_str.split('/')
    return [p.strip() for p in parts if p.strip()]

def reconstruct_matches(season_label, weeks, player_data):
    """
    Cross-reference player rows to reconstruct full 4-player match records.
    Returns list of match dicts, deduped.
    """
    # Use frozenset of both teams so (A+B vs C+D) and (C+D vs A+B) are the same match
    seen = set()
    matches = []

    for player_a, weeks_data in player_data.items():
        for week_label, entry_a in weeks_data.items():
            opp_names = parse_opponent_names(entry_a['opponent'])
            if len(opp_names) != 2:
                continue

            opp1, opp2 = opp_names

            # Skip rows where the player's own name appears in the opponent column.
            # This happens when the data entry shows the player's OWN team rather
            # than the opposing team (an inconsistency in the source spreadsheet).
            if player_a in opp_names:
                continue

            # Try to find player_a's partner by cross-referencing:
            # Look for a row by opp1 or opp2 whose opponent for this week includes player_a
            partner_a = None
            opp_scores = None

            for opp_player in [opp1, opp2]:
                if opp_player not in player_data:
                    continue
                opp_week_data = player_data[opp_player].get(week_label)
                if not opp_week_data:
                    continue
                opp_opp_names = parse_opponent_names(opp_week_data['opponent'])
                if player_a in opp_opp_names:
                    other = [n for n in opp_opp_names if n != player_a]
                    if other:
                        partner_a = other[0]
                    opp_scores = opp_week_data['scores']
                    break

            # Normalize team sets so (A+B vs C+D) == (C+D vs A+B) for deduplication
            team1_set = frozenset([player_a, partner_a or '__UNKNOWN__'])
            team2_set = frozenset([opp1, opp2])
            match_key = (week_label, frozenset({team1_set, team2_set}))
            if match_key in seen:
                continue
            seen.add(match_key)

            # Compute final set scores
            if opp_scores is not None:
                t1s1, t1s2, t1s3, t2s1, t2s2, t2s3 = combine_scores(
                    entry_a['scores'], opp_scores
                )
            else:
                t1s1, t1s2, t1s3, t2s1, t2s2, t2s3 = scores_to_sets(entry_a['scores'])

            # Skip matches with no score data at all
            if all(v is None for v in [t1s1, t1s2, t2s1, t2s2]):
                continue

            matches.append({
                'season':         season_label,
                'week_label':     week_label,
                'team1_player1':  player_a,
                'team1_player2':  partner_a,
                'team2_player1':  opp1,
                'team2_player2':  opp2,
                't1s1': t1s1, 't1s2': t1s2, 't1s3': t1s3,
                't2s1': t2s1, 't2s2': t2s2, 't2s3': t2s3,
                'partner_found': partner_a is not None,
            })

    return matches

# ── SQL generation ────────────────────────────────────────────────────────────

def member_lookup(name):
    """Generate a subquery to look up a member by name."""
    if not name:
        return 'NULL'
    # Escape single quotes
    safe = name.replace("'", "''")
    return f"(SELECT id FROM members WHERE LOWER(full_name) = LOWER('{safe}') LIMIT 1)"

def null_or_int(v):
    return 'NULL' if v is None else str(int(v))

def week_to_date(season_label, week_label):
    start = SEASON_STARTS.get(season_label)
    if not start:
        return "'2000-01-01'"
    week_num = int(week_label.replace('Week ', ''))
    d = start + timedelta(weeks=week_num - 1)
    return f"'{d.strftime('%Y-%m-%d')}'"

def generate_sql(all_seasons_matches):
    """Generate two SQL files: historical-members.sql and historical-data.sql."""

    # Collect all player names mentioned
    all_names = set()
    for m in all_seasons_matches:
        for field in ['team1_player1', 'team1_player2', 'team2_player1', 'team2_player2']:
            if m[field]:
                all_names.add(m[field])

    # Determine which names are NOT in current members list
    def is_current(name):
        name_lower = name.lower()
        for cm in CURRENT_MEMBERS:
            if cm.lower() in name_lower or name_lower in cm.lower():
                return True
        return False

    new_members = sorted(n for n in all_names if not is_current(n))

    # ── historical-members.sql ──
    members_sql = ['-- =============================================',
                   '-- historical-members.sql',
                   '-- Run FIRST in Supabase SQL editor.',
                   '-- Adds any historical players not in current roster.',
                   '-- =============================================',
                   '']
    if new_members:
        for name in new_members:
            safe = name.replace("'", "''")
            safe_email = name.lower().replace(' ', '.').replace("'", '') + '@historical.local'
            members_sql.append(
                f"INSERT INTO members (full_name, email, is_guest, is_admin)"
                f" VALUES ('{safe}', '{safe_email}', true, false)"
                f" ON CONFLICT DO NOTHING;"
            )
        members_sql.append('')
        members_sql.append(f'-- {len(new_members)} new historical member(s) added as guests.')
    else:
        members_sql.append('-- No new members to add. All historical players are already in the roster.')

    # ── historical-data.sql ──
    data_sql = ['-- =============================================',
                '-- historical-data.sql',
                '-- Run SECOND in Supabase SQL editor (after historical-members.sql).',
                '-- Inserts historical match records.',
                '-- =============================================',
                '']

    season_order = sorted(set(m['season'] for m in all_seasons_matches), reverse=True)
    for season in season_order:
        season_matches = [m for m in all_seasons_matches if m['season'] == season]
        data_sql.append(f'-- === Season {season} ({len(season_matches)} matches) ===')
        data_sql.append('')

        incomplete = sum(1 for m in season_matches if not m['partner_found'])
        if incomplete:
            data_sql.append(f'-- NOTE: {incomplete} match(es) have unknown partners')
            data_sql.append('-- (marked with team1_player2 = NULL or a guest placeholder).')
            data_sql.append('')

        for m in season_matches:
            t1p1 = member_lookup(m['team1_player1'])
            t1p2 = member_lookup(m['team1_player2']) if m['team1_player2'] else 'NULL'
            t2p1 = member_lookup(m['team2_player1'])
            t2p2 = member_lookup(m['team2_player2'])
            date_str = week_to_date(m['season'], m['week_label'])

            t1s1 = null_or_int(m['t1s1'])
            t1s2 = null_or_int(m['t1s2'])
            t1s3 = null_or_int(m['t1s3'])
            t2s1 = null_or_int(m['t2s1'])
            t2s2 = null_or_int(m['t2s2'])
            t2s3 = null_or_int(m['t2s3'])

            data_sql.append(
                f"INSERT INTO matches"
                f" (season, week_label, played_on,"
                f"  team1_player1, team1_player2, team2_player1, team2_player2,"
                f"  team1_set1, team1_set2, team1_set3, team2_set1, team2_set2, team2_set3)"
                f" VALUES"
                f" ('{m['season']}', '{m['week_label']}', {date_str},"
                f"  {t1p1}, {t1p2}, {t2p1}, {t2p2},"
                f"  {t1s1}, {t1s2}, {t1s3}, {t2s1}, {t2s2}, {t2s3});"
            )
        data_sql.append('')

    return '\n'.join(members_sql), '\n'.join(data_sql)

# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    print(f'Reading {EXCEL_PATH}...')
    wb = openpyxl.load_workbook(EXCEL_PATH, data_only=True)
    ws = wb['Sheet1']

    # Detect section boundaries by finding rows where col A is a season label
    section_starts = []
    for i, row in enumerate(ws.iter_rows(min_row=1, values_only=True), 1):
        if row[0] and str(row[0]).strip() and re.match(r'\d{4}-\d{2,4}', str(row[0])):
            section_starts.append(i)

    print(f'Found {len(section_starts)} season section(s): rows {section_starts}')

    # Add sentinel end
    section_starts.append(ws.max_row + 1)

    all_matches = []
    seen_seasons = set()

    for idx in range(len(section_starts) - 1):
        start = section_starts[idx]
        end   = section_starts[idx + 1] - 1

        season_label, weeks, player_data, player_vs = parse_section(ws, start, end)

        # Skip 2021-22: data is confirmed identical to 2022-23 (copy error in Excel)
        if season_label == '2021-22':
            print(f'  Skipping 2021-22 (duplicate of 2022-23)')
            continue

        # Skip other duplicate season labels
        if season_label in seen_seasons:
            print(f'  Skipping duplicate: {season_label}')
            continue
        seen_seasons.add(season_label)

        print(f'\n  Season {season_label} (rows {start}-{end}):')
        print(f'    Weeks: {list(weeks.keys())}')
        print(f'    Players with data: {list(player_data.keys())}')

        matches = reconstruct_matches(season_label, weeks, player_data)

        complete   = sum(1 for m in matches if m['partner_found'])
        incomplete = sum(1 for m in matches if not m['partner_found'])
        print(f'    Matches reconstructed: {len(matches)} ({complete} complete, {incomplete} with unknown partner)')

        all_matches.extend(matches)

    print(f'\nTotal matches across all seasons: {len(all_matches)}')

    members_sql, data_sql = generate_sql(all_matches)

    with open('historical-members.sql', 'w') as f:
        f.write(members_sql)
    print('\nWrote: historical-members.sql')

    with open('historical-data.sql', 'w') as f:
        f.write(data_sql)
    print('Wrote: historical-data.sql')
    print('\nNext steps:')
    print('  1. Review both SQL files for accuracy')
    print('  2. Run add-season-column.sql in Supabase SQL editor (if not done yet)')
    print('  3. Run historical-members.sql in Supabase SQL editor')
    print('  4. Run historical-data.sql in Supabase SQL editor')

if __name__ == '__main__':
    main()
