# Dashboard Layout Architect
# A Shiny app for designing Power BI dashboard layouts

required_packages <- c("shiny", "bslib", "shinyAce", "shinyjs", "colourpicker", "jsonlite", "htmltools", "stringr")

# Check and install missing packages
missing_packages <- required_packages[!required_packages %in% installed.packages()[, "Package"]]
if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

library(shiny)
library(bslib)
library(shinyAce)
library(shinyjs)
library(colourpicker)
library(jsonlite)
library(htmltools)
library(stringr)

# =============================================================================
# CONSTANTS & DEFAULTS
# =============================================================================

DEFAULT_CONFIG <- list(
  canvas = list(
    width = 1600,
    height = 900
  ),
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
    grid_rows = 3,
    grid_cols = 4,
    grid_gap = 16,
    padding = 20,
    layout_type = "uniform",
    containers_per_row = "2, 2, 2",
    kpi_proportions = NULL,    # e.g., "40, 30, 20, 10"
    row_proportions = NULL,    # e.g., "50, 30, 20"
    col_proportions = NULL     # e.g., "60, 40; 33, 33, 34" (semicolon per row)
  ),
  annotations = list(
    enabled = FALSE
  )
)

# =============================================================================
# GCPS COLOR SYSTEM
# =============================================================================

# Base palette - GCPS brand colors (selectable base colors)
gcps_base <- c(
  maroon  = "#660000",
  blue    = "#2F5FB3",
  teal    = "#007C91",
  green   = "#5E8C31",
  violet = "#6A4CC3",
  orange  = "#D96A1D",
  neutral = "#7A828C"
)

# Neutral colors (for qualitative palettes and diverging centers)
gcps_neutrals <- c(
  light = "#E3E6EA",
  mid   = "#B6BCC4",
  dark  = "#4B525A"
)

# Sequential ramps (5 steps each: light to dark)
gcps_ramps <- list(
  maroon  = c("#DDC7C7", "#BA8C8C", "#944C4C", "#660000", "#540000"),
  blue    = c("#D1DCEE", "#A1B7DD", "#6D8FCA", "#2F5FB3", "#274E93"),
  teal    = c("#C7E2E7", "#8CC4CE", "#4CA3B2", "#007C91", "#006677"),
  green   = c("#DCE6D2", "#B7CBA2", "#8EAE6F", "#5E8C31", "#4D7328"),
  violet  = c("#DED8F2", "#BCAEE4", "#9782D5", "#6A4CC3", "#573EA0"),
  orange  = c("#F7DECD", "#EEBC99", "#E49761", "#D96A1D", "#B25718"),
  neutral = c("#F4F5F7", "#E3E6EA", "#B6BCC4", "#7A828C", "#4B525A")
)

# Diverging palettes for each base color (5 steps: dark -> light center -> dark)
gcps_diverging <- list(
  maroon  = c("#540000", "#944C4C", "#F3F4F6", "#944C4C", "#540000"),
  blue   = c("#274E93", "#6D8FCA", "#F3F4F6", "#6D8FCA", "#274E93"),
  teal   = c("#006677", "#4CA3B2", "#F3F4F6", "#4CA3B2", "#006677"),
  green  = c("#4D7328", "#8EAE6F", "#F3F4F6", "#8EAE6F", "#4D7328"),
  violet = c("#573EA0", "#9782D5", "#F3F4F6", "#9782D5", "#573EA0"),
  orange = c("#B25718", "#E49761", "#F3F4F6", "#E49761", "#B25718"),
  neutral = c("#4B525A", "#7A828C", "#F3F4F6", "#7A828C", "#4B525A")
)

# Qualitative palettes for each base color (8 colors including 2 neutrals)
gcps_qualitative <- list(
  maroon = c("#660000", "#8B2929", "#A64545", "#C06060", "#E3E6EA", "#B6BCC4", "#7A828C", "#4B525A"),
  blue   = c("#2F5FB3", "#4A70BF", "#6581CB", "#8092D7", "#E3E6EA", "#B6BCC4", "#7A828C", "#4B525A"),
  teal   = c("#007C91", "#1A8FA2", "#33A2B3", "#4DB5C4", "#E3E6EA", "#B6BCC4", "#7A828C", "#4B525A"),
  green  = c("#5E8C31", "#6E9A3E", "#7EA84B", "#8EB658", "#E3E6EA", "#B6BCC4", "#7A828C", "#4B525A"),
  violet = c("#6A4CC3", "#7A5EC9", "#8A70CF", "#9A82D5", "#E3E6EA", "#B6BCC4", "#7A828C", "#4B525A"),
  orange = c("#D96A1D", "#E07D2E", "#E7903F", "#EEA350", "#E3E6EA", "#B6BCC4", "#7A828C", "#4B525A"),
  neutral = c("#7A828C", "#8A929C", "#9AA2AC", "#AAB2BC", "#E3E6EA", "#5A626C", "#4B525A", "#3D405B")
)

# Labels for qualitative palettes
gcps_qualitative_labels <- c("Primary", "Light", "Lighter", "Lightest", "Neutral Lt", "Neutral Md", "Neutral Dk", "Neutral Darkest")

# Web-safe font families
font_families <- list(
  `Segoe UI` = list(value = "'Segoe UI', system-ui, -apple-system, sans-serif", category = "Sans-serif"),
  Arial = list(value = "Arial, Helvetica, sans-serif", category = "Sans-serif"),
  `Trebuchet MS` = list(value = "'Trebuchet MS', sans-serif", category = "Sans-serif"),
  Verdana = list(value = "Verdana, Geneva, sans-serif", category = "Sans-serif"),
  Tahoma = list(value = "Tahoma, Geneva, sans-serif", category = "Sans-serif"),
  Georgia = list(value = "Georgia, serif", category = "Serif"),
  `Times New Roman` = list(value = "'Times New Roman', Times, serif", category = "Serif"),
  Consolas = list(value = "Consolas, 'Courier New', monospace", category = "Monospace"),
  `Courier New` = list(value = "'Courier New', Courier, monospace", category = "Monospace")
)

# Font weights
font_weights <- c(
  "Light (300)" = "300",
  "Regular (400)" = "400",
  "Medium (500)" = "500",
  "Semi-Bold (600)" = "600",
  "Bold (700)" = "700"
)

# Helper function to get text color based on background luminance
get_text_color <- function(hex) {
  rgb <- grDevices::col2rgb(hex)
  luminance <- (0.299 * rgb[1, ] + 0.587 * rgb[2, ] + 0.114 * rgb[3, ]) / 255
  ifelse(luminance > 0.62, "#1F2328", "#FFFFFF")
}

# Helper function to generate color swatch HTML
generate_swatch_html <- function(colors, labels = names(colors)) {
  if (is.null(labels)) labels <- colors
  swatches <- mapply(function(col, lab) {
    fg <- get_text_color(col)
    sprintf(
      '<div style="flex:1; min-width:80px; background:%s; color:%s; border-radius:8px; padding:8px; text-align:center; box-shadow: inset 0 0 0 1px rgba(0,0,0,.1);">
        <div style="font-weight:600; font-size:11px;">%s</div>
        <div style="font-family:monospace; font-size:10px; opacity:0.9;">%s</div>
      </div>',
      col, fg, lab, col
    )
  }, colors, labels, SIMPLIFY = FALSE, USE.NAMES = FALSE)
  sprintf('<div style="display:flex; gap:8px; flex-wrap:wrap; margin:8px 0;">%s</div>', paste(swatches, collapse = ""))
}

# Helper function to generate palette preview HTML
generate_palette_preview <- function(base_color_name) {
  if (is.null(base_color_name) || base_color_name == "") return("<p>Select a base color to see the palette</p>")

  # Get the ramp for this color
  ramp <- gcps_ramps[[base_color_name]]
  if (is.null(ramp)) return("<p>No ramp available for this color</p>")

  labels <- c("Lightest", "Light", "Medium", "Dark", "Darkest")
  generate_swatch_html(ramp, labels)
}

# =============================================================================
# PROPORTIONAL SIZING HELPER FUNCTIONS
# =============================================================================

#' Parse proportion string into normalized percentages
#' @param prop_str String like "60, 40" or "50, 30, 20"
#' @param count Expected count (optional, will extend/truncate to match)
#' @return Numeric vector of normalized percentages (sums to 100) or NULL
parse_proportions <- function(prop_str, count = NULL) {
  if (is.null(prop_str) || prop_str == "") return(NULL)
  values <- as.numeric(strsplit(trimws(prop_str), "\\s*,\\s*")[[1]])
  values <- values[!is.na(values)]
  if (length(values) == 0) return(NULL)

  # Normalize to sum to 100
  values <- (values / sum(values)) * 100

  # Handle count mismatch
  if (!is.null(count)) {
    if (length(values) < count) {
      # Extend with equal distribution of remaining percentage
      remaining <- 100 - sum(values)
      extra_count <- count - length(values)
      values <- c(values, rep(remaining / extra_count, extra_count))
    } else if (length(values) > count) {
      # Truncate and renormalize
      values <- values[1:count]
      values <- (values / sum(values)) * 100
    }
  }
  values
}

#' Calculate pixel values from proportions
#' @param total_px Total available pixels
#' @param gap_px Gap between items in pixels
#' @param proportions Normalized percentage vector (optional)
#' @param count Number of items (used when proportions is NULL)
#' @return Numeric vector of pixel widths/heights
calc_pixels_from_proportions <- function(total_px, gap_px, proportions, count) {
  if (is.null(proportions)) {
    # Equal distribution
    return(rep((total_px - gap_px * (count - 1)) / count, count))
  }

  # Proportional distribution
  # Available space after gaps
  available_px <- total_px - gap_px * (count - 1)
  # Convert percentages to pixels
  pixels <- available_px * (proportions / 100)
  pixels
}

#' Parse row-specific column proportions
#' @param prop_str String like "60, 40; 33, 33, 34" (semicolon separates rows)
#' @param containers_per_row Integer vector of containers per row
#' @return List of numeric vectors, one per row
parse_row_proportions <- function(prop_str, containers_per_row) {
  if (is.null(prop_str) || prop_str == "") return(NULL)

  row_strings <- strsplit(trimws(prop_str), ";")[[1]]
  result <- vector("list", length(containers_per_row))

  for (i in seq_along(containers_per_row)) {
    if (i <= length(row_strings)) {
      result[[i]] <- parse_proportions(row_strings[i], containers_per_row[i])
    } else {
      result[[i]] <- NULL
    }
  }
  result
}

# =============================================================================
# CSS GENERATION functions
# =============================================================================

generate_css_variables <- function(config) {
  sprintf("
  :root {
    --bg-page: %s;
    --bg-card: %s;
    --border: %s;
    --text-primary: %s;
    --text-secondary: %s;
    --accent: %s;
    --radius: %s;
    --radius-lg: %s;
    --shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    --shadow-lg: 0 4px 6px rgba(0, 0, 0, 0.1);
  }",
    config$theme$bg_page,
    config$theme$bg_card,
    config$theme$border,
    config$theme$text_primary,
    config$theme$text_secondary,
    config$theme$accent,
    config$theme$radius,
    config$theme$radius_lg
  )
}

generate_base_css <- function(config) {
  sprintf("
  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
    background: var(--bg-page);
    color: var(--text-primary);
  }

  .dashboard-container {
    position: relative;
    width: %dpx;
    height: %dpx;
    background: var(--bg-page);
    overflow: hidden;
  }",
    config$canvas$width,
    config$canvas$height
  )
}

generate_header_css <- function(config) {
  sprintf("
  /* Header */
  .header {
    position: absolute;
    top: 0;
    left: 0;
    width: %dpx;
    height: %dpx;
    background: var(--bg-card);
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 %dpx;
    z-index: 100;
  }

  .header-logo {
    width: %dpx;
    height: %dpx;
    background: linear-gradient(135deg, var(--accent) 0%%, #00796B 100%%);
    border-radius: var(--radius);
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-weight: 600;
    font-size: 14px;
  }
  .header-nav {
    display: flex;
    gap: 12px;
  }
  .header-nav-btn {
    width: 36px;
    height: 36px;
    background: var(--bg-page);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-secondary);
    font-size: 12px;
  }
  .header-nav-btn.active {
    background: var(--accent);
    border-color: var(--accent);
    color: white;
  }",
    config$canvas$width,
    config$header$height,
    config$header$padding,
    config$header$logo_width,
    config$header$logo_height
  )
}

generate_sidebar_css <- function(config) {
  main_height <- config$canvas$height - config$header$height

  sprintf("
  /* Sidebar */
  .sidebar {
    position: absolute;
    top: %dpx;
    left: 0;
    width: %dpx;
    height: %dpx;
    background: var(--bg-card);
    border-right: 1px solid var(--border);
    padding: %dpx;
    overflow-y: auto;
  }
  .sidebar-section {
    margin-bottom: 20px;
  }
  .sidebar-section-title {
    font-size: 11px;
    font-weight: 600;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 12px;
  }
  .sidebar-nav-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 10px 12px;
    border-radius: var(--radius);
    color: var(--text-primary);
    font-size: 14px;
    cursor: pointer;
    transition: background 0.2s;
    margin-bottom: 4px;
  }
  .sidebar-nav-item:hover {
    background: var(--bg-page);
  }
  .sidebar-nav-item.active {
    background: rgba(0, 151, 167, 0.1);
    color: var(--accent);
    font-weight: 500;
  }
  .sidebar-nav-icon {
    width: 20px;
    height: 20px;
    background: var(--bg-page);
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 10px;
    color: var(--text-secondary);
  }
  .sidebar-nav-item.active .sidebar-nav-icon {
    background: var(--accent);
    color: white;
  }",
    config$header$height,
    config$sidebar$width,
    main_height,
    config$sidebar$padding
  )
}

