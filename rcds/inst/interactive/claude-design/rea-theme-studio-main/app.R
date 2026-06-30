# Dashboard Layout Architect
# A Shiny app for designing Power BI and Quarto dashboard layouts

# Load required packages
suppressPackageStartupMessages({
  if (!requireNamespace("shiny", quietly = TRUE)) {
    install.packages("shiny")
  }
  if (!requireNamespace("bslib", quietly = TRUE)) {
    install.packages("bslib")
  }
  if (!requireNamespace("shinyjs", quietly = TRUE)) {
    install.packages("shinyjs")
  }
  if (!requireNamespace("colourpicker", quietly = TRUE)) {
    install.packages("colourpicker")
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    install.packages("jsonlite")
  }
  if (!requireNamespace("htmltools", quietly = TRUE)) {
    install.packages("htmltools")
  }
  if (!requireNamespace("stringr", quietly = TRUE)) {
    install.packages("stringr")
  }
  if (!requireNamespace("zip", quietly = TRUE)) {
    install.packages("zip")
  }

  library(shiny)
  library(bslib)
  library(shinyjs)
  library(colourpicker)
  library(jsonlite)
  library(htmltools)
  library(stringr)
  library(zip)
})

# Load K-12 Dashboard registries
source("R/theme_registry.R")
source("R/metric_registry.R")
source("R/demo_data_k12.R")
source("R/template_registry.R")
source("R/component_registry.R")
source("R/boe_preview.R")
source("R/gcps_palettes.R")
source("R/generate_templates.R")

# Default Configuration
DEFAULT_CONFIG <- list(
  canvas = list(width = 1600, height = 900),
  theme = list(
    bg_page = "#F8F9FA",
    bg_card = "#FFFFFF",
    border = "#E5E7EB",
    text_primary = "#1F2937",
    text_secondary = "#6B7280",
    accent = "#0097A7",
    radius = "8px",
    radius_lg = "12px"
  ),
  header = list(
    height = 80,
    padding = 20,
    logo_width = 180,
    logo_height = 50,
    nav_button_count = 4
  ),
  sidebar = list(
    width = 260,
    padding = 16,
    nav_item_count = 5
  ),
  content = list(
    kpi_height = 100,
    kpi_count = 4,
    kpi_gap = 20,
    grid_rows = 2,
    grid_cols = 2,
    grid_gap = 16,
    padding = 20,
    layout_type = "uniform",
    # By Row settings
    containers_per_row = "2, 2",
    row_proportions = NULL,
    col_widths_per_row = NULL,
    # By Column settings
    containers_per_col = "2, 2",
    col_widths = NULL,
    row_heights_per_col = NULL,
    # Freeform settings
    ff_rows = 3,
    ff_cols = 3,
    ff_row_heights = NULL,
    ff_col_widths = NULL,
    # KPI settings
    kpi_proportions = NULL
  ),
  typography = list(
    font_family_name = "Segoe UI",
    font_family = "'Segoe UI', system-ui, sans-serif",
    font_weight = "400",
    font_size_base = 14,
    font_size_heading = 18
  ),
  palette = list(
    base_name = "teal",
    base = "#007C91",
    ramp = c("#C7E2E7", "#8CC4CE", "#4CA3B2", "#007C91", "#006677")
  ),
  annotations = list(enabled = FALSE)
)

# Null-coalescing helper (R lacks one natively)
`%||%` <- function(a, b) {
  if (is.null(a) || (length(a) == 1 && is.na(a))) b else a
}

# GCPS Color System
gcps_base <- c(
  maroon = "#660000",
  blue = "#2F5FB3",
  teal = "#007C91",
  green = "#5E8C31",
  violet = "#6A4CC3",
  orange = "#D96A1D",
  neutral = "#7A828C",
  gold = "#C49A22",
  plum = "#7B2D8B",
  slate = "#4A6D8C",
  emerald = "#1A7D5A"
)

gcps_ramps <- list(
  maroon = c("#DDC7C7", "#BA8C8C", "#944C4C", "#660000", "#540000"),
  blue = c("#D1DCEE", "#A1B7DD", "#6D8FCA", "#2F5FB3", "#274E93"),
  teal = c("#C7E2E7", "#8CC4CE", "#4CA3B2", "#007C91", "#006677"),
  green = c("#DCE6D2", "#B7CBA2", "#8EAE6F", "#5E8C31", "#4D7328"),
  violet = c("#DED8F2", "#BCAEE4", "#9782D5", "#6A4CC3", "#573EA0"),
  orange = c("#F7DECD", "#EEBC99", "#E49761", "#D96A1D", "#B25718"),
  neutral = c("#F4F5F7", "#E3E6EA", "#B6BCC4", "#7A828C", "#4B525A"),
  gold = c("#F5EBC8", "#E3CC7E", "#C49A22", "#9A7A10", "#7A600D"),
  plum = c("#EDDCF1", "#C990D5", "#7B2D8B", "#5E1E6B", "#421450"),
  slate = c("#D5DEE6", "#A0B4C4", "#4A6D8C", "#355270", "#233850"),
  emerald = c("#C8E8DE", "#7DC4AB", "#1A7D5A", "#126347", "#0C4A35")
)

gcps_diverging <- list(
  maroon = c("#540000", "#944C4C", "#F3F4F6", "#4CA3B2", "#006677"),
  blue = c("#274E93", "#6D8FCA", "#F3F4F6", "#E49761", "#B25718"),
  teal = c("#006677", "#4CA3B2", "#F3F4F6", "#BA8C8C", "#540000"),
  green = c("#4D7328", "#8EAE6F", "#F3F4F6", "#BCAEE4", "#573EA0"),
  violet = c("#573EA0", "#9782D5", "#F3F4F6", "#8EAE6F", "#4D7328"),
  orange = c("#B25718", "#E49761", "#F3F4F6", "#6D8FCA", "#274E93"),
  gold = c("#7A600D", "#E3CC7E", "#F3F4F6", "#8CC4CE", "#006677"),
  plum = c("#421450", "#C990D5", "#F3F4F6", "#8EAE6F", "#4D7328"),
  slate = c("#233850", "#A0B4C4", "#F3F4F6", "#E49761", "#B25718"),
  emerald = c("#0C4A35", "#7DC4AB", "#F3F4F6", "#BA8C8C", "#540000")
)

font_families <- c(
  "Segoe UI" = "'Segoe UI', system-ui, sans-serif",
  "Arial" = "Arial, Helvetica, sans-serif",
  "Trebuchet MS" = "'Trebuchet MS', sans-serif",
  "Verdana" = "Verdana, Geneva, sans-serif",
  "Georgia" = "Georgia, serif",
  "Consolas" = "Consolas, 'Courier New', monospace"
)

font_weights <- c(
  "Light (300)" = "300",
  "Regular (400)" = "400",
  "Medium (500)" = "500",
  "Semi-Bold (600)" = "600",
  "Bold (700)" = "700"
)

# Helper Functions
get_text_color <- function(hex) {
  rgb <- grDevices::col2rgb(hex)
  luminance <- (0.299 * rgb[1, ] + 0.587 * rgb[2, ] + 0.114 * rgb[3, ]) / 255
  ifelse(luminance > 0.62, "#1F2328", "#FFFFFF")
}

generate_swatch_html <- function(colors, labels) {
  swatches <- mapply(
    function(col, lab) {
      fg <- get_text_color(col)
      sprintf(
        '<div style="flex:1;min-width:70px;background:%s;color:%s;border-radius:6px;padding:8px;text-align:center;box-shadow:inset 0 0 0 1px rgba(0,0,0,.1);"><div style="font-weight:600;font-size:10px;">%s</div><div style="font-family:monospace;font-size:9px;opacity:0.9;">%s</div></div>',
        col,
        fg,
        lab,
        col
      )
    },
    colors,
    labels,
    SIMPLIFY = FALSE,
    USE.NAMES = FALSE
  )
  sprintf(
    '<div style="display:flex;gap:6px;flex-wrap:wrap;margin:6px 0;">%s</div>',
    paste(swatches, collapse = "")
  )
}

parse_proportions <- function(prop_str, count) {
  if (is.null(prop_str) || prop_str == "") {
    return(NULL)
  }
  values <- as.numeric(strsplit(trimws(prop_str), "\\s*,\\s*")[[1]])
  values <- values[!is.na(values)]
  if (length(values) == 0) {
    return(NULL)
  }
  values <- (values / sum(values)) * 100
  if (length(values) < count) {
    remaining <- 100 - sum(values)
    values <- c(
      values,
      rep(remaining / (count - length(values)), count - length(values))
    )
  } else if (length(values) > count) {
    values <- (values[1:count] / sum(values[1:count])) * 100
  }
  values
}

calc_pixels <- function(total_px, gap_px, proportions, count) {
  if (is.null(proportions)) {
    return(rep((total_px - gap_px * (count - 1)) / count, count))
  }
  (total_px - gap_px * (count - 1)) * (proportions / 100)
}

parse_row_proportions <- function(prop_str, containers_per_row) {
  if (is.null(prop_str) || prop_str == "") {
    return(NULL)
  }
  row_strings <- strsplit(trimws(prop_str), ";")[[1]]
  lapply(seq_along(containers_per_row), function(i) {
    if (i <= length(row_strings)) {
      parse_proportions(row_strings[i], containers_per_row[i])
    } else {
      NULL
    }
  })
}

get_containers_per_row <- function(config) {
  if (config$content$layout_type == "uniform") {
    return(rep(config$content$grid_cols, config$content$grid_rows))
  } else if (config$content$layout_type == "byrow") {
    containers <- as.integer(strsplit(config$content$containers_per_row, ",")[[
      1
    ]])
    return(containers[!is.na(containers)])
  } else if (config$content$layout_type == "freeform") {
    return(rep(config$content$ff_cols, config$content$ff_rows))
  }
  # Fallback
  return(rep(config$content$grid_cols, config$content$grid_rows))
}

get_containers_per_col <- function(config) {
  if (config$content$layout_type == "bycol") {
    containers <- as.integer(strsplit(config$content$containers_per_col, ",")[[
      1
    ]])
    return(containers[!is.na(containers)])
  }
  return(NULL)
}

