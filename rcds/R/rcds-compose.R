#' Compose a finished RCDS map layout
#'
#' Assembles the archive's signature composition -- a main map, an optional
#' locator inset, and an optional credits strip -- into one balanced figure
#' using `patchwork`. Replaces the bespoke `plot_layout()`/`area()` wrangling
#' repeated across Days 2 and 16.
#'
#' @param main The primary map (a ggplot).
#' @param locator Optional inset ggplot (e.g. from [rcds_locator()]).
#' @param credits Optional credits strip (e.g. from [rcds_credits()]).
#' @param title,subtitle Optional overall title/subtitle applied via
#'   `patchwork::plot_annotation()`.
#' @param layout One of `"poster"` (locator top-right overlay, credits strip
#'   bottom), `"stack"` (main over credits), or `"sidebar"` (locator + legend
#'   column at right). Ignored if both `locator` and `credits` are `NULL`.
#' @param canvas Canvas key for the overall background.
#' @param base Base type size.
#' @param inset Numeric `c(left, bottom, right, top)` in npc for the locator
#'   overlay when `layout = "poster"`.
#' @return A patchwork object.
#' @export
rcds_compose <- function(main, locator = NULL, credits = NULL,
                         title = NULL, subtitle = NULL,
                         layout = c("poster", "stack", "sidebar"),
                         canvas = "dark", base = 11,
                         inset = c(0.62, 0.62, 0.98, 0.98)) {
  if (!requireNamespace("patchwork", quietly = TRUE)) {
    stop("rcds_compose() requires the 'patchwork' package.", call. = FALSE)
  }
  layout <- match.arg(layout)
  toks <- rcds_tokens()
  bg <- switch(canvas, dark = toks$canvas$dark, deep = toks$canvas$deep,
               slate = toks$canvas$slate, graphite = toks$canvas$graphite,
               light = toks$canvas$light, vintage = toks$canvas$vintage,
               toks$canvas$dark)

  body <- main
  if (!is.null(locator) && layout == "poster") {
    body <- body + patchwork::inset_element(
      locator, left = inset[1], bottom = inset[2], right = inset[3],
      top = inset[4], align_to = "full")
  }

  out <- switch(layout,
    poster = if (!is.null(credits)) {
      body / credits + patchwork::plot_layout(heights = c(8, 1))
    } else body,
    stack = if (!is.null(credits)) {
      body / credits + patchwork::plot_layout(heights = c(8, 1))
    } else body,
    sidebar = {
      side <- locator %||% patchwork::plot_spacer()
      row <- body + side + patchwork::plot_layout(widths = c(3, 1))
      if (!is.null(credits)) row / credits + patchwork::plot_layout(heights = c(8, 1)) else row
    }
  )

  ann_theme <- ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = bg, colour = NA),
    text = ggplot2::element_text(family = rcds_font("body")))
  if (!is.null(title) || !is.null(subtitle)) {
    ts <- rcds_type_scale(base)
    is_dark <- canvas %in% c("dark", "deep", "slate", "graphite")
    ink1 <- if (is_dark) toks$ink$on_dark_1 else toks$ink$on_light_1
    ink2 <- if (is_dark) toks$ink$on_dark_2 else toks$ink$on_light_2
    ann_theme <- ann_theme +
      ggplot2::theme(
        plot.title = ggplot2::element_text(family = rcds_font("display"),
          face = "bold", colour = ink1, size = ts[["title"]], hjust = 0),
        plot.subtitle = ggplot2::element_text(family = rcds_font("display"),
          colour = ink2, size = ts[["subtitle"]], hjust = 0))
  }
  out + patchwork::plot_annotation(title = title, subtitle = subtitle,
                                   theme = ann_theme)
}
