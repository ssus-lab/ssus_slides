# ssus-slides

The SSUS slide format: a Quarto revealjs extension carrying the Spatial
Science and Urban Systems identity. Loosely based on
[grantmcdermott/quarto-revealjs-clean](https://github.com/grantmcdermott/quarto-revealjs-clean)
(MIT) — minimal format config, one SCSS theme layered on `default`, low
heading hierarchy, booktabs tables, muted corner chrome — with that
reference's entire identity layer replaced by the SSUS brand
(`~/Dropbox/projects/ssus-lab-brand/`).

Write a deck like any revealjs document and set `format: ssus-slides-revealjs`.

## Start

Copy [`template.qmd`](template.qmd) and edit its metadata. Or read the
exercising decks in [`demo/`](demo/):

| Deck | Shows |
|---|---|
| `demo/index.qmd` | the flagship: blueprint hero, headings, lists, series-tinted bullets, a figure in the lab's series palette, booktabs table, math, columns, callout, citation |
| `demo/dark.qmd` | the same on `ssus-dark: true` — night ground, sky links, night series palette, night-stacked lockup |
| `demo/course.qmd` | the course eyebrow grammar (`ssus-series: "UPPP 206 · Fall 2026"`) |

Render from the repo root (`quarto render`) and screenshot every slide with
`tools/shoot.py` (Playwright against system Chrome; shots land in `qa/`).

## Options

| Option | Type | Default | Effect |
|---|---|---|---|
| `ssus-series` | string | absent | The eyebrow line on the title slide: a series name ("SSUS working paper series"), a course and term ("UPPP 206 · Fall 2026"), or a venue. Set in IBM Plex Mono, uppercase, letter-spaced. |
| `ssus-dark` | boolean | `false` | Whole-deck dark theme: night ground, haze text, sky links, the dark series palette, and the night-stacked lockup on the hero. There is deliberately no `prefers-color-scheme` anywhere — a deck is a shared-room artifact; the room picks once. |
| `ssus-lockup` | boolean | `true` | `false` suppresses the stacked lockup on the title slide (for custom-art heroes). |

Everything else is core Quarto: `title`/`subtitle`/`author`/`institute`/`date`
land on the hero; `logo`, `footer`, `title-slide-attributes`, `incremental`,
`scrollable`, and reveal's other knobs work as documented. The default
`logo` is the format's own `ssus-horizontal-light.svg` (a deck that names its
own `logo` keeps it; in a dark deck the format swaps only its own default for
the night lockup).

## What the format fixes

- **Geometry**: deck box = the viewport exactly (1280×720 at margin 0), and
  content slides pad themselves — no white ring around full-bleed heroes, no
  neighboring slide peeking through an un-covered strip.
- **Corner chrome**: the horizontal lockup sits bottom-left (the stacked
  lockup is three lines of wordmark and goes illegible at corner size) and the
  slide number bottom-right in muted mono; both are hidden where they don't
  belong (no lockup rides the hero). Quarto's progress bar is off.
  reveal-menu's hamburger moves next to the slide number: it used to sit on
  top of the lockup, and it has to stay visible because that menu is Quarto's
  mode switcher — speaker view, slide overview, PDF export — not slide
  navigation. Chrome carries no link underline.
- **Fonts**: Libre Franklin (400/600/800, roman+italic) and IBM Plex Mono
  (400/600) vendored as TTFs with their OFL licenses, no Google Fonts
  `@import` (which fails offline). `format-resources` copies the font files
  next to the rendered input (flattening the `fonts/` dir to basenames), and
  the `@font-face` rules reference them page-relative.
- **Hero**: the blueprint ground with the 30px graticule grid, the mono
  eyebrow, the heavy title, muted detail rows, and the stacked lockup are
  all in the theme and the `title-slide.html` partial (lockups embedded as
  data-URIs — regenerate with
  `base64 -i assets/ssus-stacked-*.svg | tr -d '\n'`;
  `ssus-lab-brand/build/lockups.py` regenerates the SVGs themselves).
- **Opt-in dark**: the `ssus.lua` filter adds an `html.ssus-dark` class via a
  synchronous head script and swaps the default corner mark in the DOM after
  Quarto injects it — SCSS variables compile, so the dark theme flips CSS
  custom properties at runtime, not theme files.

## Installing into another project

Vendoring is the only supported install: copy the whole
`_extensions/ssus-slides/` folder into the project, and **re-copy it in full
whenever the source changes** — a partial re-sync once left a stale vendor
elsewhere in the house and Quarto silently fell back to plain html.
`quarto add` is not the documented path here (it stalls when the GitHub
fetch hangs). Note the sibling course template gitignores `_extensions/` —
if this extension is vendored there, budget for reinstall discipline.

## Known limitations (v0.1)

- MathJax comes off the jsdelivr CDN; offline math is unrendered (vendor the
  tex-mml-chtml bundle later if needed).
- Dark is deck-level only; per-slide dark sections (`{.ssus-dark-slide}`) are
  not implemented.
- The page-relative font contract assumes a plain render next to the input,
  like the reference theme's own resource contract — verify in website
  projects before promoting decks into one.