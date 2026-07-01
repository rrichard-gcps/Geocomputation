# =============================================================================
# rcds-gcps.R -- GCPS brand pack, integrated from the imported Claude Design
# "GCPS / REA Theme Studio" and "map-design" projects
# (rcds/inst/interactive/claude-design/). Brings the official Gwinnett County
# Public Schools colour system, the three cartographic poster themes, and the
# Segoe-UI/Spectral/Archivo typography into the rcds system so static and
# interactive maps can carry the institutional identity.
#
# Source of truth for the values below:
#   .../rea-theme-studio-main/app.R          (gcps_base, gcps_ramps, gcps_diverging)
#   .../rea-theme-studio-main/R/gcps_palettes.R (family labels, 5 stops)
#   .../rea-theme-studio-main/www/themes.css (the 6 UI shells)
#   .../map-design/src/themes.js             (the 3 map poster themes A/B/C)
# =============================================================================

#' GCPS brand tokens
#'
#' The complete imported Gwinnett County Public Schools design system: 11 colour
#' families (each a base + 5-stop sequential ramp + 5-stop diverging ramp), the
#' brand neutrals, the maroon district signature, the three cartographic poster
#' themes, and the six dashboard UI shells. The single source of truth for the
#' GCPS side of `rcds`, mirroring [rcds_tokens()] for the archive side.
#'
#' Ramp stops correspond to 100 / 300 / 500 / 700 / 900 (light -> dark); the base
#' colour is the 500 stop.
#'
#' @return A named list: `signature`, `neutrals`, `base`, `ramps`, `diverging`,
#'   `family_labels`, `map_themes`, `ui_themes`.
#' @examples
#' gcps_tokens()$base[["maroon"]]
#' gcps_tokens()$map_themes$paper$accent
#' @export
gcps_tokens <- function() {
  base <- c(
    maroon = "#660000", blue = "#2F5FB3", teal = "#007C91", green = "#5E8C31",
    violet = "#6A4CC3", orange = "#D96A1D", neutral = "#7A828C", gold = "#C49A22",
    plum = "#7B2D8B", slate = "#4A6D8C", emerald = "#1A7D5A")

  ramps <- list(
    maroon  = c("#DDC7C7", "#BA8C8C", "#944C4C", "#660000", "#540000"),
    blue    = c("#D1DCEE", "#A1B7DD", "#6D8FCA", "#2F5FB3", "#274E93"),
    teal    = c("#C7E2E7", "#8CC4CE", "#4CA3B2", "#007C91", "#006677"),
    green   = c("#DCE6D2", "#B7CBA2", "#8EAE6F", "#5E8C31", "#4D7328"),
    violet  = c("#DED8F2", "#BCAEE4", "#9782D5", "#6A4CC3", "#573EA0"),
    orange  = c("#F7DECD", "#EEBC99", "#E49761", "#D96A1D", "#B25718"),
    neutral = c("#F4F5F7", "#E3E6EA", "#B6BCC4", "#7A828C", "#4B525A"),
    gold    = c("#F5EBC8", "#E3CC7E", "#C49A22", "#9A7A10", "#7A600D"),
    plum    = c("#EDDCF1", "#C990D5", "#7B2D8B", "#5E1E6B", "#421450"),
    slate   = c("#D5DEE6", "#A0B4C4", "#4A6D8C", "#355270", "#233850"),
    emerald = c("#C8E8DE", "#7DC4AB", "#1A7D5A", "#126347", "#0C4A35"))

  diverging <- list(
    maroon  = c("#540000", "#944C4C", "#F3F4F6", "#4CA3B2", "#006677"),
    blue    = c("#274E93", "#6D8FCA", "#F3F4F6", "#E49761", "#B25718"),
    teal    = c("#006677", "#4CA3B2", "#F3F4F6", "#BA8C8C", "#540000"),
    green   = c("#4D7328", "#8EAE6F", "#F3F4F6", "#BCAEE4", "#573EA0"),
    violet  = c("#573EA0", "#9782D5", "#F3F4F6", "#8EAE6F", "#4D7328"),
    orange  = c("#B25718", "#E49761", "#F3F4F6", "#6D8FCA", "#274E93"),
    gold    = c("#7A600D", "#E3CC7E", "#F3F4F6", "#8CC4CE", "#006677"),
    plum    = c("#421450", "#C990D5", "#F3F4F6", "#8EAE6F", "#4D7328"),
    slate   = c("#233850", "#A0B4C4", "#F3F4F6", "#E49761", "#B25718"),
    emerald = c("#0C4A35", "#7DC4AB", "#F3F4F6", "#BA8C8C", "#540000"))

  list(
    signature = "#660000",  # maroon -- district signature
    neutrals = list(white = "#FFFFFF", ink = "#1F2120", ink_2 = "#6B6560",
                    ink_3 = "#8B8680", minimum = "#F7F6F3", neutral = "#8B8680"),
    base = base,
    ramps = ramps,
    diverging = diverging,
    family_labels = c(
      maroon = "District signature; headers, primary emphasis",
      blue = "Cool, neutral category", teal = "Density & intensity",
      green = "Growth, positive metrics", violet = "Distinct categorical",
      orange = "Attention, secondary emphasis", neutral = "Supporting tones",
      gold = "Warm highlight; award & recognition",
      plum = "Deep contrast; adult literacy & workforce",
      slate = "Steel-blue; operations & infrastructure",
      emerald = "Deep green; sustainability & wellness"),

    # Three cartographic poster themes (map-design/src/themes.js)
    map_themes = list(
      paper = list(
        label = "Paper / editorial", canvas = "#EFE9DC",
        dist_fill = "#F4EFE3", dist_stroke = "#D6CDBA", dist_sw = 1.1,
        accent = "#8C2F39", accent_dark = "#581E25", hi_sw = 1.6,
        ink = "#2B2722", sub = "#6E665A", faint = "#9A9080", header = "#2B2722",
        num = "#A0937C", num_halo = "#EFE9DC",
        inset_fill = "#E7DFCD", inset_stroke = "#CDC3AD",
        voice = "gcps_paper", title_weight = "bold", title_transform = "none"),
      civic = list(
        label = "Civic / light", canvas = "#EEF1F5",
        dist_fill = "#FFFFFF", dist_stroke = "#D9DFE7", dist_sw = 1.1,
        accent = "#1F5C8B", accent_dark = "#123F61", hi_sw = 1.6,
        ink = "#1A2330", sub = "#5B6675", faint = "#93A0B0", header = "#15202E",
        num = "#9AA7B6", num_halo = "#FFFFFF",
        inset_fill = "#E2E7EE", inset_stroke = "#C7D0DB",
        voice = "gcps_civic", title_weight = "bold", title_transform = "none"),
      bold = list(
        label = "Bold / dark", canvas = "#14161B",
        dist_fill = "#232830", dist_stroke = "#373D49", dist_sw = 1.0,
        accent = "#E2574B", accent_dark = "#F2A69D", hi_sw = 1.4,
        ink = "#ECEEF1", sub = "#99A1AD", faint = "#69707C", header = "#FFFFFF",
        num = "#828A97", num_halo = "#232830",
        inset_fill = "#20242C", inset_stroke = "#3A414C",
        voice = "gcps_bold", title_weight = "bold", title_transform = "uppercase")),

    # Six dashboard UI shells (rea-theme-studio-main/www/themes.css)
    ui_themes = list(
      editorial = list(canvas = "#F7F6F3", surface = "#FFFFFF", sunken = "#F1EFEA",
        border = "#E4E1D9", text = "#1F2120", text_2 = "#5C5A54", text_3 = "#8A8780",
        accent = "#660000", radius = c(6, 10, 14)),
      clarity = list(canvas = "#FFFFFF", surface = "#FFFFFF", sunken = "#F5F7FA",
        border = "#E4E7EB", text = "#1F2933", text_2 = "#52606D", text_3 = "#9AA5B1",
        accent = "#660000", radius = c(5, 8, 10)),
      dark = list(canvas = "#14161A", surface = "#1C1F26", sunken = "#23272F",
        border = "#2C313C", text = "#F2F4F7", text_2 = "#AEB6C2", text_3 = "#7E8794",
        accent = "#E98A7D", radius = c(7, 12, 16)),
      soft = list(canvas = "#F5F6FB", surface = "#FFFFFF", sunken = "#EEF0F7",
        border = "#E6E8F0", text = "#24262B", text_2 = "#5B6070", text_3 = "#9CA3B4",
        accent = "#660000", radius = c(10, 16, 22)),
      bold = list(canvas = "#FFFFFF", surface = "#FFFFFF", sunken = "#F2F2F2",
        border = "#111111", text = "#0A0A0A", text_2 = "#3A3A3A", text_3 = "#6E6E6E",
        accent = "#660000", radius = c(3, 3, 3)),
      civic = list(canvas = "#F4F6F9", surface = "#FFFFFF", sunken = "#EAEEF3",
        border = "#D7DEE7", text = "#15233B", text_2 = "#3F4F66", text_3 = "#7B8799",
        accent = "#660000", radius = c(5, 6, 8)))
  )
}

