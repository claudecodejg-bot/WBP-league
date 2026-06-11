// =============================================
//  Supabase Client — shared across all pages
// =============================================

// Pinned to an exact version (not the floating @2 tag) so a bad upstream
// build or a CDN resolving @2 to something breaking can't take the site down.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.108.1'

const SUPABASE_URL  = 'https://htmrvfkaudpevmzgteyh.supabase.co'
const SUPABASE_ANON = 'sb_publishable_9MZLbcTj078P71YXuvO4SA_qW4tF0KF'

// How long to wait before giving up on a request. A paused Supabase project
// accepts the connection but never responds, so without a timeout the fetch
// hangs forever and the page's loading spinner never clears. Aborting after
// this many ms turns that hang into a normal error the page can display.
const REQUEST_TIMEOUT_MS = 15000

// The new sb_publishable_ key must NOT be sent as a Bearer token.
// This custom fetch removes the Authorization header when it contains
// the anon key, but keeps it when it contains a real user JWT.
// It also enforces a timeout so a hung/paused backend fails cleanly.
function customFetch(url, options = {}) {
  const headers = new Headers(options.headers)
  const auth = headers.get('Authorization')
  if (auth === `Bearer ${SUPABASE_ANON}`) {
    headers.delete('Authorization')
  }

  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)
  // If the caller already passed a signal, abort when either fires.
  if (options.signal) {
    options.signal.addEventListener('abort', () => controller.abort())
  }

  return fetch(url, { ...options, headers, signal: controller.signal })
    .finally(() => clearTimeout(timer))
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON, {
  global: { fetch: customFetch }
})

// Escapes HTML special characters so user-entered text (e.g. availability
// notes) can't break out of markup or inject script when interpolated into
// innerHTML. Use on any value that originated from a user.
export function escapeHtml(value) {
  if (value === null || value === undefined) return ''
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

// Standard message shown when the Supabase request throws (network failure,
// DNS error, or a paused project) rather than returning a normal error object.
// Without this, the page's loading spinner would spin forever.
export function connectionErrorHtml() {
  return '<div class="alert alert-error">Couldn\'t reach the server. It may be temporarily offline — ' +
         '<a href="#" onclick="location.reload();return false;">retry</a>.</div>'
}
