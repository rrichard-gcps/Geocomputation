#' Proof a palette for colour-vision deficiency (CVD)
#'
#' Simulates how a palette appears under the three common colour-vision
#' deficiencies (deuteranopia, protanopia, tritanopia) and flags colour pairs
#' that may become confusable. This turns the design system's "colourblind-safe"
#' claim into a check you can run, rather than a promise.
#'
#' For qualitative palettes the key risk is two categories collapsing onto each
#' other; this is measured as the minimum pairwise CIE Lab distance (deltaE)
#' after simulation. For sequential/diverging ramps, pair this with
#' [rcds_greyscale_check()] (luminance ordering is what matters there).
#'
#' @param x A palette: a character vector of hex colours, or the name of an RCDS
#'   palette (see [rcds_palettes()]).
#' @param types CVD types to simulate; any of `"deutan"`, `"protan"`, `"tritan"`.
#' @param severity Simulation severity in `[0, 1]` (1 = dichromacy).
#' @param min_delta deltaE below which a simulated pair is flagged confusable.
#' @param plot If `TRUE` (default) return a ggplot of swatch rows (Original +
#'   each simulation) on the dark canvas; if `FALSE` return the data.frame of
#'   simulated colours. Either way, warnings list confusable pairs and the result
#'   carries a `report` attribute.
#' @return A ggplot (when `plot = TRUE`) or a data.frame (when `plot = FALSE`).
#'   Requires the `colorspace` package.
#' @examples
#' \dontrun{
#' rcds_cvd_check("qual_brand")
#' rcds_cvd_check(c("#1E6FB8", "#3FA34D"), plot = FALSE)  # blue vs green
#' }
#' @export
rcds_cvd_check <- function(x, types = c("deutan", "protan", "tritan"),
                           severity = 1, min_delta = 15, plot = TRUE) {
  if (!requireNamespace("colorspace", quietly = TRUE)) {
    stop("rcds_cvd_check() requires the 'colorspace' package.", call. = FALSE)
  }
  types <- match.arg(types, several.ok = TRUE)
  cols <- .rcds_resolve_colors(x)

  sim_fun <- list(deutan = colorspace::deutan, protan = colorspace::protan,
                  tritan = colorspace::tritan)

  conditions <- c("Original", types)
  rows <- do.call(rbind, lapply(conditions, function(cond) {
    cc <- if (cond == "Original") cols else sim_fun[[cond]](cols, severity = severity)
    data.frame(condition = cond, index = seq_along(cc), colour = cc,
               stringsAsFactors = FALSE)
  }))
  rows$condition <- factor(rows$condition, levels = rev(conditions))

  # confusability: min pairwise deltaE within each simulated condition
  report <- do.call(rbind, lapply(types, function(cond) {
    cc <- sim_fun[[cond]](cols, severity = severity)
    md <- .rcds_min_pairwise_delta(cc)
    data.frame(type = cond, min_deltaE = round(md$min, 1),
               pair = paste(md$i, md$j, sep = "-"), stringsAsFactors = FALSE)
  }))
  flagged <- report[report$min_deltaE < min_delta, , drop = FALSE]
  if (nrow(flagged)) {
    warning(sprintf(
      "rcds_cvd_check: %d CVD type(s) have confusable pairs (min deltaE < %g): %s.",
      nrow(flagged), min_delta,
      paste(sprintf("%s (colours %s, deltaE=%.1f)", flagged$type, flagged$pair,
                    flagged$min_deltaE), collapse = "; ")), call. = FALSE)
  } else {
    message(sprintf("rcds_cvd_check: all simulations keep pairs >= %g deltaE apart.",
                    min_delta))
  }

  if (!plot) {
    attr(rows, "report") <- report
    return(rows)
  }
  p <- ggplot2::ggplot(rows, ggplot2::aes(x = .data$index, y = .data$condition,
                                          fill = .data$colour)) +
    ggplot2::geom_tile(width = 0.95, height = 0.85) +
    ggplot2::scale_fill_identity() +
    ggplot2::labs(title = "CVD proof",
                  subtitle = "Original palette vs simulated colour-vision deficiencies",
                  x = NULL, y = NULL) +
    theme_rcds(canvas = "dark")
  attr(p, "report") <- report
  p
}

