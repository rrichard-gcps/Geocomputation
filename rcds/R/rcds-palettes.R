#' RCDS palette families
#'
#' A curated set of palette *families* rather than one-off colour vectors. The
#' archive leaned on saturated rainbow scales (Spectral, ggsci futurama) that
#' are neither colourblind-safe nor print-stable. RCDS replaces them with
#' perceptually-ordered, accent-anchored ramps that hold up on the dark canvas,
#' in greyscale, and for the most common colour-vision deficiencies.
#'
#' Families:
#' \describe{
#'   \item{sequential}{`seq_blue`, `seq_amber`, `seq_teal` — single-hue luminance
#'     ramps anchored on the brand accents.}
#'   \item{diverging}{`div_balance` (amber<->blue, neutral mid), `div_temp`
#'     (teal<->red).}
#'   \item{qualitative}{`qual_brand` (6 brand-derived hues, max-distinct),
#'     `qual_soft` (muted, for many categories on dark).}
#'   \item{bivariate}{`biv_dkblue` 3x3 reference grid (drop-in for `biscale`).}
#' }
#'
#' All ramps are designed to be passed through [colorspace::darken()]/`lighten()`
#' if a specific canvas needs more contrast.
#'
#' @keywords internal
.rcds_palette_defs <- function() {
  acc <- rcds_tokens()$accent
  list(
    ## Sequential (light -> saturated accent) ---------------------------
    seq_blue  = c("#EAF2FB", "#B9D4F0", "#7FB1E0", "#4C8FCD", "#1E6FB8", "#0F4C84"),
    seq_amber = c("#FCEFDD", "#F8D5A6", "#F2B36A", "#E8852B", "#C56717", "#8F470C"),
    seq_teal  = c("#E2F3F0", "#B3E0D9", "#79C7BB", "#2A9D8F", "#1C7A6E", "#0F544B"),
    ## Diverging (accent <-> neutral mid <-> accent) --------------------
    div_balance = c("#8F470C", "#E8852B", "#F4C79A", "#E8E8E8", "#9CC2E5", "#1E6FB8", "#0F4C84"),
    div_temp    = c("#0F544B", "#2A9D8F", "#AFD9D2", "#EDEDED", "#E8A39B", "#C8443B", "#8A2A24"),
    ## Qualitative (categorical) ----------------------------------------
    qual_brand = unname(c(acc$blue, acc$amber, acc$teal, acc$red, acc$green, "#7E5BA6")),
    qual_soft  = c("#6C8EBF", "#D6995C", "#74A892", "#C97B7B", "#8FA869", "#9B82B5",
                   "#B0857A", "#7FA7B0"),
    ## Bivariate 3x3 (rows = y high->low within each x col) -------------
    biv_dkblue = c(
      "1-1" = "#D3D3D3", "2-1" = "#9FB8C4", "3-1" = "#5C9CB4",
      "1-2" = "#C99E9E", "2-2" = "#9786A0", "3-2" = "#5C7C9C",
      "1-3" = "#C25B5B", "2-3" = "#92516F", "3-3" = "#3F3F66"
    )
  )
}

#' Build an RCDS palette
#'
#' @param name Palette name (see [rcds_palettes()]).
#' @param n Number of colours to return. For continuous families the ramp is
#'   interpolated; for qualitative families the first `n` are returned (errors
#'   if `n` exceeds the family size).
#' @param reverse Reverse the ramp.
#' @param type `"auto"`, `"continuous"`, or `"discrete"`. `"continuous"` always
#'   interpolates; `"discrete"` subsets.
#' @return A character vector of hex colours.
#' @examples
#' rcds_pal("seq_blue", 5)
#' rcds_pal("qual_brand", 4)
#' rcds_pal("div_balance", 9)
#' @export
rcds_pal <- function(name, n = NULL, reverse = FALSE, type = "auto") {
  defs <- .rcds_palette_defs()
  if (!name %in% names(defs)) {
    stop(sprintf("Unknown palette '%s'. See rcds_palettes().", name), call. = FALSE)
  }
  # Bivariate families are a named "x-y" lookup grid, not a ramp: the names ARE
  # the payload, so return them intact (n/type/reverse don't apply).
  if (grepl("^biv_", name)) {
    return(defs[[name]])
  }
  cols <- unname(defs[[name]])
  is_qual <- grepl("^qual_", name)
  if (is.null(n)) n <- length(cols)
  if (type == "auto") type <- if (is_qual) "discrete" else "continuous"

  out <- if (type == "discrete") {
    if (n > length(cols)) {
      stop(sprintf("Palette '%s' has %d colours; requested %d. Use a continuous family or fewer categories.",
                   name, length(cols), n), call. = FALSE)
    }
    cols[seq_len(n)]
  } else {
    grDevices::colorRampPalette(cols)(n)
  }
  if (reverse) out <- rev(out)
  out
}

