"""shoot.py — screenshot every slide of a rendered SSUS deck.

Adapted from the ssus_course_template tooling (tools/scan_slides.py,
tools/check_tab_order.py), which learned two lessons: iterate every slide of
a deck (an axe scan otherwise sees only the title slide), and launch the
system Chrome via channel="chrome" — no browser download.

Usage: python3 tools/shoot.py demo/index.html demo/dark.html
Shots land in qa/<stem>-NN.png.
"""

import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

OUT = Path(__file__).resolve().parent.parent / "qa"

def shoot(page, deck: Path):
    deck_name = deck.stem
    page.goto(f"file://{deck.resolve()}")
    page.wait_for_timeout(1200)  # fonts, mathjax, reveal init
    page.evaluate("Reveal.configure({ transition: 'none' })")
    n = page.evaluate("Reveal.getTotalSlides()")
    for i in range(n):
        page.evaluate(f"Reveal.slide({i})")
        page.wait_for_timeout(250)  # let the slide settle before the shot
        page.screenshot(path=str(OUT / f"{deck_name}-{i:02}.png"))
    print(f"{deck_name}: {n} slides -> {OUT}")

def main() -> None:
    decks = [Path(p) for p in sys.argv[1:]]
    if not decks:
        sys.exit(__doc__)
    OUT.mkdir(exist_ok=True)
    with sync_playwright() as pw:
        browser = pw.chromium.launch(channel="chrome")
        page = browser.new_page(viewport={"width": 1280, "height": 720})
        for deck in decks:
            shoot(page, deck)
        browser.close()

if __name__ == "__main__":
    main()