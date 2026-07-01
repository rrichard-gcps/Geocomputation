# System Patterns

## Current Architecture

The existing app is a monolithic R/Shiny application:

```text
dashboard-layout-architect/
├── app.R
├── test.R
├── renv.lock
└── _app_archive/
```

The current `app.R` includes default configuration, Shiny UI/server, CSS generation, HTML preview generation, layout math, Shiny export, Power BI HTML export, DAX export, JSON theme export, and download handlers.

The next version should gradually extract these concerns into separate files.

## Target Architecture

```text
dashboard-layout-architect/
├── app.R
├── R/
│   ├── config_defaults.R
│   ├── config_schema.R
│   ├── theme_registry.R
│   ├── metric_registry.R
│   ├── template_registry.R
│   ├── component_registry.R
│   ├── demo_data_k12.R
│   ├── validation.R
│   ├── layout_math.R
│   ├── layout_engine_absolute.R
│   ├── layout_engine_css_grid.R
│   ├── components_header.R
│   ├── components_nav.R
│   ├── components_filters.R
│   ├── components_kpi.R
│   ├── components_tables.R
│   ├── components_charts.R
│   ├── components_maps.R
│   ├── components_notes.R
│   ├── generate_css.R
│   ├── generate_shiny_app.R
│   ├── generate_quarto_qmd.R
│   ├── generate_powerbi_html.R
│   └── generate_theme_json.R
├── modules/
│   ├── mod_sidebar_context.R
│   ├── mod_sidebar_template.R
│   ├── mod_sidebar_theme.R
│   ├── mod_sidebar_layout.R
│   ├── mod_sidebar_components.R
│   ├── mod_preview.R
│   ├── mod_export.R
│   └── mod_reference_image.R
├── www/
│   ├── architect.css
│   ├── preview.css
│   └── k12-dashboard.css
├── memory-bank/
└── tests/
```

## Core Data Flow

```text
Shiny inputs
  ↓
build_config()
  ↓
selected audience + context + template + theme
  ↓
template registry
  ↓
component registry
  ↓
preview renderer
  ↓
export generators
```

## Major Registries

### Theme Registry

File: `R/theme_registry.R`

Purpose: store reusable theme tokens including colors, typography, radius, spacing, and density settings.

Initial themes:

- GCPS Light
- GCPS Board Report
- Public Data Story
- Technical Analyst

### Metric Registry

File: `R/metric_registry.R`

Purpose: store reusable K–12 metric metadata.

Initial metrics:

- enrollment
- school_count
- chronic_absenteeism
- mobility_rate
- reading_on_grade_level
- proficient_distinguished
- ccrpi_score
- graduation_rate
- discipline_incident_rate
- teacher_retention

### Template Registry

File: `R/template_registry.R`

Purpose: store dashboard templates as structured lists.

Initial templates:

- BOE Area Snapshot
- Promise Schools Overview
- Assessment Performance Snapshot

### Component Registry

File: `R/component_registry.R`

Purpose: map component IDs to preview/render/export functions.

Initial components:

- dashboard_header
- nav_tabs
- filter_bar
- kpi_row
- metric_selector_card
- trend_chart_placeholder
- student_group_comparison
- map_school_points
- school_summary_table
- metric_matrix_table
- source_footer
- disclosure_note

## Preview Engines

Keep absolute positioning for architect canvas previews. Prefer CSS Grid for generated Shiny/Quarto exports.

## Preview Modes

1. Example Data
2. Blank Layout
3. Annotated Layout
4. Data Story Mode
5. Accessibility Review
6. Disclosure Review
7. Print Preview

## Refactor Strategy

- Modify no more than 1–3 files per task.
- Preserve existing app behavior.
- Prefer adding new modular files before altering existing logic.
- Run or describe a smoke test after each change.
- Do not perform a full rewrite unless explicitly instructed.