# CSS Generation
generate_css <- function(config) {
  main_height <- config$canvas$height - config$header$height
  main_width <- config$canvas$width - config$sidebar$width
  content_height <- main_height -
    config$content$kpi_height -
    config$content$kpi_gap -
    config$content$padding * 2

  sprintf(
    ":root{--bg-page:%s;--bg-card:%s;--border:%s;--text-primary:%s;--text-secondary:%s;--accent:%s;--radius:%s;--radius-lg:%s;--font-family:%s;--font-weight:%s;--font-size-base:%dpx;--font-size-heading:%dpx;--palette-base:%s;--palette-1:%s;--palette-2:%s;--palette-3:%s;--palette-4:%s;--palette-5:%s}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:var(--font-family);font-weight:var(--font-weight);font-size:var(--font-size-base);background:var(--bg-page);color:var(--text-primary)}
.dashboard-container{position:relative;width:%dpx;height:%dpx;background:var(--bg-page);overflow:hidden}
.header{position:absolute;top:0;left:0;width:%dpx;height:%dpx;background:var(--bg-card);border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;padding:0 %dpx;z-index:100}
.header-logo{width:%dpx;height:%dpx;background:linear-gradient(135deg,var(--accent),#00796B);border-radius:var(--radius);display:flex;align-items:center;justify-content:center;color:white;font-weight:600;font-size:14px}
.header-nav{display:flex;gap:12px}
.header-nav-btn{width:36px;height:36px;background:var(--bg-page);border:1px solid var(--border);border-radius:var(--radius);display:flex;align-items:center;justify-content:center;color:var(--text-secondary);font-size:12px}
.header-nav-btn.active{background:var(--accent);border-color:var(--accent);color:white}
.sidebar{position:absolute;top:%dpx;left:0;width:%dpx;height:%dpx;background:var(--bg-card);border-right:1px solid var(--border);padding:%dpx;overflow-y:auto}
.sidebar-section{margin-bottom:20px}
.sidebar-section-title{font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:12px}
.sidebar-nav-item{display:flex;align-items:center;gap:12px;padding:10px 12px;border-radius:var(--radius);color:var(--text-primary);font-size:14px;cursor:pointer;margin-bottom:4px}
.sidebar-nav-item:hover{background:var(--bg-page)}
.sidebar-nav-item.active{background:rgba(0,151,167,0.1);color:var(--accent);font-weight:500}
.sidebar-nav-icon{width:20px;height:20px;background:var(--bg-page);border-radius:4px;display:flex;align-items:center;justify-content:center;font-size:10px;color:var(--text-secondary)}
.sidebar-nav-item.active .sidebar-nav-icon{background:var(--accent);color:white}
.main-content{position:absolute;top:%dpx;left:%dpx;width:%dpx;height:%dpx;padding:%dpx;overflow:hidden}
.kpi-container{display:flex;gap:%dpx;margin-bottom:%dpx;height:%dpx}
.kpi-card{flex:1;background:var(--bg-card);border:1px solid var(--border);border-left:3px solid var(--palette-3);border-radius:var(--radius-lg);padding:16px;display:flex;flex-direction:column;justify-content:center;position:relative}
.kpi-swatches{position:absolute;bottom:8px;right:10px;display:flex;gap:3px;opacity:0.7}
.kpi-swatch{width:8px;height:8px;border-radius:2px}
.kpi-label{font-size:12px;color:var(--text-secondary);margin-bottom:4px}
.kpi-value{font-size:calc(var(--font-size-heading) * 1.5);font-weight:700;color:var(--text-primary)}
.kpi-change{font-size:12px;margin-top:4px}
.kpi-change.positive{color:#10B981}
.kpi-change.negative{color:#EF4444}
.content-grid{position:relative;height:%dpx}
.grid-card{background:var(--bg-card);border:1px solid var(--border);border-radius:var(--radius-lg);padding:16px;display:flex;flex-direction:column;position:absolute}
.grid-card-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}
.grid-card-title{font-size:var(--font-size-heading);font-weight:600;color:var(--text-primary)}
.grid-card-content{flex:1;background:var(--bg-page);border-radius:var(--radius);display:flex;align-items:center;justify-content:center;color:var(--text-secondary);font-size:12px}
.dimension-badge{position:absolute;background:rgba(0,121,107,0.9);color:white;font-size:9px;font-family:Consolas,monospace;padding:4px 8px;border-radius:4px;pointer-events:none;z-index:1000;white-space:nowrap;top:4px;right:4px}
.dimension-badge-small{position:absolute;top:2px;left:2px;background:rgba(0,0,0,0.6);color:white;font-size:8px;font-family:Consolas,monospace;padding:1px 3px;border-radius:2px}
.kpi-card,.grid-card,.header-logo,.sidebar-nav-item,.header-nav-btn{position:relative}",
    config$theme$bg_page,
    config$theme$bg_card,
    config$theme$border,
    config$theme$text_primary,
    config$theme$text_secondary,
    config$theme$accent,
    config$theme$radius,
    config$theme$radius_lg,
    config$typography$font_family,
    config$typography$font_weight,
    as.integer(config$typography$font_size_base),
    as.integer(config$typography$font_size_heading),
    config$palette$base,
    config$palette$ramp[1],
    config$palette$ramp[2],
    config$palette$ramp[3],
    config$palette$ramp[4],
    config$palette$ramp[5],
    config$canvas$width,
    config$canvas$height,
    config$canvas$width,
    config$header$height,
    config$header$padding,
    config$header$logo_width,
    config$header$logo_height,
    config$header$height,
    config$sidebar$width,
    main_height,
    config$sidebar$padding,
    config$header$height,
    config$sidebar$width,
    main_width,
    main_height,
    config$content$padding,
    config$content$kpi_gap,
    config$content$kpi_gap,
    config$content$kpi_height,
    content_height
  )
}

# HTML Builders
build_header_html <- function(config, mode) {
  badge <- ""
  if (mode == "annotated") {
    badge <- sprintf(
      '<span class="dimension-badge">%dx%d @ (0, 0)</span>',
      config$canvas$width,
      config$header$height
    )
  }
  logo_badge <- ""
  if (mode == "annotated") {
    logo_badge <- sprintf(
      '<span class="dimension-badge-small">%dx%d</span>',
      config$header$logo_width,
      config$header$logo_height
    )
  }

  nav_btns <- ""
  if (mode == "blank") {
    nav_btns <- paste(
      rep('<div class="header-nav-btn"></div>', config$header$nav_button_count),
      collapse = ""
    )
  } else if (mode == "annotated") {
    nav_btns <- paste(
      rep(
        '<div class="header-nav-btn"><span class="dimension-badge-small">36x36</span></div>',
        config$header$nav_button_count
      ),
      collapse = ""
    )
  } else {
    nav_btns <- paste(
      rep('<div class="header-nav-btn"></div>', config$header$nav_button_count),
      collapse = ""
    )
  }

  logo_content <- "LOGO"
  if (mode == "blank") {
    logo_content <- ""
  }

  sprintf(
    '<div class="header">%s<div class="header-logo">%s%s</div><div class="header-nav">%s</div></div>',
    badge,
    logo_badge,
    logo_content,
    nav_btns
  )
}

build_sidebar_html <- function(config, mode) {
  main_height <- config$canvas$height - config$header$height
  badge <- ""
  if (mode == "annotated") {
    badge <- sprintf(
      '<span class="dimension-badge">%dx%d @ (0, %d)</span>',
      config$sidebar$width,
      main_height,
      config$header$height
    )
  }

  nav_items <- ""
  if (mode == "blank") {
    nav_items <- paste(
      rep(
        '<div class="sidebar-nav-item"><div class="sidebar-nav-icon"></div><span></span></div>',
        config$sidebar$nav_item_count
      ),
      collapse = ""
    )
  } else {
    nav_items <- paste(
      sapply(1:config$sidebar$nav_item_count, function(i) {
        sprintf(
          '<div class="sidebar-nav-item%s"><div class="sidebar-nav-icon">%d</div><span>Navigation Item</span></div>',
          ifelse(i == 1, " active", ""),
          i
        )
      }),
      collapse = ""
    )
  }

  sprintf(
    '<div class="sidebar">%s<div class="sidebar-section"><div class="sidebar-section-title">Navigation</div>%s</div></div>',
    badge,
    nav_items
  )
}

build_kpi_html <- function(config, mode) {
  main_width <- config$canvas$width - config$sidebar$width
  total_available <- main_width - config$content$padding * 2
  kpi_props <- parse_proportions(
    config$content$kpi_proportions,
    config$content$kpi_count
  )
  kpi_widths <- calc_pixels(
    total_available,
    config$content$kpi_gap,
    kpi_props,
    config$content$kpi_count
  )

  paste(
    sapply(1:config$content$kpi_count, function(i) {
      w <- kpi_widths[i]
      badge <- ""
      if (mode == "annotated") {
        x_pos <- config$sidebar$width +
          config$content$padding +
          sum(kpi_widths[1:i - 1]) +
          config$content$kpi_gap * (i - 1)
        badge <- sprintf(
          '<span class="dimension-badge">%.0fx%d @ (%.0f, %d)</span>',
          w,
          config$content$kpi_height,
          x_pos,
          config$header$height + config$content$padding
        )
      }

      if (mode == "blank") {
        sprintf(
          '<div class="kpi-card" style="flex:none;width:%.0fpx;">%s</div>',
          w,
          badge
        )
      } else {
        # Deterministic placeholder values — stable across re-renders
        det_value <- 1000L + (i * 1373L) %% 9000L
        det_change <- 1 + ((i * 7L) %% 14L) + ((i * 3L) %% 10L) / 10
        sprintf(
          '<div class="kpi-card" style="flex:none;width:%.0fpx;">%s<div class="kpi-label">KPI Metric %d</div><div class="kpi-value">%d</div><div class="kpi-change positive">+%.1f%%</div><div class="kpi-swatches"><span class="kpi-swatch" style="background:var(--palette-1)"></span><span class="kpi-swatch" style="background:var(--palette-2)"></span><span class="kpi-swatch" style="background:var(--palette-3)"></span><span class="kpi-swatch" style="background:var(--palette-4)"></span><span class="kpi-swatch" style="background:var(--palette-5)"></span></div></div>',
          w,
          badge,
          i,
          det_value,
          det_change
        )
      }
    }),
    collapse = ""
  )
}

build_grid_html <- function(config, mode) {
  layout_type <- config$content$layout_type

  if (layout_type == "bycol") {
    return(build_grid_html_bycol(config, mode))
  }

  # For uniform, byrow, and freeform - render row by row
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height -
    config$content$kpi_height -
    config$content$kpi_gap -
    config$content$padding * 2

  containers_per_row <- get_containers_per_row(config)
  num_rows <- length(containers_per_row)

  # Get row proportions based on layout type
  if (layout_type == "freeform") {
    row_props <- parse_proportions(config$content$ff_row_heights, num_rows)
  } else if (layout_type == "byrow") {
    row_props <- parse_proportions(config$content$row_proportions, num_rows)
  } else {
    row_props <- NULL
  }
  row_heights <- calc_pixels(
    content_height,
    config$content$grid_gap,
    row_props,
    num_rows
  )

  # Get column proportions based on layout type
  if (layout_type == "freeform") {
    # Freeform: same column widths for all rows
    num_cols <- ifelse(
      !is.null(config$content$ff_cols),
      config$content$ff_cols,
      containers_per_row[1]
    )
    col_props <- parse_proportions(config$content$ff_col_widths, num_cols)
    col_props_list <- replicate(num_rows, col_props, simplify = FALSE)
  } else if (layout_type == "byrow") {
    col_props_list <- parse_row_proportions(
      config$content$col_widths_per_row,
      containers_per_row
    )
  } else {
    col_props_list <- replicate(num_rows, NULL, simplify = FALSE)
  }

  cards <- ""
  cell_idx <- 1
  y_off <- 0

  for (row in 1:num_rows) {
    cols <- containers_per_row[row]
    rh <- row_heights[row]
    col_w <- calc_pixels(
      main_width - config$content$padding * 2,
      config$content$grid_gap,
      col_props_list[[row]],
      cols
    )
    x_off <- 0

    for (col in 1:cols) {
      cw <- col_w[col]
      abs_x <- config$sidebar$width + config$content$padding + x_off
      abs_y <- config$header$height +
        config$content$padding +
        config$content$kpi_height +
        config$content$kpi_gap +
        y_off

      badge <- ""
      if (mode == "annotated") {
        badge <- sprintf(
          '<span class="dimension-badge">%.0fx%.0f @ (%.0f, %.0f)</span>',
          cw,
          rh,
          abs_x,
          abs_y
        )
      }

      if (mode == "blank") {
        cards <- paste0(
          cards,
          sprintf(
            '<div class="grid-card" style="position:absolute;left:%.0fpx;top:%.0fpx;width:%.0fpx;height:%.0fpx;">%s<div class="grid-card-content"></div></div>',
            x_off,
            y_off,
            cw,
            rh,
            badge
          )
        )
      } else {
        cards <- paste0(
          cards,
          sprintf(
            '<div class="grid-card" style="position:absolute;left:%.0fpx;top:%.0fpx;width:%.0fpx;height:%.0fpx;">%s<div class="grid-card-header"><span class="grid-card-title">Chart %d</span></div><div class="grid-card-content">Visual Placeholder</div></div>',
            x_off,
            y_off,
            cw,
            rh,
            badge,
            cell_idx
          )
        )
      }
      cell_idx <- cell_idx + 1
      x_off <- x_off + cw + config$content$grid_gap
    }
    y_off <- y_off + rh + config$content$grid_gap
  }
  cards
}

build_grid_html_bycol <- function(config, mode) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height -
    config$content$kpi_height -
    config$content$kpi_gap -
    config$content$padding * 2

  containers_per_col <- get_containers_per_col(config)
  num_cols <- length(containers_per_col)

  # Column widths from user input
  col_props <- parse_proportions(config$content$col_widths, num_cols)
  col_widths <- calc_pixels(
    main_width - config$content$padding * 2,
    config$content$grid_gap,
    col_props,
    num_cols
  )

  # Row heights per column from user input
  row_props_per_col <- parse_row_proportions(
    config$content$row_heights_per_col,
    containers_per_col
  )

  cards <- ""
  cell_idx <- 1
  x_off <- 0

  for (col in 1:num_cols) {
    rows <- containers_per_col[col]
    cw <- col_widths[col]

    # Row heights within this column (custom or equal distribution)
    row_heights <- calc_pixels(
      content_height,
      config$content$grid_gap,
      row_props_per_col[[col]],
      rows
    )
    y_off <- 0

    for (row in 1:rows) {
      rh <- row_heights[row]
      abs_x <- config$sidebar$width + config$content$padding + x_off
      abs_y <- config$header$height +
        config$content$padding +
        config$content$kpi_height +
        config$content$kpi_gap +
        y_off

      badge <- ""
      if (mode == "annotated") {
        badge <- sprintf(
          '<span class="dimension-badge">%.0fx%.0f @ (%.0f, %.0f)</span>',
          cw,
          rh,
          abs_x,
          abs_y
        )
      }

      if (mode == "blank") {
        cards <- paste0(
          cards,
          sprintf(
            '<div class="grid-card" style="position:absolute;left:%.0fpx;top:%.0fpx;width:%.0fpx;height:%.0fpx;">%s<div class="grid-card-content"></div></div>',
            x_off,
            y_off,
            cw,
            rh,
            badge
          )
        )
      } else {
        cards <- paste0(
          cards,
          sprintf(
            '<div class="grid-card" style="position:absolute;left:%.0fpx;top:%.0fpx;width:%.0fpx;height:%.0fpx;">%s<div class="grid-card-header"><span class="grid-card-title">Chart %d</span></div><div class="grid-card-content">Visual Placeholder</div></div>',
            x_off,
            y_off,
            cw,
            rh,
            badge,
            cell_idx
          )
        )
      }
      cell_idx <- cell_idx + 1
      y_off <- y_off + rh + config$content$grid_gap
    }
    x_off <- x_off + cw + config$content$grid_gap
  }
  cards
}

build_content_html <- function(config, mode) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  badge <- ""
  if (mode == "annotated") {
    badge <- sprintf(
      '<span class="dimension-badge">%dx%d @ (%d, %d)</span>',
      main_width,
      main_height,
      config$sidebar$width,
      config$header$height
    )
  }
  sprintf(
    '<div class="main-content">%s<div class="kpi-container">%s</div><div class="content-grid">%s</div></div>',
    badge,
    build_kpi_html(config, mode),
    build_grid_html(config, mode)
  )
}

generate_html <- function(config, include_css, view_mode) {
  css <- ""
  if (include_css) {
    css <- sprintf("<style>%s</style>", generate_css(config))
  }
  sprintf(
    '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Dashboard Layout</title>%s</head><body><div class="dashboard-container">%s%s%s</div></body></html>',
    css,
    build_header_html(config, view_mode),
    build_sidebar_html(config, view_mode),
    build_content_html(config, view_mode)
  )
}

generate_shiny_code <- function(config) {
  # ── Internal helpers ──────────────────────────────────────────────────

  # Convert percentage proportions to a 12-column Bootstrap grid
  props_to_12grid <- function(proportions, count) {
    if (is.null(proportions)) {
      base <- 12 %/% count
      remainder <- 12 - base * count
      widths <- rep(base, count)
      if (remainder > 0) {
        widths[1:remainder] <- widths[1:remainder] + 1
      }
      return(widths)
    }
    widths <- round(proportions / 100 * 12)
    widths <- pmax(widths, 1)
    diff <- 12 - sum(widths)
    if (diff != 0) {
      idx <- if (diff > 0) which.max(widths) else which.min(widths)
      widths[idx] <- widths[idx] + diff
    }
    widths
  }

  # Generate a single card placeholder (no trailing comma)
  card_code <- function(idx, indent = 4) {
    pad <- paste(rep(" ", indent), collapse = "")
    paste0(
      pad,
      sprintf(
        "card(card_header('Chart %d'), card_body(plotOutput('plot_%d')))",
        idx,
        idx
      )
    )
  }

  # Generate a single value_box placeholder (no trailing comma)
  vbox_code <- function(idx, indent = 4) {
    pad <- paste(rep(" ", indent), collapse = "")
    has_bsicons <- requireNamespace("bsicons", quietly = TRUE)
    showcase_part <- if (has_bsicons) {
      "showcase = bsicons::bs_icon('graph-up')"
    } else {
      "showcase = NULL"
    }
    paste0(
      pad,
      sprintf(
        "value_box(title = 'KPI %d', value = '...', %s)",
        idx,
        showcase_part
      )
    )
  }

  # ── Layout type ───────────────────────────────────────────────────────
  layout_type <- config$content$layout_type

  # ── Theme code ────────────────────────────────────────────────────────
  radius_val <- gsub("px$", "", config$theme$radius)
  theme_lines <- c(
    "theme <- bs_theme(",
    sprintf("  bg      = '%s',", config$theme$bg_page),
    sprintf("  fg      = '%s',", config$theme$text_primary),
    sprintf("  primary = '%s'", config$theme$accent),
    ") |> bs_add_variables(",
    sprintf("  'card-bg'      = '%s',", config$theme$bg_card),
    sprintf("  'border-color' = '%s',", config$theme$border),
    sprintf("  'border-radius' = '%spx'", radius_val),
    ")"
  )

  # ── Title / header code ───────────────────────────────────────────────
  lw <- config$header$logo_width
  lh <- config$header$logo_height
  title_lines <- c(
    "  title = div(",
    "    img(src = 'logo.png', height = '40px', alt = 'Logo',",
    sprintf(
      "        style = 'margin-right:12px; display:%s;'),",
      ifelse(lw > 0, "inline-block", "none")
    ),
    "    'My Dashboard'",
    "  ),"
  )

  # ── Sidebar code ──────────────────────────────────────────────────────
  nav_count <- config$sidebar$nav_item_count
  nav_lines <- vapply(
    seq_len(nav_count),
    function(i) {
      sprintf("    nav_item(actionLink('nav_%d', 'Menu Item %d')),", i, i)
    },
    character(1)
  )
  sidebar_lines <- c(
    "  sidebar = sidebar(",
    sprintf("    width = %d,", config$sidebar$width),
    "    h4('Navigation'),",
    nav_lines,
    "  ),"
  )

  # ── KPI row code ──────────────────────────────────────────────────────
  kpi_count <- config$content$kpi_count
  kpi_lines <- NULL
  if (kpi_count > 0) {
    kpi_props <- parse_proportions(config$content$kpi_proportions, kpi_count)
    kpi_cw <- props_to_12grid(kpi_props, kpi_count)
    vbox_items <- vapply(
      seq_len(kpi_count),
      function(i) {
        vbox_code(i, indent = 4)
      },
      character(1)
    )
    kpi_lines <- c(
      "  # KPI Row",
      "  layout_columns(",
      sprintf("    fill = FALSE,"),
      sprintf("    col_widths = c(%s),", paste(kpi_cw, collapse = ", ")),
      paste(vbox_items, collapse = ",\n"),
      "  ),"
    )
  }

  # ── Main grid code ────────────────────────────────────────────────────
  cell_idx <- 1
  grid_lines <- NULL

  if (layout_type == "uniform") {
    cols <- config$content$grid_cols
    rows <- config$content$grid_rows
    cw <- props_to_12grid(NULL, cols)
    n_cards <- rows * cols
    card_items <- vapply(
      seq_len(n_cards),
      function(i) {
        card_code(i, indent = 4)
      },
      character(1)
    )
    grid_lines <- c(
      "  # Main Grid (Uniform)",
      "  layout_columns(",
      sprintf("    col_widths = c(%s),", paste(cw, collapse = ", ")),
      "    fill = TRUE,",
      paste(card_items, collapse = ",\n"),
      "  )"
    )
    cell_idx <- n_cards + 1
  } else if (layout_type == "byrow") {
    containers_per_row <- get_containers_per_row(config)
    num_rows <- length(containers_per_row)
    col_props_list <- parse_row_proportions(
      config$content$col_widths_per_row,
      containers_per_row
    )
    row_block_list <- list()
    for (r in seq_len(num_rows)) {
      n <- containers_per_row[r]
      cw <- props_to_12grid(col_props_list[[r]], n)
      cards <- vapply(
        seq_len(n),
        function(j) {
          idx <- cell_idx
          cell_idx <<- cell_idx + 1
          card_code(idx, indent = 4)
        },
        character(1)
      )
      block <- c(
        sprintf("  # Row %d", r),
        "  layout_columns(",
        sprintf("    col_widths = c(%s),", paste(cw, collapse = ", ")),
        "    fill = TRUE,",
        paste(cards, collapse = ",\n"),
        sprintf("  )%s", ifelse(r < num_rows, ",", ""))
      )
      row_block_list[[r]] <- block
    }
    # Flatten
    for (r in seq_along(row_block_list)) {
      if (r == 1) {
        grid_lines <- c("  # Main Grid (By Row)", row_block_list[[r]])
      } else {
        grid_lines <- c(grid_lines, "", row_block_list[[r]])
      }
    }
  } else if (layout_type == "bycol") {
    containers_per_col <- get_containers_per_col(config)
    num_cols <- length(containers_per_col)
    col_props <- parse_proportions(config$content$col_widths, num_cols)
    outer_cw <- props_to_12grid(col_props, num_cols)
    row_props_per_col <- parse_row_proportions(
      config$content$row_heights_per_col,
      containers_per_col
    )
    col_blocks <- character(num_cols)
    for (cl in seq_len(num_cols)) {
      n_rows <- containers_per_col[cl]
      cards <- vapply(
        seq_len(n_rows),
        function(j) {
          idx <- cell_idx
          cell_idx <<- cell_idx + 1
          sprintf(
            "        card(card_header('Chart %d'), card_body(plotOutput('plot_%d')))",
            idx,
            idx
          )
        },
        character(1)
      )
      col_blocks[cl] <- paste0(
        sprintf(
          "    div(style = 'display:flex; flex-direction:column; gap:1rem;',\n"
        ),
        paste(cards, collapse = ",\n"),
        "\n    ),"
      )
    }
    grid_lines <- c(
      "  # Main Grid (By Column)",
      "  layout_columns(",
      sprintf("    col_widths = c(%s),", paste(outer_cw, collapse = ", ")),
      col_blocks,
      "  )"
    )
  } else if (layout_type == "freeform") {
    ff_rows <- config$content$ff_rows
    ff_cols <- config$content$ff_cols
    col_props <- parse_proportions(config$content$ff_col_widths, ff_cols)
    cw <- props_to_12grid(col_props, ff_cols)
    n_cards <- ff_rows * ff_cols
    card_items <- vapply(
      seq_len(n_cards),
      function(i) {
        card_code(i, indent = 4)
      },
      character(1)
    )
    grid_lines <- c(
      "  # Main Grid (Freeform)",
      "  layout_columns(",
      sprintf("    col_widths = c(%s),", paste(cw, collapse = ", ")),
      "    fill = TRUE,",
      paste(card_items, collapse = ",\n"),
      "  )"
    )
    cell_idx <- n_cards + 1
  } else {
    # Fallback
    cols <- config$content$grid_cols
    rows <- config$content$grid_rows
    cw <- props_to_12grid(NULL, cols)
    n_cards <- rows * cols
    card_items <- vapply(
      seq_len(n_cards),
      function(i) {
        card_code(i, indent = 4)
      },
      character(1)
    )
    grid_lines <- c(
      "  # Main Grid",
      "  layout_columns(",
      sprintf("    col_widths = c(%s),", paste(cw, collapse = ", ")),
      "    fill = TRUE,",
      paste(card_items, collapse = ",\n"),
      "  )"
    )
    cell_idx <- n_cards + 1
  }

  # ── Server code ───────────────────────────────────────────────────────
  total_cards <- cell_idx - 1
  server_card_lines <- vapply(
    seq_len(total_cards),
    function(i) {
      sprintf(
        "  output$plot_%d <- renderPlot({ plot(cars, main = 'Chart %d') })",
        i,
        i
      )
    },
    character(1)
  )

  server_lines <- c(
    "server <- function(input, output, session) {",
    server_card_lines,
    "}"
  )

  # ── Assemble final code ───────────────────────────────────────────────
  code <- c(
    "# Generated by Dashboard Layout Architect",
    "# Copy-paste into a new app.R file and run",
    "",
    "library(shiny)",
    "library(bslib)",
    "library(bsicons)",
    "",
    "# ── Theme ──────────────────────────────────────────────────────────",
    theme_lines,
    "",
    "# ── UI ─────────────────────────────────────────────────────────────",
    "ui <- page_sidebar(",
    title_lines,
    "  theme = theme,",
    sidebar_lines,
    ""
  )

  if (!is.null(kpi_lines)) {
    code <- c(code, kpi_lines, "")
  }

  code <- c(code, grid_lines, ")")

  code <- c(
    code,
    "",
    "# ── Server ────────────────────────────────────────────────",
    server_lines,
    "",
    "shinyApp(ui, server)"
  )

  paste(code, collapse = "\n")
}

# ── generate_quarto_dashboard ─────────────────────────────────────────────────
generate_quarto_dashboard <- function(config) {
  kpi_count <- config$content$kpi_count
  grid_rows  <- config$content$grid_rows
  grid_cols  <- config$content$grid_cols
  accent     <- config$theme$accent
  bg_page    <- config$theme$bg_page
  bg_card    <- config$theme$bg_card
  border     <- config$theme$border
  txt        <- config$theme$text_primary
  font_stack <- config$typography$font_family
  font_size  <- config$typography$font_size_base
  ramp       <- config$palette$ramp

  yaml_block <- paste(c(
    "---",
    "title: \"GCPS Dashboard\"",
    "format:",
    "  dashboard:",
    "    theme: [cosmo, theme.scss]",
    "    nav-buttons: []",
    "    expandable: true",
    "execute:",
    "  echo: false",
    "  warning: false",
    "---",
    ""
  ), collapse = "\n")

  setup_chunk <- paste(c(
    "```{r setup}",
    "#| label: setup",
    "#| include: false",
    "library(bslib)",
    "library(ggplot2)",
    "```",
    ""
  ), collapse = "\n")

  vbox_section <- ""
  if (kpi_count > 0) {
    vboxes <- vapply(seq_len(kpi_count), function(i) {
      col <- if (i <= length(ramp)) ramp[i] else accent
      paste0(
        "::: {.valuebox icon=\"graph-up\" color=\"", col, "\"}\n",
        "KPI ", i, "\n\n`—`\n:::"
      )
    }, character(1))
    vbox_section <- paste(c(
      "## Row {height=\"20%\"}",
      "",
      paste(vboxes, collapse = "\n\n"),
      ""
    ), collapse = "\n")
  }

  chart_lines <- character(0)
  cell_idx <- 1
  for (r in seq_len(grid_rows)) {
    chart_lines <- c(chart_lines, "## Row", "")
    for (cc in seq_len(grid_cols)) {
      chart_lines <- c(
        chart_lines,
        paste0("### Chart ", cell_idx),
        "",
        "```{r}",
        paste0("#| title: \"Chart ", cell_idx, "\""),
        paste0("ggplot(cars, aes(speed, dist)) +"),
        paste0("  geom_point(colour = \"", accent, "\") +"),
        paste0("  theme_minimal(base_size = ", font_size, ")"),
        "```",
        ""
      )
      cell_idx <- cell_idx + 1
    }
  }

  scss_note <- paste(c(
    "<!-- theme.scss ---------------------------------------------------",
    "/*-- scss:defaults --*/",
    paste0("$primary:                 ", accent, ";"),
    paste0("$body-bg:                 ", bg_page, ";"),
    paste0("$card-bg:                 ", bg_card, ";"),
    paste0("$border-color:            ", border, ";"),
    paste0("$body-color:              ", txt, ";"),
    paste0("$font-family-sans-serif:  ", font_stack, ";"),
    "/*-- scss:rules --*/",
    ".card { border-radius: 10px; }",
    "--------------------------------------------------------------- -->"
  ), collapse = "\n")

  paste(c(yaml_block, setup_chunk, vbox_section, chart_lines, scss_note), collapse = "\n")
}

# ── generate_quarto_html ──────────────────────────────────────────────────────
generate_quarto_html <- function(config) {
  kpi_count <- config$content$kpi_count
  grid_rows  <- config$content$grid_rows
  grid_cols  <- config$content$grid_cols
  accent     <- config$theme$accent
  bg_page    <- config$theme$bg_page
  bg_card    <- config$theme$bg_card
  border     <- config$theme$border
  txt        <- config$theme$text_primary
  font_stack <- config$typography$font_family
  font_size  <- config$typography$font_size_base
  ramp       <- config$palette$ramp

  yaml_block <- paste(c(
    "---",
    "title: \"GCPS Report\"",
    "format:",
    "  html:",
    "    theme: [cosmo, theme.scss]",
    "    page-layout: full",
    "    toc: true",
    "execute:",
    "  echo: false",
    "  warning: false",
    "---",
    ""
  ), collapse = "\n")

  setup_chunk <- paste(c(
    "```{r setup}",
    "#| label: setup",
    "#| include: false",
    "library(bslib)",
    "library(ggplot2)",
    "```",
    ""
  ), collapse = "\n")

  kpi_section <- ""
  if (kpi_count > 0) {
    col_w <- max(1L, 12L %/% kpi_count)
    vbox_args <- paste(
      vapply(seq_len(kpi_count), function(i) {
        col <- if (i <= length(ramp)) ramp[i] else accent
        paste0(
          "  value_box(\n",
          "    title = \"KPI ", i, "\",\n",
          "    value = \"—\",\n",
          "    showcase = bsicons::bs_icon(\"graph-up\"),\n",
          "    theme = value_box_theme(bg = \"", col, "\")\n",
          "  )"
        )
      }, character(1)),
      collapse = ",\n"
    )
    kpi_section <- paste(c(
      "```{r kpi-row}",
      "#| label: kpi-row",
      "layout_columns(",
      paste0("  col_widths = rep(", col_w, "L, ", kpi_count, "L),"),
      vbox_args,
      ")",
      "```",
      ""
    ), collapse = "\n")
  }

  chart_lines <- character(0)
  cell_idx <- 1
  col_w_chart <- max(1L, 12L %/% grid_cols)
  for (r in seq_len(grid_rows)) {
    row_cards <- paste(
      vapply(seq_len(grid_cols), function(cc) {
        idx <- cell_idx + cc - 1L
        paste0(
          "  card(\n",
          "    card_header(\"Chart ", idx, "\"),\n",
          "    card_body(\n",
          "      ggplot(cars, aes(speed, dist)) +\n",
          "        geom_point(colour = \"", accent, "\") +\n",
          "        theme_minimal(base_size = ", font_size, ")\n",
          "    )\n",
          "  )"
        )
      }, character(1)),
      collapse = ",\n"
    )
    chart_lines <- c(
      chart_lines,
      paste0("```{r chart-row-", r, "}"),
      paste0("#| label: chart-row-", r),
      "layout_columns(",
      paste0("  col_widths = rep(", col_w_chart, "L, ", grid_cols, "L),"),
      row_cards,
      ")",
      "```",
      ""
    )
    cell_idx <- cell_idx + grid_cols
  }

  scss_note <- paste(c(
    "<!-- theme.scss ---------------------------------------------------",
    "/*-- scss:defaults --*/",
    paste0("$primary:                 ", accent, ";"),
    paste0("$body-bg:                 ", bg_page, ";"),
    paste0("$card-bg:                 ", bg_card, ";"),
    paste0("$border-color:            ", border, ";"),
    paste0("$body-color:              ", txt, ";"),
    paste0("$font-family-sans-serif:  ", font_stack, ";"),
    "/*-- scss:rules --*/",
    ".card { border-radius: 10px; }",
    "--------------------------------------------------------------- -->"
  ), collapse = "\n")

  paste(c(yaml_block, setup_chunk, kpi_section, chart_lines, scss_note), collapse = "\n")
}

# ── generate_flexdashboard ────────────────────────────────────────────────────
generate_flexdashboard <- function(config) {
  kpi_count <- config$content$kpi_count
  grid_rows  <- config$content$grid_rows
  grid_cols  <- config$content$grid_cols
  accent     <- config$theme$accent
  bg_page    <- config$theme$bg_page
  txt        <- config$theme$text_primary
  font_name  <- config$typography$font_family_name
  font_size  <- config$typography$font_size_base
  ramp       <- config$palette$ramp

  yaml_block <- paste(c(
    "---",
    "title: \"GCPS Dashboard\"",
    "output:",
    "  flexdashboard::flex_dashboard:",
    "    orientation: rows",
    "    vertical_layout: fill",
    "    theme:",
    paste0("      bg: \"", bg_page, "\""),
    paste0("      fg: \"", txt, "\""),
    paste0("      primary: \"", accent, "\""),
    paste0("      base_font: !expr bslib::font_google(\"", font_name, "\")"),
    "---",
    ""
  ), collapse = "\n")

  setup_chunk <- paste(c(
    "```{r setup, include=FALSE}",
    "library(flexdashboard)",
    "library(ggplot2)",
    "library(bslib)",
    "```",
    ""
  ), collapse = "\n")

  kpi_section <- ""
  if (kpi_count > 0) {
    kpi_boxes <- vapply(seq_len(kpi_count), function(i) {
      col <- if (i <= length(ramp)) ramp[i] else accent
      paste(c(
        paste0("### KPI ", i),
        "",
        "```{r}",
        paste0("valueBox(\"—\", caption = \"KPI ", i, "\","),
        paste0("  icon = \"fa-chart-line\", color = \"", col, "\")"),
        "```"
      ), collapse = "\n")
    }, character(1))
    kpi_section <- paste(c(
      "## Row {data-height=150}",
      "",
      paste(kpi_boxes, collapse = "\n\n"),
      ""
    ), collapse = "\n")
  }

  chart_lines <- character(0)
  col_w <- max(200L, 600L %/% max(1L, grid_cols))
  cell_idx <- 1
  for (cc in seq_len(grid_cols)) {
    chart_lines <- c(
      chart_lines,
      paste0("## Column {data-width=", col_w, "}"),
      ""
    )
    for (r in seq_len(grid_rows)) {
      chart_lines <- c(
        chart_lines,
        paste0("### Chart ", cell_idx),
        "",
        "```{r}",
        "ggplot(cars, aes(speed, dist)) +",
        paste0("  geom_point(colour = \"", accent, "\") +"),
        paste0("  theme_minimal(base_size = ", font_size, ")"),
        "```",
        ""
      )
      cell_idx <- cell_idx + 1
    }
  }

  paste(c(yaml_block, setup_chunk, kpi_section, chart_lines), collapse = "\n")
}

generate_dax <- function(config) {
  paste(
    c(
      "// ============================================",
      "// Dashboard Layout DAX Measures",
      "// ============================================",
      "",
      "// Canvas Dimensions",
      sprintf("Canvas_Width = %d", config$canvas$width),
      sprintf("Canvas_Height = %d", config$canvas$height),
      "",
      "// Header Settings",
      sprintf("Header_Height = %d", config$header$height),
      sprintf("Header_Padding = %d", config$header$padding),
      sprintf("Logo_Width = %d", config$header$logo_width),
      sprintf("Logo_Height = %d", config$header$logo_height),
      "",
      "// Sidebar Settings",
      sprintf("Sidebar_Width = %d", config$sidebar$width),
      sprintf("Sidebar_Padding = %d", config$sidebar$padding),
      "",
      "// KPI Card Settings",
      sprintf("KPI_Height = %d", config$content$kpi_height),
      sprintf("KPI_Count = %d", config$content$kpi_count),
      sprintf("KPI_Gap = %d", config$content$kpi_gap),
      "",
      "// Grid Settings",
      sprintf("Grid_Rows = %d", config$content$grid_rows),
      sprintf("Grid_Cols = %d", config$content$grid_cols),
      sprintf("Grid_Gap = %d", config$content$grid_gap),
      "",
      "// Theme Colors",
      sprintf("Theme_BG_Page = \"%s\"", config$theme$bg_page),
      sprintf("Theme_BG_Card = \"%s\"", config$theme$bg_card),
      sprintf("Theme_Border = \"%s\"", config$theme$border),
      sprintf("Theme_Accent = \"%s\"", config$theme$accent),
      "",
      "// Layout HTML (copy from Power BI HTML tab)",
      "Layout HTML = \"<style>...</style><div class='dashboard-container'>...</div>\""
    ),
    collapse = "\n"
  )
}

generate_json_theme <- function(config) {
  # Power BI valid theme structure — driven by the selected palette base.
  ramp <- config$palette$ramp
  base_name <- config$palette$base_name
  # Use 5 stops of the selected ramp (light→dark) then fill out with other GCPS bases
  # excluding the current one, so Power BI charts read coherent for small categorical sets
  # but still distinguishable when category count grows.
  others <- setdiff(names(gcps_base), base_name)
  data_colors <- unname(c(
    ramp[2],
    ramp[3],
    ramp[4],
    ramp[5],
    ramp[1],
    unname(gcps_base[others])
  ))
  theme <- list(
    name = sprintf("Dashboard Layout Theme — %s", base_name),
    dataColors = data_colors,
    background = config$theme$bg_page,
    foreground = config$theme$text_primary,
    tableAccent = config$palette$base
  )
  toJSON(theme, pretty = TRUE, auto_unbox = TRUE)
}

# Collapsible Section Helper
collapsible_section <- function(id, title, icon_name, content, open = FALSE) {
  tagList(
    div(
      class = "section-wrapper",
      div(
        class = "section-header-clickable",
        `data-bs-toggle` = "collapse",
        `data-bs-target` = paste0("#", id),
        icon(icon_name),
        title,
        icon(
          ifelse(open, "chevron-up", "chevron-down"),
          class = "chevron pull-right"
        )
      ),
      div(
        id = id,
        class = ifelse(
          open,
          "section-content collapse show",
          "section-content collapse"
        ),
        content
      )
    )
  )
}

# Builder Sidebar (structure controls only)
builder_sidebar <- sidebar(
  width = 350,
  open = "always",

  # Canvas Section
  collapsible_section(
    "sec_canvas",
    "Canvas Settings",
    "tv",
    tagList(
      fluidRow(
        column(
          6,
          numericInput(
            "canvas_width",
            "Width",
            value = DEFAULT_CONFIG$canvas$width,
            min = 400,
            max = 3840
          )
        ),
        column(
          6,
          numericInput(
            "canvas_height",
            "Height",
            value = DEFAULT_CONFIG$canvas$height,
            min = 300,
            max = 2160
          )
        )
      ),
      selectInput(
        "aspect_ratio",
        "Aspect Ratio",
        c("Custom", "16:9", "4:3", "21:9"),
        selected = "16:9"
      )
    ),
    open = TRUE
  ),

  # Header Section
  collapsible_section(
    "sec_header",
    "Header",
    "window-maximize",
    tagList(
      fluidRow(
        column(
          6,
          numericInput(
            "header_height",
            "Height",
            value = DEFAULT_CONFIG$header$height,
            min = 40,
            max = 200
          )
        ),
        column(
          6,
          numericInput(
            "header_padding",
            "Padding",
            value = DEFAULT_CONFIG$header$padding,
            min = 0,
            max = 40
          )
        )
      ),
      fluidRow(
        column(
          6,
          numericInput(
            "logo_width",
            "Logo Width",
            value = DEFAULT_CONFIG$header$logo_width,
            min = 50,
            max = 300
          )
        ),
        column(
          6,
          numericInput(
            "logo_height",
            "Logo Height",
            value = DEFAULT_CONFIG$header$logo_height,
            min = 20,
            max = 100
          )
        )
      ),
      numericInput(
        "nav_button_count",
        "Nav Buttons",
        value = DEFAULT_CONFIG$header$nav_button_count,
        min = 0,
        max = 8
      )
    ),
    open = FALSE
  ),

  # Sidebar Section
  collapsible_section(
    "sec_sidebar",
    "Sidebar",
    "columns",
    tagList(
      fluidRow(
        column(
          6,
          numericInput(
            "sidebar_width",
            "Width",
            value = DEFAULT_CONFIG$sidebar$width,
            min = 100,
            max = 400
          )
        ),
        column(
          6,
          numericInput(
            "sidebar_padding",
            "Padding",
            value = DEFAULT_CONFIG$sidebar$padding,
            min = 0,
            max = 32
          )
        )
      ),
      numericInput(
        "nav_item_count",
        "Nav Items",
        value = DEFAULT_CONFIG$sidebar$nav_item_count,
        min = 1,
        max = 15
      )
    ),
    open = FALSE
  ),

  # KPI Cards Section
  collapsible_section(
    "sec_kpi",
    "KPI Cards",
    "chart-bar",
    tagList(
      fluidRow(
        column(
          4,
          numericInput(
            "kpi_height",
            "Height",
            value = DEFAULT_CONFIG$content$kpi_height,
            min = 60,
            max = 150
          )
        ),
        column(
          4,
          numericInput(
            "kpi_count",
            "Count",
            value = DEFAULT_CONFIG$content$kpi_count,
            min = 1,
            max = 8
          )
        ),
        column(
          4,
          numericInput(
            "kpi_gap",
            "Gap",
            value = DEFAULT_CONFIG$content$kpi_gap,
            min = 0,
            max = 40
          )
        )
      ),
      textInput(
        "kpi_proportions",
        "Width Proportions",
        value = "",
        placeholder = "e.g., 40, 30, 20, 10"
      )
    ),
    open = FALSE
  ),

  # Content Grid Section
  collapsible_section(
    "sec_grid",
    "Content Grid",
    "th",
    tagList(
      radioButtons(
        "layout_type",
        "Layout Type",
        c(
          "Uniform Grid" = "uniform",
          "By Row (varying cols)" = "byrow",
          "By Column (varying rows)" = "bycol",
          "Freeform" = "freeform"
        ),
        selected = "uniform",
        inline = TRUE
      ),

      # Uniform: Same rows and columns throughout
      conditionalPanel(
        condition = "input.layout_type == 'uniform'",
        fluidRow(
          column(
            6,
            numericInput(
              "grid_rows",
              "Rows",
              value = DEFAULT_CONFIG$content$grid_rows,
              min = 1,
              max = 10
            )
          ),
          column(
            6,
            numericInput(
              "grid_cols",
              "Columns",
              value = DEFAULT_CONFIG$content$grid_cols,
              min = 1,
              max = 6
            )
          )
        ),
        p(class = "text-muted small", "Same number of columns in each row")
      ),

      # By Row: Different number of columns per row
      conditionalPanel(
        condition = "input.layout_type == 'byrow'",
        textInput(
          "containers_per_row",
          "Containers Per Row",
          value = DEFAULT_CONFIG$content$containers_per_row,
          placeholder = "e.g., 2, 3, 2"
        ),
        p(
          class = "text-muted small",
          "Comma-separated: number of containers in each row (top to bottom)"
        ),
        hr(),
        strong("Row Heights"),
        textInput(
          "row_heights",
          "Height Per Row (%)",
          value = "",
          placeholder = "e.g., 40, 35, 25"
        ),
        p(
          class = "text-muted small",
          "Comma-separated percentages for each row's height"
        ),
        hr(),
        strong("Column Widths Per Row"),
        textInput(
          "col_widths_per_row",
          "Column Widths by Row",
          value = "",
          placeholder = "e.g., 50,50; 33,33,34; 60,40"
        ),
        p(
          class = "text-muted small",
          "Semicolon separates rows; comma separates columns within each row"
        )
      ),

      # By Column: Different number of rows per column
      conditionalPanel(
        condition = "input.layout_type == 'bycol'",
        textInput(
          "containers_per_col",
          "Containers Per Column",
          value = "2, 2",
          placeholder = "e.g., 2, 3, 2"
        ),
        p(
          class = "text-muted small",
          "Comma-separated: number of containers in each column (left to right)"
        ),
        hr(),
        strong("Column Widths"),
        textInput(
          "col_widths",
          "Width Per Column (%)",
          value = "",
          placeholder = "e.g., 30, 40, 30"
        ),
        p(
          class = "text-muted small",
          "Comma-separated percentages for each column's width"
        ),
        hr(),
        strong("Row Heights Per Column"),
        textInput(
          "row_heights_per_col",
          "Row Heights by Column",
          value = "",
          placeholder = "e.g., 50,50; 33,33,34; 60,40"
        ),
        p(
          class = "text-muted small",
          "Semicolon separates columns; comma separates rows within each column"
        )
      ),

      # Freeform: Specify exact grid with custom widths/heights per cell
      conditionalPanel(
        condition = "input.layout_type == 'freeform'",
        numericInput(
          "ff_rows",
          "Number of Rows",
          value = 3,
          min = 1,
          max = 10
        ),
        numericInput(
          "ff_cols",
          "Number of Columns",
          value = 3,
          min = 1,
          max = 6
        ),
        hr(),
        strong("Row Heights"),
        textInput(
          "ff_row_heights",
          "Height Per Row (%)",
          value = "",
          placeholder = "e.g., 30, 40, 30"
        ),
        strong("Column Widths"),
        textInput(
          "ff_col_widths",
          "Width Per Column (%)",
          value = "",
          placeholder = "e.g., 25, 50, 25"
        ),
        p(class = "text-muted small", "Uniform grid with custom proportions")
      ),

      hr(),
      numericInput(
        "grid_gap",
        "Gap (px)",
        value = DEFAULT_CONFIG$content$grid_gap,
        min = 0,
        max = 40
      )
    ),
    open = FALSE
  ),

  # Preview Options Section (Part C)
  # Theme/typography/palette now come from the Theme Studio tab via input
  # (single source of truth). This section keeps ONLY layout-level options
  # (annotations) and the JSON-theme export button that consumes build_config().
  collapsible_section(
    "sec_preview_options",
    "Preview Options",
    "eye",
    tagList(
      p(
        class = "text-muted small",
        "Theme is driven by the Theme Studio tab. These options affect the layout preview."
      ),
      checkboxInput(
        "annotations_enabled",
        "Show Dimension Badges",
        value = FALSE
      ),
      p(
        class = "text-muted small",
        "Display width x height @ (x, y) on elements"
      ),
      hr(),
      downloadButton(
        "download_json",
        "Export JSON Theme",
        class = "btn-primary btn-sm w-100"
      )
    ),
    open = FALSE
  ),

  hr(),
  actionButton(
    "reset_config",
    "Reset to Defaults",
    class = "btn-outline-danger w-100"
  )
)

# Theme Studio Tab — embedded approved client-side studio.
# The studio owns its own internal tab bar and runs as scoped static UI inside
# exactly ONE nav_panel so its init IIFE finds a present DOM. The old
# colourInput/selectInput theme controls are moved to the Architect sidebar
# (see builder_sidebar "Theme (Preview/Export)") so build_config()/Preview/
# Power BI/DAX keep working; the studio drives the Project Templates downloads.
theme_studio_tab <- nav_panel(
  title = "🎨 Theme & Typography Studio",
  value = "theme_studio_tab",
  tags$div(
    class = "ts-root semantic",
    htmltools::HTML(paste(
      readLines("www/_theme_studio_markup.html", warn = FALSE),
      collapse = "\n"
    ))
  ),
  tags$script(src = "palette-data.js"),
  tags$script(src = "theme-studio.js"),
  tags$script(src = "theme-studio-app.js")
)

# ── GCPS Theme Studio: UI helper functions ──────────────────────────────────

gcps_gallery_card <- function(family, selected = FALSE) {
  ramp <- gcps_ramps[[family]]
  label <- FAMILY_LABELS[family]
  card_class <- if (selected) "gcard gcard-selected" else "gcard"
  ring <- if (selected) "selected" else ""
  div(
    class = card_class,
    `data-family` = family,
    div(
      class = "gcard-strip",
      lapply(seq_along(ramp), function(i) {
        span(
          class = "gcard-strip-swatch",
          style = paste0("background:", ramp[i])
        )
      })
    ),
    div(
      class = "gcard-body",
      strong(
        class = "gcard-name",
        toupper(substring(family, 1, 1)),
        substring(family, 2)
      ),
      span(class = "gcard-count", "5 stops"),
      if (selected) tags$small(class = "gcard-tag", "selected")
    )
  )
}

gcps_featured_palette <- function(family) {
  ramp <- gcps_ramps[[family]]
  label <- FAMILY_LABELS[family]
  div(
    class = "gcps-featured",
    h4(
      class = "gcps-featured-title",
      toupper(substring(family, 1, 1)),
      substring(family, 2)
    ),
    p(class = "gcps-featured-desc", label),
    div(
      class = "gcps-featured-ramp",
      lapply(seq_along(ramp), function(i) {
        div(
          class = "gcps-stop",
          div(
            class = "gcps-stop-swatch",
            style = paste0("background:", ramp[i]),
            span(class = "btn-copy-stop", `data-copy` = ramp[i], "Copy")
          ),
          div(class = "gcps-stop-label", STOPS[i]),
          div(class = "gcps-stop-hex", ramp[i])
        )
      })
    ),
    actionButton(
      "gcps_copy_ramp",
      paste0("Copy all 5 \u2014 ", family),
      class = "btn-sm btn-outline-secondary gcps-copy-all"
    )
  )
}

# ── GCPS Theme Studio: head / toast / script ────────────────────────────────

gcps_head <- tags$head(
  # Web fonts are self-hosted via @font-face in theme-studio.css (www/fonts/*.woff2).
  # No runtime CDN — required for Posit Connect deployment.
  # App stylesheets
  tags$link(rel = "stylesheet", href = "explorer.css"),
  tags$link(rel = "stylesheet", href = "app.css"),
  tags$link(rel = "stylesheet", href = "theme-studio.css")
)

gcps_toast <- div(id = "gcps-toast", class = "gcps-toast", "Copied!")

gcps_script <- tags$script(HTML(
  "
  // Clipboard + toast helper (with execCommand fallback)
  function gcpsCopy(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function() {
        gcpsToast('Copied ' + text);
      });
    } else {
      var ta = document.createElement('textarea');
      ta.value = text; ta.style.position = 'fixed'; ta.style.opacity = '0';
      document.body.appendChild(ta); ta.select();
      document.execCommand('copy'); document.body.removeChild(ta);
      gcpsToast('Copied ' + text);
    }
  }
  function gcpsToast(msg) {
    var t = document.getElementById('gcps-toast');
    if (!t) return;
    t.textContent = msg;
    t.classList.add('show');
    setTimeout(function() { t.classList.remove('show'); }, 1200);
  }

  // Shiny custom message handler for server-initiated copies
  if (typeof Shiny !== 'undefined') {
    Shiny.addCustomMessageHandler('copy_to_clipboard', function(text) {
      navigator.clipboard.writeText(text).then(function() {
        gcpsToast('Copied to clipboard');
      });
    });
  }

  // Click handlers for per-stop copy (delegated)
  $(document).on('click', '.btn-copy-stop', function(e) {
    e.stopPropagation();
    gcpsCopy($(this).data('copy'));
  });

  // Click handlers for gallery cards
  $(document).on('click', '.gcard', function() {
    var fam = $(this).data('family');
    if (typeof Shiny !== 'undefined' && Shiny.setInputValue) {
      Shiny.setInputValue('gcps_gallery_pick', fam);
    }
  });

  // Copy ramp button
  $(document).on('click', '.gcps-copy-all', function() {
    var stops = [];
    $(this).closest('.gcps-featured').find('.gcps-stop-hex').each(function() {
      stops.push($(this).text());
    });
    gcpsCopy(stops.join(', '));
  });

  // Copy code blocks
  $(document).on('click', '.btn-copy-code', function() {
    var code = $(this).closest('.gcps-code-block').find('code').text();
    gcpsCopy(code);
  });

  // Navigation Kit: platform switcher
  $(document).on('click', '.gcps-platform-btn', function() {
    var $btn = $(this);
    var pat = $btn.data('pattern');
    var plat = $btn.data('platform');
    $btn.siblings('.gcps-platform-btn').removeClass('active');
    $btn.addClass('active');
    var codeBlock = $btn.closest('.gcps-nav-pattern').find('.gcps-nav-code pre code');
    if (codeBlock.length && $btn.data('code')) {
      codeBlock.text($btn.data('code'));
    }
  });
"
))

