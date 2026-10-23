# ssus-slides

The slide format of Spatial Science and Urban Systems: a Quarto revealjs
extension carrying the lab's identity. It follows the approach of
[grantmcdermott/quarto-revealjs-clean](https://github.com/grantmcdermott/quarto-revealjs-clean)
(MIT): little configuration, one SCSS theme layered on `default`, quiet
chrome. The identity is entirely SSUS, from `~/Dropbox/projects/ssus-lab-brand/`.

Write a deck like any revealjs document and set `format: ssus-slides-revealjs`.

## Start

Copy [`template.qmd`](template.qmd) and edit its metadata. The demo decks
exercise every surface:

| Deck | Shows |
|---|---|
| `demo/index.qmd` | the title slide, three parts with section slides and running heads, text, lists, math, columns, an executed figure, a table, a callout with code, a blueprint statement slide, a citation |
| `demo/dark.qmd` | the same surfaces on `ssus-dark: true` |
| `demo/course.qmd` | a course eyebrow (`ssus-series: "UPPP 206 · Fall 2026"`) and a `footer:` line |

Render each deck (`quarto render demo/index.qmd`; `quarto render` alone does
all four) and check them with `python3 tools/shoot.py demo/*.html`. It
screenshots every slide into `qa/`, shoots the title and first section slide
again in a 16:10 window and the overview from mid-deck, and exits 1 if any slide's content runs into
the footer band.

## The grammar

- **Title slide.** Blueprint with the 30 px graticule grid. The series
  eyebrow, the title, and the subtitle hold the middle; a hairline foot
  carries the byline on the left and the horizontal lockup on the right.
  The subtitle is an italic accent, the authors are the strongest detail
  line, and affiliations and the date demote by italic and tone.
- **Authors.** Each author is a name with its affiliations beneath; authors
  sit side by side and wrap, so four take one row and eight take two. Give
  each author its own `affiliations:`. Quarto folds `institute:` into the
  affiliations by position (the first institute to the first author), so a
  single `institute:` suits a single author.
- **Parts.** `# Name` opens a part on a blueprint section slide with a sheet
  number (`01`). Every slide after it names the part in a mono running head
  above its title. `# Appendix {.unnumbered}` keeps the slide and the
  running head and drops the number.
- **Content slides.** The title sits in the same place on every slide;
  nothing is centred vertically.
- **Blueprint slides.** `## Title {.ssus-blueprint}` puts any slide on the
  identity ground, for a claim the talk turns on. `.ssus-lede` sets one
  sentence larger.
- **Chrome.** The mark alone bottom left, because the horizontal lockup stops
  reading below 240 px wide. The slide number bottom right, with the menu
  button beside it; that menu is Quarto's mode switcher (speaker view,
  overview, PDF export), so it stays visible. A `footer:` line sits beside
  the mark. On blueprint grounds the mark and footer step out and the number
  takes sky.

Blueprint grounds are painted through reveal's background layer, so they
fill the screen at any aspect ratio and survive PDF export.

## Options

| Option | Type | Default | Effect |
|---|---|---|---|
| `ssus-series` | string | absent | The title-slide eyebrow: a series ("SSUS working paper series"), a course and term ("UPPP 206 · Fall 2026"), or a venue. |
| `ssus-dark` | boolean | `false` | The page goes to Night: haze text, sky links, the night series palette, dark code tokens, the night mark. Blueprint grounds stay blueprint, as the lab site's bands do in dark mode. There is no `prefers-color-scheme`: a deck is shown in a room, and the room chooses once. |
| `ssus-lockup` | boolean | `true` | `false` drops the lockup from the title slide. |
| `ssus-running-head` | boolean | `true` | `false` drops the running heads and the sheet numbers. |

