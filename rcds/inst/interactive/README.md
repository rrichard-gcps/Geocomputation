# rcds interactive assets

This folder holds the HTML/CSS side of the system — the identity for **interactive**
maps (Leaflet today, MapLibre/MapGL next) — and the landing zone for an imported
Claude Design project.

## How the static and interactive sides share one identity

```
rcds_tokens()  ──┬──►  static maps   (theme_rcds, palettes, components)
                 └──►  interactive   (rcds_interactive_css :root variables)
```

`rcds_interactive_css()` emits CSS custom properties built from `rcds_tokens()`:

```css
:root {
  --rcds-canvas: #1C1C1C;
  --rcds-ink-1:  #FFFFFF;
  --rcds-accent-blue: #1E6FB8;
  --rcds-font-display: 'Oswald', sans-serif;
  /* ... */
}
```

Every Leaflet popup, control, legend, and tooltip reads those variables. Change a
token (or override a `--rcds-*` variable) and every interactive map restyles —
the exact mirror of how overriding `rcds_tokens()` restyles every static map.

## Claude Design import lands here

When a Claude Design project is sent into the workspace (via **Send to Claude
Code Web**), drop its files under `claude-design/`. Then we wire it in by mapping
its design tokens onto the two seams:

| Claude Design artifact | Maps onto |
|------------------------|-----------|
| Colour tokens (canvas, ink, accents) | `rcds_tokens()` values |
| Type tokens (font families, scale) | `rcds_fonts()` voice + `rcds_type_scale()` |
| Spacing tokens | `rcds_tokens()$space` |
| Component CSS (cards, chips, legends, controls) | `--rcds-*` overrides + selectors in `rcds_interactive_css()` |
| Component HTML (popup/legend/panel markup) | popup/label templates in `rcds_leaflet_choropleth()` |

Nothing here is fabricated from the design projects yet — this is the wiring,
ready for the real tokens. See `docs/claude-design-integration.md` for the plan.
