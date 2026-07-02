# RCDS Map Builder — static site

A self-contained browser demo for the RCDS Map Builder: pick a dataset and field,
choose a classification, and see a choropleth styled through the RCDS system and
scored with a Map Quality Score. No build step.

```
index.html   styles.css   app.js   assets/…   data.js (generated)   prep/…
```

## Preview

Open `index.html` directly, or serve the folder:

```bash
python3 -m http.server -d apps/rcds-map-builder 8000   # → http://localhost:8000
```

## Real geometry vs. the synthetic fallback

The demo renders **real GCPS/metro geometry** when a `data.js` file is present,
and falls back to a synthetic jittered-grid mosaic when it isn't. A browser can't
read `.shp`/`.gpkg`/`.rds`, so those repo boundary files are converted **once in
R** to GeoJSON embedded in `data.js`.

### Generate `data.js` from the repo's boundary files

1. Install the R deps once: `install.packages(c("sf", "rmapshaper"))`.
2. From the **repo root**, run:
   ```bash
   Rscript apps/rcds-map-builder/prep/export_geojson.R
   ```
   It reads the files listed at the top of that script (ES/MS/HS demographics,
   metro ABSM zones, ACS tracts, district outline, counties), reprojects to
   WGS84, simplifies the geometry for the web, and writes
   `apps/rcds-map-builder/data.js`.
3. Reload the page. Datasets now draw real boundaries, and the **field dropdown
   is populated from the actual numeric columns** found in each layer (the app
   auto-discovers them; recognised names like `frpl`/`ell` get friendly labels,
   anything else uses a prettified column name).
4. Commit `data.js`.

### Pointing at different files / columns

Edit the `DATASETS` list at the top of `prep/export_geojson.R` to change which
file backs each dataset id (e.g. swap `gcps_es_demog.gpkg` for
`gcps_es_demog_std.gpkg` to map z-scores instead of raw percentages) or to adjust
the `keep` simplification fraction. The script prints the columns it found per
layer so you can confirm what will be mappable.

### How the mapping works

| Site dataset | Default source file | Notes |
|--------------|---------------------|-------|
| `es` | `data/prep/gcps_es_demog.gpkg` | ES attendance zones |
| `ms` | `data/prep/gcps_ms_demog.gpkg` | MS attendance zones |
| `hs` | `data/prep/gcps_hs_demog.gpkg` | HS clusters |
| `metro_es` | `data/prep/metro_es_absm.gpkg` | Metro ES comparison |
| `tracts` | `data/prep/metro_tract_seg_2020_acs5yr_geo.rds` | ACS tracts |
| `outline` | `data/prep/gcps_outline.gpkg` | Reference overlay |
| `counties` | `data/prep/counties.gpkg` | Reference overlay |

Datasets with no varying numeric column render as reference layers (boundary
only, no choropleth, not scored) — exactly as before.

## Notes

- `data.js` is embedded (not `fetch`-ed), so real geometry works even when you
  open `index.html` from the filesystem (`file://`) — no server or CORS needed.
- Geometry is simplified for the browser; this is a design/QA tool, not a
  survey-grade renderer. The projection is an aspect-corrected equirectangular
  fit per layer, adequate at metro scale.