#' GCPS palette definitions for the rcds palette system
#'
#' Registers the GCPS families into [rcds_pal()] as `gcps_<family>` (sequential),
#' `gcps_<family>_div` (diverging), and `qual_gcps` (the 11 base colours as a
#' categorical palette). Merged in by `.rcds_palette_defs()`.
#' @keywords internal
.rcds_gcps_palette_defs <- function() {
  tk <- gcps_tokens()
  seqs <- stats::setNames(tk$ramps, paste0("gcps_", names(tk$ramps)))
  divs <- stats::setNames(tk$diverging, paste0("gcps_", names(tk$diverging), "_div"))
  c(seqs, divs, list(qual_gcps = unname(tk$base)))
}

#' A ready-made ggplot theme for GCPS maps
#'
#' Returns a complete map theme from one of the three GCPS cartographic poster
#' themes (Paper/editorial, Civic/light, Bold/dark), registering the theme's
#' Google fonts via the matching [rcds_fonts()] voice. Pair with the GCPS data
#' palettes (`scale_fill_rcds_c("gcps_teal")`, etc.) and the theme's geometry
#' tokens (`gcps_tokens()$map_themes[[theme]]`) for fills/strokes/accents.
#'
#' @param theme One of `"paper"`, `"civic"`, `"bold"`.
#' @param base Base type size (points).
#' @param legend_position `"bottom"` (default), `"right"`, or `"none"`.
#' @param register_fonts Register the theme's fonts via the matching voice.
#' @return A ggplot2 theme.
#' @examples
#' \dontrun{
#' ggplot(districts) +
#'   geom_sf(aes(fill = enrollment), colour = gcps_tokens()$map_themes$paper$dist_stroke) +
#'   scale_fill_rcds_c("gcps_maroon") +
#'   theme_gcps_map("paper")
#' }
#' @export
theme_gcps_map <- function(theme = c("paper", "civic", "bold"), base = 14,
                           legend_position = "bottom", register_fonts = TRUE) {
  theme <- match.arg(theme)
  mt <- gcps_tokens()$map_themes[[theme]]
  if (register_fonts) rcds_fonts(mt$voice, quiet = TRUE)
  f_disp <- rcds_font("display"); f_body <- rcds_font("body"); f_cap <- rcds_font("caption")
  ts <- rcds_type_scale(base)

  ggplot2::theme_void(base_size = base, base_family = f_body) %+replace%
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = mt$canvas, colour = NA),
      panel.background = ggplot2::element_rect(fill = mt$canvas, colour = NA),
      plot.title = ggplot2::element_text(
        family = f_disp, face = mt$title_weight, colour = mt$header,
        size = ts[["title"]], hjust = 0,
        margin = ggplot2::margin(b = 6)),
      plot.subtitle = ggplot2::element_text(
        family = f_disp, colour = mt$sub, size = ts[["subtitle"]], hjust = 0,
        margin = ggplot2::margin(b = 12)),
      plot.caption = ggplot2::element_text(
        family = f_cap, colour = mt$faint, size = ts[["caption"]], hjust = 0,
        lineheight = 1.1, margin = ggplot2::margin(t = 12)),
      plot.title.position = "plot", plot.caption.position = "plot",
      legend.position = legend_position,
      legend.title = ggplot2::element_text(family = f_body, face = "bold",
                                           colour = mt$ink, size = ts[["legend"]]),
      legend.text = ggplot2::element_text(family = f_body, colour = mt$sub,
                                          size = ts[["legend"]] * 0.9),
      strip.text = ggplot2::element_text(family = f_disp, colour = mt$header,
                                         size = ts[["label"]], hjust = 0),
      plot.margin = ggplot2::margin(24, 28, 24, 28))
}

