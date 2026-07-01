# rcds — Richard Cartographic Design System

> An opinionated R package that turns Roland Richard's recurring map style into
> a reusable, consistent cartographic system.

`rcds` codifies the visual identity reverse-engineered from the
30DayMapChallenge archive — a **dark thematic canvas**, a **heavy display title
paired with a clean condensed body**, a **standardized signature caption**, and
**main + locator + credits composition** — into themes, palette families,
components, layout helpers, export presets, and a map-quality scoring rubric.

## Install (local, during development)

```r
# from the repo root
install.packages("pak")
pak::local_install("rcds")        # or devtools::load_all("rcds")
```

Dependencies are deliberately light at the core (ggplot2, grid, rlang, scales);
`sf`, `ggspatial`, `ggtext`, `showtext`, `patchwork`, `biscale`, `colorspace`
are used by helpers that need them and are listed under `Suggests`.

## 60-second tour

```r
library(rcds)
library(ggplot2)

rcds_fonts("editorial")            # register the font voice (display/body/caption)

p <- ggplot(my_sf) +
  geom_sf(aes(fill = value), colour = NA) +
  scale_fill_rcds_c("seq_blue") +  # colourblind-safe sequential ramp
  labs(
    title    = "US School District Enrollment",
    subtitle = "ACS 5-Year Estimates",
    caption  = rcds_signature(
      challenge = "#30DayMapChallenge 2024 Day 16: Choropleth",
      sources   = c("U.S. Census Bureau", "NCES"))
  ) +
  theme_rcds_map(canvas = "dark")

loc <- rcds_locator(context = us_states, highlight = georgia)
fig <- rcds_compose(p, locator = loc, layout = "poster")

rcds_export(fig, "day16.png", preset = "poster_land", canvas = "dark")
```

## What's in the box

| Area | Functions |
|------|-----------|
| Tokens | `rcds_tokens()`, `rcds_color()` |
| Fonts & type | `rcds_fonts()`, `rcds_font()`, `rcds_type_scale()` |
| Palettes | `rcds_pal()`, `scale_*_rcds_c/d()`, `rcds_palettes()`, `rcds_show_palettes()` |
| Themes | `theme_rcds()`, `theme_rcds_map()` |
| Components | `rcds_signature()`, `rcds_credits()`, `rcds_scalebar()`, `rcds_north_arrow()`, `rcds_locator()`, `rcds_annotation_box()` |
| Compose & export | `rcds_compose()`, `rcds_export()`, `rcds_export_presets()` |
| Quality | `rcds_score()`, `rcds_grade()`, `rcds_score_template()` |
| Linting | `rcds_lint()`, `rcds_lint_dir()` |
| Accessibility | `rcds_cvd_check()`, `rcds_greyscale_check()` |
| Interactive | `rcds_leaflet()`, `rcds_pal_leaflet()`, `rcds_leaflet_choropleth()`, `rcds_interactive_css()`, `rcds_maplibre_style()`, `rcds_save_widget()` |
| GCPS brand pack | `gcps_tokens()`, `theme_gcps_map()`, `gcps_interactive_css()`, palettes `gcps_*` / `qual_gcps`, voices `gcps_paper/civic/bold` |
| Brand default | `rcds_brand()` (**default `"gcps"`**), `theme_map()`, `scale_fill_map_c/d()`, `rcds_default_palette()` |
| Dashboard | `gcps_bs_theme()` (6 UI shells → bslib), `gcps_ui_themes()` |

## Demo & deploy

- **Runnable dashboard** (Shiny + Leaflet + ggplot, GCPS identity end to end):
  `apps/gcps-dashboard/app.R` — `shiny::runApp("apps/gcps-dashboard")`.
- **No-Shiny demo** (static PNG + interactive HTML): `inst/examples/gcps_demo.R`.
- **Publish to Posit Connect Cloud** from GitHub: `apps/gcps-dashboard/README.md`
  and `docs/deploy-connect-cloud.md`.

## Linting & tests

`rcds_lint()` enforces the design system's anti-patterns (RCDS.md §8) on any
script — deprecated `size=`, rainbow-on-ordered-data, hardcoded font paths,
inline keys, signature drift, copy-pasted themes, magic sizes, non-hygienic
exports. `tests/testthat/` covers the pure-R surface (tokens, palettes, scoring,
signature, type scale, lint).

```r
rcds_lint("archive/day25_heat.R")   # findings as a tidy data.frame
rcds_lint_dir("archive")            # scan a whole folder

rcds_cvd_check("qual_brand")        # colourblind simulation + confusable-pair flags
rcds_greyscale_check("seq_blue")    # survives black-and-white printing?
```

## Interactive maps (one identity, two renderers)

Static and interactive maps share `rcds_tokens()`, so they look like the same
system. Leaflet starts on a matching basemap with token-driven CSS:

```r
rcds_fonts("default")
rcds_leaflet(canvas = "dark") |>
  rcds_leaflet_choropleth(districts, value = "enrollment",
                          palette = "seq_blue", legend_title = "Enrollment") |>
  rcds_save_widget("enrollment.html")
```

`rcds_interactive_css()` emits a `:root { --rcds-* }` block — the seam where an
imported design system (e.g. a Claude Design project) drops in. See
`inst/interactive/README.md` and `docs/claude-design-integration.md`.

## Templates

Runnable skeletons under `inst/templates/` for the map types in the archive:
choropleth, points, proportional symbols, bivariate, and small multiples.

## Design system docs

The written design system — principles, brand guide, typography & colour specs,
pattern library, anti-patterns, the scoring rubric, the full archive review,
roadmap, and innovation log — lives in [`../docs/`](../docs).

## Status

v0.1.0 — first consolidation of the system. See `docs/roadmap.md` for what's
next (vignettes, `pkgdown` site, automated archive re-scoring, raster/hillshade
helpers).
