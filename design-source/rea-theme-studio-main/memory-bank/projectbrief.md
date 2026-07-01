# Project Brief: K–12 Dashboard Architect

## Project Name

Dashboard Layout Architect, evolving into **K–12 Dashboard Architect**.

## Purpose

This project is an R/Shiny application that helps design, preview, and export polished dashboard layouts. The next version should move beyond a generic grid/layout generator and become a template-driven dashboard pattern generator for K–12 education analytics.

The tool should support district analytics work such as Board reporting, school profiles, cluster summaries, Promise Schools, chronic absenteeism, assessment performance, student mobility, early learning readiness, student group analysis, and public-facing data stories.

## Core Product Idea

The app should support this workflow:

```text
Audience → Reporting Context → Dashboard Template → Components → Theme → Preview → Export
```

The tool should generate repeatable dashboard patterns, not just arbitrary boxes.

## Primary Users

- District analytics leaders
- Power BI developers
- R/Shiny and Quarto developers
- Data visualization staff
- Research, evaluation, and accountability staff
- Analysts preparing products for district leaders, school leaders, Board members, or the public

## Main Use Cases

1. Generate a polished K–12 dashboard scaffold quickly.
2. Standardize layout patterns across a district analytics team.
3. Preview education-specific dashboard templates using synthetic example data.
4. Export runnable Shiny code.
5. Export Quarto dashboard/page scaffolds.
6. Export Power BI-friendly HTML snippets and theme guidance where useful.
7. Support a design system that improves consistency, readability, accessibility, and stakeholder communication.

## Required Initial Templates

The first useful version should include these templates:

1. **BOE Area Snapshot**
   - Board member area summary with KPIs, map, school table, trends, and source notes.

2. **Promise Schools Overview**
   - Support-focused dashboard showing Promise Schools by level, cluster, geography, accountability indicators, and student context.

3. **Assessment Performance Snapshot**
   - Assessment-focused dashboard showing performance by content area, school level, school, year, and student group.

## Design Principles

- Use polished, modern, restrained dashboard design.
- Prioritize readability for leadership audiences.
- Use clear hierarchy, generous spacing, subtle borders, and consistent typography.
- Avoid pie charts.
- Prefer maps, tables, trend lines, dot plots, lollipop charts, stacked bars, small multiples, and matrix-style summaries.
- Include source, refresh date, methodology, and disclosure notes.
- Use deterministic synthetic preview data only.
- Do not expose sensitive data, student-level records, production credentials, or private internal data.

## First Milestone

A working Shiny app that can:

1. Select the **BOE Area Snapshot** template.
2. Select an audience and reporting context.
3. Select a theme.
4. Preview a polished static K–12 dashboard using deterministic fake data.
5. Switch between example, blank, annotated, accessibility review, disclosure review, and print preview modes.
6. Export a runnable Shiny scaffold.
7. Preserve current working behavior as much as possible during refactoring.
