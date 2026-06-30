# v2 Refactor Set — Flagship maps through RCDS

The highest-leverage roadmap item: prove the system end-to-end by re-rendering
the flagship maps through `rcds`. Each refactor preserves the **original data
pipeline verbatim** (the prefix of the file is unchanged) and replaces only the
**rendering, composition, and export** with framework calls — so the diff isolates
exactly what the design system buys.

> Note: R is not installed in this environment, so the refactored scripts have
> not been executed here. They are written against the `rcds` v0.1.0 API and the
> originals' data objects. Re-score with `rcds_score()` after a real render.

## Files

| New file | Refactors | Demonstrates |
|----------|-----------|--------------|
| `archive/day16_choropleth_rcds.R` | Day 16 bivariate | `rcds_pal("biv_dkblue")` → `bi_pal_manual`, `theme_rcds_map`, `rcds_credits`, `rcds_color`, `rcds_type_scale`, `rcds_export` |
| `archive/day30_cfb_rcds.R` | Day 30 CFB mosaic | `scale_fill_identity` kept, `theme_rcds_map("deep")`, token outlines, `rcds_signature`, `rcds_export` |
| `archive/day7_vintage_rcds.R` | Day 7 Du Bois | `theme_rcds_map("vintage")` (wheat/brown now tokens), `vintage` voice, palette kept verbatim |

## What changed in each (before → after)

### Day 16 — Bivariate choropleth (89 → 94, A)
- `bi_scale_fill("DkCyan")` + `bi_theme()` (white) → RCDS `biv_dkblue` grid via
  `bi_pal_manual()` on `canvas.dark`; map and legend share one palette source.
- Hand-built `geom_richtext` credits + four bespoke `area()` coords →
  `rcds_credits()` + a clean `area()` design with token-driven title/subtitle.
- `size =` on `geom_sf` → `linewidth =`; magic font sizes → `rcds_type_scale(16)`.
- `ggsave(...)` → `rcds_export(preset = "poster_land")` (showtext DPI synced).

### Day 30 — Nearest FBS program (85 → 90, A-)
- Removed the dotted grey graticule (noise on an abstract national map).
- Identity team colours **kept** (`scale_fill_identity`) — correct: these encode
  brand identity, not an ordered variable.
- Ad-hoc `theme_void()` block → `theme_rcds_map("deep")`; token neutral outlines;
  `techno` voice; standardized `rcds_signature()`; `linewidth =`; `rcds_export`.

### Day 7 — Du Bois homage (89 → 92, A-)
- Wheat canvas + brown ink were hand-set hex everywhere → now the `vintage`
  canvas tokens in `theme_rcds_map()`.
- `bebas` font ad-hoc → the sanctioned `vintage` voice (Bebas Neue display).
- Historical `dubois_colors` palette **kept verbatim** — the system improves
  execution, never the homage. Standardized caption; `linewidth =`; `rcds_export`.

## How to run

```r
# install/load the framework first
devtools::load_all("rcds")        # or pak::local_install("rcds")

# then source a refactor (after setting CENSUS_API_KEY in ~/.Renviron)
source("archive/day16_choropleth_rcds.R")
```

## Verification checklist (when R is available)

- [ ] `devtools::load_all("rcds")` succeeds; `R CMD check` is clean.
- [ ] Each `*_rcds.R` renders without error and writes its PNG.
- [ ] Visual diff vs. the original PNG: identity intact, palette safer, type tighter.
- [ ] Re-score with `rcds_score()`; replace the projected numbers above with actuals.
