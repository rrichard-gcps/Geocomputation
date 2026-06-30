#' Build the canonical RCDS signature caption
#'
#' The archive's single most consistent motif is the credit block:
#' `#30DayMapChallenge 2024 Day N: Theme / Tool: R / Created By: Roland Richard
#' / Data Sources: ...`. It drifts in format from map to map (pipes vs newlines,
#' "Tool" vs "Tools"). This builds it once, canonically, as a plain string you
#' can drop into `labs(caption=)`, or as rich text via [rcds_credits()].
#'
#' @param challenge Top line / project tag, e.g. `"#30DayMapChallenge 2024 Day 16: Choropleth"`.
#' @param author Creator name. Default `"Roland Richard"`.
#' @param tool Tool line. Default `"R"`.
#' @param sources Character vector of data sources (one per line).
#' @param handle Optional social handle, appended to the author line.
#' @return A single string with `\n` separators, ready for `labs(caption=)`.
#' @examples
#' rcds_signature(
#'   challenge = "#30DayMapChallenge 2024 Day 16: Choropleth",
#'   sources = c("U.S. Census Bureau", "NCES")
#' )
#' @export
rcds_signature <- function(challenge,
                           author = "Roland Richard",
                           tool = "R",
                           sources = NULL,
                           handle = NULL) {
  author_line <- paste0("Created By: ", author)
  if (!is.null(handle)) author_line <- paste0(author_line, " (", handle, ")")
  src_line <- if (!is.null(sources)) {
    paste0("Data Sources: ", paste(sources, collapse = "; "))
  } else NULL
  paste(c(challenge, paste0("Tool: ", tool), author_line, src_line),
        collapse = "\n")
}

#' Signature as a rich-text credits panel (patchwork-ready)
#'
#' The `ggtext::geom_richtext` credit strip the archive builds by hand (Days 2,
#' 16). Returns a standalone ggplot you can slot into [rcds_compose()] or
#' `patchwork`. Falls back to a plain `geom_text` panel if `ggtext` is absent.
#'
#' @inheritParams rcds_signature
#' @param canvas Canvas key (see [theme_rcds()]); the strip fill.
#' @param base Base type size in points.
#' @param align `"left"` or `"right"`.
#' @return A ggplot object (a one-panel credits strip).
#' @export
rcds_credits <- function(challenge,
                         author = "Roland Richard",
                         tool = "R",
                         sources = NULL,
                         handle = NULL,
                         canvas = "deep",
                         base = 11,
                         align = c("left", "right")) {
  align <- match.arg(align)
  toks <- rcds_tokens()
  bg <- switch(canvas, dark = toks$canvas$dark, deep = toks$canvas$deep,
               slate = toks$canvas$slate, graphite = toks$canvas$graphite,
               light = toks$canvas$light, vintage = toks$canvas$vintage,
               toks$canvas$deep)
  ts <- rcds_type_scale(base)
  author_line <- paste0("Created By: <b>", author, "</b>",
                        if (!is.null(handle)) paste0(" (", handle, ")") else "")
  src_line <- if (!is.null(sources)) {
    paste0("Data Sources: ", paste(sources, collapse = "; "))
  } else ""
  hjust <- if (align == "left") 0 else 1
  x <- if (align == "left") 0 else 1

  label <- sprintf(
    "<span style='font-size:%.0fpt;color:%s'><b>%s</b></span><br><span style='font-size:%.0fpt;color:%s'>Tool: %s &#124; %s</span><br><span style='font-size:%.0fpt;color:%s'>%s</span>",
    ts[["caption"]], toks$ink$on_dark_1, challenge,
    ts[["micro"]], toks$ink$on_dark_2, tool, author_line,
    ts[["micro"]], toks$ink$on_dark_3, src_line)

  if (requireNamespace("ggtext", quietly = TRUE)) {
    ggplot2::ggplot() +
      ggtext::geom_richtext(
        ggplot2::aes(x = x, y = 0, label = label),
        hjust = hjust, vjust = 0, fill = NA, label.colour = NA,
        family = rcds_font("caption")) +
      ggplot2::xlim(0, 1) +
      ggplot2::theme_void() +
      ggplot2::theme(plot.background = ggplot2::element_rect(fill = bg, colour = NA),
                     panel.background = ggplot2::element_rect(fill = bg, colour = NA))
  } else {
    plain <- rcds_signature(challenge, author, tool, sources, handle)
    ggplot2::ggplot() +
      ggplot2::annotate("text", x = x, y = 0, label = plain, hjust = hjust,
                        vjust = 0, colour = toks$ink$on_dark_2,
                        family = rcds_font("caption"), size = ts[["micro"]] / 2.83) +
      ggplot2::xlim(0, 1) +
      ggplot2::theme_void() +
      ggplot2::theme(plot.background = ggplot2::element_rect(fill = bg, colour = NA))
  }
}

