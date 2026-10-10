// =============================================
//  Shared nav behavior — hamburger menu + footer year
//  Plain script (no imports) so the menu still works
//  even if the CDN/Supabase module chain fails to load.
//  Include with: <script src="js/nav.js" defer></script>
// =============================================
(function () {
  var btn = document.getElementById('nav-hamburger')
  if (btn) {
    btn.addEventListener('click', function () {
      var open = btn.closest('nav').classList.toggle('nav-open')
      btn.textContent = open ? '✕' : '☰'
      btn.setAttribute('aria-expanded', open)
    })
    document.querySelectorAll('.nav-links a').forEach(function (a) {
      a.addEventListener('click', function () {
        btn.closest('nav').classList.remove('nav-open')
        btn.textContent = '☰'
        btn.setAttribute('aria-expanded', 'false')
      })
    })
  }

  var year = document.getElementById('footer-year')
  if (year) year.textContent = new Date().getFullYear()
})()

// ── Temporary layout probe ───────────────────────────────────────────────
// Add ?debug=1 to any page to show live layout numbers in the corner. Used
// to diagnose a header that stays pinned on some phones and not others.
// Remove this block once that is settled.
;(function () {
  if (!/[?&]debug=1\b/.test(location.search)) return

  var box = document.createElement('div')
  box.style.cssText =
    'position:fixed;left:4px;bottom:4px;z-index:99999;background:rgba(0,0,0,.82);' +
    'color:#0f0;font:11px/1.35 monospace;padding:6px 8px;border-radius:6px;' +
    'max-width:94vw;white-space:pre;pointer-events:none'
  document.addEventListener('DOMContentLoaded', function () { document.body.appendChild(box) })

  function read() {
    var de  = document.documentElement
    var nav = document.querySelector('nav')
    var ham = document.getElementById('nav-hamburger')
    var vv  = window.visualViewport
    var nr  = nav ? nav.getBoundingClientRect() : null
    var hr  = ham ? ham.getBoundingClientRect() : null

    box.textContent = [
      'innerW ' + window.innerWidth + '  clientW ' + de.clientWidth,
      'scrollW ' + de.scrollWidth + (de.scrollWidth > de.clientWidth ? '  << WIDER' : '  ok'),
      'media<=640 ' + window.matchMedia('(max-width:640px)').matches,
      vv ? ('vv w ' + Math.round(vv.width) + ' offL ' + Math.round(vv.offsetLeft) +
            ' offT ' + Math.round(vv.offsetTop) + ' scale ' + vv.scale.toFixed(2)) : 'vv n/a',
      nav ? ('nav ' + getComputedStyle(nav).position + ' top ' + Math.round(nr.top) +
             ' left ' + Math.round(nr.left) + ' w ' + Math.round(nr.width)) : 'nav MISSING',
      ham ? ('ham ' + getComputedStyle(ham).display + ' right ' + Math.round(hr.right) +
             ' vis ' + (ham.checkVisibility ? ham.checkVisibility() : 'n/a')) : 'ham MISSING',
      'scrollY ' + Math.round(window.scrollY) + '  scrollX ' + Math.round(window.scrollX)
    ].join('\n')
  }

  read()
  setInterval(read, 400)
  window.addEventListener('scroll', read, { passive: true })
  window.addEventListener('resize', read)
  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', read)
    window.visualViewport.addEventListener('scroll', read)
  }
})()
