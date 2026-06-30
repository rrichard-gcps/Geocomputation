# GCPS Theme Studio — Progress

> This progress log combines the K–12 Dashboard Architect era (Phases 0–5)
> with the GCPS Theme Studio era (Parts A–D). Earlier planning phases are
> preserved as historical context; recent implementation work follows.

---

## Earlier era — K–12 Dashboard Architect (Phases 0–5)

### Completed

- Identified the current app as a monolithic R/Shiny app.
- Decided to pivot from generic layout generation toward a K–12 dashboard pattern generator.
- Identified the medical/business dashboard example as visual inspiration only, not the target content model.
- Defined initial K–12 template priorities:
  1. BOE Area Snapshot
  2. Promise Schools Overview
  3. Assessment Performance Snapshot
- Defined initial registry concepts:
  - theme registry
  - metric registry
  - template registry
  - component registry
  - deterministic demo data
- Added or planned `.clineignore` to reduce context overload.
- Created this memory-bank structure.
- **Phase 0 complete**: Produced architecture inventory of `app.R`.
- **Phase 1 complete**: Created `R/theme_registry.R` (4 themes), `R/metric_registry.R` (10 metrics), `R/demo_data_k12.R` (5 deterministic datasets). All verified with `Rscript` sourcing.
- **Phase 2 complete**: Created `R/template_registry.R` with BOE Area Snapshot template (8 sections, 6 KPI metrics, layout defaults, audience/context metadata). Verified with `Rscript` sourcing.
- **Phase 3 complete**: Created `R/component_registry.R` with 12 component entries and 12 placeholder render functions. All verified with `Rscript` sourcing and HTML output testing.
- **Phase 4/5 complete**: Created `R/boe_preview.R` with template-driven renderer. Added "BOE Snapshot" tab to `app.R` with theme/template selectors and zoom controls. All 8 BOE sections render deterministically. Existing app behavior preserved.

### In Progress

- None.

### Not Started (K–12 dashboard scope)

- Promise Schools template.
- Assessment Performance template.
- Adding accessibility review mode.
- Adding disclosure review mode.
- Adding Quarto export.
- Adding tests.

### Suggested Phase Plan

#### Phase 0 — Inventory Only
Goal: Let the coding assistant inspect the current app without editing.
Deliverable: Architecture summary, function map, proposed extraction order.

#### Phase 1 — Registries Only
Goal: Add durable K–12 registries without refactoring the existing app.
Files: `R/theme_registry.R`, `R/metric_registry.R`, `R/demo_data_k12.R`

#### Phase 2 — Template Registry
Goal: Add `R/template_registry.R` with BOE Area Snapshot only.

#### Phase 3 — Component Registry
Goal: Add component registry and placeholder render functions.

#### Phase 4 — UI Wiring
Goal: Add template/theme/audience controls to the sidebar with minimal disruption.

#### Phase 5 — BOE Preview Renderer
Goal: Render a polished BOE Area Snapshot using fake data.

#### Phase 6 — Export Scaffold
Goal: Export a runnable Shiny scaffold for the selected BOE template.

### Known Risks

- Cline may choke if asked to modify too many files.
- The monolithic `app.R` may contain tightly coupled functions.
- Existing export logic may be fragile.
- CSS generation may rely on parameter order.
- Preview behavior may be tied to current config shape.
- Adding new dependencies may complicate deployment.

---

## Recent era — GCPS Theme Studio (Parts A–D)

### Completed

#### Part A — Embed the client-side Theme Studio (✅ green)
- Vendored `www/palette-data.js`, `www/theme-studio.js`, `www/theme-studio-app.js`
- Re-scoped all CSS under `.ts-root` in `www/theme-studio.css` (zero global bleed)
- One body reference in `theme-studio-app.js` retargeted to `.ts-root`
- Added the Shiny bridge: `render()` emits `input$ts_theme` on every studio change
- Mounted the studio in the existing `theme_studio_tab` nav_panel via
  `www/_theme_studio_markup.html` (markup → data → engine → app load order)
- `theme-studio.css` linked from the app head
- `www/fonts/README.md` documents the five self-hosted woff2 families

#### Part B — Downloadable project templates (✅ green)
- Added `zip` to the requireNamespace block + `source("R/generate_templates.R")`
- `R/generate_templates.R`: `gcps_resolve_theme()` (null-safe default), six
  builders + `theme_gcps.R` / SCSS / `_brand.yml` / CSS-vars export,
  `gcps_write_template_zip()`, `gcps_template_all()`, `gcps_write_all_zip()`
- `templates_tab` nav_panel (six cards + Download-all) inserted after the studio
- Seven `downloadHandler`s wired (one per kind + combined) driven by
  `input$ts_theme`; `ts_theme_summary` badge echoes the active theme
- Acceptance test passes: every bundle's files exist, accent hex + font label
  are baked in, `GCPS-theme.json` parses with `dataColors == palette_hex`,
  zip round-trips match the tree, the all-zip has six subfolders + README

