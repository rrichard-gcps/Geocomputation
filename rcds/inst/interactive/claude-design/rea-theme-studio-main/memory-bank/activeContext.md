# Active Context

## Current Focus

Evolve Dashboard Layout Architect into a K–12 Dashboard Architect.

Phases 0–5 are complete. The project now has six R/ files alongside the monolithic `app.R`, with a working BOE Snapshot preview tab.

## Completed Phases

- **Phase 0**: Architecture inventory of `app.R` (2,159 lines). Identified all function locations, config structure, and extraction priorities.
- **Phase 1**: Created `R/theme_registry.R` (4 themes), `R/metric_registry.R` (10 metrics), `R/demo_data_k12.R` (5 deterministic datasets). All verified via `Rscript` sourcing. No changes to `app.R`.
- **Phase 2**: Created `R/template_registry.R` with BOE Area Snapshot template. 8 sections (header, filter_bar, kpi_row, map, school_table, trend, student_groups, source_footer), 6 KPI metrics, layout defaults, audience/context metadata. Verified via `Rscript` sourcing.
- **Phase 3**: Created `R/component_registry.R` with 12 component entries and 12 placeholder render functions. All return deterministic HTML using inline styles. Verified with `Rscript` sourcing and HTML output testing.
- **Phase 4/5**: Created `R/boe_preview.R` with template-driven renderer. Added "BOE Snapshot" tab to `app.R` with theme/template selectors and zoom. All 8 sections render deterministically. Existing app behavior preserved.

## Current Priority

**Phase 6**: Export scaffold — generate a runnable Shiny app or Quarto document from the BOE template.

## Next Cline Prompt

```text
Implement Phase 6 only.

Add export buttons to the BOE Snapshot tab:

1. Add a "Download HTML" button that exports the full BOE preview as a standalone HTML file
2. Add a "Copy HTML" button
3. Optionally add a "Download R Scaffold" button for a Shiny app scaffold

Do not modify existing export tabs.
Do not add Promise Schools or Assessment templates yet.
```

## Working Assumptions

- The project root contains `app.R`.
- The current app works or mostly works before refactor.
- `_app_archive/` should be ignored unless explicitly needed.
- The first serious template should be BOE Area Snapshot.
- Promise Schools and Assessment Performance should come after the BOE template pattern works.
- Existing export behavior should be preserved during early refactor phases.
- Avoid drag-and-drop for now.
