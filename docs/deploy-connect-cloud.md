# Publishing the rcds map tool on Posit Connect Cloud

[Posit Connect Cloud](https://connect.posit.cloud) deploys content **directly
from a GitHub repository** and restores R dependencies from an `renv.lock`. This
guide covers publishing the `apps/gcps-dashboard/` Shiny app; the same pattern
works for a Quarto site or R Markdown report.

## The one wrinkle: `rcds` isn't on CRAN

`rcds` lives in the `rcds/` subdirectory of this repo, so the deploy environment
must install it from GitHub. The fix is entirely in the lockfile: when you
install `rcds` from GitHub locally and `renv::snapshot()`, renv records it as a
GitHub package with `RemoteSubdir = rcds`, and Connect Cloud restores it the same
way. No vendoring, no manual steps at deploy time.

## Step by step

### 1. Generate the lockfile (once, locally)

From `apps/gcps-dashboard/`:

```r
renv::init(bare = TRUE)
remotes::install_github("rrichard-gcps/Geocomputation", subdir = "rcds")
renv::install(c("shiny","bslib","leaflet","sf","ggplot2","htmltools","htmlwidgets","scales"))
renv::snapshot(type = "all")
```

(`setup.R` in that folder runs exactly this.) Confirm the app runs:
`shiny::runApp(".")`.

### 2. Commit and push

Commit `app.R`, `renv.lock`, `renv/activate.R`, `renv/settings.json`. The
folder's `.gitignore` excludes `renv/library/`. Push to `main` (or your branch).
Keep the repo **public** so Connect Cloud can fetch `rcds` from GitHub (or grant
the GitHub connection access to a private repo).

### 3. Publish on Connect Cloud

1. Sign in at <https://connect.posit.cloud> **with GitHub**.
2. **Publish** → it detects **Shiny**.
3. Repository `rrichard-gcps/Geocomputation`, branch `main`, primary file
   `apps/gcps-dashboard/app.R`.
4. Connect Cloud reads `apps/gcps-dashboard/renv.lock`, builds, and serves.

## Checklist

- [ ] `renv.lock` sits next to `app.R` (Connect Cloud resolves it relative to the
      entrypoint).
- [ ] `renv.lock` records `rcds` with `RemoteType: github` and
      `RemoteSubdir: rcds` (open it and check).
- [ ] Repo public, or GitHub account with repo access connected.
- [ ] App runs locally via `shiny::runApp(".")`.
- [ ] Runtime does not fetch fonts server-side (`register_fonts = FALSE`) — done.

## R version & system libraries

- Connect Cloud picks an R version; pin one by adding `RVersion` to `renv.lock`
  (renv writes your local version automatically) or a `.R-version` file.
- `sf`/`leaflet` need GDAL/GEOS/PROJ — provided by the Connect Cloud build image;
  nothing to install.

## Alternatives

- **Quarto dashboard**: a `dashboard.qmd` using the same `rcds` calls deploys the
  same way; primary file is the `.qmd`, deps still from `renv.lock`.
- **`rsconnect` / manifest**: if you prefer `rsconnect::writeManifest()` +
  `manifest.json`, Connect Cloud also accepts a manifest; the `renv.lock` route is
  simpler for GitHub-based deploys.
- **Keeping `rcds` current**: after changing the package, re-run
  `renv::snapshot()` so the lockfile points at the new commit, then push.

## Redeploying

Push to the tracked branch and redeploy from the Connect Cloud content page
(enable auto-update on push if you want it hands-off).
