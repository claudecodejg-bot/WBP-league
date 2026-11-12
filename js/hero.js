// =============================================
//  Page banners — league photos, rotating
// =============================================
//  League photographs cross-fade behind a page's banner so it reads as a
//  picture of THIS league rather than stock art. Used by the picks board,
//  Standings, Results and the Championship page.
//
//  WHY IT IS NOT IN THE CSS
//
//  A pure-CSS stack would need every one of them in the stylesheet, so
//  every one would be fetched before anything appeared — 1.7MB as the
//  list stands — and a phone on a bad connection would stare at a plain
//  gradient the whole time. Here the first photo is the only one fetched
//  up front; each later one is fetched a moment before it is needed and
//  never at all if the tab is closed, or hidden, before its turn comes
//  round. That is why the list can keep growing without costing anything
//  to whoever only glances at the page.
//
//  If this module fails to load, the banner keeps the charcoal-and-coral
//  gradient it has in the stylesheet, which is a finished design in its
//  own right rather than an empty box.

//  Fourteen of them, running from the 2014 cage match to last spring, so
//  the banner is the league's own history rather than one good night.
//  Order is deliberate: no two line-ups of the same twenty men in the
//  same clubhouse next to each other, since consecutive near-identical
//  frames read as the rotation being broken rather than as two photos.
const PHOTOS = [
  // position: where to hold the crop as the box gets wider or narrower.
  // Faces are the thing not to cut, and in most of these they sit above
  // centre — hence the percentages under 50.
  { src: 'banners/court-night.jpg',     position: 'center 55%' },
  { src: 'banners/lineup-2021.jpg',     position: 'center 45%' },
  { src: 'banners/champs-2023.jpg',     position: 'center 42%' },
  { src: 'banners/cage-2014.jpg',       position: 'center 38%' },
  { src: 'banners/group-2026.jpg',      position: 'center 38%' },
  { src: 'banners/play-2019.jpg',       position: 'center 48%' },
  { src: 'banners/group-2022.jpg',      position: 'center 42%' },
  { src: 'banners/cage-2017.jpg',       position: 'center 38%' },
  { src: 'banners/finalists-2026.jpg',  position: 'center 40%' },
  { src: 'banners/rainbow-2026.jpg',    position: 'center 58%' },
  { src: 'banners/group-2023.jpg',      position: 'center 40%' },
  { src: 'banners/champs-2019.jpg',     position: 'center 38%' },
  { src: 'banners/cage-2016.jpg',       position: 'center 40%' },
  { src: 'banners/champs-2026.jpg',     position: 'center 45%' },
]

const DWELL = 7000    // how long a photo holds
const FADE  = 1200    // must match --hero-fade in the stylesheet

const reduceMotion = () =>
  window.matchMedia?.('(prefers-reduced-motion: reduce)').matches === true

/** Resolves once the image is in cache, or when it fails — never rejects. */
function preload(src) {
  return new Promise(resolve => {
    const img = new Image()
    img.onload = img.onerror = () => resolve()
    img.src = src
  })
}

function paint(layer, photo) {
  layer.style.backgroundImage    = `url('${photo.src}')`
  layer.style.backgroundPosition = photo.position
}

/**
 * `photos` lets a page choose its own set — see CHAMPIONS. Left out, it
 * gets all of them.
 */
export function startHero(hero, photos = PHOTOS) {
  if (!hero || !photos.length) return

  const layers = [document.createElement('div'), document.createElement('div')]
  for (const el of layers) {
    el.className = 'hero-img'
    el.setAttribute('aria-hidden', 'true')   // decoration, not content
    hero.prepend(el)
  }

  // Start somewhere different each visit, so the page isn't always the
  // same photograph to anyone who opens it twice in a night.
  let index = Math.floor(Math.random() * photos.length)
  let front = 0

  paint(layers[front], photos[index])
  layers[front].classList.add('is-on')

  // One photo, held still, for anyone who has asked for less movement.
  if (photos.length === 1 || reduceMotion()) return

  let timer = null

  async function advance() {
    const next  = photos[(index + 1) % photos.length]
    const back  = 1 - front

    // Fetch before fading. Swapping to a URL that has not arrived shows a
    // gap where the photo should be for as long as the request takes.
    await preload(next.src)
    if (timer === null) return          // stopped while we were waiting

    paint(layers[back], next)
    layers[back].classList.add('is-on')
    layers[front].classList.remove('is-on')

    front = back
    index = (index + 1) % photos.length
  }

  function stop()  { window.clearInterval(timer); timer = null }
  function start() { if (timer === null) timer = window.setInterval(advance, DWELL + FADE) }

  // A hidden tab has no one looking at it; rotating there would only spend
  // someone's data on photographs nobody sees.
  document.addEventListener('visibilitychange', () => {
    document.hidden ? stop() : start()
  })

  start()
}