#' Catalogue of available palettes
#' @return A named list grouping palette names by family.
#' @export
rcds_palettes <- function() {
  list(
    sequential  = c("seq_blue", "seq_amber", "seq_teal"),
    diverging   = c("div_balance", "div_temp"),
    qualitative = c("qual_brand", "qual_soft"),
    bivariate   = c("biv_dkblue")
  )
}

# ggplot2 scale constructors --------------------------------------------------

#' RCDS continuous fill/colour scales
#' @param palette Palette name (a sequential or diverging family).
#' @param reverse Reverse the ramp.
#' @param ... Passed to [ggplot2::scale_fill_gradientn()] /
#'   [ggplot2::scale_color_gradientn()].
#' @export
scale_fill_rcds_c <- function(palette = "seq_blue", reverse = FALSE, ...) {
  ggplot2::scale_fill_gradientn(colours = rcds_pal(palette, 256, reverse, "continuous"), ...)
}
#' @rdname scale_fill_rcds_c
#' @export
scale_color_rcds_c <- function(palette = "seq_blue", reverse = FALSE, ...) {
  ggplot2::scale_color_gradientn(colours = rcds_pal(palette, 256, reverse, "continuous"), ...)
}

#' RCDS discrete fill/colour scales
#' @param palette Qualitative palette name.
#' @param reverse Reverse the order.
#' @param ... Passed to [ggplot2::discrete_scale()] downstream.
#' @export
scale_fill_rcds_d <- function(palette = "qual_brand", reverse = FALSE, ...) {
  pal_fun <- function(n) rcds_pal(palette, n, reverse, "discrete")
  ggplot2::discrete_scale("fill", paste0("rcds_", palette), palette = pal_fun, ...)
}
#' @rdname scale_fill_rcds_d
#' @export
scale_color_rcds_d <- function(palette = "qual_brand", reverse = FALSE, ...) {
  pal_fun <- function(n) rcds_pal(palette, n, reverse, "discrete")
  ggplot2::discrete_scale("colour", paste0("rcds_", palette), palette = pal_fun, ...)
}

#' Preview all RCDS palettes
#'
#' Renders every family as horizontal swatch strips on the dark canvas so you
#' can eyeball contrast before committing.
#' @param n Colours per ramp to display.
#' @return A ggplot object.
#' @export
rcds_show_palettes <- function(n = 7) {
  defs <- .rcds_palette_defs()
  names_v <- setdiff(names(defs), "biv_dkblue")
  rows <- do.call(rbind, lapply(seq_along(names_v), function(i) {
    nm <- names_v[i]
    cols <- rcds_pal(nm, n)
    data.frame(pal = nm, ord = i, x = seq_along(cols), col = cols,
               stringsAsFactors = FALSE)
  }))
  ggplot2::ggplot(rows, ggplot2::aes(x = .data$x, y = stats::reorder(.data$pal, -.data$ord),
                                     fill = .data$col)) +
    ggplot2::geom_tile(width = 0.95, height = 0.8) +
    ggplot2::scale_fill_identity() +
    ggplot2::labs(title = "RCDS palette families", x = NULL, y = NULL) +
    theme_rcds(canvas = "dark")
}
