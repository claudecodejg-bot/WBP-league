# Paddle Tennis League — Setup Guide

Follow these steps in order. You only need to do this once.

---

## Step 1 — Create a Supabase account and project

1. Go to **supabase.com** and create a free account.
2. Click **New project**.
3. Name it `paddle-tennis-league`.
4. Set a database password (save it somewhere safe).
5. Choose the region closest to you.
6. Wait about 2 minutes for the project to be created.

---

## Step 2 — Copy your project credentials

1. In your Supabase project, click **Project Settings** (gear icon, bottom-left).
2. Click **API**.
3. Copy these two values:
   - **Project URL** — looks like `https://abcdefgh.supabase.co`
   - **anon public key** — a long string starting with `eyJ...`

4. Open the file **`js/supabase-client.js`** in a text editor.
5. Replace `YOUR_SUPABASE_URL` with your Project URL.
6. Replace `YOUR_SUPABASE_ANON_KEY` with your anon public key.
7. Save the file.

---

## Step 3 — Run the database setup SQL

1. In Supabase, click **SQL Editor** in the left sidebar.
2. Click **New query**.
3. Open the file **`setup.sql`** from this project folder.
4. Copy the entire contents and paste into the SQL Editor.
5. Click **Run**.

You should see a success message. This creates your 3 tables and all security rules.

---

## Step 4 — Invite your 16 members

1. In Supabase, click **Authentication** in the left sidebar.
2. Click **Users**.
3. Click **Invite user**.
4. Enter the first member's email address and click **Send invite**.
5. Repeat for all 16 members (including yourself).

Each member will receive an email with a link to set their password.

> **Important:** After inviting each person, their UUID will appear in the Users list.
> You will need these UUIDs in the next step.

---

## Step 5 — Add your members to the database

1. In Supabase, go back to **SQL Editor**.
2. Open `setup.sql` again and scroll to **STEP 4** at the bottom.
3. Replace each `REPLACE-WITH-...-AUTH-UUID` with the actual UUID from the Users list.
4. Replace the names and emails with your real league members.
5. **Make sure your own row has `is_admin = true`** — only you should have this.
6. Run just the INSERT block.

---

## Step 6 — Deploy to Netlify

1. Go to **netlify.com** and create a free account.
2. From the Netlify dashboard, click **Add new site → Deploy manually**.
3. Drag the entire **`paddle-tennis-league`** folder onto the upload area.
4. Netlify will give you a URL like `https://amazing-name-123.netlify.app`.

That's your live website! Share the URL with your league members.

> **Tip:** You can rename the site in Netlify (Site settings → Site name) to something like `my-paddle-league`.

---

## Step 7 — (Optional) Set a custom domain

If you own a domain name (e.g., `my-paddle-league.com`):
1. In Netlify: **Site settings → Domain management → Add custom domain**.
2. Follow Netlify's instructions to update your domain's DNS settings.
3. Netlify provides free HTTPS automatically.

---

## How to update the site after changes

Whenever you edit the code files:
1. Go to Netlify → your site → **Deploys**.
2. Drag the updated project folder onto the deploy area.

---

## Pages overview

| Page | URL | Who can see it |
|---|---|---|
| Standings | /standings.html | Everyone (public) |
| Results | /results.html | Everyone (public) |
| Sign In | /login.html | Everyone |
| Availability | /availability.html | Members (must be signed in) |
| Admin | /admin.html | Admin only |

---

## How scoring works

- Each match is best of 3 sets.
- For each set, enter how many games each team won (0–6 typically, 7 for a tiebreak).
- **Win** = your team won 2 sets (scored 6 in exactly 2 sets).
  - Your match score = average of your set scores + 2 bonus points
- **Loss** = your match score = average of your set scores
- **Season average** = a running average using your spreadsheet formula:
  `AVERAGE − (MAX + MIN − 2×AVERAGE) / COUNT`

---

## Troubleshooting

**"Could not load your member profile"**
The logged-in user doesn't have a matching row in the `members` table.
Go to Supabase → Table Editor → members and check that the `auth_id` matches the user's UUID in Authentication → Users.

**Standings show no data**
No matches have been entered yet. Go to `/admin.html` and add a match result.

**Admin page redirects to standings**
The logged-in user's `is_admin` column is `false`. Go to Supabase → Table Editor → members and set `is_admin = true` for your row.

**"Failed to save availability"**
Check that the RLS policies were created correctly in Step 3. Re-run the policy creation part of `setup.sql` if needed.