#' RCDS interactive CSS for a GCPS map theme
#'
#' The GCPS counterpart to [rcds_interactive_css()]: emits Leaflet/HTML CSS from
#' a GCPS map theme's tokens (canvas, ink, accent, fonts) so interactive maps
#' match the static GCPS identity. Exposes the same `:root { --rcds-* }` seam.
#'
#' @param theme One of `"paper"`, `"civic"`, `"bold"`.
#' @return A single CSS string.
#' @examples
#' substr(gcps_interactive_css("civic"), 1, 40)
#' @export
gcps_interactive_css <- function(theme = c("paper", "civic", "bold")) {
  theme <- match.arg(theme)
  mt <- gcps_tokens()$map_themes[[theme]]
  roles <- list(paper = c("Spectral", "IBM Plex Sans", "IBM Plex Mono"),
                civic = c("Archivo", "Archivo", "IBM Plex Mono"),
                bold  = c("Archivo", "IBM Plex Sans", "IBM Plex Mono"))[[theme]]
  import <- paste0("https://fonts.googleapis.com/css2?",
                   paste(sprintf("family=%s", gsub(" ", "+", unique(roles))), collapse = "&"),
                   "&display=swap")
  sprintf("
@import url('%s');
:root {
  --rcds-canvas: %s; --rcds-panel: %s; --rcds-ink-1: %s; --rcds-ink-2: %s;
  --rcds-hairline: %s; --rcds-accent: %s;
  --rcds-font-display: '%s', serif; --rcds-font-body: '%s', sans-serif;
  --rcds-font-caption: '%s', monospace;
}
.leaflet-container { background: var(--rcds-canvas); font-family: var(--rcds-font-body); }
.leaflet-popup-content-wrapper, .leaflet-popup-tip {
  background: %s; color: var(--rcds-ink-1); border-radius: 8px;
}
.leaflet-popup-content b, .rcds-popup-title { font-family: var(--rcds-font-display); }
.leaflet-tooltip.rcds-tooltip {
  background: %s; color: var(--rcds-ink-1); border: 1px solid var(--rcds-hairline);
  font-family: var(--rcds-font-body);
}
.info.legend, .leaflet-control.legend {
  background: %s; color: var(--rcds-ink-2); font-family: var(--rcds-font-body);
  border-radius: 8px; padding: 8px 10px;
}
.info.legend .rcds-legend-title { font-family: var(--rcds-font-display); color: var(--rcds-ink-1); }
.leaflet-bar, .leaflet-control-zoom a {
  background: %s; color: var(--rcds-ink-1); border-color: var(--rcds-hairline);
}
.leaflet-control-attribution a { color: var(--rcds-accent) !important; }
",
    import, mt$canvas, mt$inset_fill, mt$ink, mt$sub, mt$dist_stroke, mt$accent,
    roles[1], roles[2], roles[3],
    mt$inset_fill, mt$inset_fill, mt$inset_fill, mt$inset_fill)
}
