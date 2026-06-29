#' RCDS export presets
#'
#' Named output presets that fix the dimensions/DPI the archive re-types into
#' every `ggsave()` call. Each preset is `c(width, height, dpi)` in inches/DPI.
#'
#' @return A named list of presets.
#' @export
rcds_export_presets <- function() {
  list(
    social_square   = c(width = 12, height = 12, dpi = 300),  # IG/X square
    social_portrait = c(width = 11, height = 14, dpi = 300),  # tall feed post
    social_land     = c(width = 16, height =  9, dpi = 300),  # 16:9 card
    poster_land     = c(width = 20, height = 15, dpi = 300),  # large landscape
    poster_port     = c(width = 18, height = 24, dpi = 300),  # large portrait
    journal_single  = c(width =  6.5, height = 5, dpi = 600), # 1-col figure
    journal_double  = c(width = 13, height =  8, dpi = 600),  # 2-col figure
    slide_169       = c(width = 13.33, height = 7.5, dpi = 200),
    web             = c(width = 12, height =  8, dpi = 150)
  )
}

#' Export an RCDS map with a preset
#'
#' Thin, opinionated wrapper over [ggplot2::ggsave()] that applies a named
#' [rcds_export_presets()] preset, defaults to the Cairo device for crisp
#' showtext rendering, and matches the background to the canvas so exports never
#' come out transparent.
#'
#' @param plot The plot/patchwork to save.
#' @param filename Output path.
#' @param preset A preset name from [rcds_export_presets()].
#' @param canvas Canvas key (sets the export background).
#' @param width,height,dpi Optional overrides of the preset.
#' @param device Graphics device; default `"cairo"` ("cairo_pdf" auto-selected
#'   for `.pdf`).
#' @param ... Passed to [ggplot2::ggsave()].
#' @return The filename, invisibly.
#' @examples
#' \dontrun{
#' rcds_export(p, "day16.png", preset = "poster_land", canvas = "dark")
#' }
#' @export
rcds_export <- function(plot, filename, preset = "social_portrait",
                        canvas = "dark", width = NULL, height = NULL,
                        dpi = NULL, device = "cairo", ...) {
  presets <- rcds_export_presets()
  if (!preset %in% names(presets)) {
    stop(sprintf("Unknown preset '%s'. One of: %s", preset,
                 paste(names(presets), collapse = ", ")), call. = FALSE)
  }
  p <- presets[[preset]]
  w <- width  %||% unname(p["width"])
  h <- height %||% unname(p["height"])
  d <- dpi    %||% unname(p["dpi"])

  toks <- rcds_tokens()
  bg <- switch(canvas, dark = toks$canvas$dark, deep = toks$canvas$deep,
               slate = toks$canvas$slate, graphite = toks$canvas$graphite,
               light = toks$canvas$light, vintage = toks$canvas$vintage,
               toks$canvas$dark)

  is_pdf <- grepl("\\.pdf$", filename, ignore.case = TRUE)
  dev <- if (is_pdf) "cairo_pdf" else device

  # keep showtext DPI in lockstep with the export so type sizes are honoured
  if (requireNamespace("showtext", quietly = TRUE)) {
    old <- showtext::showtext_opts()
    on.exit(do.call(showtext::showtext_opts, old), add = TRUE)
    showtext::showtext_opts(dpi = d)
  }

  ggplot2::ggsave(filename = filename, plot = plot, device = dev,
                  width = w, height = h, dpi = d, units = "in", bg = bg, ...)
  message(sprintf("rcds: wrote %s (%g x %g in @ %g dpi, canvas=%s).",
                  filename, w, h, d, canvas))
  invisible(filename)
}
