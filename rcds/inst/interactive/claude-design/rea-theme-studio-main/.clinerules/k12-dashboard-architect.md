# K–12 Dashboard Architect Rules

You are working on an R Shiny application called Dashboard Layout Architect.

Primary goal:
Gradually evolve the app into a K–12 dashboard pattern generator for education analytics.

Read the `memory-bank/` files before planning or editing.

Do not rewrite the entire app unless explicitly instructed.

Use small, safe, staged changes.

Preferred R style:
- tidyverse-style code
- readable functions
- explicit names
- modular files under R/
- Shiny modules under modules/
- CSS under www/

Design context:
The dashboards are for K–12 district analytics, including Board reporting, school profiles, Promise Schools, attendance, assessment, mobility, early learning, and student group analysis.

Default visual style:
- polished but restrained
- readable for leadership audiences
- avoid pie charts
- use Lexend when available
- use GCPS-style colors:
  - primary #9B2743
  - secondary #2C3641
  - accent blue #374E8E
  - accent teal #2F7C73
  - page background #F6F7F9
  - card background #FFFFFF
  - border #D8DEE8
  - text #1F2933

Safety rules:
- Before editing, summarize the files you plan to modify.
- Modify no more than 3 files per step unless explicitly asked.
- Preserve existing export behavior unless the task is specifically about replacing it.
- Use deterministic fake K–12 data only.
- Do not use random values in preview rendering.
- Do not add drag-and-drop yet.
