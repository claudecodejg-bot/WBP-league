#!/usr/bin/env python3
"""
Stamp a content fingerprint onto the stylesheet and scripts in every page.

GitHub Pages tells browsers to keep files for ten minutes, so a CSS change can
take that long to reach people — and longer in an installed home-screen app.
Adding ?v=<hash of the file> makes each change a new URL, so updates appear
immediately while unchanged files still cache normally.

Run this after editing anything under css/ or js/, before committing. Safe to
run any time: it only rewrites when a hash changes, and running it twice leaves
the second run with nothing to do.

Imports *between* modules are stamped too, so a page can never run a fresh
module against a cached old one. A module's own fingerprint covers the stamps
it carries, which means a change to a leaf like config.js ripples out to every
module importing it and on into the pages — the scheduler once showed stale
ratings and opponent counts for exactly this reason, and it looked like a bug
in the pairing logic.
"""

import hashlib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Referenced from HTML by src/href rather than imported.
ASSETS = ["css/style.css", "js/nav.js", "js/install.js"]

# A relative module import — `from './x.js'`, `import './x.js'` or
# `import('./x.js')` — with or without a stamp already on it.
IMPORT = re.compile(
    r"""(?P<lead>from\s+|import\s*\(\s*|import\s+)"""
    r"""(?P<quote>['"])(?P<spec>\.{1,2}/[\w./-]+\.js)(?:\?v=[0-9a-z]+)?(?P=quote)"""
)


class CycleError(Exception):
    pass


def digest(path):
    return hashlib.md5(path.read_bytes()).hexdigest()[:8]


def modules():
    """Every module in the site, keyed by its path relative to the repo root."""
    found = {}
    for path in sorted(ROOT.rglob("*.js")):
        if ".git" in path.parts or "node_modules" in path.parts:
            continue
        found[path.relative_to(ROOT).as_posix()] = path
    return found


def imports_of(path, text, known):
    """The modules `text` imports, as (match, key) pairs we can resolve."""
    for match in IMPORT.finditer(text):
        target = (path.parent / match.group("spec")).resolve()
        try:
            key = target.relative_to(ROOT).as_posix()
        except ValueError:
            continue
        if key in known:
            yield match, key


def leaves_first(deps):
    """Order modules so everything a module imports is fingerprinted first."""
    order, state = [], {}

    def visit(key, trail):
        if state.get(key) == "done":
            return
        if state.get(key) == "open":
            loop = trail[trail.index(key):] + [key]
            raise CycleError(" -> ".join(loop))
        state[key] = "open"
        for dep in deps[key]:
            visit(dep, trail + [key])
        state[key] = "done"
        order.append(key)

    for key in sorted(deps):
        visit(key, [])
    return order


def stamp(path, text, hashes, known):
    """Rewrite the import stamps in `text`. Returns the new text."""
    edits = []
    for match, key in imports_of(path, text, known):
        if key not in hashes:
            continue
        quote, spec = match.group("quote"), match.group("spec")
        edits.append(
            (match.start(), match.end(),
             f"{match.group('lead')}{quote}{spec}?v={hashes[key]}{quote}")
        )
    for start, end, replacement in reversed(edits):
        text = text[:start] + replacement + text[end:]
    return text


def main():
    known = modules()
    deps = {key: sorted({k for _, k in imports_of(path, path.read_text(), known)})
            for key, path in known.items()}
    try:
        order = leaves_first(deps)
    except CycleError as loop:
        print(f"import cycle: {loop}", file=sys.stderr)
        return 1

    changed = []
    hashes = {}
    for key in order:
        path = known[key]
        original = path.read_text()
        text = stamp(path, original, hashes, known)
        if text != original:
            path.write_text(text)
            changed.append(key)
        # Hashed after stamping, so a dependency's change reaches this module.
        hashes[key] = digest(path)

    assets = {a: hashes.get(a) or digest(ROOT / a)
              for a in ASSETS if (ROOT / a).exists()}

    for page in sorted(ROOT.glob("*.html")):
        original = page.read_text()
        text = original
        for asset, hashed in assets.items():
            # Matches the asset with or without an existing ?v= stamp.
            text = re.sub(
                rf'({re.escape(asset)})(\?v=[0-9a-f]+)?(["\'])',
                rf'\g<1>?v={hashed}\g<3>',
                text,
            )
        # Modules a page imports directly. availability.html used to carry a
        # hand-maintained ?v=6 that nobody remembered to bump, so phones kept
        # serving a stale copy.
        text = stamp(page, text, hashes, known)
        if text != original:
            page.write_text(text)
            changed.append(page.name)

    for asset, hashed in assets.items():
        print(f"  {asset} -> {hashed}")
    print(f"\n{len(changed)} file(s) updated" + (": " + ", ".join(changed) if changed else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
