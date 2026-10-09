#!/usr/bin/env python3
"""
Stamp a content fingerprint onto the stylesheet and plain scripts in every page.

GitHub Pages tells browsers to keep files for ten minutes, so a CSS change can
take that long to reach people — and longer in an installed home-screen app.
Adding ?v=<hash of the file> makes each change a new URL, so updates appear
immediately while unchanged files still cache normally.

Run this after editing css/style.css, js/nav.js or js/install.js, before
committing. Safe to run any time: it only rewrites when the hash changes.

Not applied to ES modules (js/auth.js and friends). Those import each other by
plain path, so versioning them would mean rewriting the whole import graph.
"""

import hashlib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ["css/style.css", "js/nav.js", "js/install.js"]


def short_hash(path):
    return hashlib.md5((ROOT / path).read_bytes()).hexdigest()[:8]


def main():
    hashes = {a: short_hash(a) for a in ASSETS if (ROOT / a).exists()}
    changed = []

    for page in sorted(ROOT.glob("*.html")):
        text = original = page.read_text()
        for asset, digest in hashes.items():
            # Matches the asset with or without an existing ?v= stamp.
            text = re.sub(
                rf'({re.escape(asset)})(\?v=[0-9a-f]+)?(["\'])',
                rf'\g<1>?v={digest}\g<3>',
                text,
            )
        if text != original:
            page.write_text(text)
            changed.append(page.name)

    for asset, digest in hashes.items():
        print(f"  {asset} -> {digest}")
    print(f"\n{len(changed)} page(s) updated" + (": " + ", ".join(changed) if changed else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
