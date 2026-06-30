#' Design tokens for the Richard Cartographic Design System
#'
#' The single source of truth for every colour, neutral, accent, and spacing
#' value in RCDS. Themes, palettes, and components all read from here so the
#' identity stays coherent. Override a token once and the whole system follows.
#'
#' Neutrals are canonicalised from the recurring dark canvases in the archive
#' (`#1c1c1c`, `#121212`, `#2b2b2b`, `#2e2e2e`, `#2f2f2f`, `#2C3E50`) and the
#' lighter `#F0F0F0`/`#F8F8F8` and vintage `#F5DEB3` variants. Text greys on
#' light canvases (`#333333` / `#555555` / `#666666`) are lifted verbatim from
#' the Day 1 map.
#'
#' @format A named list with elements `canvas`, `ink`, `accent`, `space`.
#' @export
rcds_tokens <- function() {
  list(
    ## Canvases -----------------------------------------------------------
    canvas = list(
      dark      = "#1C1C1C",  # primary dark canvas (the house default)
      deep      = "#121212",  # near-black, for credit strips / panels
      slate     = "#2C3E50",  # blue-slate alt canvas (Day 26)
      graphite  = "#2B2B2B",  # warm graphite alt
      light     = "#F0F0F0",  # primary light canvas
      paper     = "#F8F8F8",  # light panel
      vintage   = "#F5DEB3"   # sanctioned vintage / Du Bois canvas
    ),
    ## Ink (type + strokes) ----------------------------------------------
    ink = list(
      # on dark canvases
      on_dark_1 = "#FFFFFF",  # primary
      on_dark_2 = "#CFCFCF",  # secondary
      on_dark_3 = "#8A8A8A",  # tertiary / muted
      hairline_dark = "#3A3A3A",
      # on light canvases (verbatim from the archive)
      on_light_1 = "#333333",
      on_light_2 = "#555555",
      on_light_3 = "#666666",
      hairline_light = "#999999",
      # neutral graticule / outline
      graticule = "#5A5A5A"
    ),
    ## Brand accents ------------------------------------------------------
    ## "Roland blue" anchors the identity (Blue Ribbon map, Day 1 middle
    ## schools). Amber is the warm counter-accent; teal the cool secondary.
    accent = list(
      blue   = "#1E6FB8",  # brand primary
      blue_b = "#1E90FF",  # bright brand blue (interactive / highlight)
      amber  = "#E8852B",  # warm counter-accent
      teal   = "#2A9D8F",  # cool secondary
      red     = "#C8443B", # alert / emphasis
      green  = "#3FA34D"   # positive
    ),
    ## Spacing scale (pt) -------------------------------------------------
    space = c(xs = 4, sm = 8, md = 16, lg = 24, xl = 40, xxl = 64)
  )
}

#' Look up a single design token by dotted path
#'
#' @param path Dotted token path, e.g. `"canvas.dark"` or `"accent.blue"`.
#' @return The token value (a hex string or number).
#' @examples
#' rcds_color("canvas.dark")
#' rcds_color("accent.amber")
#' @export
rcds_color <- function(path) {
  toks <- rcds_tokens()
  parts <- strsplit(path, ".", fixed = TRUE)[[1]]
  out <- toks
  for (p in parts) {
    if (is.null(out[[p]])) {
      stop(sprintf("Unknown token path: '%s' (failed at '%s')", path, p),
           call. = FALSE)
    }
    out <- out[[p]]
  }
  out
}

#' Negated value matching
#'
#' The `%out%` helper that appears across the archive, promoted to a first-class
#' export so it stops being redefined in every script.
#' @param x,table Passed to [base::match()].
#' @export
#' @rdname grapes-out-grapes
`%out%` <- function(x, table) match(x, table, nomatch = 0L) == 0L