#' Proof a palette for greyscale printing
#'
#' Converts a palette to its perceptual greyscale (CIE Lab luminance) and reports
#' whether it survives black-and-white reproduction: sequential/diverging ramps
#' need monotone, well-separated luminance; qualitative palettes need every
#' category to land on a distinct grey.
#'
#' Uses only base `grDevices` (no extra dependency).
#'
#' @param x A palette: a hex vector or an RCDS palette name.
#' @param min_delta Minimum luminance gap (L*, 0-100) between adjacent/least-
#'   separated colours before a warning fires.
#' @param plot If `TRUE` (default) return a ggplot of Original vs Greyscale rows;
#'   if `FALSE` return a data.frame of colours with their luminance.
#' @return A ggplot or data.frame; carries an `luminance` attribute.
#' @examples
#' rcds_greyscale_check("seq_blue", plot = FALSE)
#' @export
rcds_greyscale_check <- function(x, min_delta = 8, plot = TRUE) {
  cols <- .rcds_resolve_colors(x)
  L <- .rcds_lab(cols)[, 1]
  grey <- grDevices::grey(pmin(pmax(L / 100, 0), 1))

  is_named_seq <- is.character(x) && length(x) == 1 &&
    grepl("^(seq_|div_)", x)
  if (is_named_seq) {
    d <- diff(L)
    monotone <- all(d <= 0) || all(d >= 0)
    worst <- min(abs(d))
    if (!monotone) {
      warning("rcds_greyscale_check: luminance is not monotone - this ordered ",
              "ramp will read ambiguously in greyscale.", call. = FALSE)
    } else if (worst < min_delta) {
      warning(sprintf(
        "rcds_greyscale_check: smallest adjacent luminance step is %.1f (< %g); steps may merge in print.",
        worst, min_delta), call. = FALSE)
    } else {
      message(sprintf("rcds_greyscale_check: monotone ramp, min step %.1f L*.", worst))
    }
  } else {
    md <- .rcds_min_pairwise_delta(grey, lab = matrix(c(L, rep(0, length(L)),
                                                        rep(0, length(L))), ncol = 3))
    if (md$min < min_delta) {
      warning(sprintf(
        "rcds_greyscale_check: colours %s map to near-identical greys (delta L* = %.1f < %g).",
        paste(md$i, md$j, sep = "-"), md$min, min_delta), call. = FALSE)
    } else {
      message(sprintf("rcds_greyscale_check: all greys >= %g L* apart (min %.1f).",
                      min_delta, md$min))
    }
  }

  df <- data.frame(index = seq_along(cols), colour = cols, grey = grey,
                   luminance = round(L, 1), stringsAsFactors = FALSE)
  if (!plot) {
    attr(df, "luminance") <- L
    return(df)
  }
  rows <- rbind(
    data.frame(condition = "Original", index = df$index, colour = df$colour),
    data.frame(condition = "Greyscale", index = df$index, colour = df$grey))
  rows$condition <- factor(rows$condition, levels = c("Greyscale", "Original"))
  p <- ggplot2::ggplot(rows, ggplot2::aes(x = .data$index, y = .data$condition,
                                          fill = .data$colour)) +
    ggplot2::geom_tile(width = 0.95, height = 0.85) +
    ggplot2::scale_fill_identity() +
    ggplot2::labs(title = "Greyscale proof",
                  subtitle = "Does the palette survive black-and-white printing?",
                  x = NULL, y = NULL) +
    theme_rcds(canvas = "dark")
  attr(p, "luminance") <- L
  p
}

# --- internals ---------------------------------------------------------------

#' @keywords internal
.rcds_resolve_colors <- function(x) {
  if (is.character(x) && length(x) == 1 && x %in% names(.rcds_palette_defs())) {
    return(unname(.rcds_palette_defs()[[x]]))
  }
  cols <- as.character(x)
  ok <- grepl("^#[0-9A-Fa-f]{6}$", cols)
  if (!all(ok)) {
    stop("rcds: expected an RCDS palette name or a vector of #RRGGBB colours; ",
         "invalid: ", paste(cols[!ok], collapse = ", "), call. = FALSE)
  }
  cols
}

#' @keywords internal
#' @return An N x 3 matrix of CIE Lab values (L, a, b) for hex colours.
.rcds_lab <- function(cols) {
  rgb <- t(grDevices::col2rgb(cols)) / 255
  grDevices::convertColor(rgb, from = "sRGB", to = "Lab")
}

#' @keywords internal
#' @return list(min, i, j): minimum pairwise deltaE (Euclidean in Lab) and the
#'   1-based indices of the closest pair. Pass `lab` to reuse a precomputed
#'   matrix (e.g. luminance-only for greyscale).
.rcds_min_pairwise_delta <- function(cols, lab = NULL) {
  if (is.null(lab)) lab <- .rcds_lab(cols)
  n <- nrow(lab)
  if (n < 2) return(list(min = Inf, i = NA_integer_, j = NA_integer_))
  best <- Inf; bi <- 1L; bj <- 2L
  for (i in 1:(n - 1)) for (j in (i + 1):n) {
    d <- sqrt(sum((lab[i, ] - lab[j, ])^2))
    if (d < best) { best <- d; bi <- i; bj <- j }
  }
  list(min = best, i = bi, j = bj)
}
