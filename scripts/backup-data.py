#!/usr/bin/env python3
"""
Snapshot the league database to JSON files in backups/.

Why this exists: the Supabase free tier has no automatic backups, and every
result entered through the admin UI since the original import lives only in
that database. These snapshots are committed to git, so every run becomes a
restore point and you can diff any two dates.

Only PUBLICLY READABLE columns are fetched, using the same publishable key
already shipped in the site's JavaScript. That is deliberate: the repo is
public, and the database's row-level security blocks this key from reading
member emails, admin flags and availability notes. The backup therefore
cannot leak anything that isn't already visible on the website.

NOT covered (would need the secret key, and isn't worth putting one in CI):
  - member emails, auth_id, is_admin
  - the availability table
  - Supabase Auth login accounts (not a table; can't be dumped this way)
"""

import json
import os
import sys
import urllib.error
import urllib.request

BASE = "https://htmrvfkaudpevmzgteyh.supabase.co/rest/v1"
KEY = os.environ.get(
    "SUPABASE_ANON_KEY",
    "sb_publishable_9MZLbcTj078P71YXuvO4SA_qW4tF0KF",
)
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backups")

# table -> (select clause, sort key for stable output)
# Stable sorting matters: without it row order can shift between runs and
# produce noisy diffs that look like data changes when nothing changed.
TABLES = {
    "matches":           ("*", "id"),
    "member_seasons":    ("*", "id"),
    "scheduled_matches": ("*", "id"),
    # Restricted on purpose — these are the only member columns the public
    # key can read, and the only ones safe for a public repo.
    "members":           ("id,full_name,is_guest", "id"),
}

PAGE = 1000  # PostgREST caps a single response at 1000 rows


def fetch_all(table, select):
    """Fetch every row, paging through PostgREST's 1000-row limit."""
    rows, offset = [], 0
    while True:
        url = f"{BASE}/{table}?select={select}&order=id&limit={PAGE}&offset={offset}"
        req = urllib.request.Request(url, headers={"apikey": KEY, "Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=45) as resp:
            batch = json.load(resp)
        if not isinstance(batch, list):
            raise RuntimeError(f"{table}: unexpected response {str(batch)[:200]}")
        rows.extend(batch)
        if len(batch) < PAGE:
            return rows
        offset += PAGE


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    summary, failed = {}, []

    for table, (select, sort_key) in TABLES.items():
        try:
            rows = fetch_all(table, select)
        except (urllib.error.URLError, urllib.error.HTTPError, RuntimeError, TimeoutError) as e:
            print(f"FAIL  {table}: {e}", file=sys.stderr)
            failed.append(table)
            continue

        rows.sort(key=lambda r: str(r.get(sort_key, "")))
        path = os.path.join(OUT_DIR, f"{table}.json")
        with open(path, "w") as f:
            json.dump(rows, f, indent=2, sort_keys=True, ensure_ascii=False)
            f.write("\n")
        summary[table] = len(rows)
        print(f"ok    {table}: {len(rows)} rows")

    if failed:
        # Non-zero exit turns the GitHub Action red, which emails the owner.
        print(f"\n{len(failed)} table(s) failed: {', '.join(failed)}", file=sys.stderr)
        return 1

    # A manifest makes it obvious at a glance what the snapshot holds.
    # Deliberately no timestamp — git already records when each snapshot was
    # taken, and a changing timestamp would create a commit on every run even
    # when the data is identical.
    with open(os.path.join(OUT_DIR, "manifest.json"), "w") as f:
        json.dump({"tables": summary, "source": BASE}, f, indent=2, sort_keys=True)
        f.write("\n")

    print(f"\nSnapshot complete: {sum(summary.values())} rows across {len(summary)} tables.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