generate_content_css <- function(config) {
  main_left <- config$sidebar$width
  main_top <- config$header$height
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2
  sprintf("
  /* Main Content */
  .main-content {
    position: absolute;
    top: %dpx;
    left: %dpx;
    width: %dpx;
    height: %dpx;
    padding: %dpx;
    overflow: hidden;
  }
  /* KPI Cards */
  .kpi-container {
    display: flex;
    gap: %dpx;
    margin-bottom: %dpx;
    height: %dpx;
  }
  .kpi-card {
    flex: 1;
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 16px;
    display: flex;
    flex-direction: column;
    justify-content: center;
    position: relative;
  }
  .kpi-label {
    font-size: 12px;
    color: var(--text-secondary);
    margin-bottom: 4px;
  }
  .kpi-value {
    font-size: 28px;
    font-weight: 700;
    color: var(--text-primary);
  }
  .kpi-change {
    font-size: 12px;
    margin-top: 4px;
  }
  .kpi-change.positive {
    color: #10B981;
  }
  .kpi-change.negative {
    color: #EF4444;
  }
  /* Content Grid */
  .content-grid {
    position: relative;
    height: %dpx;
  }
  .grid-card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 16px;
    display: flex;
    flex-direction: column;
    position: absolute;
  }
  .grid-card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
  }
  .grid-card-title {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
  }
  .grid-card-content {
    flex: 1;
    background: var(--bg-page);
    border-radius: var(--radius);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-secondary);
    font-size: 12px;
  }",
    main_top,
    main_left,
    main_width,
    main_height,
    config$content$padding,
    config$content$kpi_gap,
    config$content$kpi_gap,
    config$content$kpi_height,
    content_height
  )
}

generate_annotation_css <- function(config) {
  if (!config$annotations$enabled) return("")
  sprintf("
  /* Dimension Badges */
  .dimension-badge {
    position: absolute;
    background: rgba(0, 0, 0, 0.75);
    color: white;
    font-size: 10px;
    font-family: 'Consolas', 'Monaco', monospace;
    padding: 2px 6px;
    border-radius: 4px;
    pointer-events: none;
    z-index: 1000;
    white-space: nowrap;
    top: 4px;
    right: 4px;
  }"
  )
}

generate_css <- function(config) {
  paste0(
    generate_css_variables(config),
    generate_base_css(config),
    generate_header_css(config),
    generate_sidebar_css(config),
    generate_content_css(config),
    generate_annotation_css(config)
  )
}
# =============================================================================
# HTML BUILDER FUNCTIONS
# =============================================================================
build_header_html <- function(config) {
  nav_buttons_html <- paste(rep('<div class="header-nav-btn"></div>', config$header$nav_button_count), collapse = "\n    ")
  badge_html <- if (config$annotations$enabled) {
    sprintf('\n    <span class="dimension-badge">%dx%d</span>', config$canvas$width, config$header$height)
  } else {
    ""
  }
  sprintf('
  <div class="header">
    <div class="header-logo">LOGO</div>
    <div class="header-nav">
    %s
    </div>%s
  </div>',
    nav_buttons_html,
    badge_html
  )
}
build_sidebar_html <- function(config) {
  nav_items_html <- paste(sapply(1:config$sidebar$nav_item_count, function(i) {
    sprintf('      <div class="sidebar-nav-item%s">
        <div class="sidebar-nav-icon">%d</div>
        <span>Navigation Item</span>
      </div>', ifelse(i == 1, " active", ""), i)
  }), collapse = "\n")
  main_height <- config$canvas$height - config$header$height
  badge_html <- if (config$annotations$enabled) {
    sprintf('\n    <span class="dimension-badge">%dx%d</span>', config$sidebar$width, main_height)
  } else {
    ""
  }
  sprintf('
  <div class="sidebar">%s
    <div class="sidebar-section">
      <div class="sidebar-section-title">Navigation</div>
%s
    </div>
  </div>',
    badge_html,
    nav_items_html
  )
}
build_kpi_html <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  total_available <- main_width - config$content$padding * 2

  # Parse proportions if provided
  kpi_proportions <- parse_proportions(config$content$kpi_proportions, config$content$kpi_count)
  kpi_widths <- calc_pixels_from_proportions(total_available, config$content$kpi_gap, kpi_proportions, config$content$kpi_count)

  kpi_cards <- paste(sapply(1:config$content$kpi_count, function(i) {
    kpi_width <- kpi_widths[i]
    badge_html <- if (config$annotations$enabled) {
      sprintf('\n      <span class="dimension-badge">%.0fx%d</span>', kpi_width, config$content$kpi_height)
    } else {
      ""
    }
    # Use inline style with flex: none to override CSS flex: 1
    sprintf('    <div class="kpi-card" style="flex: none; width: %.0fpx;">%s
      <div class="kpi-label">KPI Metric %d</div>
      <div class="kpi-value">%d</div>
      <div class="kpi-change positive">+%.1f%%</div>
    </div>',
      kpi_width,
      badge_html,
      i,
      sample(1000:9999, 1),
      runif(1, 1, 15)
    )
  }), collapse = "\n")
  kpi_cards
}
build_grid_html <- function(config) {
  total_cells <- config$content$grid_rows * config$content$grid_cols
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2

  # Get containers per row based on layout type
  containers_per_row <- get_containers_per_row(config)
  num_rows <- length(containers_per_row)

  # Parse row proportions if provided
  row_proportions <- parse_proportions(config$content$row_proportions, num_rows)
  row_heights <- calc_pixels_from_proportions(content_height, config$content$grid_gap, row_proportions, num_rows)

  # Parse column proportions per row if provided
  col_proportions_list <- parse_row_proportions(config$content$col_proportions, containers_per_row)

  grid_cards <- ""
  cell_index <- 1
  y_offset <- 0

  for (row in 1:num_rows) {
    cols_in_row <- containers_per_row[row]
    row_height <- row_heights[row]

    # Get column widths for this row
    total_width_available <- main_width - config$content$padding * 2
    col_props <- col_proportions_list[[row]]
    col_widths <- calc_pixels_from_proportions(total_width_available, config$content$grid_gap, col_props, cols_in_row)

    x_offset <- 0

    for (col in 1:cols_in_row) {
      cell_width <- col_widths[col]
      # Position relative to .content-grid (which has position: relative)
      x_pos <- x_offset
      y_pos <- y_offset

      badge_html <- if (config$annotations$enabled) {
        sprintf('<span class="dimension-badge">%.0fx%.0f</span>', cell_width, row_height)
      } else {
        ""
      }

      grid_cards <- paste0(grid_cards, sprintf('    <div class="grid-card" style="position: absolute; left: %.0fpx; top: %.0fpx; width: %.0fpx; height: %.0fpx;">
      %s
      <div class="grid-card-header">
        <span class="grid-card-title">Chart %d</span>
      </div>
      <div class="grid-card-content">Visual Placeholder</div>
    </div>
',
        x_pos, y_pos, cell_width, row_height,
        badge_html,
        cell_index
      ))
      cell_index <- cell_index + 1
      x_offset <- x_offset + cell_width + config$content$grid_gap
    }
    y_offset <- y_offset + row_height + config$content$grid_gap
  }
  grid_cards
}

# Helper function to get containers per row
get_containers_per_row <- function(config) {
  layout_type <- config$content$layout_type %||% "uniform"

  if (layout_type == "uniform") {
    return(rep(config$content$grid_cols, config$content$grid_rows))
  } else if (layout_type == "custom") {
    containers_str <- config$content$containers_per_row %||% "2, 2, 2"
    containers <- as.integer(strsplit(containers_str, ",")[[1]])
    return(containers[!is.na(containers)])
  } else {
    # Numeric layout type
    cols_per_row <- as.integer(layout_type)
    total <- config$content$grid_rows * config$content$grid_cols
    rows <- ceiling(total / cols_per_row)
    return(rep(cols_per_row, rows))
  }
}
build_content_html <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  badge_html <- if (config$annotations$enabled) {
    sprintf('\n    <span class="dimension-badge">%dx%d</span>', main_width, main_height)
  } else {
    ""
  }
  sprintf('
  <div class="main-content">%s
    <div class="kpi-container">
%s
    </div>
    <div class="content-grid">
%s
    </div>
  </div>',
    badge_html,
    build_kpi_html(config),
    build_grid_html(config)
  )
}

# =============================================================================
# BLANK VERSION BUILDERS (empty containers for Power BI templates)
# =============================================================================
build_header_html_blank <- function(config) {
  sprintf('
  <div class="header">
    <div class="header-logo"></div>
    <div class="header-nav">
    %s
    </div>
  </div>',
    paste(rep('<div class="header-nav-btn"></div>', config$header$nav_button_count), collapse = "\n    ")
  )
}

build_sidebar_html_blank <- function(config) {
  nav_items_html <- paste(rep('      <div class="sidebar-nav-item">\n        <div class="sidebar-nav-icon"></div>\n        <span></span>\n      </div>', config$sidebar$nav_item_count), collapse = "\n")
  sprintf('
  <div class="sidebar">
    <div class="sidebar-section">
      <div class="sidebar-section-title"></div>
%s
    </div>
  </div>',
    nav_items_html
  )
}

build_kpi_html_blank <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  total_available <- main_width - config$content$padding * 2

  # Parse proportions if provided
  kpi_proportions <- parse_proportions(config$content$kpi_proportions, config$content$kpi_count)
  kpi_widths <- calc_pixels_from_proportions(total_available, config$content$kpi_gap, kpi_proportions, config$content$kpi_count)

  kpi_cards <- paste(sapply(1:config$content$kpi_count, function(i) {
    kpi_width <- kpi_widths[i]
    sprintf('    <div class="kpi-card" style="flex: none; width: %.0fpx;">\n    </div>', kpi_width)
  }), collapse = "\n")
  kpi_cards
}

build_grid_html_blank <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2

  containers_per_row <- get_containers_per_row(config)
  num_rows <- length(containers_per_row)

  # Parse row proportions if provided
  row_proportions <- parse_proportions(config$content$row_proportions, num_rows)
  row_heights <- calc_pixels_from_proportions(content_height, config$content$grid_gap, row_proportions, num_rows)

  # Parse column proportions per row if provided
  col_proportions_list <- parse_row_proportions(config$content$col_proportions, containers_per_row)

  grid_cards <- ""
  cell_index <- 1
  y_offset <- 0

  for (row in 1:num_rows) {
    cols_in_row <- containers_per_row[row]
    row_height <- row_heights[row]

    # Get column widths for this row
    total_width_available <- main_width - config$content$padding * 2
    col_props <- col_proportions_list[[row]]
    col_widths <- calc_pixels_from_proportions(total_width_available, config$content$grid_gap, col_props, cols_in_row)

    x_offset <- 0

    for (col in 1:cols_in_row) {
      cell_width <- col_widths[col]
      # Position relative to .content-grid (which has position: relative)
      x_pos <- x_offset
      y_pos <- y_offset

      grid_cards <- paste0(grid_cards, sprintf('    <div class="grid-card" style="position: absolute; left: %.0fpx; top: %.0fpx; width: %.0fpx; height: %.0fpx;">
      <div class="grid-card-content"></div>
    </div>
',
        x_pos, y_pos, cell_width, row_height
      ))
      cell_index <- cell_index + 1
      x_offset <- x_offset + cell_width + config$content$grid_gap
    }
    y_offset <- y_offset + row_height + config$content$grid_gap
  }
  grid_cards
}

build_content_html_blank <- function(config) {
  sprintf('
  <div class="main-content">
    <div class="kpi-container">
%s
    </div>
    <div class="content-grid">
%s
    </div>
  </div>',
    build_kpi_html_blank(config),
    build_grid_html_blank(config)
  )
}

# =============================================================================
# ANNOTATED VERSION BUILDERS (containers with dimension labels)
# =============================================================================
build_header_html_annotated <- function(config) {
  radius <- gsub("px", "", config$theme$radius)
  sprintf('
  <div class="header">
    <span class="dimension-badge-full">%dx%d @ (0, 0)</span>
    <div class="header-logo"><span class="dimension-badge-full">%dx%d r%s</span></div>
    <div class="header-nav">
    %s
    </div>
  </div>',
    config$canvas$width, config$header$height,
    config$header$logo_width, config$header$logo_height, radius,
    paste(rep('<div class="header-nav-btn"><span class="dimension-badge-small">36x36</span></div>', config$header$nav_button_count), collapse = "\n    ")
  )
}

