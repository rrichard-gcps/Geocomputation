# Package-level imports and startup.

#' @keywords internal
#' @importFrom rlang %||% .data
#' @importFrom utils packageVersion
#' @importFrom grDevices colorRampPalette
#' @importFrom stats setNames
"_PACKAGE"

# `%||%` is imported from rlang (see NAMESPACE) and used throughout.

.onLoad <- function(libname, pkgname) {
  # GCPS is the out-of-the-box default brand; switch with rcds_brand("archive").
  if (is.null(getOption("rcds.brand"))) options(rcds.brand = "gcps")
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "rcds ", utils::packageVersion("rcds"),
    " - Richard Cartographic Design System (brand: ", rcds_brand(), ").\n",
    "Start with rcds_fonts(); theme_map() + scale_fill_map_c() use the active brand. ",
    "Switch with rcds_brand('archive'). See rcds_palettes().")
}