| Class | On | Effect |
|---|---|---|
| `.ssus-blueprint` | a `##` slide | the slide on the blueprint ground |
| `.unnumbered` | a `#` section | no sheet number |
| `.ssus-lede` | a div or span | one sentence set larger, 600 |
| `.ssus-small`, `.ssus-muted` | a div or span | smaller text; the secondary voice |
| `.ssus-plate` | an image | a white plate with a hairline, for a figure with an opaque white face |
| `.ssus-series-tints` | a list or its div | bullets in the series palette, to key a figure |
| `.alert`, `.fg-s1`…`.fg-s6`, `.bg-s1`…`.bg-s6` | a span | Signal, or a series color |

Everything else is core Quarto. `title`, `subtitle`, `author`, `institute`,
and `date` land on the title slide. `logo`, `footer`, `incremental`,
`scrollable`, `.smaller`, `code-line-numbers` (off by default), and reveal's
other knobs work as documented. A slide that sets its own `background-*`
keeps it. A deck that names its own `logo` keeps it.

## Figures

A figure should ride the ground. The extension ships `ssus-slides.mplstyle`
and `ssus-slides-dark.mplstyle`: the brand's figure styles at slide scale,
with a transparent figure face and constrained layout, sized by default
(`fig-width: 11.2`, `fig-height: 3.8`) to leave room for a title and two
lines of text. The setup chunk in `template.qmd` finds them in
`_extensions/ssus-slides/` and registers the vendored Libre Franklin:

```python
from pathlib import Path
import matplotlib.pyplot as plt
from matplotlib import font_manager

ext = next(p / "_extensions/ssus-slides" for p in [Path.cwd(), *Path.cwd().parents]
           if (p / "_extensions/ssus-slides").is_dir())
for f in ext.glob("fonts/LibreFranklin-*.ttf"):
    font_manager.fontManager.addfont(f)
plt.style.use(ext / "ssus-slides.mplstyle")
```

The chunk reads from the extension folder, not from a copy next to the deck,
because Quarto copies `format-resources` after it executes code: a first
render would not find the copy. A figure made elsewhere with a white face,
such as a paper's, goes on a plate: `![](fig.png){.ssus-plate}`.

## Installing into another project

Vendoring is the only supported install: copy the whole
`_extensions/ssus-slides/` folder into the project, and re-copy it in full
whenever the source changes. A partial re-sync once left a stale vendor
elsewhere in the house, and Quarto fell back to plain html without a word.
`quarto add` is not the documented path, because it stalls when its GitHub
fetch hangs. The sibling course template gitignores `_extensions/`, so a
vendor there needs reinstall discipline.

## How it is built

- `ssus-slides.scss` holds every token, each with its brand source. Every
  rule reads `var(--ssus-*)`, and a ground is a set of values for those
  properties: `:root` (plan white), `html.ssus-dark` (night), and
  `.ssus-ground-blueprint`.
- `ssus.lua` writes `data-background-color` and `-gradient` on the title
  slide (through `title-slide-attributes`), on `#` sections, and on
  `.ssus-blueprint` slides; numbers the parts; writes the running heads; and
  switches dark decks. The part number and running head travel as custom
  properties (`--ssus-part`, `--ssus-section`) that the heading's `::before`
  draws, because reveal's overview hides a section's own pseudo-elements.
  Section slides set their title at a fixed height, not by reveal's
  centring, which overview and PDF export each redo. It inlines the hero lockup and the night mark as data
  URIs read from the extension folder at render time, so a deck copied away
  from `_extensions/` keeps them.
- `title-slide.html` is the hero partial.
- The deck box is the 1280×720 canvas exactly (margin 0) and slides pad
  themselves, so the theme's px are canvas units.
- Libre Franklin (400, 600, 800, roman and italic) and IBM Plex Mono (400,
  600) are vendored with their OFL licenses; `format-resources` copies them
  next to the rendered deck, and the `@font-face` rules point there. There
  is no Google Fonts `@import`, which fails offline.

## Known limitations

- MathJax comes from the jsdelivr CDN, so math does not render offline.
- The page-relative font contract is proven for a plain render next to the
  input; verify it inside a website project before publishing a deck there.
- Quarto's default `logo` path points into `_extensions/`, so in light decks
  the corner mark needs the extension folder beside the deck, or
  `embed-resources: true`.
