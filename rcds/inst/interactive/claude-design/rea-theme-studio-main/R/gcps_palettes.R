# =============================================================================
# R/gcps_palettes.R — GCPS Theme Studio add-only helpers
# -----------------------------------------------------------------------------
# This file is sourced by app.R AFTER the other R/ registries but BEFORE the
# inline gcps_ramps / gcps_base / gcps_diverging are defined later in app.R.
#
# IMPORTANT: gcps_ramps, gcps_base, gcps_diverging are defined INLINE in app.R
# (around lines 116–143). This file must NOT re-define them.
# FAMILY_NAMES is hard-coded (not derived from names(gcps_ramps)) because at
# source time gcps_ramps does not yet exist. build_gcps_theme() references
# gcps_ramps only inside its function body (lazy evaluation — safe).
# =============================================================================

# Hard-coded family names — must match names(gcps_ramps) defined later in app.R
FAMILY_NAMES <- c(
  "maroon",
  "blue",
  "teal",
  "green",
  "violet",
  "orange",
  "neutral",
  "gold",
  "plum",
  "slate",
  "emerald"
)

FAMILY_LABELS <- c(
  maroon = "District signature \u00B7 headers, primary emphasis",
  blue = "Sequential \u00B7 cool, neutral category",
  teal = "Sequential \u00B7 density & intensity",
  green = "Sequential \u00B7 growth, positive metrics",
  violet = "Sequential \u00B7 distinct categorical",
  orange = "Sequential \u00B7 attention, secondary emphasis",
  neutral = "Sequential \u00B7 neutral, supporting tones",
  gold = "Sequential \u00B7 warm highlight, award & recognition",
  plum = "Sequential \u00B7 deep contrast, adult literacy & workforce",
  slate = "Sequential \u00B7 steel-blue, operations & infrastructure",
  emerald = "Sequential \u00B7 deep green, sustainability & wellness"
)

STOPS <- c(100, 300, 500, 700, 900)

DEFAULT_GCPS_FAMILY <- "teal"

# build_gcps_theme(family)
# Builds a Power BI theme list using the 5-stop ramp from gcps_ramps[[family]].
# gcps_ramps is looked up at CALL TIME inside the function body — it will exist
# by the time the server function calls this.
build_gcps_theme <- function(family = DEFAULT_GCPS_FAMILY) {
  ramp <- gcps_ramps[[family]]
  base <- unname(gcps_base[[family]])
  others <- setdiff(names(gcps_base), family)

  list(
    name = paste0(
      "GCPS ",
      toupper(substring(family, 1, 1)),
      substring(family, 2)
    ),
    dataColors = c(ramp[2], ramp[4], ramp[5], ramp[1], ramp[3]),
    background = "#FFFFFF",
    foreground = "#1F2120",
    tableAccent = ramp[4],
    ## firstOther* are populated from the OTHER base colours
    firstOther = unname(gcps_base[[others[1]]]),
    secondOther = unname(gcps_base[[others[2]]]),
    thirdOther = unname(gcps_base[[others[3]]]),
    fourthOther = unname(gcps_base[[others[4]]]),
    fifthOther = unname(gcps_base[[others[5]]]),
    sixthOther = unname(gcps_base[[others[6]]]),
    minimum = "#F7F6F3",
    neutral = "#8B8680",
    text = list(
      primary = "#1F2120",
      secondary = "#6B6560"
    )
  )
}

# build_css_vars(family)
# Returns a length-1 character string: a CSS :root { … } block with
# --gcps-<family>-<stop> variables for the chosen family.
build_css_vars <- function(family = DEFAULT_GCPS_FAMILY) {
  ramp <- gcps_ramps[[family]]
  lines <- sprintf("  --gcps-%s-%d: %s;", family, STOPS, ramp)
  paste0(":root {\n", paste(lines, collapse = "\n"), "\n}")
}

# ── WCAG 2.x contrast helpers ──────────────────────────────────────────────
# Per-channel linearization then weighted sum (the CORRECT order).
# The old code linearized the weighted sum — wrong per WCAG 2.x spec.

relative_luminance <- function(hex) {
  rgb_v <- grDevices::col2rgb(hex)[, 1] / 255 # 0..1 per channel
  lin <- ifelse(rgb_v <= 0.03928, rgb_v / 12.92, ((rgb_v + 0.055) / 1.055)^2.4)
  0.2126 * lin[1] + 0.7152 * lin[2] + 0.0722 * lin[3]
}

