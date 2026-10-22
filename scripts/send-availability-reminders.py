#!/usr/bin/env python3
"""
Nudge members who haven't set their availability for the coming Monday.

Two reminders, both to non-responders only — anyone who has answered, yes
or no, is left alone:

  Thursday 3pm ET  general reminder
  Friday 10am ET   final notice: no answer by noon means unavailable

That last line is not a threat invented for the email. The scheduler only
ever picks from people who explicitly said yes, so a missing answer
already means "not playing". The email just says so out loud.

Scheduling: GitHub's cron is UTC, which drifts against New York twice a
year. The workflow therefore fires at both candidate UTC hours and this
script decides whether the local time is actually a send window, exiting
quietly when it isn't. That keeps the behaviour correct across DST with
no workflow edits.

PRIVACY: this repo is public, so the Action log is public. Addresses are
never printed — names and counts only.

Environment:
  SUPABASE_SECRET_KEY  required. Reads members.email and the availability
                       table, both of which the publishable key cannot see.
  RESEND_API_KEY       required unless --dry-run.
  REMINDER_FORCE       optional: "thursday" or "friday" to bypass the time
                       gate, for testing.

Usage:
  python3 scripts/send-availability-reminders.py --dry-run
  python3 scripts/send-availability-reminders.py
"""

import argparse
import datetime as dt
import json
import os
import re
import sys
import urllib.error
import urllib.request
from html import unescape
from zoneinfo import ZoneInfo

BASE = "https://htmrvfkaudpevmzgteyh.supabase.co/rest/v1"
RESEND_URL = "https://api.resend.com/emails"
SENDER = "WBP League <noreply@wbpleague.com>"
SITE = "https://wbpleague.com/availability.html"
TZ = ZoneInfo("America/New_York")

# Cloudflare fronts Resend's API and blocks clients whose User-Agent looks
# automated — urllib's default "Python-urllib/3.x" earns a 403 with error
# code 1010, which never reaches Resend at all. Identify properly instead.
USER_AGENT = "wbp-league-reminders/1.0 (+https://wbpleague.com)"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_JS = os.path.join(ROOT, "js", "config.js")


# ── config.js is the single source of truth, so read it rather than
#    restating the season dates here and letting the two drift apart.
def read_config():
    src = open(CONFIG_JS, encoding="utf-8").read()

    def const(name):
        m = re.search(r"export const %s\s*=\s*'([^']+)'" % name, src)
        if not m:
            sys.exit("Could not find %s in js/config.js" % name)
        return m.group(1)

    m = re.search(r"export const UNOFFICIAL_WEEKS\s*=\s*\[([^\]]*)\]", src)
    unofficial = re.findall(r"'([^']+)'", m.group(1)) if m else []

    return {
        "season": const("CURRENT_SEASON"),
        "start": const("AVAILABILITY_START"),
        "end": const("AVAILABILITY_END"),
        "unofficial": unofficial,
    }


def target_monday(now_local, cfg):
    """The Monday responses are being collected for: the next one on or
    after today, clamped to the configured availability window."""
    today = now_local.date()
    ahead = (0 - today.weekday()) % 7          # Monday is 0
    monday = today + dt.timedelta(days=ahead)

    start = dt.date.fromisoformat(cfg["start"])
    end = dt.date.fromisoformat(cfg["end"])
    if monday < start:
        monday = start
    if monday > end:
        return None                            # window closed for the season
    return monday


# Windows, not exact hours. GitHub's scheduler has run this workflow up to
# three and a half hours behind its cron time, so an exact-hour test missed
# every single run. The workflow now fires hourly across the morning and
# afternoon and these windows decide which run does the work; a claim in the
# database stops the others repeating it.
#
# Friday closes at noon on purpose: the email says "if we haven't heard from
# you by noon today", which is false after noon. Better to send nothing than
# to send that.
THURSDAY_WINDOW = range(15, 20)   # 3pm to 7:59pm ET
FRIDAY_WINDOW   = range(9, 12)    # 9am to 11:59am ET