#### Part C — Studio is the single source of truth (✅ green)
- `gcps_config_theme_from_studio(ts)` maps the studio list into the
  `build_config()` shape (theme/typography/palette)
- `build_config()` now pulls theme/typography/palette from
  `gcps_config_theme_from_studio(input$ts_theme)`; canvas/header/sidebar/
  content/annotations stay on the Architect sidebar
- Removed the old sidebar colour/font/palette inputs; kept
  `annotations_enabled` under a "Preview Options" section
- `gcps_resolve_theme()` returns the GCPS default on first paint so Preview
  and exports render before the studio JS emits
- Generators (`generate_css/html/shiny_code/dax/json_theme`) untouched; they
  receive the same config shape from a single source

#### Part D — Power BI `.pbip` project scaffold (✅ green)
- `gcps_template_pbip(t)` emits the PBIR-enhanced project tree (10 files):
  `GCPS-Report.pbip`, `*.Report/definition.{pbir,report.json,pages/…,
  StaticResources/.../GCPS-theme.json}`, `*.SemanticModel/definition.{pbism,
  database.tmdl}`, `.gitignore`, `README.md`
- Theme JSON under `StaticResources` is byte-identical to the B2 builder
  (single source); `report.json` references it via the correct relative path
- `download_tmpl_pbip` handler + a 7th card added to the Project Templates
  grid; registered in `gcps_template_all()` / `gcps_write_all_zip()` as the
  `powerbi-pbip/` subfolder
- Acceptance test passes: all 10 paths present, pointers parse, theme JSON
  parses and equals B2, zip round-trips (10 entries), all-zip has 7 subfolders
  incl. `powerbi-pbip`
- README documents the two required Desktop preview features + recovery steps

### Files changed (this session)
- `www/palette-data.js`, `www/theme-studio.js`, `www/theme-studio-app.js`,
  `www/theme-studio.css`, `www/_theme_studio_markup.html`, `www/fonts/README.md`
- `R/generate_templates.R` (new)
- `app.R` (studio mount, templates tab + handlers, Part C rewiring)
---

## GCPS Theme Studio — Parts A/B/C (2026-06-25)

### Part A — Quarto / flexdashboard code-view tabs (✅ complete)

#### A1 — Generator functions (app.R)
- `generate_quarto_dashboard(config)`: Quarto `format: dashboard`, cosmo + theme.scss, valueBox rows, ggplot chart grid, inline SCSS note
- `generate_quarto_html(config)`: Quarto `format: html`, page-layout: full, bslib `layout_columns` + `value_box` KPIs, `card()` charts, SCSS note
- `generate_flexdashboard(config)`: `.Rmd` YAML, `output: flexdashboard::flex_dashboard`, bslib theme via YAML, `valueBox()` KPIs, By-Column charts

#### A2 — nav_panels (app.R, ~line 2337)
Three nav_panels inserted after `shiny_tab`, before `powerbi_tab`:
- `Quarto Dashboard` / `quarto_dash_tab`
- `Quarto HTML` / `quarto_html_tab`
- `flexdashboard` / `flex_tab`
CSS `.code-output` block updated with `#quarto_dash_output`, `#quarto_html_output`, `#flex_output`

#### A3 — Server wiring (app.R)
- `output$quarto_dash_output`, `output$quarto_html_output`, `output$flex_output` — renderText
- `output$download_quarto_dash` (.qmd), `output$download_quarto_html` (.qmd), `output$download_flex` (.Rmd) — downloadHandlers
- `copy_quarto_dash`, `copy_quarto_html`, `copy_flex` — observeEvents → `copy_to_clipboard`

### Part B — 4 new palette families (✅ complete)

Added to `gcps_base`, `gcps_ramps`, `gcps_diverging` in `app.R` and `FAMILY_NAMES`/`FAMILY_LABELS` in `R/gcps_palettes.R`:
- `gold` (#C49A22) — warm highlight, award & recognition; diverges toward teal
- `plum` (#7B2D8B) — deep contrast, adult literacy & workforce; diverges toward green
- `slate` (#4A6D8C) — steel-blue, operations & infrastructure; diverges toward orange
- `emerald` (#1A7D5A) — deep green, sustainability & wellness; diverges toward maroon

`length(gcps_base) == length(gcps_ramps) == 11`

### Part C — Accent panel moved to Palette tab (✅ complete)

- Accent `.panel` div (containing `#accentRow`) moved from `#tab-surfaces` to be the first panel inside `#tab-palette` in `www/_theme_studio_markup.html`
- `id="accentRow"` preserved; JS still resolves by ID

### git diff --stat
 R/gcps_palettes.R             |  12 +-
 app.R                         | 440 +++++++++++++++++++++++++++++++++++++++++-
 www/_theme_studio_markup.html |  10 +-
 3 files changed, 452 insertions(+), 10 deletions(-)
