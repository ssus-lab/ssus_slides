"""shoot.py — screenshot and measure every slide of a rendered SSUS deck.

Adapted from the ssus_course_template tooling (tools/scan_slides.py,
tools/check_tab_order.py), which learned two lessons: iterate every slide of
a deck (a scan otherwise sees only the title slide), and launch the system
Chrome via channel="chrome", with no browser download.

Each slide is shot at the 1280×720 canvas. The title slide and the first
section slide are shot again in a 1440×900 window, where a ground painted on
the section instead of reveal's background layer shows as letterbox bars.

It also measures: any slide whose content runs past the safe box (the
canvas minus the 64 px footer band) is reported, because the canvas clips
overflow silently and a screenshot only shows it if you look.

Usage: python3 tools/shoot.py demo/index.html demo/dark.html
Shots land in qa/<stem>-NN.png; exits 1 if any slide overflows.
"""

import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

OUT = Path(__file__).resolve().parent.parent / "qa"
SAFE_BOTTOM = 720 - 64

# The lowest content edge of the current slide, in canvas px. Reveal scales
# the canvas, so divide by its scale; the running head (::before) is chrome.
MEASURE = """() => {
  const s = Reveal.getCurrentSlide();
  const box = document.querySelector('.reveal .slides').getBoundingClientRect();
  const scale = Reveal.getScale();
  let bottom = 0;
  s.querySelectorAll(':scope > *').forEach(el => {
    const r = el.getBoundingClientRect();
    if (r.height > 0) bottom = Math.max(bottom, (r.bottom - box.top) / scale);
  });
  return {id: s.id || '(untitled)', bottom: Math.round(bottom)};
}"""


def settle(page):
    page.wait_for_timeout(250)


def shoot(page, deck: Path) -> list[str]:
    page.goto(f"file://{deck.resolve()}")
    page.wait_for_timeout(1500)  # fonts, mathjax, reveal init
    page.evaluate("Reveal.configure({ transition: 'none' })")
    n = page.evaluate("Reveal.getTotalSlides()")
    problems = []
    for i in range(n):
        page.evaluate(f"Reveal.slide(...Object.values(Reveal.getIndices(Reveal.getSlides()[{i}])))")
        settle(page)
        page.screenshot(path=str(OUT / f"{deck.stem}-{i:02}.png"))
        m = page.evaluate(MEASURE)
        is_title = page.evaluate("Reveal.getCurrentSlide().id === 'title-slide'")
        if not is_title and m["bottom"] > SAFE_BOTTOM:
            problems.append(f"{deck.stem}-{i:02} {m['id']}: content to {m['bottom']} px, past {SAFE_BOTTOM}")
    print(f"{deck.stem}: {n} slides -> {OUT}")
    return problems


def shoot_wide(browser, deck: Path) -> None:
    page = browser.new_page(viewport={"width": 1440, "height": 900})
    page.goto(f"file://{deck.resolve()}")
    page.wait_for_timeout(1500)
    page.evaluate("Reveal.configure({ transition: 'none' })")
    page.screenshot(path=str(OUT / f"{deck.stem}-wide-hero.png"))
    first = page.evaluate("""() => Reveal.getSlides().findIndex(s => s.classList.contains('level1'))""")
    if first >= 0:
        page.evaluate(f"Reveal.slide(...Object.values(Reveal.getIndices(Reveal.getSlides()[{first}])))")
        settle(page)
        page.screenshot(path=str(OUT / f"{deck.stem}-wide-section.png"))
    page.close()


def main() -> None:
    decks = [Path(p) for p in sys.argv[1:]]
    if not decks:
        sys.exit(__doc__)
    OUT.mkdir(exist_ok=True)
    problems = []
    with sync_playwright() as pw:
        browser = pw.chromium.launch(channel="chrome")
        page = browser.new_page(viewport={"width": 1280, "height": 720})
        for deck in decks:
            problems += shoot(page, deck)
            shoot_wide(browser, deck)
        browser.close()
    for p in problems:
        print("OVERFLOW", p)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