build_sidebar_html_annotated <- function(config) {
  main_height <- config$canvas$height - config$header$height
  radius <- gsub("px", "", config$theme$radius)
  nav_items_html <- paste(sapply(1:config$sidebar$nav_item_count, function(i) {
    y_pos <- config$header$height + 45 + (i - 1) * 44
    item_width <- config$sidebar$width - config$sidebar$padding * 2
    sprintf('      <div class="sidebar-nav-item">
        <span class="dimension-badge-full">%dx40 @ (%d, %d) r%s</span>
        <div class="sidebar-nav-icon"></div>
        <span>Nav Item %d</span>
      </div>', item_width, config$sidebar$padding, y_pos, radius, i)
  }), collapse = "\n")

  sprintf('
  <div class="sidebar">
    <span class="dimension-badge-full">%dx%d @ (0, %d)</span>
    <div class="sidebar-section">
      <div class="sidebar-section-title">Navigation</div>
%s
    </div>
  </div>',
    config$sidebar$width, main_height, config$header$height,
    nav_items_html
  )
}

build_kpi_html_annotated <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  total_available <- main_width - config$content$padding * 2
  y_pos <- config$header$height + config$content$padding
  radius_lg <- gsub("px", "", config$theme$radius_lg)

  # Parse proportions if provided
  kpi_proportions <- parse_proportions(config$content$kpi_proportions, config$content$kpi_count)
  kpi_widths <- calc_pixels_from_proportions(total_available, config$content$kpi_gap, kpi_proportions, config$content$kpi_count)

  x_offset <- 0
  paste(sapply(1:config$content$kpi_count, function(i) {
    kpi_width <- kpi_widths[i]
    x_pos <- config$sidebar$width + config$content$padding + x_offset
    x_offset <<- x_offset + kpi_width + config$content$kpi_gap
    sprintf('    <div class="kpi-card" style="flex: none; width: %.0fpx;">
      <span class="dimension-badge-full">%.0fx%d @ (%.0f, %d) r%s</span>
    </div>', kpi_width, kpi_width, config$content$kpi_height, x_pos, y_pos, radius_lg)
  }), collapse = "\n")
}

build_grid_html_annotated <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2

  containers_per_row <- get_containers_per_row(config)
  num_rows <- length(containers_per_row)
  radius_lg <- gsub("px", "", config$theme$radius_lg)

  # Parse row proportions if provided
  row_proportions <- parse_proportions(config$content$row_proportions, num_rows)
  row_heights <- calc_pixels_from_proportions(content_height, config$content$grid_gap, row_proportions, num_rows)

  # Parse column proportions per row if provided
  col_proportions_list <- parse_row_proportions(config$content$col_proportions, containers_per_row)

  grid_cards <- ""
  cell_index <- 1
  y_offset <- 0

  for (row in 1:num_rows) {
    cols_in_row <- containers_per_row[row]
    row_height <- row_heights[row]

    # Get column widths for this row
    total_width_available <- main_width - config$content$padding * 2
    col_props <- col_proportions_list[[row]]
    col_widths <- calc_pixels_from_proportions(total_width_available, config$content$grid_gap, col_props, cols_in_row)

    x_offset <- 0

    for (col in 1:cols_in_row) {
      cell_width <- col_widths[col]
      # Position relative to .content-grid (which has position: relative)
      x_pos <- x_offset
      y_pos <- y_offset

      # Calculate absolute canvas position for annotation display
      abs_x <- config$sidebar$width + config$content$padding + x_offset
      abs_y <- config$header$height + config$content$padding + config$content$kpi_height + config$content$kpi_gap + y_offset

      # Create detailed annotation with shape settings (showing absolute canvas position)
      annotation_text <- sprintf("%.0fx%.0f @ (%.0f, %.0f) r%s", cell_width, row_height, abs_x, abs_y, radius_lg)

      grid_cards <- paste0(grid_cards, sprintf('    <div class="grid-card" style="position: absolute; left: %.0fpx; top: %.0fpx; width: %.0fpx; height: %.0fpx;">
      <span class="dimension-badge-full">%s</span>
      <div class="grid-card-content"></div>
    </div>
',
        x_pos, y_pos, cell_width, row_height,
        annotation_text
      ))
      cell_index <- cell_index + 1
      x_offset <- x_offset + cell_width + config$content$grid_gap
    }
    y_offset <- y_offset + row_height + config$content$grid_gap
  }
  grid_cards
}

build_content_html_annotated <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  sprintf('
  <div class="main-content">
    <span class="dimension-badge-full">%dx%d @ (%d, %d)</span>
    <div class="kpi-container">
%s
    </div>
    <div class="content-grid">
%s
    </div>
  </div>',
    main_width, main_height, config$sidebar$width, config$header$height,
    build_kpi_html_annotated(config),
    build_grid_html_annotated(config)
  )
}

# =============================================================================
# MASTER HTML GENERATOR (routes to appropriate version)
# =============================================================================
generate_html <- function(config, include_css = TRUE, view_mode = "example") {
  css <- if (include_css) sprintf("<style>\n%s\n%s\n</style>", generate_css(config), generate_annotation_css_extended(config)) else ""

  # Select appropriate builders based on view_mode
  if (view_mode == "blank") {
    header_html <- build_header_html_blank(config)
    sidebar_html <- build_sidebar_html_blank(config)
    content_html <- build_content_html_blank(config)
  } else if (view_mode == "annotated") {
    header_html <- build_header_html_annotated(config)
    sidebar_html <- build_sidebar_html_annotated(config)
    content_html <- build_content_html_annotated(config)
  } else {
    # Default: example mode
    header_html <- build_header_html(config)
    sidebar_html <- build_sidebar_html(config)
    content_html <- build_content_html(config)
  }

  sprintf('<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard Layout</title>
%s
</head>
<body>
<div class="dashboard-container">
%s
%s
%s
</div>
</body>
</html>',
    css,
    header_html,
    sidebar_html,
    content_html
  )
}

# Extended annotation CSS for full dimension labels
generate_annotation_css_extended <- function(config) {
  if (config$annotations$enabled || TRUE) {
    "
    .dimension-badge-full {
      position: absolute;
      top: 4px;
      right: 4px;
      background: rgba(0, 121, 107, 0.9);
      color: white;
      font-size: 9px;
      font-family: 'Consolas', 'Monaco', monospace;
      padding: 4px 8px;
      border-radius: 4px;
      pointer-events: none;
      z-index: 1000;
      white-space: nowrap;
      line-height: 1.4;
      max-width: calc(100% - 8px);
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .dimension-badge-small {
      position: absolute;
      top: 2px;
      left: 2px;
      background: rgba(0, 0, 0, 0.6);
      color: white;
      font-size: 8px;
      font-family: 'Consolas', 'Monaco', monospace;
      padding: 1px 3px;
      border-radius: 2px;
      pointer-events: none;
      z-index: 1000;
    }
    .kpi-card, .grid-card, .header-logo, .sidebar-nav-item, .header-nav-btn {
      position: relative;
    }
    "
  } else {
    ""
  }
}

generate_html_original <- function(config, include_css = TRUE) {
  css <- if (include_css) sprintf("<style>\n%s\n</style>", generate_css(config)) else ""
  sprintf('<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard Layout</title>
%s
</head>
<body>
<div class="dashboard-container">
%s
%s
%s
</div>
</body>
</html>',
    css,
    build_header_html(config),
    build_sidebar_html(config),
    build_content_html(config)
  )
}
# Generate Power BI compatible CSS (no comments, numeric radius)
generate_powerbi_css <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2
  # Extract numeric radius values (remove 'px' suffix if present)
  radius_num <- as.numeric(gsub("px", "", config$theme$radius))
  radius_lg_num <- as.numeric(gsub("px", "", config$theme$radius_lg))
  sprintf("
    :root {
        --bg-page: %s;
        --bg-card: %s;
        --border: %s;
        --text-primary: %s;
        --text-secondary: %s;
        --accent: %s;
        --radius: %d;
        --radius-lg: %d;
        --shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        --shadow-lg: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
    }
    body {
        font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
        background: var(--bg-page);
        color: var(--text-primary);
    }
    .dashboard-container {
        position: relative;
        width: %dpx;
        height: %dpx;
        background: var(--bg-page);
        overflow: hidden;
    }
    .header {
        position: absolute;
        top: 0;
        left: 0;
        width: %dpx;
        height: %dpx;
        background: var(--bg-card);
        border-bottom: 1px solid var(--border);
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 %dpx;
        z-index: 100;
    }
    .header-logo {
        width: %dpx;
        height: %dpx;
        background: linear-gradient(135deg, var(--accent) 0%%, #00796B 100%%);
        border-radius: var(--radius);
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-weight: 600;
        font-size: 14px;
    }
    .header-nav {
        display: flex;
        gap: 12px;
    }
    .header-nav-btn {
        width: 36px;
        height: 36px;
        background: var(--bg-page);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--text-secondary);
        font-size: 12px;
    }
    .header-nav-btn.active {
        background: var(--accent);
        border-color: var(--accent);
        color: white;
    }
    .sidebar {
        position: absolute;
        top: %dpx;
        left: 0;
        width: %dpx;
        height: %dpx;
        background: var(--bg-card);
        border-right: 1px solid var(--border);
        padding: %dpx;
        overflow-y: auto;
    }
    .sidebar-section {
        margin-bottom: 20px;
    }
    .sidebar-section-title {
        font-size: 11px;
        font-weight: 600;
        color: var(--text-secondary);
        text-transform: uppercase;
        letter-spacing: 0.5px;
        margin-bottom: 12px;
    }
    .sidebar-nav-item {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 10px 12px;
        border-radius: var(--radius);
        color: var(--text-primary);
        font-size: 14px;
        cursor: pointer;
        transition: background 0.2s;
        margin-bottom: 4px;
    }
    .sidebar-nav-item:hover {
        background: var(--bg-page);
    }
    .sidebar-nav-item.active {
        background: rgba(0, 151, 167, 0.1);
        color: var(--accent);
        font-weight: 500;
    }
    .sidebar-nav-icon {
        width: 20px;
        height: 20px;
        background: var(--bg-page);
        border-radius: 4px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 10px;
        color: var(--text-secondary);
    }
    .sidebar-nav-item.active .sidebar-nav-icon {
        background: var(--accent);
        color: white;
    }
    .main-content {
        position: absolute;
        top: %dpx;
        left: %dpx;
        width: %dpx;
        height: %dpx;
        padding: %dpx;
        overflow: hidden;
    }
    .kpi-container {
        display: flex;
        gap: %dpx;
        margin-bottom: %dpx;
        height: %dpx;
    }
    .kpi-card {
        flex: 1;
        background: var(--bg-card);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        padding: 16px;
        display: flex;
        flex-direction: column;
        justify-content: center;
        position: relative;
    }
    .kpi-label {
        font-size: 12px;
        color: var(--text-secondary);
        margin-bottom: 4px;
    }
    .kpi-value {
        font-size: 28px;
        font-weight: 700;
        color: var(--text-primary);
    }
    .kpi-change {
        font-size: 12px;
        margin-top: 4px;
    }
    .kpi-change.positive {
        color: #10B981;
    }
    .kpi-change.negative {
        color: #EF4444;
    }
    .content-grid {
        position: relative;
        height: %dpx;
    }
    .grid-card {
        background: var(--bg-card);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        padding: 16px;
        display: flex;
        flex-direction: column;
        position: absolute;
    }
    .grid-card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 12px;
    }
    .grid-card-title {
        font-size: 14px;
        font-weight: 600;
        color: var(--text-primary);
    }
    .grid-card-content {
        flex: 1;
        background: var(--bg-page);
        border-radius: var(--radius);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--text-secondary);
        font-size: 12px;
    }",
    config$theme$bg_page,
    config$theme$bg_card,
    config$theme$border,
    config$theme$text_primary,
    config$theme$text_secondary,
    config$theme$accent,
    radius_num,
    radius_lg_num,
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
# Generate Power BI compatible HTML (no full document structure)
generate_powerbi_html <- function(config, single_line = FALSE) {
  css <- generate_powerbi_css(config)
  html_content <- sprintf('<style>%s</style>
<div class="dashboard-container">
%s
%s
%s
</div>',
    css,
    build_header_html(config),
    build_sidebar_html(config),
    build_content_html(config)
  )
  if (single_line) {
    # Minify for DAX - remove newlines and extra spaces
    html_content <- str_replace_all(html_content, "\n\\s*", " ")
    html_content <- str_replace_all(html_content, "\\s+", " ")
    html_content <- str_trim(html_content)
  }
  html_content
}
# Generate SVG from dashboard config
generate_svg_from_html <- function(config, view_mode = "example") {
  # Route to appropriate SVG generator based on view_mode
  if (view_mode == "blank") {
    return(generate_svg_blank(config))
  } else if (view_mode == "annotated") {
    return(generate_svg_annotated(config))
  } else {
    return(generate_svg_example(config))
  }
}

