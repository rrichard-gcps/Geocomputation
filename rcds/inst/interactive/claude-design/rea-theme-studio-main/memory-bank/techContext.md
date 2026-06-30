# Technical Context

## Language and Framework

- Language: R
- R version target: 4.5.0+
- Framework: Shiny
- UI toolkit: bslib / Bootstrap 5
- Package management: renv
- Deployment target: Posit Connect
- Current deployment mode: Shiny app

## Current Known Stack

The current app uses or may use:

- shiny
- bslib
- htmltools
- jsonlite
- stringr
- glue
- tibble
- dplyr

The generated output may eventually use:

- plotly
- leaflet
- gt
- reactable
- echarts4r
- sf
- htmlwidgets

Only add dependencies when necessary.

## Current App Characteristics

The current app is a single large `app.R`.

Current features include live preview, canvas sizing, aspect ratio presets, KPI row configuration, content grid configuration, multiple layout types, theme controls, annotation overlay, Shiny code export, Power BI HTML export, DAX export, JSON theme export, full HTML export, and download handlers.

Known partial or missing features:

- Typography controls exist but are not fully wired into config or generated CSS.
- Copy buttons may only show notifications rather than actually writing to clipboard.
- Preview data may use random sample values; replace with deterministic fake K–12 data.
- No save/load configuration yet.
- No unit tests yet.
- Current architecture is monolithic.

## Coding Style Preferences

Use tidyverse-style R, clear function names, explicit object names, small functions, modular files, readable comments, and deterministic examples.

Avoid giant unstructured functions, silent parsing failures, unnecessary JavaScript frameworks, excessive dependencies, random values in previews, and hardcoded one-off dashboard content unless part of a template.

## CSS/Design Style

Default dashboard style:

- Polished but restrained
- Leadership-friendly
- High contrast but not harsh
- Subtle borders
- Clear visual hierarchy
- Generous spacing
- Strong source/methodology footer
- Accessibility-aware colors and type size

Preferred default theme:

```text
Primary:       #9B2743
Secondary:     #2C3641
Accent blue:   #374E8E
Accent teal:   #2F7C73
Page bg:       #F6F7F9
Card bg:       #FFFFFF
Border:        #D8DEE8
Text:          #1F2933
Muted text:    #667085
Font:          Lexend
```

Avoid pie charts, excessive decoration, low-contrast labels, tiny typography, and too many competing accent colors.

## Development Workflow

1. Read memory-bank files.
2. Inspect relevant project files.
3. Summarize plan.
4. List files to edit.
5. Modify only a small number of files.
6. Provide testing instructions.
7. Update `activeContext.md` and `progress.md`.

## Recommended Smoke Tests

After each change:

```r
shiny::runApp()
```

Also check:

- App starts without sourcing errors.
- Preview renders.
- Existing download buttons still appear.
- No missing object/function errors in console.
- New registry files can be sourced independently.
- Generated Shiny export still produces runnable code if that area was touched.

## Data Safety

Use deterministic fake K–12 data in previews.

Do not store student-level data, real student names, credentials, database connection strings, internal secrets, production extracts, or sensitive small-n data.
