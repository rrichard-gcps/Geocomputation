# Product Context

## Why This Exists

The current Dashboard Layout Architect can generate layout containers and export code, but it is still too generic. The next version should encode real K–12 analytics patterns so the team can create more consistent, polished, and stakeholder-ready dashboards.

The tool should help shift dashboard development from one-off report construction toward reusable design patterns and reusable analytic products.

## Work Context

The project supports a K–12 district analytics environment where dashboards are used for:

- Board of Education summaries
- District leadership reporting
- School leadership reporting
- Public data stories
- Internal QA/research views
- Promise Schools support
- Assessment performance reporting
- Attendance and chronic absenteeism analysis
- Mobility analysis
- Early learning/readiness dashboards
- Student group equity analysis
- School profiles and cluster summaries

## Audiences

| Audience | Needs |
|---|---|
| Board Members | Clear area-level summaries, school lists, maps, source notes, restrained design |
| District Leadership | Fast interpretation, trend direction, high-level patterns, intervention context |
| School Leadership | School profile, peer comparison, student group detail, action-oriented notes |
| Research/Analytics Team | Denser QA views, methodology notes, metric definitions |
| Public | Plain language, accessibility, disclosure-safe summaries, explanatory framing |

## Reporting Contexts

- District
- BOE Area
- Cluster
- School
- School Level
- Student Group
- Grade Band
- Content Area
- School Year
- Comparison Year
- Promise School status
- Title I status
- Attendance zone or geography

## K–12 Metric Domains

- Enrollment
- Demographics
- Attendance
- Chronic absenteeism
- Student mobility
- Assessment performance
- Reading on grade level
- Graduation rate
- Accountability / CCRPI-style indicators
- Discipline
- Staff profile
- Teacher experience and retention
- Early learning readiness

## Product Direction

The project should become a **dashboard pattern generator**.

The app should know about education-specific templates, metric definitions, dashboard components, GCPS-style themes, and source/methodology/disclosure notes.

## What Not To Do

- Do not model the app around the medical/business sample dashboard. That was only a visual inspiration.
- Do not add drag-and-drop yet.
- Do not create a giant rewrite in one pass.
- Do not remove working exports unless replacing them with a better equivalent.
- Do not use random preview values.
- Do not rely on pie charts.
- Do not store sensitive data or credentials in the project.
