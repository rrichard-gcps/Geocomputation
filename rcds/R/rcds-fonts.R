#' Register the RCDS font stack
#'
#' Registers a consistent, role-based font system with `sysfonts`/`showtext`
#' and turns `showtext` on. The archive swaps display faces per map (Anton,
#' Bebas Neue, Bungee, Cinzel, Oswald, Montserrat, Roboto...). RCDS keeps the
#' expressiveness but assigns fonts to *roles* so every map shares a structure:
#' a heavy display title, a clean condensed body, and a neutral caption face.
#'
#' Four sanctioned "voices" are provided. `default` is the house identity;
#' the others are pre-approved thematic alternates so themed maps stay on-brand
#' instead of reaching for an arbitrary Google font.
#'
#' \describe{
#'   \item{default}{display = Oswald, body = Roboto Condensed, caption = Roboto}
#'   \item{editorial}{display = Anton, body = Roboto Condensed, caption = Roboto}
#'   \item{vintage}{display = Bebas Neue, body = Roboto Condensed, caption = Roboto}
#'   \item{fantasy}{display = Cinzel, body = Cormorant SC, caption = Roboto}
#'   \item{techno}{display = Orbitron, body = Smooch Sans, caption = Roboto}
#' }
#'
#' After calling this, refer to fonts by *role* via [rcds_font()] (`"display"`,
#' `"body"`, `"caption"`) rather than by Google name. That indirection is what
#' lets you restyle every map by changing one argument.
#'
#' @param voice One of `"default"`, `"editorial"`, `"vintage"`, `"fantasy"`,
#'   `"techno"`, or the imported GCPS map voices `"gcps_paper"`, `"gcps_civic"`,
#'   `"gcps_bold"`. `NULL` (the default) resolves to the active brand's voice
#'   (see [rcds_brand()]) -- GCPS out of the box.
#' @param quiet Suppress the "fonts registered" message.
#' @return Invisibly, the named character vector of role -> family mappings.
#' @examples
#' \dontrun{
#' rcds_fonts("editorial")
#' ggplot2::element_text(family = rcds_font("display"))
#' }
#' @export
rcds_fonts <- function(voice = NULL, quiet = FALSE) {
  choices <- c("default", "editorial", "vintage", "fantasy", "techno",
               "gcps_paper", "gcps_civic", "gcps_bold")
  # No voice given -> use the active brand's default (GCPS out of the box).
  if (is.null(voice)) voice <- rcds_default_voice()
  voice <- match.arg(voice, choices)

  voices <- list(
    default   = c(display = "Oswald",   body = "Roboto Condensed", caption = "Roboto"),
    editorial = c(display = "Anton",    body = "Roboto Condensed", caption = "Roboto"),
    vintage   = c(display = "Bebas Neue", body = "Roboto Condensed", caption = "Roboto"),
    fantasy   = c(display = "Cinzel",   body = "Cormorant SC",     caption = "Roboto"),
    techno    = c(display = "Orbitron", body = "Smooch Sans",      caption = "Roboto"),
    ## Imported GCPS map-theme voices (see R/rcds-gcps.R). All Google fonts.
    gcps_paper = c(display = "Spectral", body = "IBM Plex Sans", caption = "IBM Plex Mono"),
    gcps_civic = c(display = "Archivo",  body = "Archivo",       caption = "IBM Plex Mono"),
    gcps_bold  = c(display = "Archivo",  body = "IBM Plex Sans", caption = "IBM Plex Mono")
  )
  roles <- voices[[voice]]

  has_showtext <- requireNamespace("sysfonts", quietly = TRUE) &&
    requireNamespace("showtext", quietly = TRUE)

  if (has_showtext) {
    # role family alias = the literal Google name; we register the Google name.
    for (g in unique(unname(roles))) {
      tryCatch(
        sysfonts::font_add_google(g, g),
        error = function(e) {
          if (!quiet) {
            message(sprintf(
              "rcds: could not fetch Google font '%s' (offline?). Falling back to system default.", g))
          }
        }
      )
    }
    showtext::showtext_auto()
    showtext::showtext_opts(dpi = getOption("rcds.dpi", 300))
  } else if (!quiet) {
    message("rcds: 'sysfonts'/'showtext' not installed; fonts will use device defaults.")
  }

  # Stash the active role->family map for rcds_font() to read.
  options(rcds.fonts = as.list(roles), rcds.voice = voice)
  if (!quiet) message(sprintf("rcds: registered '%s' voice (display=%s, body=%s, caption=%s).",
                              voice, roles[["display"]], roles[["body"]], roles[["caption"]]))
  invisible(roles)
}

#' Resolve a font role to its registered family name
#'
#' @param role One of `"display"`, `"body"`, `"caption"`.
#' @return The family string to pass to `family =`. Falls back to a sensible
#'   sans family if [rcds_fonts()] has not been called.
#' @export
rcds_font <- function(role = c("display", "body", "caption")) {
  role <- match.arg(role)
  active <- getOption("rcds.fonts", NULL)
  if (is.null(active)) {
    fallback <- c(display = "sans", body = "sans", caption = "sans")
    return(unname(fallback[[role]]))
  }
  active[[role]]
}

#' The RCDS modular type scale
#'
#' A single ratio-based scale (1.25 / major third) keyed to a base size, so
#' titles, subtitles, labels, and captions stay in proportion instead of being
#' hand-tuned per map. Sizes are in points and assume `showtext` DPI is set
#' (see [rcds_fonts()]); the values returned scale linearly with `base`.
#'
#' @param base Base body size in points. Default 11 for screen/journal; bump to
#'   ~16-22 for large posters rendered through showtext.
#' @return A named numeric vector of point sizes.
#' @examples
#' rcds_type_scale(11)
#' rcds_type_scale(20)["title"]
#' @export
rcds_type_scale <- function(base = 11) {
  r <- 1.25
  c(
    micro    = base / r,        # fine print, source lines
    caption  = base * r^0,      # = base; captions/credits
    body     = base * r^0.5,
    label    = base * r^0.5,    # map labels
    legend   = base * r^0.5,
    subtitle = base * r^2,
    title    = base * r^4,
    hero     = base * r^6       # poster / hero titles
  )
}
