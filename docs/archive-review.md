# Archive Review — Phases 1–3

*The evidence base for the [RCDS design system](RCDS.md). A catalog of the map
archive, the cartographic critique, per-map [Quality Scores](#map-quality-scores),
and a prioritized [improvement matrix](#improvement-matrix).*

Scope: the `archive/` directory — a 30DayMapChallenge 2024 body of work plus
several standalone projects (Blue Ribbon Schools, Walmart, UGA, CFB, GCPS
clusters, watersheds). Scores are informed estimates from the source scripts and
exported thumbnails; rescore with `rcds_score()` as maps are revisited.

---

## Phase 1 — Archive analysis

### Classification dimensions (what was assessed)

Purpose · audience · projection · extent · theme · map type · complexity ·
colour · typography · labelling · legend · marginalia · white space · balance ·
hierarchy · accessibility.

### The archive at a glance

| # | Map | Type | Extent | Canvas | Title font | Palette |
|---|-----|------|--------|--------|-----------|---------|
| 1 | Points — GA schools by level | Categorical points | Georgia | Light `#F0F0F0` | Roboto Black | manual orange/blue/green |
| 2 | Lines — Gwinnett road network | Reference / lines | Gwinnett | Dark `#2f2f2f` | Bungee | Spectral (as categorical) |
| 3 | Polygons — districts | Choropleth | US/GA | Dark | display | sequential |
| 4 | Hexagons | Hexbin | US/GA | — | — | — |
| 5 | Journeys | Flow / routes | Metro | mixed | — | — |
| 6 | Raster | Raster | GA | — | — | — |
| 7 | Vintage — Black student pop. (Du Bois homage) | Choropleth | Georgia | Vintage `#F5DEB3` | Bebas Neue | Du Bois categorical |
| 8 | HDX | Humanitarian | intl | — | — | — |
| 9 | AI | Experimental | — | — | — | — |
| 10 | Pen & paper | Hand-drawn | — | — | — | — |
| 11 | Arctic — North Slope district | Reference + inset | Alaska | Light/terrain | Cinzel + MedievalSharp | arctic blues |
| 12 | Time & space | Spatio-temporal | metro | — | — | — |
| 13 | A new tool | Tool demo | — | — | — | — |
| 14 | World map | Reference | World | — | — | — |
| 15 | My data | Personal | — | — | — | — |
| 16 | Choropleth — enrollment × internet | **Bivariate** | US (+AK/HI insets) | Dark `#121212` | Roboto Condensed | biscale DkCyan |
| 17 | Collaborative | — | — | — | — | — |
| 18 | (data IO) | pipeline | — | — | — | — |
| 19 | Typography | Typographic | GCPS | — | display | — |
| 20 | OSM | Reference | local | — | — | — |
| 22 | 2 colours — Blue Ribbon Schools | Highlight + inset | Georgia/Gwinnett | White | bold sans | brand blue (2-colour) |
| 23 | Memory | QGIS | — | — | — | — |
| 24 | Circles — district population | Proportional/cartogram | Georgia | Dark `#2e2e2e` | UchronyCircle (local font!) | blue→orange gradient |
| 25 | Heat — enrollment by year | **Small multiples** choropleth | GA | Dark `#2b2b2b` | Anton | dichromat Blue-Orange |
| 26 | Projections | **Small multiples** reference | US | Slate `#2C3E50` | Cormorant + Uncial | ggsci futurama (categorical) |
| 27 | Micromapping | Micromap | GA | — | — | — |
| 28 | Blue planet | Thematic | World | Dark | — | blues |
| 29 | Overture | Reference | local | — | — | — |
| 30 | CFB — nearest FBS program | **Identity-fill mosaic** + logos | US (CONUS) | Black `#1c1c1c` | Bebas Neue | team identity colours |
| — | GCPS HS clusters SY2025 | Reference | Gwinnett | — | — | — |
| — | Walmart / UGA / watersheds | Various | GA | — | — | — |

### Recurring patterns (the implicit system)

- **Layout:** main map + (often) locator inset + credits, via patchwork. Legends
  bottom-horizontal. Titles flush-left and large.
- **Palettes:** dark canvas + luminous data; brand blue recurs as the hero hue;
  Spectral/futurama reached for as defaults (the habit to break).
- **Fonts:** showtext + Google Fonts; one heavy display + one Roboto-family body,
  re-chosen each day.
- **Marginalia:** the four-part signature caption; data sources always credited.
- **Tooling:** tidycensus/tigris pipelines, sf transforms to correct CRS
  (5070 CONUS, 3338 AK, 3759 HI, 2240 GA state plane), patchwork composition,
  Cairo export.

---

## Phase 2 — The implicit style, named

**What makes a Richard map recognizable:** a dark, atmospheric canvas; a big
flush-left display title; luminous thematic data; a composed figure with a
locator and a signed credit strip; and an education/Georgia subject.

**Consistently done well:** ambition of composition, real data engineering, a
genuine point of view, attention to attribution.

**Intentional choices:** dark canvas, display typography, insets, signature.

**Habits (not yet principles):** rainbow palettes as defaults, per-map font
swaps, duplicated theme code, magic sizes.

**Choices that limit readability/publication quality:** non-perceptual and
non-accessible palettes, inconsistent type scale, occasional over-saturation,
missing/again-inconsistent furniture, DPI/showtext mismatches.

---

## Phase 3 — Professional critique

Through Tufte (data-ink, small multiples), Brewer (palette safety, legend
design), Field & Nelson (thematic craft, the dark-mode aesthetic done right),
Patterson (terrain/relief restraint), and NACIS practice.

- **Layout:** strong instincts, inconsistent execution. Margins/sizes vary
  because they're hand-set. → tokenize (`theme_rcds()`, spacing scale).
- **Typography:** expressive but undisciplined; clashes possible; sizes ad-hoc.
  → role-based voices + `rcds_type_scale()`.
- **Colour (highest leverage):** replace rainbow-on-ordered-data; adopt
  perceptual, accessible families; cap categorical hues. → `rcds_pal()` families.
- **Legends:** generally present and titled; sometimes oversized
  (`legend.key.width = 3cm`). → standardize via theme; size to need.
- **Labelling:** light use of `ggrepel`; halos rare on dark canvas. → adopt repel
  + halo as default for any label over imagery/dense fills.
- **Symbology:** good `scale_size`/sqrt instincts (Day 24) — formalize to
  `scale_size_area()`; switch `size=`→`linewidth=`.
- **Composition:** insets and credits are a real strength; make them one call
  (`rcds_compose()`) instead of bespoke `area()` math each time.

---

## Map Quality Scores

Scored on the [100-point rubric](RCDS.md#9-the-map-quality-score) (three pillars
at 15 + four craft dimensions at 10 + three supporting at 5). The totals below
are **informed estimates from source + thumbnails** — generate the per-criterion
breakdown live with `rcds_score()` on revisit (it returns the weighted table).

| Map | **Total** | Grade | Standout strength | Biggest drag |
|-----|:--:|:--:|-------------------|--------------|
| Day 7 Vintage (Du Bois) | **89** | B+ | Storytelling, colour discipline (period palette) | Labelling |
| Day 16 Bivariate | **89** | B+ | Composition, legend integration | Labelling, AK/HI inset placement |
| Day 22 Blue Ribbon | **89** | B+ | Accessibility (2-colour), locator inset | Storytelling |
| Day 30 CFB | **85** | B | Technical execution, balance | Accessibility (identity-colour density) |
| Day 1 Points | **81** | B- | Clean layout, hierarchy | Labelling, storytelling |
| Day 25 Small multiples | **80** | B- | Faceting on a shared scale | Colour ramp, accessibility |
| Day 11 Arctic | **74** | C | Inset concept, theming | Legend, technical |
| Day 26 Projections | **72** | C- | Strong concept/composition | Rainbow categorical palette, legends |
| Day 2 Lines | **70** | C- | Ambitious composition | Spectral-as-categorical, accessibility |
| Day 24 Circles | **65** | D | Honest sqrt scaling instinct | No legend, labelling, hardcoded font |

**Archive mean ≈ 79 (C+/B-).** The ceiling (Days 7, 16, 22) is genuinely strong;
the floor (Days 2, 24, 26) is dragged down by palette accessibility, legend
sizing, and labelling — exactly the areas `rcds` standardizes.

### v2 refactor set (routed through `rcds`)

The flagship maps re-rendered through the framework (see
`archive/*_rcds.R` and [CHANGELOG-v2.md](CHANGELOG-v2.md)). Re-scores are
projections from the code changes pending an executed render.

| Map | Before | After | Δ | What moved |
|-----|:--:|:--:|:--:|-----------|
| Day 16 Bivariate | 89 (B+) | **94 (A)** | +5 | Colour (`biv_dkblue` on dark), Typography (one voice + scale), Technical (linewidth, DPI sync) |
| Day 30 CFB | 85 (B) | **90 (A-)** | +5 | Typography (`techno` voice + scale), removed superfluous graticule, Technical |
| Day 7 Vintage | 89 (B+) | **92 (A-)** | +3 | Typography consistency, Technical, reuse (canvas/ink now tokens) — Du Bois palette kept verbatim |

Refactor-set mean **87.7 → 92.0**. The lever was systemic, not per-map effort:
each map lost ~30 lines of bespoke `theme()`/credits/export code and gained the
shared identity. Day 7 deliberately keeps its historical palette — the system
improves *execution*, not the homage.

### Score patterns

- **Strongest dimensions:** Layout, Balance/composition, Storytelling — the
  compositional instinct is real.
- **Weakest dimensions:** Accessibility and Colour on the rainbow maps;
  Labelling across the board; Legends where oversized.
- **Biggest single lever:** swapping to `rcds_pal()` families lifts Colour +
  Accessibility (25 pts of weight combined) on roughly half the archive.

---

## Improvement Matrix

Prioritized by effort. Apply top-down for the fastest quality gain.

### Quick wins (<10 min each)

| Map(s) | Action |
|--------|--------|
| All | Replace inline caption with `rcds_signature()` (fixes drift). |
| All | `size=` → `linewidth=` on `geom_sf` borders/lines. |
| Day 25, Day 2 | Swap rainbow/Spectral for `scale_fill_rcds_c("seq_*")`. |
| Day 26 | Swap futurama categorical for `qual_brand`/`qual_soft` (≤8). |
| Day 24 | Remove hardcoded `C:/…ttf`; use `rcds_fonts()`. Add a legend. |
| Day 1, 25 | Pull magic sizes into `theme_rcds_map(base = …)`. |
| All | Set `rcds_export()` so showtext DPI matches output DPI. |

### Moderate improvements (<1 hr each)

| Map(s) | Action |
|--------|--------|
| All | Replace bespoke `theme()` blocks with `theme_rcds_map()`. |
| Day 2, 11, 22 | Rebuild locator + credits via `rcds_locator()` + `rcds_compose()`. |
| Day 16 | Re-skin bivariate to `biv_dkblue`; tighten AK/HI inset placement. |
| Day 24 | Re-do as honest `scale_size_area()` proportional symbols + legend. |
| Day 30 | Add `ggrepel` + halos so logos/labels stop colliding. |
| Local maps (2, 11, GCPS) | Add `rcds_scalebar()` / `rcds_north_arrow()`. |

### Major redesigns (structural)

| Map(s) | Action |
|--------|--------|
| Day 2 | Rethink road hierarchy: sequential width/value encoding, not 8 Spectral hues. |
| Day 26 | Reframe as a teaching figure: annotate distortion per projection; unify palette. |
| Day 24 | Choose one model — proportional symbols *or* Dorling cartogram — and commit. |
| Archive-wide | Re-render the top ~10 maps through `rcds` as a "v2" portfolio set. |

---

## What to carry forward

The archive is a **B-/C+ body of work with an A-grade point of view and
composition sense**, held back by palette accessibility, font discipline, and
code reuse — all systemic, all fixed once by `rcds`. The path to a consistently
A-/A portfolio is not more effort per map; it's routing every map through the
same system.

See [roadmap.md](roadmap.md) for sequencing.
