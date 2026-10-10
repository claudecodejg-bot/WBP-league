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
