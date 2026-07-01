# GCPS Theme Studio — Decision Log

> This log combines the K–12 Dashboard Architect era (Decisions 001–007) with
> the GCPS Theme Studio era (ADRs Part A–D). Entries are chronological:
> strategic architecture decisions first, then implementation ADRs.

---

## Earlier era — K–12 Dashboard Architect

### Decision 001 — K–12 First

The next version should be K–12-specific, not a generic business dashboard clone.

Reason: The actual work context is education analytics. Reusable templates should reflect real K–12 reporting patterns. The medical/business dashboard was only a visual reference.

### Decision 002 — Template-Driven Architecture

The app should move from generic layout boxes toward dashboard templates and component slots.

Reason: Repeatable K–12 products need repeatable design patterns. Templates reduce manual layout tuning. Templates make exports more consistent.

### Decision 003 — Registries Before Refactor

Create theme, metric, template, component, and demo-data registries before deep refactoring.

Reason: Registries provide structure without breaking the app. Cline can handle small file creation better than whole-app rewrites. The current app can keep working during incremental migration.

### Decision 004 — No Drag-and-Drop Yet

Do not add drag-and-drop in the next version.

Reason: It would add complexity before the product model is stable. Template selection and component-aware preview are higher value right now.

### Decision 005 — Deterministic Fake Data

Use deterministic synthetic K–12 data only.

Reason: Preview should be stable. Random values cause unnecessary reactivity churn. Synthetic data avoids privacy and disclosure concerns.

### Decision 006 — BOE Area Snapshot First

Build BOE Area Snapshot before Promise Schools and Assessment templates.

Reason: It contains the core dashboard shell: header, tabs, filters, KPIs, map, school table, trend, student group comparison, detail table, and footer. Later templates can reuse this structure.

### Decision 007 — Absolute Preview, CSS Grid Export

Keep absolute positioning for the architect canvas preview, but prefer CSS Grid for generated Shiny/Quarto output.

Reason: Absolute positioning supports design-canvas precision. CSS Grid is more maintainable in exported apps.

---

## Recent era — GCPS Theme Studio

### ADR: Studio is the single theme source (Part C)

**Status:** Accepted (2026-06-18)

**Context.** Part A5 shipped a deliberate dual-theme state: the new embedded
client-side Theme Studio drove the Project Template downloads, while the
old `colourInput`/`selectInput` controls in the Architect sidebar continued
to drive `build_config()` → Preview / Power BI HTML / DAX / Full HTML. This
kept the existing exports green while the studio stood up, but it left two
independent theme surfaces that could drift.

**Decision.** Make the studio (`input$ts_theme`, emitted by the JS bridge in
`www/theme-studio-app.js`) the single source of truth for the
`theme` / `typography` / `palette` sub-lists of `build_config()`. Layout
fields (canvas, header, sidebar, content, annotations) stay on the
Architect sidebar. `gcps_config_theme_from_studio()` in
`R/generate_templates.R` performs the shape mapping; `gcps_resolve_theme()`
makes it null-safe so first paint uses the GCPS default before the studio
JS emits.

**Consequences.**
- One place to set the theme; changing any studio control propagates to
  Preview, Power BI HTML, DAX, Full HTML, and every Project Template.
- `generate_css/html/shiny_code/dax/json_theme` signatures and bodies are
  unchanged — they still receive the same config shape, now fed from one
  source.
- The old sidebar colour/font/palette inputs are removed; `annotations_enabled`
  is retained (it is layout, not theme).

### ADR: Ship a PBIR `.pbip` scaffold, not a synthetic `.pbip` binary (Part D)

**Status:** Accepted (2026-06-18)

**Context.** The Part B Power BI bundle is a portable **report-theme JSON**
the user imports by hand. Users asked for a template that opens directly in
Power BI Desktop with the theme pre-registered. A true `.pbip` is a
multi-file project folder (PBIR enhanced-report format), not a single file.

**Decision.** Emit the minimal PBIR project tree (`GCPS-Report.pbip` +
`*.Report/…` + `*.SemanticModel/definition/database.tmdl` with one empty
`Placeholder` table) and reuse the Part-B theme JSON verbatim under
`StaticResources/.../GCPS-theme.json`. Keep JSON/TMDL minimal and
schema-valid; document the two required Desktop preview features
(`.pbip save option` + `Store reports using enhanced metadata format (PBIR)`)
in the bundle README.

**Consequences.**
- Single source of truth for the theme JSON (the B2 builder); the `.pbip`
  tree references it by the correct relative path.
- The format is preview-gated and version-sensitive; the README tells the
  user how to recover if a field is rejected (re-save from Desktop, diff).
- D is independent of B's six bundles and does not gate them.

### ADR: Embed the studio as scoped static assets (Part A)

**Status:** Accepted (2026-06-18)

**Context.** Re-porting the studio's palette/type/surface/preview/WCAG/export
interactions into Shiny reactives caused earlier "tabs didn't render / layout
is off" symptoms, and the standalone mock's global CSS bled into the yeti
shell + Architect.

**Decision.** Vendor the studio as scoped static assets under `www/`, mount
its markup inside exactly one `nav_panel` as static UI (not `renderUI`), and
re-scope every CSS rule under a single root class `.ts-root`. The studio owns
its own internal tab bar; init runs once against a present DOM. A single JS
emitter pushes the active theme to `input$ts_theme` for the R side.

**Consequences.**
- 1:1 fidelity with the approved mock; no reactive re-render drift.
- Zero CSS bleed into the Architect sidebar, unified Preview, or the shell.
- `input$ts_theme` is the bridge for every downstream export/template.