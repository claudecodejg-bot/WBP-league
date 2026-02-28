// =============================================
//  Supabase Client — shared across all pages
// =============================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL  = 'https://htmrvfkaudpevmzgteyh.supabase.co'
const SUPABASE_ANON = 'sb_publishable_9MZLbcTj078P71YXuvO4SA_qW4tF0KF'

// The new sb_publishable_ key must NOT be sent as a Bearer token.
// This custom fetch removes the Authorization header when it contains
// the anon key, but keeps it when it contains a real user JWT.
function customFetch(url, options = {}) {
  const headers = new Headers(options.headers)
  const auth = headers.get('Authorization')
  if (auth === `Bearer ${SUPABASE_ANON}`) {
    headers.delete('Authorization')
  }
  return fetch(url, { ...options, headers })
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON, {
  global: { fetch: customFetch }
})
