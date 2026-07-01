# GCPS Map Studio — rcds dashboard demo

A runnable Shiny dashboard that shows the imported GCPS identity end to end: a
`bslib` UI shell (one of the six GCPS shells), an interactive Leaflet choropleth,
and a static ggplot map — all sharing the GCPS tokens/palettes/themes from the
`rcds` package. Deployable to **Posit Connect Cloud** from GitHub.

Demo data is North Carolina SIDS (`sf::nc`) so it runs with no API keys. Swap
`nc` in `app.R` for your GCPS/GA `sf` layer to localise.

## Run locally

```r
# from apps/gcps-dashboard/
source("setup.R")        # one-time: builds the project library + renv.lock
shiny::runApp(".")
```

If you already have the packages, you can skip `setup.R` and just
`shiny::runApp(".")` after `remotes::install_github("rrichard-gcps/Geocomputation", subdir = "rcds")`.

## Publish to Posit Connect Cloud (from GitHub)

Connect Cloud deploys directly from a GitHub repo and restores R dependencies
from `renv.lock`. Steps:

1. **Generate the lockfile once** (locally): run `setup.R` (above). It creates
   `renv.lock` in this folder, recording `rcds` from this repo's `rcds/`
   subdirectory (GitHub remote) plus all app deps.
2. **Commit & push** `apps/gcps-dashboard/app.R`, `renv.lock`, and
   `renv/activate.R` + `renv/settings.json` (the `.gitignore` here already
   excludes the heavy `renv/library/`). Make sure the repo is **public** (or that
   you grant Connect Cloud access) so it can fetch `rcds` from GitHub.
3. Go to **<https://connect.posit.cloud>** and sign in **with GitHub**.
4. **Publish → Shiny** (Connect Cloud auto-detects the framework).
5. Select repository **`rrichard-gcps/Geocomputation`**, branch **`main`**, and
   primary file **`apps/gcps-dashboard/app.R`**.
6. Connect Cloud reads **`apps/gcps-dashboard/renv.lock`**, installs everything
   (including `rcds` from the GitHub subdir), and serves the app.

### Notes & gotchas

- **`renv.lock` must sit next to `app.R`** (it does here). Connect Cloud looks
  for the lockfile in the entrypoint's directory.
- **`rcds` install**: the lockfile records it as a GitHub package with
  `RemoteSubdir = rcds`. Connect Cloud needs the repo reachable — public repo is
  simplest. If you keep the repo private, connect the GitHub account that has
  access when prompted.
- **Fonts**: the app calls `theme_gcps_map(..., register_fonts = FALSE)` so it
  never tries to fetch Google fonts at runtime on the server (uses system/CSS
  fallbacks). The interactive map loads brand fonts via CSS `@import`, which the
  user's browser fetches — no server dependency.
- **System libraries**: `sf`/`leaflet` need GDAL/GEOS/PROJ. Connect Cloud's build
  image provides these; nothing to configure.
- **Updating the deployed app**: push to the branch; Connect Cloud can redeploy
  (enable "update on push" or click redeploy). If you change `rcds`, bump/re-run
  `renv::snapshot()` so the lockfile points at the new commit.

See `docs/deploy-connect-cloud.md` for the same steps with more context and
alternatives (Quarto, manifest-based `rsconnect`).
