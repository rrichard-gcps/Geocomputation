# GCPS Brand Pack (imported design system)

The Gwinnett County Public Schools design language — imported from the Claude
Design **GCPS / REA Theme Studio** and **map-design** projects — integrated into
`rcds` so the map tool can produce institution-branded maps, static and
interactive, from one system.

Source files live under `rcds/inst/interactive/claude-design/`; the integrated R
API lives in `rcds/R/rcds-gcps.R`. Single source of truth: `gcps_tokens()`.

## The colour system

Eleven named families, each a base (the 500 stop) plus a 5-stop sequential ramp
(100/300/500/700/900) and a 5-stop diverging ramp. **Maroon `#660000` is the
district signature.**

| Family | Base | Role |
|--------|------|------|
| maroon | `#660000` | District signature; headers, primary emphasis |
| blue | `#2F5FB3` | Cool, neutral category |
| teal | `#007C91` | Density & intensity |
| green | `#5E8C31` | Growth, positive metrics |
| violet | `#6A4CC3` | Distinct categorical |
| orange | `#D96A1D` | Attention, secondary emphasis |
| neutral | `#7A828C` | Supporting tones |
| gold | `#C49A22` | Award & recognition |
| plum | `#7B2D8B` | Adult literacy & workforce |
| slate | `#4A6D8C` | Operations & infrastructure |
| emerald | `#1A7D5A` | Sustainability & wellness |

These are registered into the normal palette surface, so everything works the
same way as the archive palettes:

```r
rcds_pal("gcps_teal", 5)            # sequential ramp
rcds_pal("gcps_maroon_div", 7)      # diverging
rcds_pal("qual_gcps", 6)            # the 11 bases as a categorical palette
scale_fill_rcds_c("gcps_plum")      # ggplot continuous scale
rcds_pal_leaflet("gcps_blue")       # interactive choropleths
rcds_cvd_check("gcps_orange")       # same accessibility proofing applies
```

`rcds_palettes()` lists them under `gcps_sequential`, `gcps_diverging`,
`gcps_qualitative`.

## The three cartographic poster themes

From `map-design`, three complete map themes — canvas, ink, accent, geometry
strokes, and typography bundled together:

| Theme | Canvas | Accent | Type | Use |
|-------|--------|--------|------|-----|
| `paper` | `#EFE9DC` warm | maroon `#8C2F39` | Spectral / IBM Plex Sans / Mono | Editorial, print |
| `civic` | `#EEF1F5` light | blue `#1F5C8B` | Archivo / Archivo / Mono | Official public reports |
| `bold` | `#14161B` dark | coral `#E2574B` | Archivo 800 / IBM Plex Sans | Presentation, screen |

One call themes a map and registers its (Google) fonts:

```r
library(ggplot2)
mt <- gcps_tokens()$map_themes$paper
ggplot(districts) +
  geom_sf(aes(fill = enrollment), colour = mt$dist_stroke, linewidth = 0.3) +
  geom_sf(data = highlight, fill = NA, colour = mt$accent, linewidth = mt$hi_sw) +
  scale_fill_rcds_c("gcps_maroon") +
  labs(title = "Enrollment by District") +
  theme_gcps_map("paper")
```

The matching font voices are also available globally: `rcds_fonts("gcps_paper")`,
`rcds_fonts("gcps_civic")`, `rcds_fonts("gcps_bold")`.

## Interactive

`gcps_interactive_css(theme)` is the GCPS counterpart to `rcds_interactive_css()`
— Leaflet/HTML CSS from a map theme's tokens, exposing the same
`:root { --rcds-* }` seam. See `inst/templates/template_gcps_choropleth.R`.

## The six dashboard UI shells

`gcps_tokens()$ui_themes` carries the Studio's six selectable shells
(editorial, clarity, dark, soft, bold, civic) — canvas/surface/border/text/accent
+ corner radii — for Shiny/dashboard chrome around maps. Not yet wired to a
ggplot theme (maps use the three poster themes); kept as tokens for dashboard use.

## GCPS is the default brand

As of the brand system (`R/rcds-brand.R`), **GCPS is the out-of-the-box default**.
The convenience entry points resolve to the GCPS identity automatically:

```r
library(rcds)                 # loads with brand = "gcps"
rcds_brand()                  # "gcps"

ggplot(districts) +
  geom_sf(aes(fill = enrollment)) +
  scale_fill_map_c() +        # -> gcps_teal (brand default sequential)
  theme_map()                 # -> theme_gcps_map("civic")

rcds_fonts()                  # no voice -> gcps_civic
```

Switch the entire tool back to the dark, archive-derived identity with one call:

```r
rcds_brand("archive")         # theme_map() -> theme_rcds_map("dark"),
                              # scale_fill_map_c() -> seq_blue, rcds_fonts() -> default
```

Explicit calls are never overridden by the brand: `theme_rcds_map("dark")`,
`scale_fill_rcds_c("seq_blue")`, `theme_gcps_map("bold")`, and
`rcds_fonts("techno")` all still do exactly what they say. The brand only decides
what the *unqualified* `theme_map()` / `scale_*_map_*()` / `rcds_fonts(NULL)`
produce.

Recommended usage: keep the GCPS default for institutional work; drop to explicit
`theme_rcds_map()` / `seq_*` palettes (or `rcds_brand("archive")` for a whole
session) for personal, social, and challenge maps.

## Accessibility note

GCPS brand colours were chosen for identity, not guaranteed colour-vision safety.
Proof any GCPS palette before shipping:

```r
rcds_cvd_check("gcps_teal")
rcds_greyscale_check("gcps_maroon")
```