def which_reminder(now_local):
    forced = os.environ.get("REMINDER_FORCE", "").strip().lower()
    if forced in ("thursday", "friday"):
        return forced
    # weekday(): Thursday 3, Friday 4
    if now_local.weekday() == 3 and now_local.hour in THURSDAY_WINDOW:
        return "thursday"
    if now_local.weekday() == 4 and now_local.hour in FRIDAY_WINDOW:
        return "friday"
    return None


def claim(monday, kind):
    """
    Claim this (week, reminder) so only one run sends it.

    The insert is the lock: the table's primary key is (week_start, kind),
    so a second run gets a 409 and backs off. Claiming before sending
    rather than recording after means two runs overlapping cannot both
    get through.

    Returns True if this run owns the send.
    """
    body = json.dumps({"week_start": monday.isoformat(), "kind": kind}).encode()
    req = urllib.request.Request(
        BASE + "/reminder_log", data=body,
        headers={
            "apikey": SECRET, "Authorization": "Bearer " + SECRET,
            "Content-Type": "application/json", "Prefer": "return=minimal",
            "User-Agent": USER_AGENT,
        }, method="POST")
    try:
        urllib.request.urlopen(req, timeout=30)
        return True
    except urllib.error.HTTPError as e:
        if e.code == 409:
            return False          # another run already sent this one
        if e.code == 404:
            # Table missing: the migration has not been run. Say so loudly
            # rather than silently sending the same email every hour.
            print("reminder_log table not found — run add-reminder-log.sql. "
                  "Refusing to send without it, to avoid repeat emails.")
            sys.exit(1)
        raise


def release(monday, kind):
    """Give the claim back when nothing actually went out, so a later run
    in the same window can try again."""
    url = "%s/reminder_log?week_start=eq.%s&kind=eq.%s" % (
        BASE, monday.isoformat(), kind)
    req = urllib.request.Request(
        url, headers={"apikey": SECRET, "Authorization": "Bearer " + SECRET,
                      "User-Agent": USER_AGENT},
        method="DELETE")
    try:
        urllib.request.urlopen(req, timeout=30)
    except Exception:
        pass