# UI Definition (assembled from builder sidebar + tabs)
ui <- page_sidebar(
  title = "Dashboard Architect",
  theme = bs_theme(bootswatch = "yeti", version = 5),
  sidebar = builder_sidebar,
  navset_tab(
    id = "main_tabs",

    # Unified Preview Tab
    nav_panel(
      title = "Preview",
      value = "preview_tab",
      div(
        class = "p-3 bg-light border-bottom",
        fluidRow(
          column(
            3,
            selectInput(
              "preview_mode",
              "Preview Mode",
              choices = c(
                "Template Preview" = "template",
                "Wireframe Preview" = "wireframe",
                "Annotated Layout" = "annotated",
                "Blank Layout" = "blank",
                "Accessibility Review" = "accessibility",
                "Disclosure Review" = "disclosure",
                "Print Preview" = "print"
              ),
              selected = "template"
            )
          ),
          column(
            3,
            conditionalPanel(
              condition = "input.preview_mode == 'template'",
              selectInput(
                "boe_theme",
                "Theme",
                choices = setNames(
                  names(theme_registry),
                  sapply(theme_registry, `[[`, "name")
                ),
                selected = names(theme_registry)[1]
              )
            )
          ),
          column(
            3,
            conditionalPanel(
              condition = "input.preview_mode == 'template'",
              selectInput(
                "boe_template",
                "Template",
                choices = setNames(
                  names(template_registry),
                  sapply(template_registry, `[[`, "name")
                ),
                selected = "boe_area_snapshot"
              )
            )
          ),
          column(
            3,
            div(
              class = "d-flex align-items-center gap-2 mt-4",
              "Zoom:",
              actionButton(
                "zoom_out",
                "-",
                class = "btn btn-sm btn-outline-secondary"
              ),
              textOutput("zoom_display", inline = TRUE),
              actionButton(
                "zoom_in",
                "+",
                class = "btn btn-sm btn-outline-secondary"
              )
            )
          )
        )
      ),
      div(
        class = "p-4 bg-secondary",
        style = "overflow: auto; height: calc(100vh - 200px);",
        div(class = "d-flex justify-content-center", uiOutput("preview_frame"))
      )
    ),

    theme_studio_tab,

    # Project Templates Tab (Part B/D)
    nav_panel(
      title = "Project Templates",
      value = "templates_tab",
      div(
        class = "p-3",
        p(
          class = "text-muted small",
          "Starters are baked with your current Theme Studio selections —",
          "surfaces, palette, typography, and accent."
        ),
        uiOutput("ts_theme_summary"),
        tags$hr(),
        downloadButton(
          "download_tmpl_all",
          "Download all (.zip)",
          class = "btn-primary btn-sm mb-3"
        ),
        layout_columns(
          col_widths = 12,
          card(
            card_header(class = "bg-light", strong("Quarto Document")),
            card_body(
              p(
                class = "text-muted small",
                "A single-page HTML report themed with your studio selections."
              ),
              tags$pre(
                class = "small text-muted",
                "report.qmd\ntheme.scss\n_brand.yml\nR/theme_gcps.R\nREADME.md"
              ),
              downloadButton(
                "download_tmpl_qdoc",
                "Download .zip",
                class = "btn-primary btn-sm"
              )
            )
          ),
          card(
            card_header(class = "bg-light", strong("Quarto Website")),
            card_body(
              p(
                class = "text-muted small",
                "A multi-page Quarto site (index / analysis / about)."
              ),
              tags$pre(
                class = "small text-muted",
                "_quarto.yml\nindex.qmd\nanalysis.qmd\nabout.qmd\ntheme.scss\n_brand.yml\nR/theme_gcps.R\nREADME.md"
              ),
              downloadButton(
                "download_tmpl_qsite",
                "Download .zip",
                class = "btn-primary btn-sm"
              )
            )
          ),
          card(
            card_header(class = "bg-light", strong("Quarto Dashboard")),
            card_body(
              p(
                class = "text-muted small",
                "format: dashboard with value boxes and themed plots."
              ),
              tags$pre(
                class = "small text-muted",
                "dashboard.qmd\ntheme.scss\n_brand.yml\nR/theme_gcps.R\nREADME.md"
              ),
              downloadButton(
                "download_tmpl_qdash",
                "Download .zip",
                class = "btn-primary btn-sm"
              )
            )
          ),
          card(
            card_header(class = "bg-light", strong("flexdashboard")),
            card_body(
              p(
                class = "text-muted small",
                "RMarkdown flexdashboard with valueBox()s and themed plots."
              ),
              tags$pre(
                class = "small text-muted",
                "dashboard.Rmd\nstyles.css\nR/theme_gcps.R\nREADME.md"
              ),
              downloadButton(
                "download_tmpl_flex",
                "Download .zip",
                class = "btn-primary btn-sm"
              )
            )
          ),
          card(
            card_header(class = "bg-light", strong("Shiny App")),
            card_body(
              p(
                class = "text-muted small",
                "bslib starter themed to your studio selections."
              ),
              tags$pre(
                class = "small text-muted",
                "app.R\nwww/theme.css\nR/theme_gcps.R\nREADME.md"
              ),
              downloadButton(
                "download_tmpl_shiny",
                "Download .zip",
                class = "btn-primary btn-sm"
              )
            )
          ),
          card(
            card_header(class = "bg-light", strong("Power BI Theme JSON")),
            card_body(
              p(
                class = "text-muted small",
                "Importable report theme JSON + palette swatches."
              ),
              tags$pre(
                class = "small text-muted",
                "GCPS-theme.json\npalette-swatches.txt\nREADME.md"
              ),
              downloadButton(
                "download_tmpl_powerbi",
                "Download .zip",
                class = "btn-primary btn-sm"
              )
            )
          ),
          card(
            card_header(class = "bg-light", strong("Power BI .pbip Project")),
            card_body(
              p(
                class = "text-muted small",
                "A Power BI Project folder (PBIR) that opens in Desktop with the",
                "theme pre-registered. Requires .pbip + PBIR preview features."
              ),
              tags$pre(
                class = "small text-muted",
                "GCPS-Report.pbip\nGCPS-Report.Report/...\nGCPS-Report.SemanticModel/...\nREADME.md"
              ),
              downloadButton(
                "download_tmpl_pbip",
                "Download .zip",
                class = "btn-primary btn-sm"
              )
            )
          )
        )
      )
    ),

    #  Shiny Tab
    nav_panel(
      title = "Shiny Code",
      value = "shiny_tab",
      div(
        class = "p-3",
        div(
          class = "d-flex gap-2 mb-3",
          downloadButton(
            "download_shiny",
            "Download .R",
            class = "btn-primary btn-sm"
          ),
          actionButton(
            "copy_shiny",
            "Copy Code",
            class = "btn-outline-primary btn-sm"
          )
        ),
        p(
          class = "text-muted small",
          "Starter code for an R Shiny application using bslib."
        ),
        div(class = "code-output", verbatimTextOutput("shiny_output"))
      )
    ),

    # Quarto Dashboard Tab
    nav_panel(
      title = "Quarto Dashboard",
      value = "quarto_dash_tab",
      div(
        class = "p-3",
        div(
          class = "d-flex gap-2 mb-3",
          downloadButton(
            "download_quarto_dash",
            "Download .qmd",
            class = "btn-primary btn-sm"
          ),
          actionButton(
            "copy_quarto_dash",
            "Copy Code",
            class = "btn-outline-primary btn-sm"
          )
        ),
        p(
          class = "text-muted small",
          "Starter Quarto dashboard (format: dashboard) with bslib theming and value boxes."
        ),
        div(class = "code-output", verbatimTextOutput("quarto_dash_output"))
      )
    ),

    # Quarto HTML Tab
    nav_panel(
      title = "Quarto HTML",
      value = "quarto_html_tab",
      div(
        class = "p-3",
        div(
          class = "d-flex gap-2 mb-3",
          downloadButton(
            "download_quarto_html",
            "Download .qmd",
            class = "btn-primary btn-sm"
          ),
          actionButton(
            "copy_quarto_html",
            "Copy Code",
            class = "btn-outline-primary btn-sm"
          )
        ),
        p(
          class = "text-muted small",
          "Starter Quarto HTML page built from bslib cards and layout_columns()."
        ),
        div(class = "code-output", verbatimTextOutput("quarto_html_output"))
      )
    ),

    # flexdashboard Tab
    nav_panel(
      title = "flexdashboard",
      value = "flex_tab",
      div(
        class = "p-3",
        div(
          class = "d-flex gap-2 mb-3",
          downloadButton(
            "download_flex",
            "Download .Rmd",
            class = "btn-primary btn-sm"
          ),
          actionButton(
            "copy_flex",
            "Copy Code",
            class = "btn-outline-primary btn-sm"
          )
        ),
        p(
          class = "text-muted small",
          "Starter flexdashboard (.Rmd) themed with bslib::bs_theme()."
        ),
        div(class = "code-output", verbatimTextOutput("flex_output"))
      )
    ),

    # Power BI HTML Tab
    nav_panel(
      title = "Power BI HTML",
      value = "powerbi_tab",
      div(
        class = "p-3",
        div(
          class = "d-flex gap-2 mb-3",
          downloadButton(
            "download_powerbi",
            "Download",
            class = "btn-primary btn-sm"
          ),
          actionButton(
            "copy_powerbi",
            "Copy",
            class = "btn-outline-primary btn-sm"
          ),
          checkboxInput("single_line", "Single Line (for DAX)", value = TRUE)
        ),
        p(
          class = "text-muted small",
          "HTML formatted for Power BI HTML Content visual. Use in DAX: Layout HTML = \"...\""
        ),
        div(class = "code-output", verbatimTextOutput("powerbi_output"))
      )
    ),

    # DAX Tab
    nav_panel(
      title = "DAX",
      value = "dax_tab",
      div(
        class = "p-3",
        div(
          class = "d-flex gap-2 mb-3",
          downloadButton(
            "download_dax",
            "Download",
            class = "btn-primary btn-sm"
          ),
          actionButton("copy_dax", "Copy", class = "btn-outline-primary btn-sm")
        ),
        p(class = "text-muted small", "DAX measures for layout configuration."),
        div(class = "code-output", verbatimTextOutput("dax_output"))
      )
    ),

    # Full HTML Tab
    nav_panel(
      title = "Full HTML",
      value = "html_tab",
      div(
        class = "p-3",
        div(
          class = "d-flex gap-2 mb-3",
          downloadButton(
            "download_html",
            "Download",
            class = "btn-primary btn-sm"
          ),
          actionButton(
            "copy_html",
            "Copy",
            class = "btn-outline-primary btn-sm"
          )
        ),
        p(
          class = "text-muted small",
          "Complete HTML document for standalone use."
        ),
        div(class = "code-output", verbatimTextOutput("html_output"))
      )
    ),

    # NOTE: The superseded `nav_menu` (duplicate gcps_theme_studio_tab mount +
    # Navigation Kit) is removed — the studio now lives in the single
    # theme_studio_tab above. Two mounts would double-init the studio IIFE and
    # collide on element IDs (#tabs, #semToggle, …). One mount = one source.
  )
)

