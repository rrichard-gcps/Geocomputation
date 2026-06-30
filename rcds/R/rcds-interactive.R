#' RCDS basemap providers by canvas
#'
#' Maps each RCDS canvas to a CARTO/Leaflet provider tile set, so an interactive
#' map starts on a background that matches the static identity. Dark canvases get
#' DarkMatter; light canvases get Positron.
#'
#' @param labels If `TRUE` (default) use the labelled variant; `FALSE` for a clean
#'   no-labels base (label your own features).
#' @return A named character vector (canvas -> provider name).
#' @examples
#' rcds_basemaps()[["dark"]]
#' @export
rcds_basemaps <- function(labels = TRUE) {
  suffix <- if (labels) "" else "NoLabels"
  c(
    dark     = paste0("CartoDB.DarkMatter", suffix),
    deep     = paste0("CartoDB.DarkMatter", suffix),
    graphite = paste0("CartoDB.DarkMatter", suffix),
    slate    = paste0("CartoDB.DarkMatter", suffix),
    light    = paste0("CartoDB.Positron", suffix),
    paper    = paste0("CartoDB.Positron", suffix),
    vintage  = paste0("CartoDB.Positron", suffix)
  )
}

#' Active font families for the HTML/interactive context
#'
#' Resolves the current [rcds_fonts()] voice (or the default voice) to the family
#' names used in CSS, plus the Google Fonts import URL that loads them.
#' @keywords internal
.rcds_voice_families <- function() {
  active <- getOption("rcds.fonts", NULL)
  if (is.null(active)) {
    active <- list(display = "Oswald", body = "Roboto Condensed", caption = "Roboto")
  }
  fams <- unlist(active)
  import <- paste0(
    "https://fonts.googleapis.com/css2?",
    paste(sprintf("family=%s", gsub(" ", "+", unique(unname(fams)))), collapse = "&"),
    "&display=swap")
  list(display = active$display, body = active$body, caption = active$caption,
       import = import)
}

#' RCDS CSS for interactive maps
#'
#' Generates the stylesheet that gives Leaflet (and other HTML map widgets) the
#' RCDS identity: token-driven CSS custom properties, the active font voice, and
#' styled popups, tooltips, controls, legend, and attribution on the chosen
#' canvas.
#'
#' The `:root { --rcds-* }` custom properties are the **integration seam**: a
#' Claude Design import (or any external design system) only needs to override
#' these variables to restyle every interactive map, exactly as overriding
#' [rcds_tokens()] restyles every static map.
#'
#' @param canvas Canvas key (see [theme_rcds()]).
#' @return A single CSS string.
#' @examples
#' substr(rcds_interactive_css("dark"), 1, 60)
#' @export
rcds_interactive_css <- function(canvas = "dark") {
  tk <- rcds_tokens()
  bg <- switch(canvas, dark = tk$canvas$dark, deep = tk$canvas$deep,
               slate = tk$canvas$slate, graphite = tk$canvas$graphite,
               light = tk$canvas$light, paper = tk$canvas$paper,
               vintage = tk$canvas$vintage,
               stop("Unknown canvas: ", canvas, call. = FALSE))
  is_dark <- canvas %in% c("dark", "deep", "slate", "graphite")
  ink1 <- if (is_dark) tk$ink$on_dark_1 else tk$ink$on_light_1
  ink2 <- if (is_dark) tk$ink$on_dark_2 else tk$ink$on_light_2
  panel <- if (is_dark) tk$canvas$deep else tk$canvas$paper
  hairline <- if (is_dark) tk$ink$hairline_dark else tk$ink$hairline_light
  v <- .rcds_voice_families()

  sprintf("
@import url('%s');
:root {
  --rcds-canvas: %s;
  --rcds-panel: %s;
  --rcds-ink-1: %s;
  --rcds-ink-2: %s;
  --rcds-hairline: %s;
  --rcds-accent-blue: %s;
  --rcds-accent-amber: %s;
  --rcds-accent-teal: %s;
  --rcds-font-display: '%s', sans-serif;
  --rcds-font-body: '%s', sans-serif;
  --rcds-font-caption: '%s', sans-serif;
}
.leaflet-container { background: var(--rcds-canvas); font-family: var(--rcds-font-body); }
.leaflet-popup-content-wrapper, .leaflet-popup-tip {
  background: var(--rcds-panel); color: var(--rcds-ink-1);
  border-radius: 6px; box-shadow: 0 2px 10px rgba(0,0,0,0.4);
}
.leaflet-popup-content { font-family: var(--rcds-font-body); margin: 10px 14px; }
.leaflet-popup-content b, .leaflet-popup-content strong, .rcds-popup-title {
  font-family: var(--rcds-font-display); color: var(--rcds-ink-1);
}
.leaflet-tooltip.rcds-tooltip {
  background: var(--rcds-panel); color: var(--rcds-ink-1);
  border: 1px solid var(--rcds-hairline); font-family: var(--rcds-font-body);
  box-shadow: none;
}
.leaflet-bar, .leaflet-control-zoom a {
  background: var(--rcds-panel); color: var(--rcds-ink-1);
  border-color: var(--rcds-hairline);
}
.leaflet-control-zoom a:hover { background: var(--rcds-canvas); }
.info.legend, .leaflet-control.legend {
  background: var(--rcds-panel); color: var(--rcds-ink-2);
  font-family: var(--rcds-font-body); padding: 8px 10px; border-radius: 6px;
  line-height: 1.4;
}
.info.legend .rcds-legend-title, .legend strong {
  font-family: var(--rcds-font-display); color: var(--rcds-ink-1);
}
.leaflet-control-attribution {
  background: rgba(0,0,0,0.45) !important; color: var(--rcds-ink-2) !important;
  font-family: var(--rcds-font-caption);
}
.leaflet-control-attribution a { color: var(--rcds-accent-blue) !important; }
",
    v$import, bg, panel, ink1, ink2, hairline,
    tk$accent$blue, tk$accent$amber, tk$accent$teal,
    v$display, v$body, v$caption)
}