# Generate SVG for example mode (with content)
generate_svg_example <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2

  # Extract numeric values
  radius <- as.numeric(gsub("px", "", config$theme$radius))
  radius_lg <- as.numeric(gsub("px", "", config$theme$radius_lg))

  # Build SVG content
  sprintf('<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">
  <defs>
    <style>
      .header-text { font-family: Segoe UI, system-ui, sans-serif; font-weight: 600; fill: white; font-size: 14px; }
      .nav-text { font-family: Segoe UI, system-ui, sans-serif; font-size: 12px; fill: %s; }
      .nav-text-active { font-family: Segoe UI, system-ui, sans-serif; font-size: 14px; fill: %s; font-weight: 500; }
      .section-title { font-family: Segoe UI, system-ui, sans-serif; font-size: 11px; fill: %s; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
      .kpi-label { font-family: Segoe UI, system-ui, sans-serif; font-size: 12px; fill: %s; }
      .kpi-value { font-family: Segoe UI, system-ui, sans-serif; font-size: 28px; fill: %s; font-weight: 700; }
      .kpi-change { font-family: Segoe UI, system-ui, sans-serif; font-size: 12px; fill: #10B981; }
      .card-title { font-family: Segoe UI, system-ui, sans-serif; font-size: 14px; fill: %s; font-weight: 600; }
      .card-content { font-family: Segoe UI, system-ui, sans-serif; font-size: 12px; fill: %s; }
    </style>
    <linearGradient id="logoGradient" x1="0%%" y1="0%%" x2="100%%" y2="100%%">
      <stop offset="0%%" style="stop-color:%s"/>
      <stop offset="100%%" style="stop-color:#00796B"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="%d" height="%d" fill="%s"/>

  <!-- Header -->
  <rect x="0" y="0" width="%d" height="%d" fill="%s"/>
  <line x1="0" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>
  <rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="url(#logoGradient)"/>
  <text x="%d" y="%d" class="header-text" text-anchor="middle" dominant-baseline="middle">LOGO</text>

  <!-- Header Nav Buttons -->
  %s

  <!-- Sidebar -->
  <rect x="0" y="%d" width="%d" height="%d" fill="%s"/>
  <line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>
  <text x="%d" y="%d" class="section-title">NAVIGATION</text>
  %s

  <!-- Main Content Area -->
  <rect x="%d" y="%d" width="%d" height="%d" fill="none"/>

  <!-- KPI Cards -->
  %s

  <!-- Content Grid -->
  %s
</svg>',
    config$canvas$width, config$canvas$height, config$canvas$width, config$canvas$height,
    # Style colors
    config$theme$text_secondary,
    config$theme$text_primary,
    config$theme$text_secondary,
    config$theme$text_secondary,
    config$theme$text_primary,
    config$theme$text_primary,
    config$theme$text_secondary,
    config$theme$accent,
    # Background
    config$canvas$width, config$canvas$height, config$theme$bg_page,
    # Header
    config$canvas$width, config$header$height, config$theme$bg_card,
    config$header$height, config$canvas$width, config$header$height, config$theme$border,
    config$header$padding, (config$header$height - config$header$logo_height) / 2,
    config$header$logo_width, config$header$logo_height, radius,
    config$header$padding + config$header$logo_width / 2, config$header$height / 2,
    # Nav buttons
    generate_svg_nav_buttons(config),
    # Sidebar
    config$header$height, config$sidebar$width, main_height, config$theme$bg_card,
    config$sidebar$width, config$header$height, config$sidebar$width, config$header$height + main_height, config$theme$border,
    config$sidebar$padding, config$header$height + config$sidebar$padding + 20,
    # Nav items
    generate_svg_nav_items(config),
    # Main content
    config$sidebar$width, config$header$height, main_width, main_height,
    # KPI cards
    generate_svg_kpi_cards(config),
    # Grid cards
    generate_svg_grid_cards(config)
  )
}

# Helper: Generate SVG nav buttons
generate_svg_nav_buttons <- function(config) {
  radius <- as.numeric(gsub("px", "", config$theme$radius))
  buttons <- ""
  start_x <- config$canvas$width - config$header$padding - (config$header$nav_button_count * 48)
  for (i in 1:config$header$nav_button_count) {
    x <- start_x + (i - 1) * 48
    fill <- if (i == 1) config$theme$accent else config$theme$bg_page
    stroke <- if (i == 1) config$theme$accent else config$theme$border
    buttons <- paste0(buttons, sprintf(
      '<rect x="%d" y="%d" width="36" height="36" rx="%d" fill="%s" stroke="%s" stroke-width="1"/>',
      x, (config$header$height - 36) / 2, radius, fill, stroke
    ))
  }
  buttons
}

# Helper: Generate SVG nav items
generate_svg_nav_items <- function(config) {
  radius <- as.numeric(gsub("px", "", config$theme$radius))
  items <- ""
  y_start <- config$header$height + config$sidebar$padding + 45
  for (i in 1:config$sidebar$nav_item_count) {
    y <- y_start + (i - 1) * 44
    is_active <- i == 1
    bg_fill <- if (is_active) paste0(config$theme$accent, "1A") else "transparent"
    text_class <- if (is_active) "nav-text-active" else "nav-text"

    items <- paste0(items, sprintf(
      '<rect x="%d" y="%d" width="%d" height="40" rx="%d" fill="%s"/>
      <rect x="%d" y="%d" width="20" height="20" rx="4" fill="%s"/>
      <text x="%d" y="%d" class="%s">%s</text>',
      config$sidebar$padding, y, config$sidebar$width - config$sidebar$padding * 2, radius, bg_fill,
      config$sidebar$padding + 12, y + 10, if (is_active) config$theme$accent else config$theme$bg_page,
      config$sidebar$padding + 44, y + 20, text_class, "Navigation Item"
    ))
  }
  items
}

# Helper: Generate SVG KPI cards
generate_svg_kpi_cards <- function(config) {
  radius_lg <- as.numeric(gsub("px", "", config$theme$radius_lg))
  main_width <- config$canvas$width - config$sidebar$width
  kpi_width <- (main_width - config$content$padding * 2 - config$content$kpi_gap * (config$content$kpi_count - 1)) / config$content$kpi_count

  cards <- ""
  for (i in 1:config$content$kpi_count) {
    x <- config$sidebar$width + config$content$padding + (i - 1) * (kpi_width + config$content$kpi_gap)
    y <- config$header$height + config$content$padding

    cards <- paste0(cards, sprintf(
      '<rect x="%d" y="%d" width="%.0f" height="%d" rx="%d" fill="%s" stroke="%s" stroke-width="1"/>
      <text x="%d" y="%d" class="kpi-label">KPI Metric %d</text>
      <text x="%d" y="%d" class="kpi-value">%d</text>
      <text x="%d" y="%d" class="kpi-change">+%.1f%%</text>',
      x, y, kpi_width, config$content$kpi_height, radius_lg, config$theme$bg_card, config$theme$border,
      x + 16, y + 30, i,
      x + 16, y + 65, sample(1000:9999, 1),
      x + 16, y + 88, runif(1, 1, 15)
    ))
  }
  cards
}

# Helper: Generate SVG grid cards
generate_svg_grid_cards <- function(config) {
  radius <- as.numeric(gsub("px", "", config$theme$radius))
  radius_lg <- as.numeric(gsub("px", "", config$theme$radius_lg))
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2

  cell_width <- (main_width - config$content$padding * 2 - config$content$grid_gap * (config$content$grid_cols - 1)) / config$content$grid_cols
  cell_height <- (content_height - config$content$grid_gap * (config$content$grid_rows - 1)) / config$content$grid_rows

  cards <- ""
  for (row in 1:config$content$grid_rows) {
    for (col in 1:config$content$grid_cols) {
      i <- (row - 1) * config$content$grid_cols + col
      x <- config$sidebar$width + config$content$padding + (col - 1) * (cell_width + config$content$grid_gap)
      y <- config$header$height + config$content$padding + config$content$kpi_height + config$content$kpi_gap + (row - 1) * (cell_height + config$content$grid_gap)

      cards <- paste0(cards, sprintf(
        '<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" rx="%d" fill="%s" stroke="%s" stroke-width="1"/>
        <text x="%.0f" y="%.0f" class="card-title">Chart %d</text>
        <rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" rx="%d" fill="%s"/>
        <text x="%.0f" y="%.0f" class="card-content" text-anchor="middle">Visual Placeholder</text>',
        x, y, cell_width, cell_height, radius_lg, config$theme$bg_card, config$theme$border,
        x + 16, y + 24, i,
        x + 16, y + 40, cell_width - 32, cell_height - 56, radius, config$theme$bg_page,
        x + cell_width / 2, y + 40 + (cell_height - 56) / 2
      ))
    }
  }
  cards
}

# Generate SVG for blank mode (empty containers)
generate_svg_blank <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2

  radius <- as.numeric(gsub("px", "", config$theme$radius))
  radius_lg <- as.numeric(gsub("px", "", config$theme$radius_lg))

  sprintf('<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">
  <defs>
    <style>
      .header-text { font-family: Segoe UI, system-ui, sans-serif; font-weight: 600; fill: white; font-size: 14px; }
    </style>
    <linearGradient id="logoGradient" x1="0%%" y1="0%%" x2="100%%" y2="100%%">
      <stop offset="0%%" style="stop-color:%s"/>
      <stop offset="100%%" style="stop-color:#00796B"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="%d" height="%d" fill="%s"/>

  <!-- Header -->
  <rect x="0" y="0" width="%d" height="%d" fill="%s"/>
  <line x1="0" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>
  <rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="url(#logoGradient)"/>

  <!-- Header Nav Buttons (blank) -->
  %s

  <!-- Sidebar -->
  <rect x="0" y="%d" width="%d" height="%d" fill="%s"/>
  <line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>
  %s

  <!-- Main Content Area -->
  <rect x="%d" y="%d" width="%d" height="%d" fill="none"/>

  <!-- KPI Cards (blank) -->
  %s

  <!-- Content Grid (blank) -->
  %s
</svg>',
    config$canvas$width, config$canvas$height, config$canvas$width, config$canvas$height,
    config$theme$accent,
    config$canvas$width, config$canvas$height, config$theme$bg_page,
    config$canvas$width, config$header$height, config$theme$bg_card,
    config$header$height, config$canvas$width, config$header$height, config$theme$border,
    config$header$padding, (config$header$height - config$header$logo_height) / 2,
    config$header$logo_width, config$header$logo_height, radius,
    generate_svg_nav_buttons_blank(config),
    config$header$height, config$sidebar$width, main_height, config$theme$bg_card,
    config$sidebar$width, config$header$height, config$sidebar$width, config$header$height + main_height, config$theme$border,
    generate_svg_nav_items_blank(config),
    config$sidebar$width, config$header$height, main_width, main_height,
    generate_svg_kpi_cards_blank(config),
    generate_svg_grid_cards_blank(config)
  )
}

# Generate SVG for annotated mode (with dimension labels)
generate_svg_annotated <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2

  radius <- as.numeric(gsub("px", "", config$theme$radius))
  radius_lg <- as.numeric(gsub("px", "", config$theme$radius_lg))

  sprintf('<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">
  <defs>
    <style>
      .header-text { font-family: Segoe UI, system-ui, sans-serif; font-weight: 600; fill: white; font-size: 14px; }
      .dimension-badge { font-family: Consolas, Monaco, monospace; font-size: 10px; fill: white; }
      .dimension-badge-dark { font-family: Consolas, Monaco, monospace; font-size: 8px; fill: white; }
    </style>
    <linearGradient id="logoGradient" x1="0%%" y1="0%%" x2="100%%" y2="100%%">
      <stop offset="0%%" style="stop-color:%s"/>
      <stop offset="100%%" style="stop-color:#00796B"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="%d" height="%d" fill="%s"/>

  <!-- Header with dimension badge -->
  <rect x="0" y="0" width="%d" height="%d" fill="%s"/>
  <rect x="%d" y="4" width="%d" height="16" rx="4" fill="rgba(0, 121, 107, 0.9)"/>
  <text x="%d" y="14" class="dimension-badge">%dx%d @ (0, 0)</text>
  <line x1="0" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>
  <rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="url(#logoGradient)"/>
  <rect x="%d" y="%d" width="%d" height="12" rx="2" fill="rgba(0, 0, 0, 0.6)"/>
  <text x="%d" y="%d" class="dimension-badge-dark">%dx%d</text>

  <!-- Header Nav Buttons with badges -->
  %s

  <!-- Sidebar with dimension badge -->
  <rect x="0" y="%d" width="%d" height="%d" fill="%s"/>
  <rect x="4" y="%d" width="%d" height="16" rx="4" fill="rgba(0, 121, 107, 0.9)"/>
  <text x="8" y="%d" class="dimension-badge">%dx%d @ (0, %d)</text>
  <line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>
  %s

  <!-- Main Content Area with dimension badge -->
  <rect x="%d" y="%d" width="%d" height="%d" fill="none"/>
  <rect x="%d" y="%d" width="%d" height="16" rx="4" fill="rgba(0, 121, 107, 0.9)"/>
  <text x="%d" y="%d" class="dimension-badge">%dx%d @ (%d, %d)</text>

  <!-- KPI Cards with dimension badges -->
  %s

  <!-- Content Grid with dimension badges -->
  %s
</svg>',
    config$canvas$width, config$canvas$height, config$canvas$width, config$canvas$height,
    config$theme$accent,
    config$canvas$width, config$canvas$height, config$theme$bg_page,
    config$canvas$width, config$header$height, config$theme$bg_card,
    config$canvas$width - 120, 120, config$canvas$width - 60, 14,
    config$canvas$width, config$header$height,
    config$header$height, config$canvas$width, config$header$height, config$theme$border,
    config$header$padding, (config$header$height - config$header$logo_height) / 2,
    config$header$logo_width, config$header$logo_height, radius,
    config$header$padding + 2, (config$header$height - config$header$logo_height) / 2 + 2, 60, 10,
    config$header$padding + 32, (config$header$height - config$header$logo_height) / 2 + 10,
    config$header$logo_width, config$header$logo_height,
    generate_svg_nav_buttons_annotated(config),
    config$header$height, config$sidebar$width, main_height, config$theme$bg_card,
    4, 100, 100 + 12,
    config$sidebar$width, main_height, config$header$height,
    config$sidebar$width, config$header$height, config$sidebar$width, config$header$height + main_height, config$theme$border,
    generate_svg_nav_items_annotated(config),
    config$sidebar$width, config$header$height, main_width, main_height,
    config$sidebar$width + 4, config$header$height + 4, 120, 14,
    config$sidebar$width + 8, config$header$height + 14, main_width, main_height, config$sidebar$width, config$header$height,
    generate_svg_kpi_cards_annotated(config),
    generate_svg_grid_cards_annotated(config)
  )
}

