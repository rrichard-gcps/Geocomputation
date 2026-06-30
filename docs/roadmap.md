# RCDS Roadmap & Continuous Improvement

*Phase 7 (continuous improvement) and Phase 8 (RCDS as a package) operating plan.*

---

## Where we are

`rcds` v0.1.0 establishes the foundation: tokens, fonts/voices, palette families,
themes, components, composition, export presets, and the scoring rubric — plus
five templates and the written design system. The identity is now codified and
reusable.

## Prioritized roadmap

### Now (v0.1 → v0.2) — adopt & prove
1. ~~**Refactor 3 flagship maps through `rcds`**~~ ✅ Done — Days 16, 7, 30 →
   `archive/*_rcds.R`, see `CHANGELOG-v2.md`.
2. **Re-score** the refactored maps with `rcds_score()` once R is available;
   replace the projected numbers in `archive-review.md` with actuals.
3. ~~**`rcds_lint()`** anti-pattern enforcement~~ ✅ Done (pulled forward from
   v0.3 — highest leverage for "prevent in future work"). Rules A1–A8 + tests.
4. ~~**Unit tests** for the pure-R surface~~ ✅ Done — `tests/testthat/` covers
   tokens, palettes, scoring, signature, type scale, and lint.
5. **Vignette:** `vignettes/getting-started.Rmd` walking the 60-second tour.
6. **`R CMD check`** clean: roxygenize tags → regenerate `man/`/`NAMESPACE`,
   add `@importFrom rlang .data`, confirm green.

### Next (v0.2 → v0.3) — broaden coverage
5. **Templates** for the missing types: dot density, hexbin, raster + hillshade,
   reference/locator-only, election, flow, time-series animation.
6. **`pkgdown` site** so the system is browsable (palette swatches, theme gallery).
7. **Label helper** `rcds_label()` wrapping `ggrepel` + halo defaults.
8. **Palette tooling:** `rcds_cvd_check()` (simulate CVD via `colorspace`),
   `rcds_greyscale_check()`.

### Later (v0.3 → v1.0) — automate the loop
9. **Automated archive re-scoring** + a tracked score history (CSV) to visualize
   the [evolution curve](#personal-cartographic-evolution).
10. **`rcds_lint()`** — static checks on a script: flags `size=` on `geom_sf`,
    rainbow-on-continuous, hardcoded font paths, missing signature, DPI mismatch.
11. **Snapshot tests** (`vdiffr`) so theme/palette changes can't silently regress.
12. **CRAN-readiness** pass (or a stable GitHub release + renv lockfile).

## Continuous-improvement protocol (Phase 7)

When a new map is finished:

1. **Score it** with `rcds_score()`. Record the total + breakdown.
2. **Compare** to the running mean and to the same map type's best.
3. **Diagnose:** which dimension regressed vs. last comparable map? Which improved?
4. **Decide:**
   - If a recurring weakness surfaces again → add/upgrade a helper or template.
   - If a new technique earned points → log it in [innovation-log.md](innovation-log.md).
   - If the map breaks a principle for good reason → note the exception; if the
     exception recurs, the principle may need revising.
5. **Update** templates/the system when a pattern proves itself ≥3 times.

## Personal cartographic evolution

Track these over time (the package will automate the chart):

- **Trend to reward:** rising Colour + Accessibility scores as `rcds` palettes
  replace rainbows; tighter, more consistent typography.
- **Regressions to watch:** reverting to ad-hoc fonts under deadline pressure;
  over-decorating themed maps; oversized legends creeping back.
- **Emerging strengths:** narrative annotation, small-multiple comparisons,
  identity-fill mosaics — lean into these.
- **Next skill frontier:** terrain/hillshade restraint, uncertainty
  visualization, and animation (see innovation log).

**Quarterly summary cadence:** every ~10 new maps, write a short note — mean
score delta, dimension that moved most, one technique to adopt next. The goal is
a deliberate climb from a B-/C+ mean toward a steady A-, with a recognizable
identity intact the whole way.
