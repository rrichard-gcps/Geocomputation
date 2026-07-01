# =============================================================================
# rcds-dashboard.R -- the GCPS dashboard chrome.
# Turns the six imported UI shells (gcps_tokens()$ui_themes) into bslib themes,
# so a Shiny/bslib dashboard framing a map carries the same GCPS identity as the
# maps themselves. The dashboard shell and the map palettes share gcps_tokens().
# =============================================================================

#' A bslib theme from a GCPS UI shell
#'
#' Builds a [bslib::bs_theme()] from one of the six imported GCPS dashboard
#' shells (editorial, clarity, dark, soft, bold, civic), so the app chrome around
#' a map matches the brand. Pair with the GCPS map themes/palettes.
#'
#' @param theme One of `"editorial"`, `"clarity"`, `"dark"`, `"soft"`, `"bold"`,
#'   `"civic"`.
#' @param version Bootstrap version (default 5).
#' @param ... Passed to [bslib::bs_theme()].
#' @return A `bs_theme` object.
#' @examples
#' \dontrun{
#' bslib::page_sidebar(theme = gcps_bs_theme("civic"), title = "GCPS")
#' }
#' @export
gcps_bs_theme <- function(theme = c("editorial", "clarity", "dark", "soft",
                                    "bold", "civic"),
                          version = 5, ...) {
  .rcds_need("bslib", "gcps_bs_theme")
  theme <- match.arg(theme)
  ut <- gcps_tokens()$ui_themes[[theme]]

  base_font <- bslib::font_collection("Segoe UI", "system-ui", "-apple-system",
                                      "Roboto", "sans-serif")
  heading_font <- if (theme == "civic") {
    bslib::font_collection("Georgia", "Times New Roman", "serif")
  } else base_font

  th <- bslib::bs_theme(
    version = version,
    bg = ut$canvas, fg = ut$text,
    primary = ut$accent, secondary = ut$text_2,
    base_font = base_font, heading_font = heading_font,
    ...)

  # bs_add_variables() adds these as Sass !default variables (its default
  # behaviour), so the theme's own values still win. Only real Bootstrap 5
  # variables are set here.
  bslib::bs_add_variables(
    th,
    "body-bg" = ut$canvas,
    "body-color" = ut$text,
    "card-bg" = ut$surface,
    "card-border-color" = ut$border,
    "border-color" = ut$border,
    "border-radius" = paste0(ut$radius[2], "px"),
    "border-radius-sm" = paste0(ut$radius[1], "px"),
    "border-radius-lg" = paste0(ut$radius[3], "px"))
}

#' List the GCPS dashboard shells
#'
#' @return A named character vector: shell name -> one-line description.
#' @export
gcps_ui_themes <- function() {
  c(editorial = "Warm, hairline (house default)",
    clarity   = "Crisp white, cool grey (Datawrapper-clean)",
    dark      = "Presentation / screen (charcoal, lightened maroon)",
    soft      = "Rounded, friendly (product)",
    bold      = "Big type, high contrast (data journalism)",
    civic     = "Serif headings, official (public report)")
}
