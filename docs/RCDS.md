# The Richard Cartographic Design System (RCDS)

*A personal, opinionated cartographic design language for producing nearly all
future maps in R — derived from Roland Richard's map archive and reconciled with
modern thematic-cartography practice.*

Version 0.1 · Companion to the `rcds` R package (`../rcds`)

---

## How to read this document

This is the **standard**. The [`rcds`](../rcds) package is the **implementation**.
The [archive review](archive-review.md) is the **evidence** the standard is built
from. When the three disagree, the design system wins and the package is the bug.

Contents:

1. [Design principles](#1-design-principles)
2. [Visual identity (brand guide)](#2-visual-identity)
3. [Typography system](#3-typography-system)
4. [Colour system](#4-colour-system)
5. [Layout & composition](#5-layout--composition)
6. [Map components](#6-map-components)
7. [Pattern library](#7-pattern-library)
8. [Anti-patterns](#8-anti-patterns)
9. [The Map Quality Score](#9-the-map-quality-score)
10. [Export standards](#10-export-standards)

---

## 1. Design principles

Twelve principles, derived from what the archive already does well and where it
falls short. Every design decision should be traceable to one of these.

1. **Clarity before decoration.** A map earns ornament only after it is legible.
   The expressive fonts and dark canvases stay — but never at the cost of the
   message.
2. **Purpose drives form.** Audience and medium (social card, journal figure,
   poster) are chosen *first*; layout, type scale, and export follow.
3. **One canvas, one voice.** Each map commits to a single canvas family and a
   single font voice. No mixing Anton with Cinzel in the same figure.
4. **Colour carries meaning, not mood alone.** Hue is reserved for data. Mood is
   set by the neutral canvas, not by saturating the data colours.
5. **Type establishes hierarchy.** A heavy display title, a clean condensed
   body, a quiet caption — always in that order of weight, always to scale.
6. **White (and dark) space is active.** Negative space frames the subject; it
   is allocated deliberately, not left over.
7. **Geographic context must never out-shout the message.** Reference layers
   recede (hairlines, muted fills); the data layer dominates.
8. **Every element justifies its existence.** North arrow, scale bar, graticule,
   border — each is included because it does work, or it is cut.
9. **The signature is sacred and standardized.** The credit block is the brand
   wordmark. Same structure, same order, every time.
10. **Accessible by default.** Colourblind-safe and greyscale-survivable is the
    starting point, not a later accommodation.
11. **Reproducible, not bespoke.** Style lives in functions, not in copy-pasted
    `theme()` blocks. Restyling a map is changing an argument.
12. **Evolve deliberately.** The identity is stable; the execution improves.
    Changes are tracked against the [Map Quality Score](#9-the-map-quality-score),
    not made on a whim.

---

## 2. Visual identity

> If you saw one of these maps with the credit cropped off, you should still
> know who made it.

### Defining characteristics

- **The dark canvas.** The signature move. Charcoal-to-near-black backgrounds
  (`#1C1C1C`, `#121212`, `#2B2B2B`, `#2C3E50`) with luminous data on top.
- **Display-title drama.** A heavy, condensed or decorative title face set
  large and flush-left, paired with a calm Roboto-family body.
- **The signature caption.** `#30DayMapChallenge … / Tool: R / Created By:
  Roland Richard / Data Sources: …` — a consistent four-part wordmark.
- **Composed figures, not bare maps.** Main map + locator inset + credits strip,
  assembled with patchwork. The map is presented, framed, attributed.
- **Education & Georgia as home turf.** Schools, districts, enrollment, Gwinnett
  / Atlanta metro / Georgia recur — a genuine subject-matter identity.

### Recurring motifs

| Motif | Where it shows up |
|-------|-------------------|
| Dark charcoal canvas + white type | Days 2, 3, 16, 24, 25, 30; Blue Ribbon; Walmart |
| Heavy display title flush-left | Days 2, 7, 25, 26; CFB |
| Locator inset (AOI-in-context) | Day 2 (Gwinnett-in-GA), Blue Ribbon (GA inset) |
| richtext credits strip | Days 2, 16 |
| Bottom horizontal legend | Days 1, 7, 25 |
| sqrt-scaled symbols | Day 24 |
| Brand blue as the hero hue | Blue Ribbon, Day 1 (middle), CFB highlights |

### Strengths to preserve

- Confident, atmospheric **dark aesthetic** that reads as intentional, not default.
- **Ambitious composition** — insets, faceting, rich credits, real data pipelines
  (tidycensus/tigris), parallelized spatial joins (Day 30).
- A **real point of view**: education equity, access, and place.

### What to modernize

- **Font discipline.** Beautiful faces, but a different pairing every day. RCDS
  keeps the expressiveness via *sanctioned voices* (see §3) instead of ad-hoc choices.
- **Palette safety.** Spectral and futurama rainbows are vivid but not
  colourblind-safe or greyscale-stable. Replace with the RCDS families (§4).
- **Consistency of the signature.** Standardize via `rcds_signature()`.
- **Reuse.** Replace ~40 duplicated theme blocks with `theme_rcds()`.
- **Cartographic furniture.** Add scale bars / north arrows where they do work
  (most local maps), and only there.

### Recommended evolution (the north star)

Keep the dark, dramatic, composed look. Make it *systematic*: one default voice,
one safe palette set, one signature builder, one theme, one export path — so the
identity becomes recognizable *because* it is consistent, not in spite of being
improvised each time.

---

## 3. Typography system

The archive's fonts, observed: Anton, Bebas Neue, Bungee, Cinzel, MedievalSharp,
Uncial Antiqua, Cormorant SC, Orbitron, Oswald-class, Montserrat, Poppins,
Smooch Sans, Roboto, Roboto Condensed.

RCDS organizes these into **roles** and **voices** (`rcds_fonts()`):

| Role | Job | Default voice |
|------|-----|---------------|
| `display` | Titles, subtitles, strip labels | Oswald |
| `body` | Legends, labels, axis text | Roboto Condensed |
| `caption` | Credits / signature | Roboto |

**Sanctioned voices** (pick one per map, never mix):

| Voice | display / body / caption | Use for |
|-------|--------------------------|---------|
| `default` | Oswald / Roboto Condensed / Roboto | Everyday, journal, dashboards |
| `editorial` | Anton / Roboto Condensed / Roboto | Bold social posters, headlines |
| `vintage` | Bebas Neue / Roboto Condensed / Roboto | Retro / Du Bois homages |
| `fantasy` | Cinzel / Cormorant SC / Roboto | Themed/narrative maps |
| `techno` | Orbitron / Smooch Sans / Roboto | Sports, sci-fi, data-art |

### The type scale (`rcds_type_scale()`)

A single major-third (1.25) scale keyed to a `base` size, ending the per-map
magic numbers (`size = 54`, `48`, `80`…):

```
micro  caption  body/label/legend  subtitle  title  hero
0.8×    1.0×        1.12×            1.56×     2.44× 3.8×   (× base)
```

Rules:

- Exactly one `title`, one `subtitle`. Captions never compete with titles.
- Titles flush-left (`hjust = 0`) by default; centered only for symmetric/poster
  compositions.
- **showtext DPI must match export DPI** or sizes drift — `rcds_export()` keeps
  them in lockstep. (This is the single most common rendering bug in the archive.)
- Never hand-set point sizes in a theme; pull from the scale.

---

## 4. Colour system

> The archive's biggest, highest-leverage upgrade. Rainbow categorical scales out;
> perceptual, accent-anchored, accessible families in.

### Neutrals (canvases & ink)

Canonicalized from the archive's backgrounds (`rcds_tokens()`):

| Token | Hex | Role |
|-------|-----|------|
| `canvas.dark` | `#1C1C1C` | House default canvas |
| `canvas.deep` | `#121212` | Credit strips / panels |
| `canvas.slate` | `#2C3E50` | Cool alt canvas |
| `canvas.graphite` | `#2B2B2B` | Warm alt canvas |
| `canvas.light` | `#F0F0F0` | Light canvas |
| `canvas.vintage` | `#F5DEB3` | Vintage / Du Bois |
| `ink.on_dark_1/2/3` | `#FFFFFF` / `#CFCFCF` / `#8A8A8A` | Type on dark |
| `ink.on_light_1/2/3` | `#333333` / `#555555` / `#666666` | Type on light |

### Brand accents

| Token | Hex | Meaning |
|-------|-----|---------|
| `accent.blue` | `#1E6FB8` | **Brand primary** ("Roland blue") |
| `accent.blue_b` | `#1E90FF` | Bright highlight / interactive |
| `accent.amber` | `#E8852B` | Warm counter-accent |
| `accent.teal` | `#2A9D8F` | Cool secondary |
| `accent.red` | `#C8443B` | Alert / emphasis |
| `accent.green` | `#3FA34D` | Positive |

### Palette families (`rcds_pal()`)

| Family | Members | Use when |
|--------|---------|----------|
| Sequential | `seq_blue`, `seq_amber`, `seq_teal` | One variable, low→high |
| Diverging | `div_balance`, `div_temp` | A meaningful midpoint (z-scores, change) |
| Qualitative | `qual_brand` (≤6), `qual_soft` (≤8) | Unordered categories |
| Bivariate | `biv_dkblue` (3×3) | Two variables at once |

Design constraints every family meets:

- **Perceptually ordered** (monotonic luminance for sequential).
- **Colourblind-considerate** — anchored on blue/amber/teal, the most robust
  axis for deuter/protanopia; reds used sparingly and never as the sole
  distinction from green.
- **Greyscale-survivable** — sequential ramps keep luminance separation.
- **Canvas-aware** — tested against `canvas.dark`.

ggplot scales: `scale_fill_rcds_c/d()`, `scale_color_rcds_c/d()`.

**Proof it, don't promise it.** Accessibility is a check, not a claim:

```r
rcds_cvd_check("qual_brand")        # simulate deutan/protan/tritan; flag confusable pairs
rcds_greyscale_check("seq_blue")    # luminance ordering for black-and-white print
```

`rcds_cvd_check()` flags any category pair whose simulated CIE Lab distance drops
below ~15 deltaE; `rcds_greyscale_check()` verifies sequential ramps stay monotone
and well-separated in luminance. Run them on a custom palette before you ship it.

Rules:

- Never encode an ordered variable with a qualitative palette (the Spectral-on-
  enrollment habit). Sequential or binned.
- Cap categorical maps at ~6 hues; beyond that, group, facet, or use position.
- Saturation budget: at most one fully-saturated accent per map; everything else
  recedes.

---

## 5. Layout & composition

### The canonical figure

```
┌─────────────────────────────────────────┐
│ TITLE (display, flush-left)              │
│ Subtitle (display, muted)                │
│                                ┌───────┐ │
│            MAIN MAP            │locator│ │
│         (the message)         └───────┘ │
│                                          │
├─────────────────────────────────────────┤
│ Signature credits strip (deep canvas)    │
└─────────────────────────────────────────┘
```

Built with `rcds_compose(main, locator, credits, layout = "poster")`.

### Layout presets

| Preset | Structure | Medium |
|--------|-----------|--------|
| `poster` | Locator overlaid top-right, credits strip below | Social/poster |
| `stack` | Main over credits | Simple/portrait |
| `sidebar` | Map + locator/legend column at right, credits below | Dashboards, journals |

### Format → preset map

| Format | Aspect | Export preset |
|--------|--------|---------------|
| Social square | 1:1 | `social_square` |
| Social portrait | ~3:4 | `social_portrait` |
| Social landscape card | 16:9 | `social_land` |
| Large landscape poster | 4:3 | `poster_land` |
| Large portrait poster | 3:4 | `poster_port` |
| Journal single column | ~5:4 | `journal_single` |
| Journal double column | ~13:8 | `journal_double` |
| Presentation slide | 16:9 | `slide_169` |
| Web/blog | 3:2 | `web` |

### Spacing & margins

Use the token spacing scale (`rcds_tokens()$space`: 4/8/16/24/40/64 pt). The
default `theme_rcds()` margin is `lg`/`xl`/`lg`/`xl` — generous side gutters,
moderate top/bottom. Keep margins symmetric unless a locator or legend
deliberately breaks symmetry.

---

## 6. Map components

| Component | Function | Standard |
|-----------|----------|----------|
| Title / subtitle | `theme_rcds()` slots | Display voice, flush-left, one each |
| Signature caption | `rcds_signature()` | Four lines: challenge / tool / author / sources |
| Credits strip | `rcds_credits()` | richtext on `canvas.deep`, right- or left-aligned |
| Scale bar | `rcds_scalebar()` | Minimal, bottom-left, **local maps only** |
| North arrow | `rcds_north_arrow()` | Minimal orienteering, top-right, only when orientation isn't obvious |
| Locator inset | `rcds_locator()` | AOI in brand blue on muted context, void theme |
| Annotation callout | `rcds_annotation_box()` | richtext panel on `canvas.deep` |

**Furniture policy.** Continental/abstract thematic maps (CFB, projections,
choropleths of the US) generally *omit* scale bar and north arrow — they add
noise, not information. Local reference maps (Gwinnett roads, school clusters)
*include* them. Decide by principle #8.

---

## 7. Pattern library

Reusable, named patterns extracted from the best of the archive. Each: when to
use, when not, and the `rcds` call.

### P1 — Dark thematic choropleth
- **Use:** one ordered variable over polygons, hero presentation.
- **Avoid:** when print is greyscale-only without luminance-separated ramp.
- **Build:** `scale_fill_rcds_c("seq_blue")` + `theme_rcds_map("dark")`. See
  `template_choropleth.R`.

### P2 — Locator-in-context inset
- **Use:** local AOI that readers can't place nationally (a county, a district).
- **Avoid:** when the extent is self-evidently national/global.
- **Build:** `rcds_locator()` → `rcds_compose(layout = "poster")`.

### P3 — Signature credits strip
- **Use:** every published map.
- **Build:** `rcds_credits()` (rich) or `rcds_signature()` (plain `labs(caption=)`).

### P4 — Small multiples on a shared scale
- **Use:** time series / scenario / category comparison.
- **Avoid:** when panels would each need their own scale (then it's not a
  comparison — rethink).
- **Build:** `facet_wrap()` + one `scale_fill_rcds_c()` + `template_small_multiples.R`.

### P5 — Bivariate choropleth
- **Use:** two variables whose *interaction* is the story (enrollment × access).
- **Avoid:** general audiences who'll bounce off a 3×3 legend; >3×3 dims.
- **Build:** `biscale::bi_class()` + `rcds_pal("biv_dkblue")` + `template_bivariate.R`.

### P6 — Area-proportional symbols
- **Use:** magnitudes at points/centroids.
- **Avoid:** dense overlapping centroids (switch to choropleth/hexbin).
- **Build:** `scale_size_area()` (never `scale_size`) + `template_proportional_symbols.R`.

### P7 — Categorical points, graduated
- **Use:** point features in a few classes (school levels).
- **Build:** `scale_color_rcds_d("qual_brand")` + graduated `scale_size_manual()`.

### P8 — Identity-fill mosaic
- **Use:** pre-computed colours per feature (team colours, Day 30).
- **Build:** `scale_fill_identity()` + `theme_rcds_map("deep")`; keep outlines hairline.

---

## 8. Anti-patterns

Recurring mistakes in the archive, why they hurt, and the fix. Most are now
**enforced mechanically** by `rcds_lint()` (rule codes `A1`–`A8` below) — run it
on any script before export, or over the whole archive with `rcds_lint_dir()`.

```r
rcds_lint("archive/day25_heat.R")     # one script
rcds_lint_dir("archive")              # the whole folder
```

### A1 — Rainbow scale on ordered data
- **Where:** Day 25 (Spectral/BluetoDarkOrange on enrollment), Day 2 (Spectral
  as a *categorical* road hierarchy).
- **Why it hurts:** non-monotonic luminance → readers can't rank; fails
  colourblind and greyscale.
- **Fix:** `scale_fill_rcds_c("seq_*")` for order; `qual_brand` only for true categories.
- **Prevent:** never pass a continuous variable to a qualitative palette.

### A2 — A new font pairing every map
- **Why it hurts:** dilutes identity; pairings sometimes clash.
- **Fix:** pick one `rcds_fonts()` voice per map.
- **Prevent:** the voice is a project setting, chosen once at the top.

### A3 — Copy-pasted `theme()` blocks
- **Where:** every script re-declares 20–40 theme lines.
- **Why it hurts:** drift, bugs, unmaintainable; sizes/colours diverge silently.
- **Fix:** `theme_rcds()` / `theme_rcds_map()`.

### A4 — Magic font sizes
- **Where:** `size = 54/48/80/44…` tuned per map.
- **Why it hurts:** inconsistent hierarchy; breaks when DPI changes.
- **Fix:** `rcds_type_scale(base)`; change `base`, not individual sizes.

### A5 — Signature drift
- **Where:** "Tool: R" vs "Tools: R [...]"; pipes vs newlines; handle sometimes present.
- **Fix:** `rcds_signature()` is the only way to build it.

### A6 — Deprecated `size =` on `geom_sf` lines
- **Where:** most scripts (`size = 0.2` on polygons/lines).
- **Why it hurts:** deprecated since ggplot2 3.4; warnings, future breakage.
- **Fix:** `linewidth =` for lines/polygon borders.

### A7 — Hardcoded absolute font paths & secrets
- **Where:** Day 24 (`C:/Users/.../UchronyCircle…ttf`), commented census keys.
- **Why it hurts:** non-portable; won't run on another machine; secret-leak risk.
- **Fix:** Google fonts via `rcds_fonts()`; keys in `~/.Renviron`.

### A8 — showtext/export DPI mismatch
- **Why it hurts:** type renders too large/small relative to the layout.
- **Fix:** `rcds_export()` syncs showtext DPI to the output DPI.

### A9 — Furniture for its own sake
- **Where:** dotted graticules / arrows on abstract national maps.
- **Fix:** include scale bar/north arrow only on local reference maps (§6 policy).

### A10 — Over-saturated everything
- **Why it hurts:** no focal point when every element shouts.
- **Fix:** one saturated accent; recede the rest with `colorspace::desaturate()`.

---

## 9. The Map Quality Score

A weighted 100-point rubric (`rcds_score()`), applied identically to old and new
maps so quality is measured, not asserted.

| Criterion | Weight | The map earns points for… |
|-----------|-------:|---------------------------|
| Layout | 15 | margins, alignment, panel proportions, white space |
| Visual hierarchy | 15 | message lands first; clear primary/secondary order |
| Typography | 10 | one voice, scale-based sizes, no clashes |
| Colour | 15 | perceptual, right scale type, on-brand, not over-saturated |
| Accessibility | 10 | colourblind-safe, greyscale-survivable, contrast |
| Legends | 10 | ordered, titled, right sizing, integrated |
| Labelling | 10 | placement, density, collision handling, halos |
| Balance & composition | 10 | framing, focal point, inset/credit integration |
| Storytelling | 5 | a clear, argued point |
| Technical execution | 10 | projection, geometry, resolution, export hygiene |
| **Total** | **100** | |

Grades: A+ ≥97 · A ≥93 · A- ≥90 · B+ ≥87 · B ≥83 · B- ≥80 · C+ ≥77 · C ≥73 ·
C- ≥70 · D range 60–69 · F <60.

Usage:

```r
rcds_score(layout = 0.8, hierarchy = 0.7, typography = 0.6, colour = 0.5,
           accessibility = 0.4, legends = 0.7, labelling = 0.6, balance = 0.8,
           storytelling = 0.7, technical = 0.9, map = "day25_heat")
```

Per-map scores for the existing archive are in
[archive-review.md](archive-review.md#map-quality-scores).

---

## 10. Export standards

- **Device:** Cairo (`type = "cairo"`, `cairo_pdf` for vector) for crisp
  showtext text and anti-aliasing. `rcds_export()` defaults here.
- **Background:** always set to the canvas — never transparent — to avoid the
  white-halo bug.
- **DPI:** 300 for print/social, 600 for journal figures, 150–200 for web/slides.
  showtext DPI is synced automatically.
- **Dimensions:** from `rcds_export_presets()`; never re-typed by hand.
- **Naming:** `dayNN_<theme>.png` for the challenge; `<project>_<variant>.png`
  otherwise.
- **Colour space:** sRGB for screen; for true print work, soft-proof CMYK and
  prefer the print-safe ramps (sequential families hold up best).

---

*Next: see [archive-review.md](archive-review.md) for the evidence base and
per-map scores, [roadmap.md](roadmap.md) for the improvement plan, and
[innovation-log.md](innovation-log.md) for techniques to grow into.*