# Additional CSS
tags_style <- tags$style(HTML(
  "
  .section-wrapper { margin-bottom: 8px; }
  .section-header-clickable {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 12px;
    background: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 500;
    font-size: 13px;
    transition: background 0.2s;
  }
  .section-header-clickable:hover { background: #e9ecef; }
  .section-header-clickable .chevron { margin-left: auto; transition: transform 0.2s; }
  .section-content { padding: 12px; border: 1px solid #dee2e6; border-top: none; border-radius: 0 0 6px 6px; }
  .section-content .form-group { margin-bottom: 8px; }
  .section-content .form-group label { font-size: 11px; margin-bottom: 2px; }
  .code-output {
    background: #1e1e1e !important;
    border-radius: 8px;
    padding: 15px;
    max-height: 500px;
    overflow: auto;
  }
  .code-output pre,
  .code-output #shiny_output,
  .code-output #quarto_dash_output,
  .code-output #quarto_html_output,
  .code-output #flex_output,
  .code-output #powerbi_output,
  .code-output #dax_output,
  .code-output #json_output,
  .code-output #html_output {
    color: #d4d4d4 !important;
    background: transparent !important;
    font-family: 'Consolas', Monaco, monospace;
    font-size: 12px;
    white-space: pre-wrap;
  }
  .preview-frame {
    background: white;
    box-shadow: 0 4px 20px rgba(0,0,0,0.15);
    transform-origin: top center;
  }
"
))

# Server Logic
server <- function(input, output, session) {
  # Zoom reactive value
  rv <- reactiveValues(zoom = 0.5)

  # Build config reactively
  build_config <- reactive({
    # Part C: the Theme Studio is now the SINGLE source of truth for theme,
    # typography, and palette. We pull those from input$ts_theme (the JS bridge
    # in www/theme-studio-app.js) via gcps_config_theme_from_studio(), which is
    # null-safe — it returns the GCPS default before the studio JS first emits.
    # Canvas / header / sidebar / content / annotations stay on the Architect
    # sidebar. generate_css/html/shiny_code/dax/json_theme see the same config
    # shape they always did; only the source of the theme fields changed.
    studio <- gcps_config_theme_from_studio(input$ts_theme)

    list(
      canvas = list(width = input$canvas_width, height = input$canvas_height),
      typography = studio$typography,
      palette = studio$palette,
      theme = studio$theme,
      header = list(
        height = input$header_height,
        padding = input$header_padding,
        logo_width = input$logo_width,
        logo_height = input$logo_height,
        nav_button_count = input$nav_button_count
      ),
      sidebar = list(
        width = input$sidebar_width,
        padding = input$sidebar_padding,
        nav_item_count = input$nav_item_count
      ),
      content = list(
        kpi_height = input$kpi_height,
        kpi_count = input$kpi_count,
        kpi_gap = input$kpi_gap,
        grid_rows = input$grid_rows,
        grid_cols = input$grid_cols,
        grid_gap = input$grid_gap,
        padding = 20,
        layout_type = input$layout_type,
        # By Row settings
        containers_per_row = input$containers_per_row,
        row_proportions = input$row_heights,
        col_widths_per_row = input$col_widths_per_row,
        # By Column settings
        containers_per_col = input$containers_per_col,
        col_widths = input$col_widths,
        row_heights_per_col = input$row_heights_per_col,
        # Freeform settings
        ff_rows = input$ff_rows,
        ff_cols = input$ff_cols,
        ff_row_heights = input$ff_row_heights,
        ff_col_widths = input$ff_col_widths,
        # KPI settings
        kpi_proportions = input$kpi_proportions
      ),
      annotations = list(enabled = input$annotations_enabled),

      # K-12 template and theme selections
      selected_template_id = input$boe_template,
      selected_template = template_registry[[input$boe_template]],
      selected_theme_id = input$boe_theme,
      selected_theme = theme_registry[[input$boe_theme]]
    )
  })

  # Aspect ratio presets
  observeEvent(input$aspect_ratio, {
    if (input$aspect_ratio != "Custom") {
      ratios <- list(
        "16:9" = c(1600, 900),
        "4:3" = c(1200, 900),
        "21:9" = c(2100, 900)
      )
      if (input$aspect_ratio %in% names(ratios)) {
        updateNumericInput(
          session,
          "canvas_width",
          value = ratios[[input$aspect_ratio]][1]
        )
        updateNumericInput(
          session,
          "canvas_height",
          value = ratios[[input$aspect_ratio]][2]
        )
      }
    }
  })

  # Zoom controls
  observeEvent(input$zoom_in, {
    rv$zoom <- min(1.5, rv$zoom + 0.1)
  })
  observeEvent(input$zoom_out, {
    rv$zoom <- max(0.25, rv$zoom - 0.1)
  })

  output$zoom_display <- renderText({
    paste0(round(rv$zoom * 100), "%")
  })

  # Reset to defaults
  observeEvent(input$reset_config, {
    updateNumericInput(
      session,
      "canvas_width",
      value = DEFAULT_CONFIG$canvas$width
    )
    updateNumericInput(
      session,
      "canvas_height",
      value = DEFAULT_CONFIG$canvas$height
    )
    updateSelectInput(session, "aspect_ratio", selected = "16:9")
    # Theme reset is handled by the Theme Studio (input$ts_theme) — no sidebar
    # colour inputs to reset since Part C.
    updateNumericInput(
      session,
      "header_height",
      value = DEFAULT_CONFIG$header$height
    )
    updateNumericInput(
      session,
      "sidebar_width",
      value = DEFAULT_CONFIG$sidebar$width
    )
    updateNumericInput(
      session,
      "kpi_count",
      value = DEFAULT_CONFIG$content$kpi_count
    )
    updateNumericInput(
      session,
      "grid_rows",
      value = DEFAULT_CONFIG$content$grid_rows
    )
    updateNumericInput(
      session,
      "grid_cols",
      value = DEFAULT_CONFIG$content$grid_cols
    )
    # Reset layout type and related fields
    updateRadioButtons(session, "layout_type", selected = "uniform")
    updateTextInput(
      session,
      "containers_per_row",
      value = DEFAULT_CONFIG$content$containers_per_row
    )
    updateTextInput(
      session,
      "containers_per_col",
      value = DEFAULT_CONFIG$content$containers_per_col
    )
    updateTextInput(session, "row_heights", value = "")
    updateTextInput(session, "col_widths", value = "")
    updateTextInput(session, "col_widths_per_row", value = "")
    updateTextInput(session, "row_heights_per_col", value = "")
    updateNumericInput(
      session,
      "ff_rows",
      value = DEFAULT_CONFIG$content$ff_rows
    )
    updateNumericInput(
      session,
      "ff_cols",
      value = DEFAULT_CONFIG$content$ff_cols
    )
    updateTextInput(session, "ff_row_heights", value = "")
    updateTextInput(session, "ff_col_widths", value = "")
    updateCheckboxInput(session, "annotations_enabled", value = FALSE)
    showNotification("Reset to defaults", type = "message")
  })

  # ── Unified Preview Output ──────────────────────────────────────
  output$preview_frame <- renderUI({
    mode <- input$preview_mode
    html_content <- NULL

    if (mode == "template") {
      # K-12 template preview (BOE Area Snapshot, etc.)
      html_content <- render_boe_preview(
        template_id = input$boe_template,
        theme_id = input$boe_theme,
        embedded = TRUE
      )
    } else if (mode %in% c("wireframe", "annotated")) {
      # Wireframe with example content, or annotated layout
      config <- build_config()
      html_content <- generate_html(
        config,
        include_css = TRUE,
        view_mode = mode
      )
    } else if (mode == "blank") {
      # Blank layout wireframe
      config <- build_config()
      html_content <- generate_html(
        config,
        include_css = TRUE,
        view_mode = "blank"
      )
    } else if (mode == "accessibility") {
      # Accessibility review: template preview with a11y overlay notice
      html_content <- render_boe_preview(
        template_id = input$boe_template,
        theme_id = input$boe_theme,
        embedded = TRUE
      )
      html_content <- paste0(
        '<div style="background:#1A7F37;color:#fff;padding:8px 16px;border-radius:8px 8px 0 0;font-size:13px;font-weight:600;">Accessibility Review Mode — Check contrast ratios, alt text, and tab order.</div>',
        html_content
      )
    } else if (mode == "disclosure") {
      # Disclosure review: template preview with disclosure overlay notice
      html_content <- render_boe_preview(
        template_id = input$boe_template,
        theme_id = input$boe_theme,
        embedded = TRUE
      )
      html_content <- paste0(
        '<div style="background:#9A6700;color:#fff;padding:8px 16px;border-radius:8px 8px 0 0;font-size:13px;font-weight:600;">Disclosure Review Mode — Verify suppressed cells, minimum cell sizes, and FERPA compliance.</div>',
        html_content
      )
    } else if (mode == "print") {
      # Print preview: template with print-friendly styling
      html_content <- render_boe_preview(
        template_id = input$boe_template,
        theme_id = "gcps_board_report",
        embedded = TRUE
      )
      html_content <- paste0(
        '<div style="background:#2C3641;color:#fff;padding:8px 16px;border-radius:8px 8px 0 0;font-size:13px;font-weight:600;">Print Preview — Uses GCPS Board Report theme (high contrast, white background).</div>',
        html_content
      )
    }

    if (is.null(html_content)) {
      html_content <- "<p>Select a preview mode above.</p>"
    }

    div(
      style = sprintf(
        "transform: scale(%s); transform-origin: top center;",
        rv$zoom
      ),
      class = "preview-frame",
      HTML(html_content)
    )
  })

  output$shiny_output <- renderText({
    generate_shiny_code(build_config())
  })

  output$quarto_dash_output <- renderText({
    generate_quarto_dashboard(build_config())
  })

  output$quarto_html_output <- renderText({
    generate_quarto_html(build_config())
  })

  output$flex_output <- renderText({
    generate_flexdashboard(build_config())
  })

  # Power BI HTML output
  output$powerbi_output <- renderText({
    config <- build_config()
    view_mode <- if (config$annotations$enabled) "annotated" else "blank"
    html <- generate_html(config, include_css = TRUE, view_mode = view_mode)
    if (input$single_line) {
      html <- gsub("\n", " ", html)
      html <- gsub("\\s+", " ", html)
    }
    html
  })

  # DAX output
  output$dax_output <- renderText({
    generate_dax(build_config())
  })

  # JSON output
  output$json_output <- renderText({
    generate_json_theme(build_config())
  })

  # Full HTML output
  output$html_output <- renderText({
    config <- build_config()
    view_mode <- if (config$annotations$enabled) "annotated" else "example"
    generate_html(config, include_css = TRUE, view_mode = view_mode)
  })

  # Download handlers

  output$download_shiny <- downloadHandler(
    filename = function() paste0("app-", format(Sys.Date(), "%Y%m%d"), ".R"),
    content = function(file) {
      writeLines(generate_shiny_code(build_config()), file)
    }
  )

  output$download_quarto_dash <- downloadHandler(
    filename = function() paste0("dashboard-", format(Sys.Date(), "%Y%m%d"), ".qmd"),
    content = function(file) writeLines(generate_quarto_dashboard(build_config()), file)
  )

  output$download_quarto_html <- downloadHandler(
    filename = function() paste0("report-", format(Sys.Date(), "%Y%m%d"), ".qmd"),
    content = function(file) writeLines(generate_quarto_html(build_config()), file)
  )

  output$download_flex <- downloadHandler(
    filename = function() paste0("flexdash-", format(Sys.Date(), "%Y%m%d"), ".Rmd"),
    content = function(file) writeLines(generate_flexdashboard(build_config()), file)
  )

  output$download_powerbi <- downloadHandler(
    filename = function() {
      paste0("dashboard-layout-", format(Sys.Date(), "%Y%m%d"), ".html")
    },
    content = function(file) {
      config <- build_config()
      view_mode <- if (config$annotations$enabled) "annotated" else "blank"
      writeLines(generate_html(config, TRUE, view_mode), file)
    }
  )

  output$download_dax <- downloadHandler(
    filename = function() {
      paste0("dashboard-measures-", format(Sys.Date(), "%Y%m%d"), ".dax")
    },
    content = function(file) writeLines(generate_dax(build_config()), file)
  )

  output$download_json <- downloadHandler(
    filename = function() {
      paste0("dashboard-theme-", format(Sys.Date(), "%Y%m%d"), ".json")
    },
    content = function(file) {
      writeLines(generate_json_theme(build_config()), file)
    }
  )

  output$download_html <- downloadHandler(
    filename = function() {
      paste0("dashboard-full-", format(Sys.Date(), "%Y%m%d"), ".html")
    },
    content = function(file) {
      config <- build_config()
      view_mode <- if (config$annotations$enabled) "annotated" else "example"
      writeLines(generate_html(config, TRUE, view_mode), file)
    }
  )

  # Copy-code buttons — write to clipboard via custom message handler

  observeEvent(input$copy_shiny, {
    session$sendCustomMessage(
      "copy_to_clipboard",
      generate_shiny_code(build_config())
    )
  })

  observeEvent(input$copy_quarto_dash, {
    session$sendCustomMessage("copy_to_clipboard", generate_quarto_dashboard(build_config()))
  })

  observeEvent(input$copy_quarto_html, {
    session$sendCustomMessage("copy_to_clipboard", generate_quarto_html(build_config()))
  })

  observeEvent(input$copy_flex, {
    session$sendCustomMessage("copy_to_clipboard", generate_flexdashboard(build_config()))
  })

  observeEvent(input$copy_powerbi, {
    config <- build_config()
    view_mode <- if (config$annotations$enabled) "annotated" else "blank"
    session$sendCustomMessage(
      "copy_to_clipboard",
      generate_html(config, TRUE, view_mode)
    )
  })

  observeEvent(input$copy_dax, {
    session$sendCustomMessage("copy_to_clipboard", generate_dax(build_config()))
  })

  observeEvent(input$copy_json, {
    session$sendCustomMessage(
      "copy_to_clipboard",
      generate_json_theme(build_config())
    )
  })

  observeEvent(input$copy_html, {
    config <- build_config()
    view_mode <- if (config$annotations$enabled) "annotated" else "example"
    session$sendCustomMessage(
      "copy_to_clipboard",
      generate_html(config, TRUE, view_mode)
    )
  })

  # ── Project Templates: summary + downloadHandlers (Part B) ──────
  # Each handler resolves the current studio theme (or the GCPS default before
  # the studio first emits) and writes the themed .zip via R/generate_templates.R.
  output$ts_theme_summary <- renderUI({
    t <- gcps_resolve_theme(input$ts_theme)
    span(
      class = "badge bg-light text-dark border",
      sprintf(
        "Source: %s · Font: %s · Accent: %s",
        t$source,
        t$font_label,
        t$accent
      )
    )
  })

  tmpl_kind <- function(suffix) {
    paste0("gcps-", suffix, "-", format(Sys.Date(), "%Y%m%d"), ".zip")
  }

  output$download_tmpl_qdoc <- downloadHandler(
    filename = function() tmpl_kind("quarto-doc"),
    content = function(file) {
      t <- gcps_resolve_theme(input$ts_theme)
      gcps_write_template_zip(gcps_template_quarto_doc(t), file)
    },
    contentType = "application/zip"
  )
  output$download_tmpl_qsite <- downloadHandler(
    filename = function() tmpl_kind("quarto-site"),
    content = function(file) {
      t <- gcps_resolve_theme(input$ts_theme)
      gcps_write_template_zip(gcps_template_quarto_site(t), file)
    },
    contentType = "application/zip"
  )
  output$download_tmpl_qdash <- downloadHandler(
    filename = function() tmpl_kind("quarto-dashboard"),
    content = function(file) {
      t <- gcps_resolve_theme(input$ts_theme)
      gcps_write_template_zip(gcps_template_quarto_dashboard(t), file)
    },
    contentType = "application/zip"
  )
  output$download_tmpl_flex <- downloadHandler(
    filename = function() tmpl_kind("flexdashboard"),
    content = function(file) {
      t <- gcps_resolve_theme(input$ts_theme)
      gcps_write_template_zip(gcps_template_flexdashboard(t), file)
    },
    contentType = "application/zip"
  )
  output$download_tmpl_shiny <- downloadHandler(
    filename = function() tmpl_kind("shiny-app"),
    content = function(file) {
      t <- gcps_resolve_theme(input$ts_theme)
      gcps_write_template_zip(gcps_template_shiny_app(t), file)
    },
    contentType = "application/zip"
  )
  output$download_tmpl_powerbi <- downloadHandler(
    filename = function() tmpl_kind("powerbi"),
    content = function(file) {
      t <- gcps_resolve_theme(input$ts_theme)
      gcps_write_template_zip(gcps_template_powerbi(t), file)
    },
    contentType = "application/zip"
  )
  output$download_tmpl_pbip <- downloadHandler(
    filename = function() tmpl_kind("powerbi-pbip"),
    content = function(file) {
      t <- gcps_resolve_theme(input$ts_theme)
      gcps_write_template_zip(gcps_template_pbip(t), file)
    },
    contentType = "application/zip"
  )
  output$download_tmpl_all <- downloadHandler(
    filename = function() {
      paste0("gcps-all-templates-", format(Sys.Date(), "%Y%m%d"), ".zip")
    },
    content = function(file) {
      gcps_write_all_zip(gcps_resolve_theme(input$ts_theme), file)
    },
    contentType = "application/zip"
  )

  # ── GCPS Theme Studio reactives/outputs ──────────────────────────

  gcps_selected <- reactiveVal(DEFAULT_GCPS_FAMILY)

  # Dropdown -> reactive
  observeEvent(input$gcps_family, ignoreInit = TRUE, {
    req(input$gcps_family)
    gcps_selected(input$gcps_family)
  })

  # Gallery click -> dropdown + reactive
  observeEvent(input$gcps_gallery_pick, ignoreInit = TRUE, {
    req(input$gcps_gallery_pick)
    fam <- input$gcps_gallery_pick
    updateSelectInput(session, "gcps_family", selected = fam)
    gcps_selected(fam)
  })

  output$gcps_featured_ui <- renderUI({
    gcps_featured_palette(gcps_selected())
  })

  output$gcps_gallery_ui <- renderUI({
    sel <- gcps_selected()
    cards <- lapply(FAMILY_NAMES, function(fam) {
      gcps_gallery_card(fam, selected = (fam == sel))
    })
    div(class = "gcps-gallery", cards)
  })

  output$gcps_preview_ui <- renderUI({
    fam <- gcps_selected()
    ramp <- gcps_ramps[[fam]]
    kpis <- demo_district_kpis
    div(
      h5(
        "Theme Preview \u2014 ",
        toupper(substring(fam, 1, 1)),
        substring(fam, 2)
      ),
      p(
        class = "text-muted small",
        "Palette: ",
        fam,
        " \u00B7 Font: Segoe UI \u00B7 Synthetic K-12 data"
      ),
      div(
        class = "gcps-preview-kpis",
        lapply(seq_along(kpis), function(i) {
          kpi <- kpis[[i]]
          div(
            class = "gcps-kpi-card",
            div(
              class = "gcps-kpi-stripe",
              style = paste0("background:", ramp[3])
            ),
            div(
              class = "gcps-kpi-body",
              div(class = "gcps-kpi-label", kpi$label),
              div(class = "gcps-kpi-value", kpi$value),
              div(class = "gcps-kpi-delta", kpi$delta)
            )
          )
        })
      ),
      div(
        class = "gcps-preview-trend",
        h6("Proficiency Trend"),
        div(
          class = "gcps-trend-bars",
          lapply(seq_along(demo_trend_pcts), function(i) {
            div(
              class = "gcps-trend-bar-group",
              div(
                class = "gcps-trend-bar",
                style = paste0(
                  "height:",
                  demo_trend_heights[[i]],
                  ";background:",
                  ramp[i]
                )
              ),
              span(class = "gcps-trend-label", demo_trend_years[[i]]),
              span(class = "gcps-trend-val", demo_trend_pcts[[i]])
            )
          })
        ),
        div(
          class = "gcps-trend-legend",
          lapply(seq_along(ramp), function(i) {
            span(
              class = "gcps-legend-item",
              span(
                class = "gcps-legend-swatch",
                style = paste0("background:", ramp[i])
              ),
              STOPS[i]
            )
          })
        )
      )
    )
  })

  output$gcps_a11y_ui <- renderUI({
    fam <- gcps_selected()
    ramp <- gcps_ramps[[fam]]
    div(
      h5(
        "WCAG Contrast \u2014 ",
        toupper(substring(fam, 1, 1)),
        substring(fam, 2)
      ),
      p(
        class = "text-muted small",
        "Contrast ratios against white (#FFFFFF) and text (#1F2120)."
      ),
      div(
        class = "gcps-a11y-grid",
        lapply(seq_along(ramp), function(i) {
          hex <- ramp[i]
          ratio_w <- round(contrast_ratio(hex, "#FFFFFF"), 2)
          ratio_t <- round(contrast_ratio(hex, "#1F2120"), 2)
          ratio <- ratio_w
          badge <- if (ratio >= 7) {
            "AAA"
          } else if (ratio >= 4.5) {
            "AA"
          } else {
            "Fail"
          }
          badge_class <- if (badge == "AAA") {
            "gcps-badge-pass"
          } else if (badge == "AA") {
            "gcps-badge-warn"
          } else {
            "gcps-badge-fail"
          }
          div(
            class = "gcps-a11y-card",
            div(class = "gcps-a11y-swatch", style = paste0("background:", hex)),
            div(
              class = "gcps-a11y-info",
              strong(STOPS[i], "\u2014", hex),
              div(class = "gcps-a11y-ratio", ratio, ":1"),
              span(class = paste("gcps-a11y-badge", badge_class), badge)
            )
          )
        })
      )
    )
  })

  output$gcps_json_preview <- renderText({
    toJSON(build_gcps_theme(gcps_selected()), pretty = TRUE, auto_unbox = TRUE)
  })

  gcps_download_fn <- function(file) {
    writeLines(
      toJSON(
        build_gcps_theme(gcps_selected()),
        pretty = TRUE,
        auto_unbox = TRUE
      ),
      file
    )
  }

  output$gcps_download_json <- downloadHandler(
    filename = function() paste0("gcps-", gcps_selected(), "-theme.json"),
    content = gcps_download_fn
  )

  observeEvent(input$gcps_copy_css, {
    css <- build_css_vars(gcps_selected())
    session$sendCustomMessage("copy_to_clipboard", css)
  })

  # ── Export tab: snippet cards ────────────────────────────────────
  output$gcps_snippets_ui <- renderUI({
    fam <- gcps_selected()
    snippets <- list(
      list(title = "CSS Variables", fn = build_css_snippet, id = "css"),
      list(title = "bslib Theme (R)", fn = build_bslib_snippet, id = "bslib"),
      list(
        title = "Quarto _brand.yml",
        fn = build_quarto_snippet,
        id = "quarto"
      ),
      list(title = "ggplot2 Scale", fn = build_ggplot_snippet, id = "ggplot")
    )
    div(
      class = "gcps-snippets-grid",
      lapply(snippets, function(s) {
        code <- s$fn(fam)
        div(
          class = "gcps-snippet-card",
          div(
            class = "gcps-snippet-header",
            strong(s$title),
            actionButton(
              paste0("gcps_copy_snippet_", s$id),
              "Copy",
              class = "btn-sm btn-outline-secondary gcps-snippet-copy",
              `data-snippet` = s$id
            )
          ),
          div(
            class = "gcps-code-block",
            tags$pre(tags$code(code))
          )
        )
      })
    )
  })

  # Snippet copy handlers (delegated via JS .gcps-snippet-copy clicks,
  # but we also register server-side for the toast)
  lapply(c("css", "bslib", "quarto", "ggplot"), function(id) {
    obs_id <- paste0("gcps_copy_snippet_", id)
    observeEvent(input[[obs_id]], {
      fam <- gcps_selected()
      code <- switch(
        id,
        css = build_css_snippet(fam),
        bslib = build_bslib_snippet(fam),
        quarto = build_quarto_snippet(fam),
        ggplot = build_ggplot_snippet(fam)
      )
      session$sendCustomMessage("copy_to_clipboard", code)
    })
  })

  # ── Navigation Kit: pattern cards with platform switcher ────────
  output$gcps_nav_patterns_ui <- renderUI({
    lapply(names(NAV_PATTERNS), function(pat_key) {
      pat <- NAV_PATTERNS[[pat_key]]
      platforms <- names(pat$platforms)
      div(
        class = "gcps-nav-pattern",
        h6(pat$name),
        div(
          class = "gcps-platform-tabs",
          lapply(seq_along(platforms), function(pi) {
            p_name <- platforms[pi]
            btn_class <- if (pi == 1) {
              "gcps-platform-btn active"
            } else {
              "gcps-platform-btn"
            }
            tags$button(
              class = btn_class,
              `data-pattern` = pat_key,
              `data-platform` = p_name,
              `data-code` = pat$platforms[[p_name]],
              p_name
            )
          })
        ),
        div(
          class = "gcps-code-block gcps-nav-code",
          `data-pattern` = pat_key,
          tags$pre(tags$code(pat$platforms[[1]]))
        )
      )
    })
  })
}

# Run application
shinyApp(
  ui = tagList(
    tags_style,
    gcps_head,
    ui,
    gcps_toast,
    gcps_script
  ),
  server = server
)