#' RCDS scale bar (ggspatial wrapper)
#'
#' Pre-styled [ggspatial::annotation_scale()] matching the active canvas. The
#' archive almost always omits a scale bar; this makes adding a correct one a
#' one-liner.
#' @param location Corner, e.g. `"bl"`.
#' @param canvas Canvas key, controls line/text colour.
#' @param unit_category `"metric"` or `"imperial"`.
#' @param ... Passed to [ggspatial::annotation_scale()].
#' @export
rcds_scalebar <- function(location = "bl", canvas = "dark",
                          unit_category = "imperial", ...) {
  if (!requireNamespace("ggspatial", quietly = TRUE)) {
    stop("rcds_scalebar() requires the 'ggspatial' package.", call. = FALSE)
  }
  toks <- rcds_tokens()
  is_dark <- canvas %in% c("dark", "deep", "slate", "graphite")
  txt <- if (is_dark) toks$ink$on_dark_1 else toks$ink$on_light_1
  ggspatial::annotation_scale(
    location = location, unit_category = unit_category,
    text_col = txt, line_col = txt, text_family = rcds_font("body"),
    height = grid::unit(0.2, "cm"), ...)
}

#' RCDS north arrow (ggspatial wrapper)
#'
#' Pre-styled [ggspatial::annotation_north_arrow()]. Defaults to the minimal
#' orienteering style; restrained, never the dominant element.
#' @param location Corner, e.g. `"tr"`.
#' @param canvas Canvas key.
#' @param style A ggspatial north-arrow style. Default `north_arrow_minimal`.
#' @param ... Passed to [ggspatial::annotation_north_arrow()].
#' @export
rcds_north_arrow <- function(location = "tr", canvas = "dark",
                             style = NULL, ...) {
  if (!requireNamespace("ggspatial", quietly = TRUE)) {
    stop("rcds_north_arrow() requires the 'ggspatial' package.", call. = FALSE)
  }
  toks <- rcds_tokens()
  is_dark <- canvas %in% c("dark", "deep", "slate", "graphite")
  fg <- if (is_dark) toks$ink$on_dark_1 else toks$ink$on_light_1
  if (is.null(style)) {
    style <- ggspatial::north_arrow_minimal(line_col = fg, text_col = fg,
                                            fill = fg, text_family = rcds_font("body"))
  }
  ggspatial::annotation_north_arrow(
    location = location, which_north = "true", style = style,
    height = grid::unit(0.9, "cm"), width = grid::unit(0.9, "cm"), ...)
}

#' RCDS locator / inset map
#'
#' Builds the small "where am I" overview the archive composes by hand (the
#' Gwinnett-in-Georgia inset, Day 2). The area of interest is highlighted on a
#' muted context layer with a transparent void theme so it drops cleanly onto a
#' main map via [rcds_compose()] or `patchwork::inset_element()`.
#'
#' @param context An `sf` object: the surrounding reference geography.
#' @param highlight An `sf` object: the area of interest, drawn on top.
#' @param canvas Canvas key for the inset background.
#' @param highlight_fill Fill for the area of interest. Default brand blue.
#' @param context_color Outline colour for the context layer.
#' @return A ggplot object suitable as an inset.
#' @export
rcds_locator <- function(context, highlight, canvas = "deep",
                         highlight_fill = NULL, context_color = NULL) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("rcds_locator() requires the 'sf' package.", call. = FALSE)
  }
  toks <- rcds_tokens()
  bg <- switch(canvas, dark = toks$canvas$dark, deep = toks$canvas$deep,
               slate = toks$canvas$slate, graphite = toks$canvas$graphite,
               light = toks$canvas$light, toks$canvas$deep)
  highlight_fill <- highlight_fill %||% toks$accent$blue_b
  context_color  <- context_color  %||% toks$ink$hairline_dark

  ggplot2::ggplot() +
    ggplot2::geom_sf(data = context, fill = NA, colour = context_color, linewidth = 0.25) +
    ggplot2::geom_sf(data = highlight, fill = highlight_fill,
                     colour = highlight_fill, linewidth = 0.4, alpha = 0.9) +
    ggplot2::theme_void() +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = bg, colour = NA),
                   panel.background = ggplot2::element_rect(fill = bg, colour = NA))
}

#' RCDS annotation callout box
#'
#' A consistent text callout for on-map annotation: rich text if `ggtext` is
#' available, with a subtle rounded panel. Returns a layer list to add to a map.
#' @param x,y Data coordinates (in the map's CRS / scales).
#' @param label Text (may include HTML if `ggtext` is present).
#' @param canvas Canvas key (controls text/box colours).
#' @param size Text size (points).
#' @param hjust,vjust Justification.
#' @return A ggplot layer (or list of layers).
#' @export
rcds_annotation_box <- function(x, y, label, canvas = "dark", size = 9,
                                hjust = 0, vjust = 1) {
  toks <- rcds_tokens()
  is_dark <- canvas %in% c("dark", "deep", "slate", "graphite")
  txt <- if (is_dark) toks$ink$on_dark_1 else toks$ink$on_light_1
  box <- if (is_dark) toks$canvas$deep else toks$canvas$paper
  if (requireNamespace("ggtext", quietly = TRUE)) {
    ggtext::geom_richtext(
      data = data.frame(x = x, y = y, label = label),
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
      hjust = hjust, vjust = vjust, size = size / 2.83,
      colour = txt, fill = box, label.colour = NA,
      family = rcds_font("body"),
      label.padding = grid::unit(c(4, 6, 4, 6), "pt"))
  } else {
    ggplot2::annotate("label", x = x, y = y, label = label, hjust = hjust,
                      vjust = vjust, size = size / 2.83, colour = txt,
                      fill = box, family = rcds_font("body"), label.size = 0)
  }
}
