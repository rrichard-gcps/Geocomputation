# Task Prompts for Cline/OpenCode

Use these prompts one at a time. Do not combine phases.

## Prompt 0 — Inventory Only

```text
Read the memory-bank files first. Then inspect the project files that are not ignored.

Do not modify files yet.

Your task is only to produce a concise inventory of the current app structure.

Focus on:
1. Where DEFAULT_CONFIG is defined
2. Where build_config() is defined
3. Where CSS is generated
4. Where preview HTML is generated
5. Where Shiny code export is generated
6. Which functions should be extracted first

Return:
- a short architecture summary
- a proposed 5-step refactor plan
- the first 3 files you recommend creating

Do not write code yet.
```

## Prompt 1 — Registries Only

```text
Implement Phase 1 only.

Create these files:
- R/theme_registry.R
- R/metric_registry.R
- R/demo_data_k12.R

Do not refactor app.R.

Only add source() calls to app.R if necessary, and only after summarizing where they should go.

Use deterministic fake K–12 data only.
Do not use random values.

After editing, summarize exactly what changed and how to test that the app still starts.
```

## Prompt 2 — Template Registry Only

```text
Implement Phase 2 only.

Create R/template_registry.R with one template:
BOE Area Snapshot.

Do not modify preview rendering yet.
Do not add Promise Schools or Assessment templates yet.
Do not refactor the existing app.

After editing, summarize the template structure and how it will connect to the current app in the next step.
```

## Prompt 3 — Component Registry Only

```text
Implement Phase 3 only.

Create R/component_registry.R.

Add registry entries for:
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

Add placeholder render functions only if needed.
Do not wire them into app.R yet.

After editing, summarize how components will connect to templates.
```

## Prompt 4 — Minimal UI Wiring

```text
Implement Phase 4 only.

Add minimal sidebar controls for:
- audience
- reporting context
- template
- theme

Do not remove existing controls.
Do not alter export logic.
Do not redesign the full UI.

After editing, summarize the changed files and provide a smoke test.
```

## Prompt 5 — BOE Preview

```text
Implement Phase 5 only.

Add a BOE Area Snapshot preview renderer using deterministic fake K–12 data.

The preview should include:
- dashboard header
- navigation tabs
- filter bar
- KPI row
- map placeholder
- school summary table
- trend placeholder
- student group comparison placeholder
- detail table
- source footer

Do not add Promise Schools yet.
Do not add Assessment template yet.
Do not add drag-and-drop.

After editing, summarize how to test the BOE preview.
```
