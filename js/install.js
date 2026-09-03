// =============================================
//  "Add to Home Screen" prompt
// =============================================
// Plain script (no imports), loaded with defer on every page.
//
// The two platforms work very differently:
//
//   Android / desktop Chrome — fire a real install prompt via the
//   `beforeinstallprompt` event. One tap and it installs.
//
//   iPhone / iPad — Safari has no install API at all. The only route is the
//   user tapping Share → Add to Home Screen, so the button opens short
//   instructions instead. Chrome and Firefox on iOS cannot install at all
//   (only Safari can), so we tell those users to open the page in Safari.
//
// The banner hides itself once the app is installed, and stays hidden for
// 60 days after someone dismisses it.

// Register the service worker. This must happen regardless of whether the
// banner is shown — without it Android/Chrome will never offer to install.
// Note it caches nothing; see sw.js for why.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('sw.js').catch(function (err) {
      console.warn('Service worker registration failed:', err)
    })
  })
}

(function () {
  var DISMISS_KEY = 'wbpInstallDismissedAt'
  var DISMISS_DAYS = 60

  // ── Environment checks ────────────────────────────────────────────────
  function isInstalled() {
    return window.matchMedia('(display-mode: standalone)').matches ||
           window.navigator.standalone === true
  }

  // iPadOS 13+ reports itself as a Mac, so also treat a touch-capable
  // "MacIntel" as iOS.
  function isIOS() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
           (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
  }

  // On iOS every browser uses the WebKit engine, but only Safari itself can
  // add to the home screen. Chrome/Firefox/Edge on iOS identify themselves
  // with these tokens.
  function isIOSSafari() {
    return isIOS() && !/CriOS|FxiOS|EdgiOS|OPiOS|mercury/i.test(navigator.userAgent)
  }

  function wasDismissed() {
    try {
      var at = localStorage.getItem(DISMISS_KEY)
      if (!at) return false
      return (Date.now() - parseInt(at, 10)) < DISMISS_DAYS * 86400000
    } catch (e) {
      return false   // private mode / storage blocked — just show it
    }
  }

  function rememberDismissal() {
    try { localStorage.setItem(DISMISS_KEY, String(Date.now())) } catch (e) {}
  }

  if (isInstalled() || wasDismissed()) return

  // ── Banner ────────────────────────────────────────────────────────────
  var deferredPrompt = null
  var banner = null

  function buildBanner(actionLabel, onAction) {
    if (banner) return
    banner = document.createElement('div')
    banner.className = 'a2hs-banner'
    banner.setAttribute('role', 'region')
    banner.setAttribute('aria-label', 'Install this app')
    banner.innerHTML =
      '<img src="icons/icon-192.png" alt="" class="a2hs-icon">' +
      '<div class="a2hs-text">' +
        '<div class="a2hs-title">Add WBP League to your phone</div>' +
        '<div class="a2hs-sub">Open it like an app, straight from your home screen.</div>' +
      '</div>' +
      '<button type="button" class="a2hs-action"></button>' +
      '<button type="button" class="a2hs-close" aria-label="Not now">&times;</button>'

    banner.querySelector('.a2hs-action').textContent = actionLabel
    banner.querySelector('.a2hs-action').addEventListener('click', onAction)
    banner.querySelector('.a2hs-close').addEventListener('click', function () {
      rememberDismissal()
      hideBanner()
    })
    document.body.appendChild(banner)
    // Brief timeout (not requestAnimationFrame) so the slide-up transition
    // still runs when the page was loaded in a background tab — rAF is
    // paused while a tab is hidden, which would leave the banner stuck
    // off-screen until the user happened to focus the tab.
    setTimeout(function () { if (banner) banner.classList.add('a2hs-show') }, 20)
  }

  function hideBanner() {
    if (!banner) return
    banner.classList.remove('a2hs-show')
    setTimeout(function () {
      if (banner && banner.parentNode) banner.parentNode.removeChild(banner)
      banner = null
    }, 250)
  }

  // ── iOS instructions sheet ────────────────────────────────────────────
  function showIOSInstructions() {
    var safari = isIOSSafari()
    var overlay = document.createElement('div')
    overlay.className = 'a2hs-overlay'
    overlay.innerHTML =
      '<div class="a2hs-sheet" role="dialog" aria-modal="true" aria-label="Add to Home Screen">' +
        '<button type="button" class="a2hs-sheet-close" aria-label="Close">&times;</button>' +
        '<div class="a2hs-sheet-title">Add to Home Screen</div>' +
        (safari
          ? '<ol class="a2hs-steps">' +
              '<li>Tap the <strong>Share</strong> button at the bottom of Safari ' +
                '<span class="a2hs-share" aria-hidden="true">&#x2191;</span></li>' +
              '<li>Scroll down and tap <strong>Add to Home Screen</strong></li>' +
              '<li>Tap <strong>Add</strong> in the top right</li>' +
            '</ol>'
          : '<p class="a2hs-note">On iPhone and iPad, only <strong>Safari</strong> can add a site ' +
            'to the home screen. Open this page in Safari, then tap ' +
            '<strong>Share &rarr; Add to Home Screen</strong>.</p>') +
      '</div>'

    function close() {
      overlay.classList.remove('a2hs-show')
      setTimeout(function () {
        if (overlay.parentNode) overlay.parentNode.removeChild(overlay)
      }, 200)
    }
    overlay.addEventListener('click', function (e) { if (e.target === overlay) close() })
    overlay.querySelector('.a2hs-sheet-close').addEventListener('click', close)
    document.addEventListener('keydown', function esc(e) {
      if (e.key === 'Escape') { close(); document.removeEventListener('keydown', esc) }
    })
    document.body.appendChild(overlay)
    setTimeout(function () { overlay.classList.add('a2hs-show') }, 20)
  }

  // ── Android / desktop Chrome ──────────────────────────────────────────
  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault()            // stop Chrome's own mini-infobar
    deferredPrompt = e
    buildBanner('Install', function () {
      if (!deferredPrompt) return
      hideBanner()
      deferredPrompt.prompt()
      deferredPrompt.userChoice.then(function (choice) {
        if (choice.outcome !== 'accepted') rememberDismissal()
        deferredPrompt = null
      })
    })
  })

  window.addEventListener('appinstalled', function () {
    rememberDismissal()
    hideBanner()
  })

  // ── iOS ───────────────────────────────────────────────────────────────
  // No install event exists, so show the banner on a short delay and let the
  // button explain the manual steps.
  if (isIOS()) {
    setTimeout(function () {
      buildBanner('How', showIOSInstructions)
    }, 1500)
  }
})()