#' Start an RCDS-styled Leaflet map
#'
#' Initialises a `leaflet` widget on the RCDS basemap for `canvas` and injects
#' [rcds_interactive_css()] so popups, controls, and the legend carry the
#' identity. Add layers with `leaflet::add*` or [rcds_leaflet_choropleth()].
#'
#' @param data Optional `sf`/data passed to [leaflet::leaflet()].
#' @param canvas Canvas key.
#' @param labels Use the labelled basemap variant.
#' @param ... Passed to [leaflet::leaflet()].
#' @return A `leaflet` htmlwidget.
#' @examples
#' \dontrun{
#' rcds_leaflet(canvas = "dark") |>
#'   rcds_leaflet_choropleth(districts, value = "enrollment", palette = "seq_blue")
#' }
#' @export
rcds_leaflet <- function(data = NULL, canvas = "dark", labels = TRUE, ...) {
  .rcds_need(c("leaflet", "htmlwidgets", "htmltools"), "rcds_leaflet")
  prov <- rcds_basemaps(labels = labels)[[canvas]]
  m <- leaflet::leaflet(data = data, ...)
  m <- leaflet::addProviderTiles(m, prov)
  htmlwidgets::prependContent(
    m, htmltools::tags$style(rcds_interactive_css(canvas)))
}

#' Bridge an RCDS palette to a Leaflet colour function
#'
#' Wraps the RCDS palette families so interactive choropleths use the same
#' accessible ramps as static maps.
#'
#' @param palette RCDS palette name (see [rcds_palettes()]).
#' @param domain Value domain (passed to the leaflet colour function).
#' @param type `"numeric"`, `"bin"`, or `"factor"`.
#' @param bins For `type = "bin"`: number of bins or a breaks vector.
#' @param reverse Reverse the ramp.
#' @param ... Passed to the underlying `leaflet::color*` function.
#' @return A leaflet palette function.
#' @export
rcds_pal_leaflet <- function(palette = "seq_blue", domain = NULL,
                             type = c("numeric", "bin", "factor"),
                             bins = 5, reverse = FALSE, ...) {
  .rcds_need("leaflet", "rcds_pal_leaflet")
  type <- match.arg(type)
  switch(type,
    numeric = leaflet::colorNumeric(rcds_pal(palette, 256, reverse, "continuous"),
                                    domain = domain, ...),
    bin = leaflet::colorBin(rcds_pal(palette, 256, reverse, "continuous"),
                            domain = domain, bins = bins, ...),
    factor = {
      n <- if (!is.null(domain)) length(unique(domain)) else NULL
      cols <- if (is.null(n)) rcds_pal(palette, reverse = reverse)
              else rcds_pal(palette, n, reverse, "discrete")
      leaflet::colorFactor(cols, domain = domain, ...)
    })
}

