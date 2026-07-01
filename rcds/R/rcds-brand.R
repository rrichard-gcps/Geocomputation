# =============================================================================
# rcds-brand.R -- the active-brand default.
# Lets the framework yield one identity out of the box while staying switchable.
# "gcps"    -> the imported Gwinnett County Public Schools brand pack (default)
# "archive" -> the dark, archive-derived rcds identity
# The brand drives the default font voice, map theme, and palettes used by the
# convenience entry points theme_map() / scale_*_map_*() / rcds_fonts(NULL).
# =============================================================================

#' @keywords internal
.rcds_brand_defaults <- function(brand) {
  switch(brand,
    gcps = list(
      voice = "gcps_civic",
      map = list(engine = "gcps", theme = "civic"),
      seq = "gcps_teal", qual = "qual_gcps", div = "gcps_blue_div"),
    archive = list(
      voice = "default",
      map = list(engine = "archive", canvas = "dark"),
      seq = "seq_blue", qual = "qual_brand", div = "div_balance"),
    stop("Unknown brand: '", brand, "'. Use 'gcps' or 'archive'.", call. = FALSE))
}

#' Get or set the active rcds brand
#'
#' The brand determines what the convenience entry points produce by default:
#' [theme_map()], [scale_fill_map_c()] and friends, and [rcds_fonts()] called
#' with no voice. `"gcps"` (the imported Gwinnett County Public Schools system)
#' is the out-of-the-box default; `"archive"` selects the dark, archive-derived
#' identity. Explicit calls (e.g. `theme_rcds_map("dark")`,
#' `scale_fill_rcds_c("seq_blue")`) are unaffected by the brand.
#'
#' @param brand `"gcps"`, `"archive"`, or `NULL` to read the current value.
#' @return The active brand string (invisibly when setting).
#' @examples
#' rcds_brand()             # current default
#' \dontrun{
#' rcds_brand("archive")    # switch the whole tool back to the dark identity
#' }
#' @export
rcds_brand <- function(brand = NULL) {
  if (is.null(brand)) return(getOption("rcds.brand", "gcps"))
  brand <- match.arg(brand, c("gcps", "archive"))
  options(rcds.brand = brand)
  message(sprintf("rcds: default brand set to '%s'.", brand))
  invisible(brand)
}

#' The active brand's default font voice
#' @return A voice name for [rcds_fonts()].
#' @export
rcds_default_voice <- function() .rcds_brand_defaults(rcds_brand())$voice

#' The active brand's default palette for a given data type
#' @param type `"sequential"`, `"qualitative"`, or `"diverging"`.
#' @return An rcds palette name (see [rcds_palettes()]).
#' @examples
#' rcds_default_palette("sequential")
#' @export
rcds_default_palette <- function(type = c("sequential", "qualitative", "diverging")) {
  type <- match.arg(type)
  d <- .rcds_brand_defaults(rcds_brand())
  switch(type, sequential = d$seq, qualitative = d$qual, diverging = d$div)
}

#' The house map theme for the active brand
#'
#' The single entry point for a themed map: returns the active brand's default
#' map theme (GCPS Civic, or the archive dark theme). Switch the whole tool's
#' look with [rcds_brand()] rather than changing every map.
#'
#' @param base Base type size (points).
#' @param legend_position `"bottom"` (default), `"right"`, or `"none"`.
#' @param ... Passed to the underlying theme.
#' @return A ggplot2 theme.
#' @examples
#' \dontrun{
#' ggplot(districts) + geom_sf(aes(fill = v)) + scale_fill_map_c() + theme_map()
#' }
#' @export
theme_map <- function(base = 14, legend_position = "bottom", ...) {
  d <- .rcds_brand_defaults(rcds_brand())
  if (d$map$engine == "gcps") {
    theme_gcps_map(d$map$theme, base = base, legend_position = legend_position, ...)
  } else {
    theme_rcds_map(base = base, canvas = d$map$canvas,
                   legend_position = legend_position, ...)
  }
}

#' Brand-default ggplot scales
#'
#' Continuous/discrete fill and colour scales that use the active brand's default
#' palette, so a map inherits the house identity without naming a palette. For a
#' specific palette use [scale_fill_rcds_c()] etc.
#'
#' @param ... Passed to the underlying `scale_*_rcds_*()`.
#' @name scale_map
#' @export
scale_fill_map_c <- function(...) scale_fill_rcds_c(rcds_default_palette("sequential"), ...)
#' @rdname scale_map
#' @export
scale_color_map_c <- function(...) scale_color_rcds_c(rcds_default_palette("sequential"), ...)
#' @rdname scale_map
#' @export
scale_fill_map_d <- function(...) scale_fill_rcds_d(rcds_default_palette("qualitative"), ...)
#' @rdname scale_map
#' @export
scale_color_map_d <- function(...) scale_color_rcds_d(rcds_default_palette("qualitative"), ...)
