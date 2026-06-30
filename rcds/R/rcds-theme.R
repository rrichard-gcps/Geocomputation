#' The RCDS theme
#'
#' One theme to replace the ~40 hand-tuned `theme()` blocks in the archive.
#' `theme_rcds()` is the general chrome (titles, captions, legend, panel);
#' [theme_rcds_map()] strips axes/grid for actual maps. Both read fonts via
#' [rcds_font()] and colours via [rcds_tokens()], so changing the active voice
#' or a token restyles everything.
#'
#' Canvas variants are lifted from the archive's recurring backgrounds:
#' `"dark"` (`#1C1C1C`), `"deep"` (`#121212`), `"slate"` (`#2C3E50`),
#' `"graphite"` (`#2B2B2B`), `"light"` (`#F0F0F0`), `"vintage"` (`#F5DEB3`).
#'
#' @param base Base type size in points (feeds [rcds_type_scale()]). Use ~11 for
#'   journal/screen, ~16-22 for posters under showtext.
#' @param canvas One of `"dark"`, `"deep"`, `"slate"`, `"graphite"`, `"light"`,
#'   `"vintage"`.
#' @param legend_position `"bottom"` (house default), `"right"`, `"none"`, or a
#'   numeric `c(x, y)`.
#' @return A ggplot2 theme object.
#' @examples
#' \dontrun{
#' ggplot(df) + geom_sf() + theme_rcds(canvas = "dark")
#' }
#' @export
theme_rcds <- function(base = 11, canvas = "dark", legend_position = "bottom") {
  toks <- rcds_tokens()
  ts <- rcds_type_scale(base)

  bg <- switch(canvas,
    dark = toks$canvas$dark, deep = toks$canvas$deep, slate = toks$canvas$slate,
    graphite = toks$canvas$graphite, light = toks$canvas$light,
    paper = toks$canvas$paper, vintage = toks$canvas$vintage,
    stop("Unknown canvas: ", canvas, call. = FALSE))

  is_dark <- canvas %in% c("dark", "deep", "slate", "graphite")
  if (canvas == "vintage") {
    ink1 <- "#332310"; ink2 <- "#4B3621"; ink3 <- "#5C4A33"
  } else if (is_dark) {
    ink1 <- toks$ink$on_dark_1; ink2 <- toks$ink$on_dark_2; ink3 <- toks$ink$on_dark_3
  } else {
    ink1 <- toks$ink$on_light_1; ink2 <- toks$ink$on_light_2; ink3 <- toks$ink$on_light_3
  }

  f_disp <- rcds_font("display"); f_body <- rcds_font("body"); f_cap <- rcds_font("caption")

  ggplot2::theme_minimal(base_size = base, base_family = f_body) %+replace%
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = bg, colour = NA),
      panel.background = ggplot2::element_rect(fill = bg, colour = NA),
      panel.grid       = ggplot2::element_blank(),
      panel.border     = ggplot2::element_blank(),

      plot.title = ggplot2::element_text(
        family = f_disp, face = "bold", colour = ink1, size = ts[["title"]],
        hjust = 0, margin = ggplot2::margin(b = toks$space[["sm"]])),
      plot.subtitle = ggplot2::element_text(
        family = f_disp, colour = ink2, size = ts[["subtitle"]],
        hjust = 0, margin = ggplot2::margin(b = toks$space[["md"]])),
      plot.caption = ggplot2::element_text(
        family = f_cap, colour = ink3, size = ts[["caption"]],
        hjust = 0, lineheight = 1.1, margin = ggplot2::margin(t = toks$space[["md"]])),
      plot.caption.position = "plot",
      plot.title.position = "plot",

      legend.position   = legend_position,
      legend.direction  = if (identical(legend_position, "bottom")) "horizontal" else "vertical",
      legend.background = ggplot2::element_blank(),
      legend.key        = ggplot2::element_blank(),
      legend.title = ggplot2::element_text(family = f_body, face = "bold",
                                           colour = ink1, size = ts[["legend"]]),
      legend.text  = ggplot2::element_text(family = f_body, colour = ink2,
                                           size = ts[["legend"]] * 0.9),

      strip.text = ggplot2::element_text(family = f_disp, colour = ink1,
                                         size = ts[["label"]], hjust = 0,
                                         margin = ggplot2::margin(b = toks$space[["xs"]])),
      axis.text  = ggplot2::element_text(colour = ink3, size = ts[["micro"]]),
      axis.title = ggplot2::element_text(colour = ink2, size = ts[["body"]]),

      plot.margin = ggplot2::margin(toks$space[["lg"]], toks$space[["xl"]],
                                    toks$space[["lg"]], toks$space[["xl"]])
    )
}

#' RCDS theme for maps (no axes, no grid)
#'
#' [theme_rcds()] with the cartographic chrome removed -- the `theme_void()`
#' look the archive reaches for, but consistent and token-driven.
#' @inheritParams theme_rcds
#' @export
theme_rcds_map <- function(base = 11, canvas = "dark", legend_position = "bottom") {
  theme_rcds(base = base, canvas = canvas, legend_position = legend_position) %+replace%
    ggplot2::theme(
      axis.text   = ggplot2::element_blank(),
      axis.title  = ggplot2::element_blank(),
      axis.ticks  = ggplot2::element_blank(),
      panel.grid  = ggplot2::element_blank()
    )
}

# re-export the ggplot2 replace operator for internal use
`%+replace%` <- ggplot2::`%+replace%`
