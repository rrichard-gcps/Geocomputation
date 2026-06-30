# Cartographic Innovation Log

*A living list of techniques to grow into. Each entry: why it's useful, where it
excels, how to do it in R, the learning effort, and a priority. Add to this
whenever a technique would meaningfully elevate the work without sacrificing
clarity or maintainability.*

Priority key: **High** = adopt in the next few maps · **Med** = within the year ·
**Low** = when a project calls for it.

---

### 1. Colourblind & greyscale proofing in the loop — ✅ **Done** (v0.1)
- **Why:** turns accessibility from a hope into a check; defends the new palettes.
- **Excels:** any published map, especially choropleths.
- **Shipped:** `rcds_cvd_check()` (simulates deutan/protan/tritan via `colorspace`,
  flags pairs below ~15 deltaE) and `rcds_greyscale_check()` (luminance ordering /
  separation, base `grDevices` only). Both accept a palette name or a hex vector
  and return swatch-row plots or a tidy report.
- **Next:** extend to whole-plot proofing (render → simulate the raster) and add
  an optional gate in `rcds_export()` that warns if the active palette fails.

### 2. Halo'd repel labels as default — **High**, low effort
- **Why:** the archive's labels collide and lack contrast on dark fills.
- **Excels:** point maps, reference maps, callouts over imagery.
- **R:** `ggrepel::geom_text_repel(bg.color = ..., bg.r = ...)` or `shadowtext`.
- **Effort:** ~1 hr. **Now.**

### 3. Binned (classed) choropleths — **High**, low effort
- **Why:** classed maps often read better than continuous ramps; pairs with the
  sequential families.
- **Excels:** enrollment, rates, counts for general audiences.
- **R:** `ggplot2::binned_scale()` / `scale_fill_stepsn()`, or `classInt` breaks
  (Jenks/quantile) → `rcds_pal("seq_*", k)`.
- **Effort:** ~1 hr. **Now.**

### 4. Hillshade / terrain relief, with restraint — **Med**, medium effort
- **Why:** depth and place for physical-geography maps without overwhelming data.
- **Excels:** watersheds (already in archive!), parks, regional context.
- **R:** `elevatr` (DEM) → `terra`/`whitebox` hillshade → `tidyterra::geom_spatraster`
  blended under a muted data layer. Patterson-style: low contrast, cool shadows.
- **Effort:** ~half a day. **Med.**

### 5. Dasymetric / dot-density refinement — **Med**, medium effort
- **Why:** more honest population surfaces than choropleths of large polygons.
- **Excels:** the education/demographic subjects at the core of the portfolio.
- **R:** `sf::st_sample()` for dot density; `terra` + ancillary land-use for
  dasymetric reallocation.
- **Effort:** ~half a day. **Med.**

### 6. Uncertainty visualization — **Med**, medium effort
- **Why:** ACS estimates (used heavily) carry margins of error that maps hide.
- **Excels:** any tidycensus-derived choropleth.
- **R:** bivariate value-vs-MOE (`biscale`), or `ggdist`/texture/transparency to
  encode CI width; "value-suppressing uncertainty palettes" (VSUP).
- **Effort:** ~half a day. **Med.**

### 7. Animated time-series maps — **Med**, medium effort
- **Why:** Day 25's small multiples could also breathe as motion for social.
- **Excels:** enrollment-over-time, change, diffusion.
- **R:** `gganimate` (transition_states) on the RCDS theme; export GIF/MP4. Keep a
  static small-multiple companion for print.
- **Effort:** ~half a day. **Med.**

### 8. Interactive / web maps on-brand — **Med**, medium effort
- **Why:** extend the identity beyond static PNGs (story maps already attempted).
- **Excels:** exploratory dashboards, story maps.
- **R:** `mapgl`/`maplibre` or `leaflet` with an RCDS dark basemap + token colours;
  `ggiraph` for tooltip'd ggplot maps.
- **Effort:** ~1 day. **Med.**

### 9. Hex / H3 spatial binning — **Low**, medium effort
- **Why:** equal-area aggregation that sidesteps the big-rural-polygon bias.
- **Excels:** national point phenomena (the CFB/Census-block work).
- **R:** `h3jsr` or `sf::st_make_grid(square = FALSE)` → aggregate → choropleth.
- **Effort:** ~half a day. **Low.**

### 10. Inset-driven detail-on-demand layouts — **Low**, low effort
- **Why:** systematize the AK/HI and metro insets already in use.
- **Excels:** national maps with dense metros; multi-scale stories.
- **R:** `rcds_compose(layout = "sidebar")` + multiple `rcds_locator()` panels;
  `patchwork::area()` grids.
- **Effort:** ~1 hr. **Low.**

### 11. Cartograms (contiguous / Dorling) — **Low**, medium effort
- **Why:** Day 24 reached for a cartogram feel; do it properly.
- **Excels:** population/enrollment where area should encode value.
- **R:** `cartogram::cartogram_cont()` / `cartogram_dorling()`.
- **Effort:** ~half a day. **Low.**

### 12. Typographic & textured maps — **Low**, medium effort
- **Why:** Day 19 typography map shows appetite; a signature art-cartography mode.
- **Excels:** posters, narrative pieces.
- **R:** `ggfx` (texture, glow, shadow), label-as-fill techniques, `geomtextpath`.
- **Effort:** ~half a day. **Low.**

---

*Reviewed: 2026-06. Next review after the v0.2 refactor set.*