def get(path):
    req = urllib.request.Request(
        BASE + path,
        headers={
            "apikey": SECRET,
            "Authorization": "Bearer " + SECRET,
            "Accept": "application/json",
            "User-Agent": USER_AGENT,
        },
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def non_responders(monday, cfg):
    """Current-season members with an address and no answer for that week."""
    members = get("/members?select=id,full_name,email,is_guest")
    roster = get("/member_seasons?select=member_id&season=eq." + cfg["season"])
    answered = get("/availability?select=member_id&week_start=eq." + monday.isoformat())

    on_roster = {r["member_id"] for r in roster}
    replied = {r["member_id"] for r in answered}

    out = []
    for m in members:
        if m["id"] not in on_roster or m["id"] in replied:
            continue
        if not (m.get("email") or "").strip():
            continue                            # no address on file; nothing to send
        out.append(m)
    return sorted(out, key=lambda m: m["full_name"]), len(on_roster), len(replied)


def render(kind, name, monday):
    when = monday.strftime("%-d %B")   # "Monday" is already in the sentence
    first = name.split(",")[0]

    if kind == "thursday":
        subject = "Paddle Monday %s — are you in?" % monday.strftime("%-d %b")
        lead = (
            "We're putting the courts together for <strong>Monday %s</strong> "
            "and haven't heard from you yet." % when
        )
        close = "Takes about five seconds — it saves as soon as you tap."
    else:
        subject = "Last call — paddle Monday %s" % monday.strftime("%-d %b")
        lead = (
            "Still nothing from you for <strong>Monday %s</strong>, and pairings "
            "go out this afternoon." % when
        )
        close = (
            "<strong>If we haven't heard from you by noon today, we'll assume "
            "you're unavailable</strong> and you won't be put on a court."
        )

    html = """\
<div style="font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;
            font-size:15px;line-height:1.6;color:#1a1a1a;max-width:520px;">
  <p>%s,</p>
  <p>%s</p>
  <p style="margin:1.4rem 0;">
    <a href="%s" style="background:#f4845f;color:#fff;text-decoration:none;
       padding:11px 20px;border-radius:8px;font-weight:700;display:inline-block;">
      Set your availability
    </a>
  </p>
  <p>%s</p>
  <p style="color:#4a4a4a;font-size:13px;margin-top:1.6rem;">
    WBP League &middot; <a href="https://wbpleague.com" style="color:#4a4a4a;">wbpleague.com</a>
  </p>
</div>""" % (first, lead, SITE, close)

    text = re.sub(r"<[^>]+>", "", "%s,\n\n%s\n\n%s\n\n%s\n\nWBP League — wbpleague.com"
                  % (first, lead, SITE, close))
    return subject, html, text


def send(to_addr, subject, html, text):
    body = json.dumps({
        "from": SENDER, "to": [to_addr],
        "subject": subject, "html": html, "text": text,
    }).encode()
    req = urllib.request.Request(
        RESEND_URL, data=body,
        headers={
            "Authorization": "Bearer " + RESEND_KEY,
            "Content-Type": "application/json",
            "User-Agent": USER_AGENT,
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true",
                    help="work out who would be emailed and show it, send nothing")
    args = ap.parse_args()

    now = dt.datetime.now(TZ)
    kind = which_reminder(now)
    print("Local time: %s" % now.strftime("%a %d %b %H:%M %Z"))

    if not kind:
        print("Not a reminder window (Thu 3pm / Fri 10am ET). Nothing to do.")
        return 0

    cfg = read_config()
    monday = target_monday(now, cfg)
    if monday is None:
        print("Past AVAILABILITY_END (%s) — season window closed." % cfg["end"])
        return 0

    warm = " (warm-up week)" if monday.isoformat() in cfg["unofficial"] else ""
    print("Reminder: %s | week of %s%s" % (kind, monday, warm))

    people, roster_n, replied_n = non_responders(monday, cfg)
    print("Roster %d · answered %d · chasing %d" % (roster_n, replied_n, len(people)))

    if not people:
        print("Everyone has answered. No emails sent.")
        return 0

    # Names only. Addresses must not reach a public Action log.
    print("To: " + ", ".join(p["full_name"] for p in people))
    if args.dry_run:
        subject, html, _ = render(kind, people[0]["full_name"], monday)
        print("\n--- dry run, nothing sent ---\nSubject: %s\n" % subject)
        # Strip the markup and turn &middot; and friends back into characters,
        # so the preview reads like the email instead of like source.
        preview = unescape(re.sub(r"<[^>]+>", "", html))
        print(re.sub(r"\n\s*\n", "\n", preview).strip())
        return 0

    # Take the slot before sending anything. If another run in today's
    # window already has it, stop here.
    if not claim(monday, kind):
        print("Already sent for this week — another run got there first.")
        return 0

    sent = failed = 0
    for p in people:
        subject, html, text = render(kind, p["full_name"], monday)
        try:
            send(p["email"], subject, html, text)
            sent += 1
        except urllib.error.HTTPError as e:
            # Name the person, never the address.
            print("FAILED for %s: HTTP %s %s" % (p["full_name"], e.code,
                                                 e.read().decode()[:200]))
            failed += 1
        except Exception as e:
            print("FAILED for %s: %s" % (p["full_name"], e))
            failed += 1

    print("Sent %d, failed %d." % (sent, failed))

    # Nothing got through, so do not let the claim block a retry later in
    # the window.
    if sent == 0:
        release(monday, kind)
        print("Nothing sent — claim released so a later run can retry.")

    return 1 if failed else 0


if __name__ == "__main__":
    SECRET = os.environ.get("SUPABASE_SECRET_KEY", "").strip()
    RESEND_KEY = os.environ.get("RESEND_API_KEY", "").strip()
    if not SECRET:
        sys.exit("SUPABASE_SECRET_KEY is not set.")
    if not RESEND_KEY and "--dry-run" not in sys.argv:
        sys.exit("RESEND_API_KEY is not set (or pass --dry-run).")
    sys.exit(main())
