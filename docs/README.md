# RCDS Documentation

The written half of the **Richard Cartographic Design System**. The code half is
the [`rcds`](../rcds) R package.

| Document | What it covers | Prompt phase |
|----------|----------------|--------------|
| [RCDS.md](RCDS.md) | The design system: principles, brand guide, typography, colour, layout, components, pattern library, anti-patterns, scoring rubric, export standards | 4, 8 |
| [archive-review.md](archive-review.md) | Archive catalog, professional critique, per-map Quality Scores, improvement matrix | 1, 2, 3, 8 |
| [roadmap.md](roadmap.md) | Prioritized improvement plan + continuous-improvement protocol + evolution tracking | 7, 8 |
| [innovation-log.md](innovation-log.md) | Living list of advanced techniques to grow into | 7, 8 |
| [claude-design-integration.md](claude-design-integration.md) | Status + record of folding the Claude Design projects into rcds | — |
| [gcps-brand.md](gcps-brand.md) | The imported GCPS brand pack: 11-family colour system, 3 map themes, interactive CSS | — |
| [deploy-connect-cloud.md](deploy-connect-cloud.md) | Publishing the map tool / dashboard to Posit Connect Cloud from GitHub | — |

## Start here

1. Read [RCDS.md §1–§4](RCDS.md) for the identity (principles, brand, type, colour).
2. Skim [archive-review.md](archive-review.md) to see where your archive stands
   and what to fix first.
3. Install the package (`../rcds/README.md`) and rebuild one map through it.
4. Follow [roadmap.md](roadmap.md) to refactor the flagship set and track scores.

## Deliverables map (from the brief)

- Review of existing style → `archive-review.md` (Phases 1–3)
- Strengths/weaknesses catalog → `archive-review.md` + `RCDS.md §2`
- Prioritized improvement roadmap → `archive-review.md` (matrix) + `roadmap.md`
- Formal design guide → `RCDS.md`
- Reusable R framework → `../rcds` package
- Palette library → `rcds-palettes.R` + `RCDS.md §4`
- Layout templates → `../rcds/inst/templates/` + `RCDS.md §5`
- Typography standards → `rcds-fonts.R` + `RCDS.md §3`
- Export standards → `rcds-export.R` + `RCDS.md §10`
- Advanced techniques → `innovation-log.md`
- Map Quality Score → `rcds-score.R` + `RCDS.md §9`
- Pattern library / anti-patterns → `RCDS.md §7–§8`
