# Package-level imports and startup.

#' @keywords internal
#' @importFrom rlang %||% .data
#' @importFrom utils packageVersion
"_PACKAGE"

# `%||%` is imported from rlang (see NAMESPACE) and used throughout.

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "rcds ", utils::packageVersion("rcds"),
    " - Richard Cartographic Design System.\n",
    "Start with rcds_fonts() then theme_rcds() / theme_rcds_map(). ",
    "See rcds_palettes() and rcds_export_presets().")
}