# Helper: Generate blank nav buttons for SVG
generate_svg_nav_buttons_blank <- function(config) {
  radius <- as.numeric(gsub("px", "", config$theme$radius))
  buttons <- ""
  start_x <- config$canvas$width - config$header$padding - (config$header$nav_button_count * 48)
  for (i in 1:config$header$nav_button_count) {
    x <- start_x + (i - 1) * 48
    buttons <- paste0(buttons, sprintf(
      '<rect x="%d" y="%d" width="36" height="36" rx="%d" fill="%s" stroke="%s" stroke-width="1"/>',
      x, (config$header$height - 36) / 2, radius, config$theme$bg_page, config$theme$border
    ))
  }
  buttons
}

# Helper: Generate annotated nav buttons for SVG
generate_svg_nav_buttons_annotated <- function(config) {
  radius <- as.numeric(gsub("px", "", config$theme$radius))
  buttons <- ""
  start_x <- config$canvas$width - config$header$padding - (config$header$nav_button_count * 48)
  for (i in 1:config$header$nav_button_count) {
    x <- start_x + (i - 1) * 48
    buttons <- paste0(buttons, sprintf(
      '<rect x="%d" y="%d" width="36" height="36" rx="%d" fill="%s" stroke="%s" stroke-width="1"/>
      <rect x="%d" y="%d" width="32" height="10" rx="2" fill="rgba(0, 0, 0, 0.6)"/>
      <text x="%d" y="%d" class="dimension-badge-dark">36x36</text>',
      x, (config$header$height - 36) / 2, radius, config$theme$bg_page, config$theme$border,
      x + 2, (config$header$height - 36) / 2 + 2,
      x + 18, (config$header$height - 36) / 2 + 10
    ))
  }
  buttons
}

# Helper: Generate blank nav items for SVG
generate_svg_nav_items_blank <- function(config) {
  radius <- as.numeric(gsub("px", "", config$theme$radius))
  items <- ""
  y_start <- config$header$height + config$sidebar$padding + 45
  for (i in 1:config$sidebar$nav_item_count) {
    y <- y_start + (i - 1) * 44
    items <- paste0(items, sprintf(
      '<rect x="%d" y="%d" width="%d" height="40" rx="%d" fill="transparent"/>
      <rect x="%d" y="%d" width="20" height="20" rx="4" fill="%s"/>',
      config$sidebar$padding, y, config$sidebar$width - config$sidebar$padding * 2, radius,
      config$sidebar$padding + 12, y + 10, config$theme$bg_page
    ))
  }
  items
}

# Helper: Generate annotated nav items for SVG
generate_svg_nav_items_annotated <- function(config) {
  radius <- as.numeric(gsub("px", "", config$theme$radius))
  items <- ""
  y_start <- config$header$height + config$sidebar$padding + 45
  for (i in 1:config$sidebar$nav_item_count) {
    y <- y_start + (i - 1) * 44
    item_width <- config$sidebar$width - config$sidebar$padding * 2
    items <- paste0(items, sprintf(
      '<rect x="%d" y="%d" width="%d" height="40" rx="%d" fill="transparent"/>
      <rect x="%d" y="%d" width="%d" height="12" rx="2" fill="rgba(0, 121, 107, 0.9)"/>
      <text x="%d" y="%d" class="dimension-badge">%dx40 @ (0, %d)</text>
      <rect x="%d" y="%d" width="20" height="20" rx="4" fill="%s"/>',
      config$sidebar$padding, y, item_width, radius,
      config$sidebar$padding + 2, y + 2, 100, config$sidebar$padding + 6, y + 12, item_width, y,
      config$sidebar$padding + 12, y + 10, config$theme$bg_page
    ))
  }
  items
}

# Helper: Generate blank KPI cards for SVG
generate_svg_kpi_cards_blank <- function(config) {
  radius_lg <- as.numeric(gsub("px", "", config$theme$radius_lg))
  main_width <- config$canvas$width - config$sidebar$width
  kpi_width <- (main_width - config$content$padding * 2 - config$content$kpi_gap * (config$content$kpi_count - 1)) / config$content$kpi_count

  cards <- ""
  for (i in 1:config$content$kpi_count) {
    x <- config$sidebar$width + config$content$padding + (i - 1) * (kpi_width + config$content$kpi_gap)
    y <- config$header$height + config$content$padding

    cards <- paste0(cards, sprintf(
      '<rect x="%d" y="%d" width="%.0f" height="%d" rx="%d" fill="%s" stroke="%s" stroke-width="1"/>',
      x, y, kpi_width, config$content$kpi_height, radius_lg, config$theme$bg_card, config$theme$border
    ))
  }
  cards
}

# Helper: Generate annotated KPI cards for SVG
generate_svg_kpi_cards_annotated <- function(config) {
  radius_lg <- as.numeric(gsub("px", "", config$theme$radius_lg))
  main_width <- config$canvas$width - config$sidebar$width
  kpi_width <- (main_width - config$content$padding * 2 - config$content$kpi_gap * (config$content$kpi_count - 1)) / config$content$kpi_count
  x_start <- config$sidebar$width + config$content$padding
  y_pos <- config$header$height + config$content$padding

  cards <- ""
  for (i in 1:config$content$kpi_count) {
    x <- x_start + (i - 1) * (kpi_width + config$content$kpi_gap)

    cards <- paste0(cards, sprintf(
      '<rect x="%d" y="%d" width="%.0f" height="%d" rx="%d" fill="%s" stroke="%s" stroke-width="1"/>
      <rect x="%d" y="%d" width="%d" height="16" rx="4" fill="rgba(0, 121, 107, 0.9)"/>
      <text x="%d" y="%d" class="dimension-badge">%.0fx%d @ (%.0f, %d) r%d</text>',
      x, y_pos, kpi_width, config$content$kpi_height, radius_lg, config$theme$bg_card, config$theme$border,
      x + 4, y_pos + 4, 130, x + 8, y_pos + 14, kpi_width, config$content$kpi_height, x, y_pos, radius_lg
    ))
  }
  cards
}

# Helper: Generate blank grid cards for SVG
generate_svg_grid_cards_blank <- function(config) {
  radius_lg <- as.numeric(gsub("px", "", config$theme$radius_lg))
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2

  containers_per_row <- get_containers_per_row(config)
  num_rows <- length(containers_per_row)
  row_height <- (content_height - config$content$grid_gap * (num_rows - 1)) / num_rows

  cards <- ""
  for (row in 1:num_rows) {
    cols_in_row <- containers_per_row[row]
    cell_width <- (main_width - config$content$padding * 2 - config$content$grid_gap * (cols_in_row - 1)) / cols_in_row

    for (col in 1:cols_in_row) {
      x <- config$sidebar$width + config$content$padding + (col - 1) * (cell_width + config$content$grid_gap)
      y <- config$header$height + config$content$padding + config$content$kpi_height + config$content$kpi_gap + (row - 1) * (row_height + config$content$grid_gap)

      cards <- paste0(cards, sprintf(
        '<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" rx="%d" fill="%s" stroke="%s" stroke-width="1"/>',
        x, y, cell_width, row_height, radius_lg, config$theme$bg_card, config$theme$border
      ))
    }
  }
  cards
}

# Helper: Generate annotated grid cards for SVG
generate_svg_grid_cards_annotated <- function(config) {
  radius_lg <- as.numeric(gsub("px", "", config$theme$radius_lg))
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  content_height <- main_height - config$content$kpi_height - config$content$kpi_gap - config$content$padding * 2

  containers_per_row <- get_containers_per_row(config)
  num_rows <- length(containers_per_row)
  row_height <- (content_height - config$content$grid_gap * (num_rows - 1)) / num_rows

  cards <- ""
  for (row in 1:num_rows) {
    cols_in_row <- containers_per_row[row]
    cell_width <- (main_width - config$content$padding * 2 - config$content$grid_gap * (cols_in_row - 1)) / cols_in_row

    for (col in 1:cols_in_row) {
      x <- config$sidebar$width + config$content$padding + (col - 1) * (cell_width + config$content$grid_gap)
      y <- config$header$height + config$content$padding + config$content$kpi_height + config$content$kpi_gap + (row - 1) * (row_height + config$content$grid_gap)

      cards <- paste0(cards, sprintf(
        '<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" rx="%d" fill="%s" stroke="%s" stroke-width="1"/>
        <rect x="%.0f" y="%.0f" width="%d" height="16" rx="4" fill="rgba(0, 121, 107, 0.9)"/>
        <text x="%.0f" y="%.0f" class="dimension-badge">%.0fx%.0f @ (%.0f, %.0f) r%d</text>',
        x, y, cell_width, row_height, radius_lg, config$theme$bg_card, config$theme$border,
        x + 4, y + 4, 140, x + 8, y + 14, cell_width, row_height, x, y, radius_lg
      ))
    }
  }
  cards
}

# =============================================================================
# EXPORT HANDLERS
# =============================================================================
generate_dax_measures <- function(config) {
  main_width <- config$canvas$width - config$sidebar$width
  main_height <- config$canvas$height - config$header$height
  sprintf('// Dashboard Layout Measures
// Copy these measures into Power BI
// Canvas Dimensions
Canvas Width = %d
Canvas Height = %d
// Header
Header Height = %d
Header Padding = %d
Logo Width = %d
Logo Height = %d
// Sidebar
Sidebar Width = %d
Sidebar Padding = %d
Sidebar Height = [Canvas Height] - [Header Height]
// Main Content
Main Width = [Canvas Width] - [Sidebar Width]
Main Height = [Canvas Height] - [Header Height]
Content Padding = %d
// KPI Cards
KPI Card Height = %d
KPI Card Count = %d
KPI Card Gap = %d
KPI Card Width = DIVIDE([Main Width] - ([Content Padding] * 2) - ([KPI Card Gap] * ([KPI Card Count] - 1)), [KPI Card Count])
// Grid Layout
Grid Rows = %d
Grid Columns = %d
Grid Gap = %d
Content Available Height = [Main Height] - [KPI Card Height] - [KPI Card Gap] - ([Content Padding] * 2)
Grid Cell Width = DIVIDE([Main Width] - ([Content Padding] * 2) - ([Grid Gap] * ([Grid Columns] - 1)), [Grid Columns])
Grid Cell Height = DIVIDE([Content Available Height] - ([Grid Gap] * ([Grid Rows] - 1)), [Grid Rows])
// Theme Colors (for reference)
Theme Bg Page = "%s"
Theme Bg Card = "%s"
Theme Border = "%s"
Theme Accent = "%s"
Theme Radius = "%s"
Theme Radius Large = "%s"',
    config$canvas$width,
    config$canvas$height,
    config$header$height,
    config$header$padding,
    config$header$logo_width,
    config$header$logo_height,
    config$sidebar$width,
    config$sidebar$padding,
    config$content$padding,
    config$content$kpi_height,
    config$content$kpi_count,
    config$content$kpi_gap,
    config$content$grid_rows,
    config$content$grid_cols,
    config$content$grid_gap,
    config$theme$bg_page,
    config$theme$bg_card,
    config$theme$border,
    config$theme$accent,
    config$theme$radius,
    config$theme$radius_lg
  )
}
generate_json_theme <- function(config) {
  theme <- list(
    name = "Custom Dashboard Theme",
    dataColors = c(
      config$theme$accent,
      "#00796B",
      "#004D40",
      "#B2DFDB",
      "#80CBC4",
      "#4DB6AC"
    ),
    background = config$theme$bg_page,
    foreground = config$theme$text_primary,
    tableAccent = config$theme$accent,
    visualStyles = list(
      page = list(
        "*" = list(
          background = list(
            color = list(solid = list(color = config$theme$bg_page))
          )
        )
      ),
      card = list(
        "*" = list(
          background = list(
            color = list(solid = list(color = config$theme$bg_card))
          ),
          border = list(
            color = list(solid = list(color = config$theme$border))
          )
        )
      )
    )
  )
  jsonlite::toJSON(theme, auto_unbox = TRUE, pretty = TRUE)
}
# =============================================================================
# HTML PARSER
# =============================================================================
# Null coalescing operator (must be defined before use)
`%||%` <- function(x, y) if (is.null(x)) y else x

