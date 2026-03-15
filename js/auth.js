// =============================================
//  Auth helpers — used by all protected pages
// =============================================

import { supabase } from './supabase-client.js'

/** Returns the current session, or null if not logged in. */
export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession()
  return session
}

/**
 * Redirects to login.html if no active session.
 * Returns the session if valid.
 */
export async function requireLogin() {
  const session = await getSession()
  if (!session) {
    window.location.href = 'login.html'
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
  window.location.href = '/login.html'
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

  const authBtn = document.getElementById('nav-auth-btn')
  if (!authBtn) return

  const session = await getSession()
  if (session) {
    authBtn.textContent = 'Sign Out'
    authBtn.addEventListener('click', signOut)
  } else {
    authBtn.textContent = 'Sign In'
    authBtn.addEventListener('click', () => { window.location.href = 'login.html' })
  }
}