#' Add an RCDS choropleth layer to a Leaflet map
#'
#' Convenience layer: fills `sf` polygons by `value` with an RCDS palette, a
#' hairline stroke, an RCDS-styled hover tooltip, and a matching legend.
#'
#' @param map A leaflet map (from [rcds_leaflet()]).
#' @param data An `sf` polygon layer.
#' @param value Column name (string) to encode.
#' @param palette RCDS palette name.
#' @param type Colour mapping: `"numeric"`, `"bin"`, or `"factor"`.
#' @param bins Bins for `type = "bin"`.
#' @param label Optional character vector / column for hover labels; defaults to
#'   the value.
#' @param legend_title Legend title.
#' @param opacity Fill opacity.
#' @param ... Passed to [leaflet::addPolygons()].
#' @return The leaflet map, with the layer and legend added.
#' @export
rcds_leaflet_choropleth <- function(map, data, value, palette = "seq_blue",
                                    type = "numeric", bins = 5, label = NULL,
                                    legend_title = value, opacity = 0.85, ...) {
  .rcds_need(c("leaflet", "sf"), "rcds_leaflet_choropleth")
  vals <- data[[value]]
  pal <- rcds_pal_leaflet(palette, domain = vals, type = type, bins = bins)
  lab <- if (is.null(label)) vals else if (length(label) == 1 && label %in% names(data)) data[[label]] else label

  map <- leaflet::addPolygons(
    map, data = data, fillColor = pal(vals), fillOpacity = opacity,
    color = rcds_color("ink.hairline_dark"), weight = 0.5,
    label = lab,
    labelOptions = leaflet::labelOptions(className = "rcds-tooltip"),
    highlightOptions = leaflet::highlightOptions(
      weight = 2, color = rcds_color("accent.blue_b"), bringToFront = TRUE),
    ...)
  leaflet::addLegend(map, position = "bottomright", pal = pal, values = vals,
                     title = paste0("<span class='rcds-legend-title'>",
                                    legend_title, "</span>"),
                     opacity = opacity)
}

#' A minimal MapLibre/MapGL style with the RCDS identity
#'
#' Returns a MapLibre GL style (as an R list) with the RCDS canvas as the map
#' background and token colours exposed, for use with `mapgl::maplibre(style=)`.
#' A starting point for vector interactive maps; add your own sources/layers.
#'
#' @param canvas Canvas key.
#' @return A named list (a MapLibre style spec).
#' @examples
#' rcds_maplibre_style("dark")$layers[[1]]$paint
#' @export
rcds_maplibre_style <- function(canvas = "dark") {
  tk <- rcds_tokens()
  bg <- switch(canvas, dark = tk$canvas$dark, deep = tk$canvas$deep,
               slate = tk$canvas$slate, graphite = tk$canvas$graphite,
               light = tk$canvas$light, paper = tk$canvas$paper,
               vintage = tk$canvas$vintage, tk$canvas$dark)
  list(
    version = 8L,
    name = paste0("RCDS ", canvas),
    sources = stats::setNames(list(), character()),
    layers = list(list(
      id = "rcds-background", type = "background",
      paint = list(`background-color` = bg)))
  )
}

#' Save an RCDS interactive widget to a self-contained HTML file
#'
#' @param widget A leaflet/htmlwidget.
#' @param file Output `.html` path.
#' @param selfcontained Inline all assets (default `TRUE`).
#' @param ... Passed to [htmlwidgets::saveWidget()].
#' @return The file path, invisibly.
#' @export
rcds_save_widget <- function(widget, file, selfcontained = TRUE, ...) {
  .rcds_need("htmlwidgets", "rcds_save_widget")
  htmlwidgets::saveWidget(widget, file = file, selfcontained = selfcontained, ...)
  message(sprintf("rcds: wrote interactive map %s.", file))
  invisible(file)
}

#' @keywords internal
.rcds_need <- function(pkgs, fn) {
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop(sprintf("%s() requires package(s): %s.", fn, paste(missing, collapse = ", ")),
         call. = FALSE)
  }
  invisible(TRUE)
}