contrast_ratio <- function(hex_a, hex_b) {
  la <- relative_luminance(hex_a)
  lb <- relative_luminance(hex_b)
  (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
}

# ── Export snippet builders ─────────────────────────────────────────────────

build_css_snippet <- function(family) {
  ramp <- gcps_ramps[[family]]
  lines <- sprintf("  --gcps-%s-%d: %s;", family, STOPS, ramp)
  base <- gcps_base[[family]]
  paste0(
    "/* GCPS ",
    toupper(substring(family, 1, 1)),
    substring(family, 2),
    " tokens */\n",
    ":root {\n",
    paste(lines, collapse = "\n"),
    "\n",
    sprintf("  --gcps-base: %s;", base),
    "\n",
    "}"
  )
}

build_bslib_snippet <- function(family) {
  ramp <- gcps_ramps[[family]]
  base <- gcps_base[[family]]
  paste0(
    'library(bslib)\n\n',
    sprintf(
      'theme <- bs_theme(\n  bootswatch = "yeti",\n  primary = "%s",\n',
      base
    ),
    sprintf('  bg = "#FFFFFF",\n  fg = "#1F2120"\n)\n\n'),
    sprintf('bs_add_variables(theme,\n  "gcps-base" = "%s",\n', base),
    paste(
      sprintf('  "gcps-%s-%d" = "%s"', family, STOPS, ramp),
      collapse = ",\n"
    ),
    '\n)'
  )
}

build_quarto_snippet <- function(family) {
  ramp <- gcps_ramps[[family]]
  base <- gcps_base[[family]]
  paste0(
    sprintf('brand:\n  color:\n    base: "%s"\n', base),
    sprintf('    %s-lightest: "%s"\n', family, ramp[1]),
    sprintf('    %s-light: "%s"\n', family, ramp[2]),
    sprintf('    %s-mid: "%s"\n', family, ramp[3]),
    sprintf('    %s-dark: "%s"\n', family, ramp[4]),
    sprintf('    %s-darkest: "%s"\n', family, ramp[5])
  )
}

build_ggplot_snippet <- function(family) {
  ramp <- gcps_ramps[[family]]
  base <- gcps_base[[family]]
  paste0(
    sprintf(
      '# ggplot2 scale using GCPS %s tokens\n',
      toupper(substring(family, 1, 1))
    ),
    sprintf('scale_fill_manual(values = c(\n'),
    paste(sprintf('  "%s-100" = "%s",', family, ramp[1]), collapse = "\n"),
    sprintf('\n  "%s-300" = "%s",', family, ramp[2]),
    sprintf('\n  "%s-500" = "%s",', family, ramp[3]),
    sprintf('\n  "%s-700" = "%s",', family, ramp[4]),
    sprintf('\n  "%s-900" = "%s"', family, ramp[5]),
    '\n))\n'
  )
}

# ── Navigation Kit data ─────────────────────────────────────────────────────

NAV_ICONS <- c(
  "chart-bar",
  "chart-line",
  "table",
  "gauge",
  "bullseye",
  "filter",
  "download",
  "gear",
  "circle-info",
  "users",
  "building",
  "graduation-cap",
  "book",
  "calendar",
  "clipboard"
)

NAV_PATTERNS <- list(
  sidebar_nav = list(
    name = "Sidebar Navigation",
    platforms = list(
      Shiny = 'nav_panel("Tab", uiOutput("tab_content"))',
      HTML = '<nav class="sidebar-nav">\n  <a href="#" class="active">Dashboard</a>\n  <a href="#">Reports</a>\n</nav>',
      Quarto = 'sidebar:\n  - id: dashboard\n    text: "Dashboard"\n  - id: reports\n    text: "Reports"',
      PowerBI = '// Use the Pages pane to create tabs'
    )
  ),
  breadcrumb = list(
    name = "Breadcrumb Trail",
    platforms = list(
      Shiny = 'tagList(\n  tags$nav("aria-label"="breadcrumb",\n    tags$ol(class="breadcrumb",\n      tags$li(class="breadcrumb-item", a("Home")),\n      tags$li(class="breadcrumb-item active", "Reports")\n    )\n  )\n)',
      HTML = '<nav aria-label="breadcrumb">\n  <ol class="breadcrumb">\n    <li class="breadcrumb-item"><a href="#">Home</a></li>\n    <li class="breadcrumb-item active">Reports</li>\n  </ol>\n</nav>',
      Quarto = '<!-- Quarto does not have native breadcrumbs -->\n<!-- Add via HTML partial or _metadata.yml -->',
      PowerBI = '// Breadcrumbs via page-level bookmarks\n// Create a bookmark for each state'
    )
  ),
  tab_bar = list(
    name = "Horizontal Tab Bar",
    platforms = list(
      Shiny = 'navset_tab(\n  nav_panel("Overview", ...),\n  nav_panel("Details", ...)\n)',
      HTML = '<ul class="nav nav-tabs">\n  <li class="nav-item"><a class="nav-link active">Overview</a></li>\n  <li class="nav-item"><a class="nav-link">Details</a></li>\n</ul>',
      Quarto = '# Quarto tabset\n\n:::: {.panel-tabset}\n## Overview\nContent here\n\n## Details\nContent here\n::::',
      PowerBI = '// Use report-level Pages as tabs\n// Each page = one tab'
    )
  )
)
