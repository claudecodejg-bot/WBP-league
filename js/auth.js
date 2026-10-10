// =============================================
//  Auth helpers — used by all protected pages
// =============================================

import { supabase } from './supabase-client.js'

/** Returns the current session, or null if not logged in. */
export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession()
  return session
}

// Pages that should never be a post-login destination: sending someone back
// to the login screen (or the password form) after they sign in would loop.
const NEVER_RETURN_TO = ['login.html', 'set-password.html']

/**
 * Validates a "return to this page" value before redirecting to it.
 *
 * Only a bare page name from this site is accepted — e.g. "availability.html"
 * or "player.html?id=…". Anything else (full URLs, "//other-site.com",
 * "javascript:" and so on) is rejected, so a crafted sign-in link can't be
 * used to bounce a member off to another website after they log in.
 *
 * Returns the safe page, or null.
 */
export function safeReturnPage(raw) {
  if (!raw) return null
  if (!/^[a-z0-9_-]+\.html(\?[^#]*)?$/i.test(raw)) return null
  const page = raw.split('?')[0].toLowerCase()
  return NEVER_RETURN_TO.includes(page) ? null : raw
}

/**
 * Where to send someone once they've signed in: the page they were trying to
 * open if there was one, otherwise the home page.
 */
export function postLoginDestination() {
  const next = new URLSearchParams(window.location.search).get('next')
  return safeReturnPage(next) || 'index.html'
}

/**
 * Redirects to login.html if no active session, remembering the current page
 * so the member comes straight back here after signing in.
 * Returns the session if valid.
 */
export async function requireLogin() {
  const session = await getSession()
  if (!session) {
    const here = (window.location.pathname.split('/').pop() || 'index.html') + window.location.search
    const next = safeReturnPage(here)
    window.location.href = next ? `login.html?next=${encodeURIComponent(next)}` : 'login.html'
    return null
  }
  return session
}

/**
 * Checks that the logged-in user is an admin.
 * Redirects to standings.html if not.
 * Returns the member record if valid.
 */
export async function requireAdmin() {
  const session = await requireLogin()
  if (!session) return null

  const { data: member, error } = await supabase
    .from('members')
    .select('id, full_name, is_admin')
    .eq('auth_id', session.user.id)
    .single()

  if (error || !member?.is_admin) {
    window.location.href = 'standings.html'
    return null
  }
  return member
}

/**
 * Returns the logged-in member's record, or null.
 * Does NOT redirect — use requireLogin() first if you need that.
 */
export async function getCurrentMember() {
  const session = await getSession()
  if (!session) return null

  const { data: member } = await supabase
    .from('members')
    .select('id, full_name, is_admin')
    .eq('auth_id', session.user.id)
    .single()

  return member || null
}

/** Signs the user out and redirects to login.html. */
export async function signOut() {
  await supabase.auth.signOut()
  window.location.href = 'login.html'
}

/**
 * Updates the nav bar based on login state.
 * Call this on every page.
 */
export async function initNav(activePage) {
  // Mark active link
  if (activePage) {
    const link = document.querySelector(`.nav-links a[data-page="${activePage}"]`)
    if (link) link.classList.add('active')
  }

  // Sign in/out lives in the menu rather than as its own button in the bar.
  // On a phone the bar only has room for the logo, Save and the menu toggle.
  const links = document.querySelector('.nav-links')
  if (!links) return

  const session = await getSession()
  const li = document.createElement('li')
  li.className = 'nav-auth-item'

  const link = document.createElement('a')
  link.href = '#'
  link.id = 'nav-auth-link'
  link.textContent = session ? 'Sign Out' : 'Sign In'
  link.addEventListener('click', e => {
    e.preventDefault()
    if (session) signOut()
    else window.location.href = 'login.html'
  })

  li.appendChild(link)
  links.appendChild(li)
}