parse_html_config <- function(html_content) {
  config <- DEFAULT_CONFIG
  # Extract CSS variables
  root_match <- str_match(html_content, ":root\\s*\\{([^}]+)\\}")
  if (!is.na(root_match[1, 1])) {
    root_content <- root_match[1, 2]
    extract_color <- function(var_name, content) {
      pattern <- sprintf("--%s:\\s*([^;]+);", var_name)
      match <- str_match(content, pattern)
      if (!is.na(match[1, 2])) str_trim(match[1, 2]) else NULL
    }
    config$theme$bg_page <- extract_color("bg-page", root_content) %||% config$theme$bg_page
    config$theme$bg_card <- extract_color("bg-card", root_content) %||% config$theme$bg_card
    config$theme$border <- extract_color("border", root_content) %||% config$theme$border
    config$theme$text_primary <- extract_color("text-primary", root_content) %||% config$theme$text_primary
    config$theme$text_secondary <- extract_color("text-secondary", root_content) %||% config$theme$text_secondary
    config$theme$accent <- extract_color("accent", root_content) %||% config$theme$accent
    config$theme$radius <- extract_color("radius", root_content) %||% config$theme$radius
    config$theme$radius_lg <- extract_color("radius-lg", root_content) %||% config$theme$radius_lg
  }
  # Extract dimensions from .dashboard-container
  container_match <- str_match(html_content, "\\.dashboard-container[^{]*\\{([^}]+)\\}")
  if (!is.na(container_match[1, 1])) {
    width_match <- str_match(container_match[1, 2], "width:\\s*(\\d+)px")
    height_match <- str_match(container_match[1, 2], "height:\\s*(\\d+)px")
    if (!is.na(width_match[1, 2])) config$canvas$width <- as.integer(width_match[1, 2])
    if (!is.na(height_match[1, 2])) config$canvas$height <- as.integer(height_match[1, 2])
  }
  # Extract header dimensions
  header_match <- str_match(html_content, "\\.header[^{]*\\{([^}]+)\\}")
  if (!is.na(header_match[1, 1])) {
    height_match <- str_match(header_match[1, 2], "height:\\s*(\\d+)px")
    if (!is.na(height_match[1, 2])) config$header$height <- as.integer(height_match[1, 2])
  }
  # Extract sidebar dimensions
  sidebar_match <- str_match(html_content, "\\.sidebar[^{]*\\{([^}]+)\\}")
  if (!is.na(sidebar_match[1, 1])) {
    width_match <- str_match(sidebar_match[1, 2], "width:\\s*(\\d+)px")
    if (!is.na(width_match[1, 2])) config$sidebar$width <- as.integer(width_match[1, 2])
  }
  # Extract grid configuration
  grid_match <- str_match(html_content, "\\.content-grid[^{]*\\{([^}]+)\\}")
  if (!is.na(grid_match[1, 1])) {
    cols_match <- str_match(grid_match[1, 2], "grid-template-columns:\\s*repeat\\((\\d+)")
    rows_match <- str_match(grid_match[1, 2], "grid-template-rows:\\s*repeat\\((\\d+)")
    gap_match <- str_match(grid_match[1, 2], "gap:\\s*(\\d+)px")
    if (!is.na(cols_match[1, 2])) config$content$grid_cols <- as.integer(cols_match[1, 2])
    if (!is.na(rows_match[1, 2])) config$content$grid_rows <- as.integer(rows_match[1, 2])
    if (!is.na(gap_match[1, 2])) config$content$grid_gap <- as.integer(gap_match[1, 2])
  }
  config
}
# =============================================================================
# UI COMPONENTS
# =============================================================================
wizard_step_1 <- function() {
  tagList(
    div(class = "wizard-step",
      h5(icon("expand"), " Canvas Settings"),
      numericInput("canvas_width", "Width (px)", value = DEFAULT_CONFIG$canvas$width, min = 800, max = 3840),
      numericInput("canvas_height", "Height (px)", value = DEFAULT_CONFIG$canvas$height, min = 600, max = 2160),
      selectInput("aspect_ratio", "Aspect Ratio Preset",
        choices = c("Custom", "16:9", "4:3", "21:9"),
        selected = "16:9"
      )
    )
  )
}
wizard_step_2 <- function() {
  tagList(
    div(class = "wizard-step",
      h5(icon("palette"), " Global Theme"),
      colourInput("bg_page", "Page Background", value = DEFAULT_CONFIG$theme$bg_page),
      colourInput("bg_card", "Card Background", value = DEFAULT_CONFIG$theme$bg_card),
      colourInput("border", "Border Color", value = DEFAULT_CONFIG$theme$border),
      colourInput("accent", "Accent Color", value = DEFAULT_CONFIG$theme$accent),
      textInput("radius", "Border Radius", value = DEFAULT_CONFIG$theme$radius),
      textInput("radius_lg", "Large Radius", value = DEFAULT_CONFIG$theme$radius_lg)
    )
  )
}
wizard_step_3 <- function() {
  tagList(
    div(class = "wizard-step",
      h5(icon("window-maximize"), " Header"),
      numericInput("header_height", "Height (px)", value = DEFAULT_CONFIG$header$height, min = 40, max = 150),
      numericInput("header_padding", "Padding (px)", value = DEFAULT_CONFIG$header$padding, min = 0, max = 40),
      numericInput("logo_width", "Logo Width (px)", value = DEFAULT_CONFIG$header$logo_width, min = 50, max = 300),
      numericInput("logo_height", "Logo Height (px)", value = DEFAULT_CONFIG$header$logo_height, min = 20, max = 100),
      numericInput("nav_button_count", "Nav Buttons", value = DEFAULT_CONFIG$header$nav_button_count, min = 0, max = 8)
    )
  )
}
wizard_step_4 <- function() {
  tagList(
    div(class = "wizard-step",
      h5(icon("columns"), " Sidebar"),
      numericInput("sidebar_width", "Width (px)", value = DEFAULT_CONFIG$sidebar$width, min = 100, max = 400),
      numericInput("sidebar_padding", "Padding (px)", value = DEFAULT_CONFIG$sidebar$padding, min = 0, max = 32),
      numericInput("nav_item_count", "Nav Items", value = DEFAULT_CONFIG$sidebar$nav_item_count, min = 1, max = 15)
    )
  )
}
wizard_step_5 <- function() {
  tagList(
    div(class = "wizard-step",
      h5(icon("chart-bar"), " KPI Card Settings"),
      numericInput("kpi_height", "Height (px)", value = DEFAULT_CONFIG$content$kpi_height, min = 60, max = 150),
      numericInput("kpi_count", "Count", value = DEFAULT_CONFIG$content$kpi_count, min = 1, max = 8),
      numericInput("kpi_gap", "Gap (px)", value = DEFAULT_CONFIG$content$kpi_gap, min = 0, max = 40),
      textInput("kpi_proportions", "Width Proportions", value = "",
                placeholder = "e.g., 40, 30, 20, 10 (empty = equal)")
    )
  )
}

wizard_step_6 <- function() {
  tagList(
    div(class = "wizard-step",
      h5(icon("th"), " Content Grid Settings"),
      selectInput("layout_type", "Layout Type",
        choices = c(
          "Uniform (same cols per row)" = "uniform",
          "Custom (varying cols per row)" = "custom"
        ),
        selected = "uniform"
      ),
      conditionalPanel(
        condition = "input.layout_type == 'uniform'",
        numericInput("grid_rows", "Rows", value = DEFAULT_CONFIG$content$grid_rows, min = 1, max = 6),
        numericInput("grid_cols", "Columns", value = DEFAULT_CONFIG$content$grid_cols, min = 1, max = 6)
      ),
      conditionalPanel(
        condition = "input.layout_type == 'custom'",
        textInput("containers_per_row", "Containers Per Row", value = DEFAULT_CONFIG$content$containers_per_row,
                  placeholder = "e.g., 2, 3, 2 (one number per row)")
      ),
      numericInput("grid_gap", "Gap (px)", value = DEFAULT_CONFIG$content$grid_gap, min = 0, max = 32),
      h6("Proportional Sizing"),
      textInput("row_proportions", "Row Height Proportions", value = "",
                placeholder = "e.g., 50, 30, 20 (empty = equal)"),
      textInput("col_proportions", "Column Width Proportions", value = "",
                placeholder = "e.g., 60, 40 (empty = equal)")
    )
  )
}

