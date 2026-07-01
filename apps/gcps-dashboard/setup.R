# =============================================================================
# setup.R -- one-time, run on YOUR machine from apps/gcps-dashboard/ to produce
# the renv.lock that Posit Connect Cloud restores from. (Cannot be generated in
# a no-R environment; run this locally once, then commit renv.lock.)
# =============================================================================

# 0. Make sure you're in the app directory:
#    setwd("apps/gcps-dashboard")

# 1. Isolated project library
install.packages("renv")
renv::init(bare = TRUE)

# 2. Install the rcds package from THIS GitHub repo's subdirectory.
#    (rcds is not on CRAN; it lives in rcds/ of rrichard-gcps/Geocomputation.)
renv::install("remotes")
remotes::install_github("rrichard-gcps/Geocomputation", subdir = "rcds")
#    Alternative with pak:
#    renv::install("pak"); pak::pak("rrichard-gcps/Geocomputation/rcds")

# 3. Install the app's direct dependencies (renv also discovers these from app.R)
renv::install(c("shiny", "bslib", "leaflet", "sf", "ggplot2",
                "htmltools", "htmlwidgets", "scales"))

# 4. Snapshot -> writes renv.lock (records rcds with its GitHub RemoteSubdir).
renv::snapshot(type = "all")

# 5. Sanity check locally:
#    shiny::runApp(".")

# 6. Commit renv.lock (and renv/activate.R, renv/settings.json) and push.
#    Then publish on Posit Connect Cloud -- see README.md.