wizard_step_7 <- function() {
  tagList(
    div(class = "wizard-step",
      h5(icon("ruler-combined"), " Annotations"),
      checkboxInput("annotations_enabled", "Show Dimension Badges", value = FALSE),
      p(class = "text-muted", "Display width x height labels on all elements")
    )
  )
}
# =============================================================================
# MAIN UI
# =============================================================================
ui <- page_sidebar(
  title = "Dashboard Layout Architect",
  theme = bs_theme(bootswatch = "yeti"),
  sidebar = sidebar(
    width = 320,
    open = "always",
    collapsible = FALSE,
    # Import section
    div(class = "import-section",
      h5(icon("upload"), " Import Layout"),
      fileInput("import_file", "Upload HTML",
        accept = c(".html", ".htm"),
        buttonLabel = "Browse..."
      ),
      actionButton("import_paste", "Paste from Clipboard", class = "btn-sm btn-outline-secondary")
    ),
    hr(),
    # Wizard steps
    div(class = "wizard-container",
      wizard_step_1(),
      wizard_step_2(),
      hr(),
      wizard_step_3(),
      wizard_step_4(),
      hr(),
      wizard_step_5(),
      hr(),
      wizard_step_6(),
      wizard_step_7()
    ),
    hr(),
    # Actions
    div(class = "wizard-actions",
      p(class = "text-muted", style = "font-size: 11px; margin-bottom: 8px;",
        "Preview updates live. Click 'Lock Settings' to finalize for export."),
      actionButton("generate_layout", "Lock Settings for Export", class = "btn-sm btn-primary w-100 mb-2"),
      actionButton("reset_config", "Reset to Defaults", class = "btn-sm btn-outline-danger w-100")
    )
  ),
  # Main content with tabs
  navset_tab(
    id = "main_tabs",
    # Preview Tab
    nav_panel(
      title = "Preview",
      value = "preview_tab",
      div(class = "preview-controls",
        flowLayout(
          radioButtons("view_mode", "View Mode",
            choices = c(
              "Example (with content)" = "example",
              "Blank (containers only)" = "blank",
              "Annotated (dimensions)" = "annotated"
            ),
            selected = "example",
            inline = TRUE
          ),
          selectInput("zoom_level", "Zoom",
            choices = c("50%" = 0.5, "75%" = 0.75, "100%" = 1, "125%" = 1.25),
            selected = 0.75
          )
        )
      ),
      div(class = "preview-container",
        uiOutput("preview_frame")
      )
    ),
    # Power BI HTML Tab
    nav_panel(
      title = "Power BI HTML",
      value = "powerbi_tab",
      div(class = "export-controls",
        downloadButton("download_powerbi", "Download HTML", class = "btn-sm btn-primary"),
        downloadButton("download_svg", "Download SVG", class = "btn-sm btn-success"),
        actionButton("copy_powerbi", "Copy to Clipboard", class = "btn-sm btn-outline-primary", `data-clipboard-target` = "#powerbi_code"),
        checkboxInput("single_line", "Single Line (for DAX)", value = TRUE)
      ),
      p(class = "text-muted", style = "margin-bottom: 10px; font-size: 12px;",
        "Uses locked settings. Click 'Lock Settings for Export' to update. ",
        "This HTML is formatted for Power BI's HTML Content visual. Use in a DAX measure like: ",
        code("Layout HTML = \"<style>...\"")
      ),
      div(class = "code-container",
        tags$pre(id = "powerbi_code", tags$code(verbatimTextOutput("powerbi_output")))
      )
    ),
    # Full HTML Tab
    nav_panel(
      title = "Full HTML",
      value = "html_tab",
      div(class = "export-controls",
        downloadButton("download_html", "Download HTML", class = "btn-sm btn-primary"),
        actionButton("copy_html", "Copy to Clipboard", class = "btn-sm btn-outline-primary", `data-clipboard-target` = "#html_code")
      ),
      p(class = "text-muted", style = "margin-bottom: 10px; font-size: 12px;",
        "Uses locked settings. Click 'Lock Settings for Export' to update. ",
        "Complete HTML document for standalone use or embedding in iframes."
      ),
      div(class = "code-container",
        tags$pre(id = "html_code", tags$code(verbatimTextOutput("html_output")))
      )
    ),
    # DAX Tab
    nav_panel(
      title = "DAX",
      value = "dax_tab",
      div(class = "export-controls",
        actionButton("copy_dax", "Copy to Clipboard", class = "btn-sm btn-outline-primary", `data-clipboard-target` = "#dax_code")
      ),
      div(class = "code-container",
        tags$pre(id = "dax_code", tags$code(verbatimTextOutput("dax_output")))
      )
    ),
    # JSON Theme Tab
    nav_panel(
      title = "JSON Theme",
      value = "json_tab",
      div(class = "export-controls",
        downloadButton("download_json", "Download JSON", class = "btn-sm btn-primary"),
        actionButton("copy_json", "Copy to Clipboard", class = "btn-sm btn-outline-primary", `data-clipboard-target` = "#json_code")
      ),
      div(class = "code-container",
        tags$pre(id = "json_code", tags$code(verbatimTextOutput("json_output")))
      )
    ),
    # Palette & Typography Tab
    nav_panel(
      title = "Palette & Typography",
      value = "palette_tab",
      div(class = "palette-container",
        fluidRow(
          # Left column - Color Palette
          column(6,
            div(class = "palette-section",
              h4("Color Palette"),
              # Base Color Selector
              div(class = "palette-control",
                selectInput("base_color", "Base Color",
                  choices = names(gcps_base),
                  selected = "teal"
                )
              ),
              hr(),
              # Sequential Ramp Preview
              h5("Sequential Ramp"),
              p(class = "text-muted", style = "font-size: 11px;",
                "5-step ramp from light to dark. Use for ordered numeric values."),
              uiOutput("ramp_preview"),
              hr(),
              # Diverging Palette Preview
              h5("Diverging Palette"),
              p(class = "text-muted", style = "font-size: 11px;",
                "5-step diverging scale with neutral center. Use for deviation from a midpoint."),
              uiOutput("diverging_preview"),
              hr(),
              # Qualitative Palette Preview
              h5("Qualitative Palette"),
              p(class = "text-muted", style = "font-size: 11px;",
                "8 colors including neutrals. Use for unordered categories."),
              uiOutput("qualitative_preview")
            )
          ),
          # Right column - Typography
          column(6,
            div(class = "typography-section",
              h4("Typography"),
              # Font Family Selector
              div(class = "typography-control",
                selectInput("font_family", "Font Family",
                  choices = names(font_families),
                  selected = "Segoe UI"
                )
              ),
              # Font Weight Selector
              div(class = "typography-control",
                selectInput("font_weight", "Font Weight",
                  choices = font_weights,
                  selected = "400"
                )
              ),
              # Base Font Size
              div(class = "typography-control",
                numericInput("base_font_size", "Base Font Size (px)",
                  value = 14, min = 10, max = 24, step = 1
                )
              ),
              # Heading Font Size
              div(class = "typography-control",
                numericInput("heading_font_size", "Heading Font Size (px)",
                  value = 18, min = 14, max = 36, step = 2
                )
              ),
              hr(),
              # Sample Text Preview
              h5("Sample Preview"),
              uiOutput("font_preview"),
              hr(),
              # Export Buttons
              div(class = "palette-actions",
                actionButton("apply_palette", "Apply to Layout", class = "btn-sm btn-primary"),
                downloadButton("download_r_code", "Download R Code", class = "btn-sm btn-success"),
                downloadButton("download_css_vars", "Download CSS", class = "btn-sm btn-info")
              )
            )
          )
        )
      )
    )
  )
)
# =============================================================================
# SERVER LOGIC
# =============================================================================
server <- function(input, output, session) {
  # Reactive values for configuration
  rv <- reactiveValues(
    config = DEFAULT_CONFIG,
    locked = FALSE  # Track if settings are locked for export
  )

  # Build configuration reactively from all inputs (for live preview)
  live_config <- reactive({
    # Determine grid rows and cols based on layout type
    layout_type <- input$layout_type %||% "uniform"

    if (layout_type == "custom") {
      # Parse containers_per_row to get rows count
      containers_str <- input$containers_per_row %||% DEFAULT_CONFIG$content$containers_per_row
      containers <- as.integer(strsplit(containers_str, ",")[[1]])
      containers <- containers[!is.na(containers)]
      grid_rows <- length(containers)
      grid_cols <- max(containers)
    } else {
      grid_rows <- input$grid_rows %||% DEFAULT_CONFIG$content$grid_rows
      grid_cols <- input$grid_cols %||% DEFAULT_CONFIG$content$grid_cols
    }

    list(
      canvas = list(
        width = input$canvas_width %||% DEFAULT_CONFIG$canvas$width,
        height = input$canvas_height %||% DEFAULT_CONFIG$canvas$height
      ),
      theme = list(
        bg_page = input$bg_page %||% DEFAULT_CONFIG$theme$bg_page,
        bg_card = input$bg_card %||% DEFAULT_CONFIG$theme$bg_card,
        border = input$border %||% DEFAULT_CONFIG$theme$border,
        text_primary = DEFAULT_CONFIG$theme$text_primary,
        text_secondary = DEFAULT_CONFIG$theme$text_secondary,
        accent = input$accent %||% DEFAULT_CONFIG$theme$accent,
        radius = input$radius %||% DEFAULT_CONFIG$theme$radius,
        radius_lg = input$radius_lg %||% DEFAULT_CONFIG$theme$radius_lg
      ),
      header = list(
        height = input$header_height %||% DEFAULT_CONFIG$header$height,
        padding = input$header_padding %||% DEFAULT_CONFIG$header$padding,
        logo_width = input$logo_width %||% DEFAULT_CONFIG$header$logo_width,
        logo_height = input$logo_height %||% DEFAULT_CONFIG$header$logo_height,
        nav_button_count = input$nav_button_count %||% DEFAULT_CONFIG$header$nav_button_count
      ),
      sidebar = list(
        width = input$sidebar_width %||% DEFAULT_CONFIG$sidebar$width,
        padding = input$sidebar_padding %||% DEFAULT_CONFIG$sidebar$padding,
        nav_item_count = input$nav_item_count %||% DEFAULT_CONFIG$sidebar$nav_item_count
      ),
      content = list(
        kpi_height = input$kpi_height %||% DEFAULT_CONFIG$content$kpi_height,
        kpi_count = input$kpi_count %||% DEFAULT_CONFIG$content$kpi_count,
        kpi_gap = input$kpi_gap %||% DEFAULT_CONFIG$content$kpi_gap,
        grid_rows = grid_rows,
        grid_cols = grid_cols,
        grid_gap = input$grid_gap %||% DEFAULT_CONFIG$content$grid_gap,
        padding = DEFAULT_CONFIG$content$padding,
        layout_type = layout_type,
        containers_per_row = input$containers_per_row %||% DEFAULT_CONFIG$content$containers_per_row,
        kpi_proportions = input$kpi_proportions,
        row_proportions = input$row_proportions,
        col_proportions = input$col_proportions
      ),
      annotations = list(
        enabled = isTRUE(input$annotations_enabled)
      )
    )
  })

  # Lock settings for export when Generate button is clicked
  observeEvent(input$generate_layout, {
    rv$config <- live_config()
    rv$locked <- TRUE
    showNotification("Settings locked for export!", type = "message")
  }, ignoreInit = FALSE)
  # Aspect ratio presets
  observeEvent(input$aspect_ratio, {
    if (input$aspect_ratio != "Custom") {
      width <- input$canvas_width %||% 1280
      ratios <- list("16:9" = 16/9, "4:3" = 4/3, "21:9" = 21/9)
      ratio <- ratios[[input$aspect_ratio]]
      new_height <- round(width / ratio)
      updateNumericInput(session, "canvas_height", value = new_height)
    }
  })
  # Reset to defaults
  observeEvent(input$reset_config, {
    updateNumericInput(session, "canvas_width", value = DEFAULT_CONFIG$canvas$width)
    updateNumericInput(session, "canvas_height", value = DEFAULT_CONFIG$canvas$height)
    updateNumericInput(session, "header_height", value = DEFAULT_CONFIG$header$height)
    updateNumericInput(session, "header_padding", value = DEFAULT_CONFIG$header$padding)
    updateNumericInput(session, "logo_width", value = DEFAULT_CONFIG$header$logo_width)
    updateNumericInput(session, "logo_height", value = DEFAULT_CONFIG$header$logo_height)
    updateNumericInput(session, "nav_button_count", value = DEFAULT_CONFIG$header$nav_button_count)
    updateNumericInput(session, "sidebar_width", value = DEFAULT_CONFIG$sidebar$width)
    updateNumericInput(session, "sidebar_padding", value = DEFAULT_CONFIG$sidebar$padding)
    updateNumericInput(session, "nav_item_count", value = DEFAULT_CONFIG$sidebar$nav_item_count)
    updateNumericInput(session, "kpi_height", value = DEFAULT_CONFIG$content$kpi_height)
    updateNumericInput(session, "kpi_count", value = DEFAULT_CONFIG$content$kpi_count)
    updateNumericInput(session, "kpi_gap", value = DEFAULT_CONFIG$content$kpi_gap)
    updateNumericInput(session, "grid_rows", value = DEFAULT_CONFIG$content$grid_rows)
    updateNumericInput(session, "grid_cols", value = DEFAULT_CONFIG$content$grid_cols)
    updateNumericInput(session, "grid_gap", value = DEFAULT_CONFIG$content$grid_gap)
    updateSelectInput(session, "layout_type", selected = "uniform")
    updateTextInput(session, "containers_per_row", value = DEFAULT_CONFIG$content$containers_per_row)
    updateCheckboxInput(session, "annotations_enabled", value = FALSE)
    # Reset proportion inputs
    updateTextInput(session, "kpi_proportions", value = "")
    updateTextInput(session, "row_proportions", value = "")
    updateTextInput(session, "col_proportions", value = "")
    # Reset colors
    updateColourInput(session, "bg_page", value = DEFAULT_CONFIG$theme$bg_page)
    updateColourInput(session, "bg_card", value = DEFAULT_CONFIG$theme$bg_card)
    updateColourInput(session, "border", value = DEFAULT_CONFIG$theme$border)
    updateColourInput(session, "accent", value = DEFAULT_CONFIG$theme$accent)
    updateTextInput(session, "radius", value = DEFAULT_CONFIG$theme$radius)
    updateTextInput(session, "radius_lg", value = DEFAULT_CONFIG$theme$radius_lg)
    # Reset locked config
    rv$config <- DEFAULT_CONFIG
    rv$locked <- FALSE
    showNotification("Reset to defaults!", type = "message")
  })
  # File import
  observeEvent(input$import_file, {
    req(input$import_file)
    html_content <- readLines(input$import_file$datapath, warn = FALSE)
    html_content <- paste(html_content, collapse = "\n")
    parsed_config <- parse_html_config(html_content)
    update_inputs_from_config(session, parsed_config)
    showNotification("Layout imported successfully!", type = "message")
  })
  # Paste import
  observeEvent(input$import_paste, {
    showModal(modalDialog(
      title = "Paste HTML Content",
      aceEditor("paste_html", value = "", mode = "html", height = "300px"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_paste", "Import", class = "btn-primary")
      )
    ))
  })
  observeEvent(input$confirm_paste, {
    req(input$paste_html)
    parsed_config <- parse_html_config(input$paste_html)
    update_inputs_from_config(session, parsed_config)
    removeModal()
    showNotification("Layout imported successfully!", type = "message")
  })
  # Helper to update inputs from parsed config
  update_inputs_from_config <- function(session, config) {
    updateNumericInput(session, "canvas_width", value = config$canvas$width)
    updateNumericInput(session, "canvas_height", value = config$canvas$height)
    updateColourInput(session, "bg_page", value = config$theme$bg_page)
    updateColourInput(session, "bg_card", value = config$theme$bg_card)
    updateColourInput(session, "border", value = config$theme$border)
    updateColourInput(session, "accent", value = config$theme$accent)
    updateTextInput(session, "radius", value = config$theme$radius)
    updateTextInput(session, "radius_lg", value = config$theme$radius_lg)
    updateNumericInput(session, "header_height", value = config$header$height)
    updateNumericInput(session, "sidebar_width", value = config$sidebar$width)
    updateNumericInput(session, "grid_rows", value = config$content$grid_rows)
    updateNumericInput(session, "grid_cols", value = config$content$grid_cols)
    updateNumericInput(session, "grid_gap", value = config$content$grid_gap)
  }
  # Generate HTML for preview (uses live config for immediate updates)
  generated_html <- reactive({
    generate_html(live_config(), include_css = TRUE, view_mode = input$view_mode)
  })
  # Generate Power BI compatible HTML (uses locked config for export)
  generated_powerbi_html <- reactive({
    single_line <- isTRUE(input$single_line)
    generate_powerbi_html(rv$config, single_line = single_line)
  })
  # Preview output (live updates)
  output$preview_frame <- renderUI({
    zoom <- as.numeric(input$zoom_level %||% 0.75)
    config <- live_config()
    tags$iframe(
      srcdoc = generated_html(),
      style = paste0(
        "width: ", config$canvas$width, "px;",
        "height: ", config$canvas$height, "px;",
        "transform: scale(", zoom, ");",
        "transform-origin: top left;",
        "border: 1px solid #dee2e6;",
        "background: white;"
      ),
      class = "preview-iframe"
    )
  })
  # Power BI HTML output (uses locked config)
  output$powerbi_output <- renderText({
    generated_powerbi_html()
  })
  # Full HTML output (uses locked config)
  output$html_output <- renderText({
    generate_html(rv$config, include_css = TRUE, view_mode = input$view_mode)
  })
  # DAX output (uses locked config)
  output$dax_output <- renderText({
    generate_dax_measures(rv$config)
  })
  # JSON output (uses locked config)
  output$json_output <- renderText({
    generate_json_theme(rv$config)
  })
  # Download handlers
  output$download_html <- downloadHandler(
    filename = function() {
      sprintf("dashboard-layout-%dx%d.html", rv$config$canvas$width, rv$config$canvas$height)
    },
    content = function(file) {
      writeLines(generated_html(), file)
    }
  )
  output$download_powerbi <- downloadHandler(
    filename = function() {
      sprintf("powerbi-layout-%dx%d.html", rv$config$canvas$width, rv$config$canvas$height)
    },
    content = function(file) {
      writeLines(generated_powerbi_html(), file)
    }
  )
  output$download_json <- downloadHandler(
    filename = function() {
      "dashboard-theme.json"
    },
    content = function(file) {
      writeLines(generate_json_theme(rv$config), file)
    }
  )
  # SVG Download handler
  output$download_svg <- downloadHandler(
    filename = function() {
      sprintf("dashboard-layout-%s-%dx%d.svg", input$view_mode, rv$config$canvas$width, rv$config$canvas$height)
    },
    content = function(file) {
      # Generate SVG based on selected view mode
      svg_content <- generate_svg_from_html(rv$config, view_mode = input$view_mode)
      writeLines(svg_content, file)
    }
  )
  # Copy to clipboard handlers using shinyjs
  observeEvent(input$copy_powerbi, {
    shinyjs::runjs("navigator.clipboard.writeText(document.getElementById('powerbi_code').innerText);")
    showNotification("Power BI HTML copied to clipboard!", type = "message")
  })
  observeEvent(input$copy_html, {
    shinyjs::runjs("navigator.clipboard.writeText(document.getElementById('html_code').innerText);")
    showNotification("HTML copied to clipboard!", type = "message")
  })
  observeEvent(input$copy_dax, {
    shinyjs::runjs("navigator.clipboard.writeText(document.getElementById('dax_code').innerText);")
    showNotification("DAX measures copied to clipboard!", type = "message")
  })
  observeEvent(input$copy_json, {
    shinyjs::runjs("navigator.clipboard.writeText(document.getElementById('json_code').innerText);")
    showNotification("JSON theme copied to clipboard!", type = "message")
  })

  # ===========================================================================
  # PALETTE & TYPOGRAPHY SERVER LOGIC
  # ===========================================================================

  # Sequential Ramp Preview
  output$ramp_preview <- renderText({
    req({
      base_color <- input$base_color

      if (is.null(base_color) || base_color == "") {
        return("<p>Select a base color to see the sequential ramp</p>")
      }

      ramp <- gcps_ramps[[base_color]]
      if (is.null(ramp)) {
        return("<p>No ramp available for this color</p>")
      }

      labels <- c("Lightest", "Light", "Medium", "Dark", "Darkest")
      generate_swatch_html(ramp, labels)
    })
  })

  # Diverging Palette Preview
  output$diverging_preview <- renderText({
    req({
      base_color <- input$base_color

      if (is.null(base_color) || base_color == "") {
        return("<p>Select a base color to see the diverging palette</p>")
      }

      div_palette <- gcps_diverging[[base_color]]
      if (is.null(div_palette)) {
        return("<p>No diverging palette available for this color</p>")
      }

      labels <- c("Low", "Below", "Center", "Above", "High")
      generate_swatch_html(div_palette, labels)
    })
  })

  # Qualitative Palette Preview
  output$qualitative_preview <- renderText({
    req({
      base_color <- input$base_color

      if (is.null(base_color) || base_color == "") {
        return("<p>Select a base color to see the qualitative palette</p>")
      }

      qual_palette <- gcps_qualitative[[base_color]]
      if (is.null(qual_palette)) {
        return("<p>No qualitative palette available for this color</p>")
      }

      generate_swatch_html(qual_palette, gcps_qualitative_labels)
    })
  })

  # Font Preview
  output$font_preview <- renderText({
    req({
      font_family <- input$font_family
      font_weight <- input$font_weight
      base_font_size <- input$base_font_size
      heading_font_size <- input$heading_font_size

      font_css <- sprintf(
        "font-family: %s; font-weight: %s;",
        font_families[[font_family]]$value,
        font_weight
      )

      div_style <- sprintf(
        "padding: 20px; background: #fff; border-radius: 8px; margin: 10px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"
      )

      HTML(sprintf(
        '<div style="%s">
          <h1 style="%s font-size: %dpx;">Heading 1 - Sample Dashboard Title</h1>
          <h2 style="%s font-size: %dpx;">Heading 2 - Section Title</h2>
          <h3 style="%s font-size: 16px;">Heading 3 - Subsection</h3>
          <p style="%s font-size: %dpx;">
            This is sample body text demonstrating the %s at %s weight.
            The quick brown fox jumps over the lazy dog.
          </p>
          <p style="%s font-size: %dpx;">
            <strong>Bold text</strong> and <em>italic text</em> and <code>monospace code</code>.
          </p>
        </div>',
        div_style,
        font_css, heading_font_size, font_css, heading_font_size, font_css,
        font_css, base_font_size, font_css, base_font_size,
        font_css, font_families[[font_family]]$value, font_weight
      ))
    })
  })

  # Apply palette to layout
  observeEvent(input$apply_palette, {
    base_color <- input$base_color
    if (!is.null(base_color) && base_color %in% names(gcps_base)) {
      # Update accent color with selected base color
      updateColourInput(session, "accent", value = gcps_base[base_color])
      showNotification(sprintf("Applied %s palette to layout!", base_color), type = "message")
    }
  })

  # Download R Code
  output$download_r_code <- downloadHandler(
    filename = function() {
      sprintf("gcps_palette_%s.R", input$base_color)
    },
    content = function() {
      base_color <- input$base_color
      ramp <- gcps_ramps[[base_color]]
      div_palette <- gcps_diverging[[base_color]]
      qual_palette <- gcps_qualitative[[base_color]]

      r_code <- sprintf(
'# GCPS Color Palette - %s base
# Generated by Dashboard Layout Architect

# Sequential Ramp (5 steps: light to dark)
gcps_%s_ramp <- c(
  lightest = "%s",
  light    = "%s",
  medium   = "%s",
  dark     = "%s",
  darkest  = "%s"
)

# Diverging Palette (5 steps: low -> center -> high)
gcps_%s_diverging <- c(
  low    = "%s",
  below  = "%s",
  center = "%s",
  above = "%s",
  high   = "%s"
)

# Qualitative Palette (8 colors)
gcps_%s_qualitative <- c(
  primary     = "%s",
  light       = "%s",
  lighter     = "%s",
  lightest    = "%s",
  neutral_lt  = "%s",
  neutral_mid = "%s",
  neutral_dk  = "%s",
  neutral_darkest = "%s"
)

# Usage in ggplot2:
# scale_fill_manual(values = gcps_%s_ramp)
# scale_color_manual(values = gcps_%s_qualitative)
',
        base_color, base_color,
        ramp[1], ramp[2], ramp[3], ramp[4], ramp[5],
        base_color,
        div_palette[1], div_palette[2], div_palette[3], div_palette[4], div_palette[5],
        base_color,
        qual_palette[1], qual_palette[2], qual_palette[3], qual_palette[4],
        qual_palette[5], qual_palette[6], qual_palette[7], qual_palette[8],
        base_color, base_color
      )

      r_code
    }
  )

  # Download CSS Variables
  output$download_css_vars <- downloadHandler(
    filename = function() {
      sprintf("gcps_palette_%s.css", input$base_color)
    },
    content = function() {
      base_color <- input$base_color
      ramp <- gcps_ramps[[base_color]]
      div_palette <- gcps_diverging[[base_color]]
      qual_palette <- gcps_qualitative[[base_color]]
      font_family <- input$font_family
      font_weight <- input$font_weight

      css_vars <- sprintf(
'/* GCPS Color Palette - %s base */
/* Generated by Dashboard Layout Architect */

:root {
  /* Sequential Ramp */
  --%s-lightest: %s;
  --%s-light: %s;
  --%s-medium: %s;
  --%s-dark: %s;
  --%s-darkest: %s;

  /* Diverging Palette */
  --%s-low: %s;
  --%s-below: %s;
  --%s-center: %s;
  --%s-above: %s;
  --%s-high: %s;

  /* Qualitative Palette */
  --%s-primary: %s;
  --%s-qual-light: %s;
  --%s-qual-lighter: %s;
  --%s-qual-lightest: %s;
  --%s-neutral-lt: %s;
  --%s-neutral-mid: %s;
  --%s-neutral-dk: %s;
  --%s-neutral-darkest: %s;

  /* Typography */
  --font-family: %s;
  --font-weight: %s;
}
',
        base_color,
        base_color, ramp[1], ramp[2], ramp[3], ramp[4], ramp[5],
        base_color, div_palette[1], div_palette[2], div_palette[3], div_palette[4], div_palette[5],
        base_color, qual_palette[1], qual_palette[2], qual_palette[3], qual_palette[4],
        qual_palette[5], qual_palette[6], qual_palette[7], qual_palette[8],
        font_families[[font_family]]$value, font_weight
      )

      css_vars
    }
  )
}
# =============================================================================
# CUSTOM STYLES
# =============================================================================
# Add custom CSS for the app
app_css <- "
/* Sidebar - single scroll, compact inputs */
.sidebar {
  overflow-y: auto !important;
}
.wizard-container {
  overflow: visible;
}
.wizard-step h5 {
  color: #0097A7;
  margin-bottom: 10px;
  padding-bottom: 6px;
  border-bottom: 1px solid #e5e7eb;
  font-size: 13px;
  font-weight: 600;
}
.wizard-step h6 {
  color: #6b7280;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-top: 10px;
  margin-bottom: 8px;
}
.import-section {
  margin-bottom: 10px;
}
.import-section h5 {
  font-size: 13px;
  margin-bottom: 8px;
}
/* Standardized inputs */
.wizard-step .form-group {
  margin-bottom: 8px;
}
.wizard-step .form-group label {
  font-size: 12px;
  margin-bottom: 3px;
  font-weight: 500;
}
.wizard-step .form-control {
  font-size: 12px;
  padding: 6px 10px;
  height: 32px;
}
.wizard-step select.form-control {
  height: 32px;
  padding: 4px 10px;
}
.wizard-step input[type='text'] {
  font-size: 12px;
  padding: 6px 10px;
  height: 32px;
}
.wizard-step input[type='number'] {
  font-size: 12px;
  padding: 6px 10px;
  height: 32px;
}
.wizard-step .input-group {
  font-size: 12px;
  height: 32px;
}
.wizard-step .btn {
  font-size: 12px;
  padding: 6px 12px;
}
/* Compact color picker - match input height */
.colourpicker-input .input-group {
  width: 100%;
  height: 32px;
}
.colourpicker-input .input-group input {
  font-size: 12px;
  padding: 6px 10px;
  height: 32px;
}
.colourpicker-input .input-group-addon {
  height: 32px;
  padding: 4px 8px;
}
/* Checkbox compact */
.wizard-step .checkbox {
  margin-top: 6px;
  margin-bottom: 6px;
}
.wizard-step .checkbox label {
  font-size: 12px;
}
/* Horizontal rules */
.wizard-container hr {
  margin: 12px 0;
  border-top: 2px solid #e5e7eb;
}
/* Preview container */
.preview-container {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  overflow: auto;
  min-height: 500px;
}
.preview-iframe {
  display: block;
}
/* Code container */
.code-container {
  background: #1e1e1e;
  color: #d4d4d4;
  padding: 15px;
  border-radius: 8px;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 12px;
  overflow-x: auto;
  max-height: 500px;
  overflow-y: auto;
}
.code-container pre {
  margin: 0;
  color: #d4d4d4;
  white-space: pre-wrap;
  word-break: break-all;
}
/* Export controls */
.export-controls {
  margin-bottom: 10px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
}
.export-controls .btn {
  font-size: 12px;
}
/* Preview controls */
.preview-controls {
  margin-bottom: 15px;
}
/* Hide verbatim text output styling */
.shiny-text-output {
  margin: 0;
}
/* Success notification styling */
.shiny-notification-success {
  background-color: #10B981 !important;
  color: white !important;
}
/* Wizard actions */
.wizard-actions {
  margin-top: 10px;
}
.wizard-actions .btn {
  font-size: 12px;
  padding: 8px 12px;
}
/* Palette & Typography Tab */
.palette-container {
  padding: 15px;
}
.palette-section {
  background: #fff;
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 15px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}
.palette-section h4 {
  color: #0097A7;
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid #e5e7eb;
}
.palette-control {
  margin-bottom: 15px;
}
.typography-control {
  margin-bottom: 10px;
}
.palette-actions {
  margin-top: 15px;
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.palette-actions .btn {
  font-size: 12px;
}
"
# =============================================================================
# RUN APP
# =============================================================================
shinyApp(ui = tagList(
  shinyjs::useShinyjs(),
  tags$head(tags$style(HTML(app_css))),
  ui
), server)
