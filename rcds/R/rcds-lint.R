#' Lint an R map script against the RCDS anti-patterns
#'
#' Static analysis that turns the [anti-pattern catalog][rcds-anti-patterns]
#' (RCDS.md section 8) into a mechanical check. It reads a script (or a string of
#' code) and flags the recurring mistakes from the archive -- deprecated `size=`
#' on `geom_sf`, rainbow palettes on ordered data, hardcoded absolute font paths,
#' inline API keys, caption/signature drift, copy-pasted theme blocks, magic font
#' sizes, and non-hygienic exports -- each tied to its anti-pattern code and fix.
#'
#' This is intentionally heuristic (regex over source, not a full parse): it errs
#' toward surfacing things to look at. Treat findings as prompts, not verdicts.
#'
#' @param x A path to a `.R` file, or a character vector of code lines, or a
#'   single string containing newlines.
#' @param ignore Character vector of rule codes (e.g. `c("A3", "A8")`) to skip.
#' @return A data.frame of findings (`rule`, `severity`, `line`, `message`,
#'   `fix`), ordered by line. Zero rows means a clean bill of health. The frame
#'   carries a `clean` attribute and prints a one-line summary via [message()].
#' @examples
#' code <- '
#' ggplot(d) + geom_sf(aes(fill = v), size = 0.2) +
#'   scale_fill_distiller(palette = "Spectral")
#' ggsave("m.png", width = 10, height = 8)
#' '
#' rcds_lint(code)
#' @export
rcds_lint <- function(x, ignore = character()) {
  lines <- .rcds_read_code(x)
  rules <- .rcds_lint_rules()
  findings <- list()

  for (rule in rules) {
    if (rule$code %in% ignore) next
    hits <- rule$check(lines)
    hits <- hits[!is.na(hits)]
    if (length(hits)) {
      findings[[length(findings) + 1]] <- data.frame(
        rule = rule$code, severity = rule$severity, line = hits,
        message = rule$message, fix = rule$fix,
        stringsAsFactors = FALSE)
    }
  }

  out <- if (length(findings)) {
    df <- do.call(rbind, findings)
    df[order(df$line, df$rule), , drop = FALSE]
  } else {
    data.frame(rule = character(), severity = character(), line = integer(),
               message = character(), fix = character(), stringsAsFactors = FALSE)
  }
  rownames(out) <- NULL
  attr(out, "clean") <- nrow(out) == 0L

  n <- nrow(out)
  if (n == 0L) {
    message("rcds_lint: clean - no anti-patterns detected.")
  } else {
    sev <- table(factor(out$severity, levels = c("high", "warning", "info")))
    message(sprintf("rcds_lint: %d finding%s (%d high, %d warning, %d info).",
                    n, if (n == 1) "" else "s",
                    sev[["high"]], sev[["warning"]], sev[["info"]]))
  }
  out
}

#' Lint every R script in a directory
#'
#' @param dir Directory to scan.
#' @param pattern File pattern. Default `"\\.R$"`.
#' @param recursive Recurse into subdirectories.
#' @param ignore Rule codes to skip (passed to [rcds_lint()]).
#' @return A data.frame of findings with a leading `file` column.
#' @export
rcds_lint_dir <- function(dir = ".", pattern = "\\.R$", recursive = FALSE,
                          ignore = character()) {
  files <- list.files(dir, pattern = pattern, full.names = TRUE,
                       recursive = recursive)
  rows <- lapply(files, function(f) {
    res <- suppressMessages(rcds_lint(f, ignore = ignore))
    if (nrow(res)) cbind(file = f, res, stringsAsFactors = FALSE) else NULL
  })
  out <- do.call(rbind, rows)
  if (is.null(out)) {
    out <- data.frame(file = character(), rule = character(),
                      severity = character(), line = integer(),
                      message = character(), fix = character(),
                      stringsAsFactors = FALSE)
  }
  rownames(out) <- NULL
  message(sprintf("rcds_lint_dir: scanned %d file%s, %d finding%s.",
                  length(files), if (length(files) == 1) "" else "s",
                  nrow(out), if (nrow(out) == 1) "" else "s"))
  out
}

# --- internals ---------------------------------------------------------------

#' @keywords internal
.rcds_read_code <- function(x) {
  if (is.character(x) && length(x) == 1 && !grepl("\n", x) &&
      file.exists(x)) {
    return(readLines(x, warn = FALSE))
  }
  if (is.character(x) && length(x) == 1 && grepl("\n", x)) {
    return(strsplit(x, "\n", fixed = TRUE)[[1]])
  }
  as.character(x)
}

#' @keywords internal
#' @return integer line numbers where `pattern` matches (and any `not` pattern
#'   does not).
.rcds_grep_lines <- function(lines, pattern, not = NULL, ignore.case = FALSE) {
  hit <- grepl(pattern, lines, perl = TRUE, ignore.case = ignore.case)
  if (!is.null(not)) hit <- hit & !grepl(not, lines, perl = TRUE, ignore.case = ignore.case)
  which(hit)
}

#' @keywords internal
.rcds_lint_rules <- function() {
  list(
    list(
      code = "A1", severity = "warning",
      message = "Rainbow / non-perceptual palette likely used on ordered data.",
      fix = "Use scale_fill_rcds_c('seq_*'|'div_*') for order; qual_* only for categories.",
      check = function(l) .rcds_grep_lines(
        l, "Spectral|futurama|planetexpress|rainbow\\(|brewer\\.pal\\(|RdYlBu|RdYlGn",
        ignore.case = TRUE)
    ),
    list(
      code = "A2", severity = "info",
      message = "Multiple ad-hoc Google fonts; identity drifts when each map differs.",
      fix = "Pick one rcds_fonts() voice per map instead of font_add_google() calls.",
      check = function(l) {
        idx <- .rcds_grep_lines(l, "font_add_google\\(")
        if (length(idx) > 1 && !any(grepl("rcds_fonts\\(", l))) idx else integer()
      }
    ),
    list(
      code = "A3", severity = "info",
      message = "Many element_text()/element_rect() lines suggest a copy-pasted theme block.",
      fix = "Replace with theme_rcds() / theme_rcds_map().",
      check = function(l) {
        if (any(grepl("theme_rcds", l))) return(integer())
        idx <- .rcds_grep_lines(l, "element_(text|rect)\\(")
        if (length(idx) >= 6) idx[1] else integer()
      }
    ),
    list(
      code = "A4", severity = "info",
      message = "Magic font size (>=20) hardcoded in a theme element.",
      fix = "Pull sizes from rcds_type_scale(base); change 'base', not each size.",
      check = function(l) .rcds_grep_lines(
        l, "element_text\\([^)]*\\bsize\\s*=\\s*(2[0-9]|[3-9][0-9]|[0-9]{3})")
    ),
    list(
      code = "A5", severity = "warning",
      message = "Signature caption built inline; format will drift between maps.",
      fix = "Build it with rcds_signature() (or rcds_credits()).",
      check = function(l) {
        if (any(grepl("rcds_signature\\(|rcds_credits\\(", l))) return(integer())
        hits <- .rcds_grep_lines(l, "Created By|#30DayMapChallenge", ignore.case = TRUE)
        if (length(hits)) hits[1] else integer()
      }
    ),
    list(
      code = "A6", severity = "warning",
      message = "Deprecated 'size =' on an sf/line geom (ggplot2 >= 3.4).",
      fix = "Use 'linewidth =' for polygon borders and line geoms.",
      check = function(l) .rcds_grep_lines(
        l, "geom_(sf|line|path|segment|curve|step)\\b[^#]*\\bsize\\s*=")
    ),
    list(
      code = "A7", severity = "high",
      message = "Hardcoded absolute font path or inline secret (non-portable / leak risk).",
      fix = "Use Google fonts via rcds_fonts(); keep API keys in ~/.Renviron.",
      check = function(l) {
        font_path <- .rcds_grep_lines(l, "font_add\\([^)]*([A-Za-z]:[\\\\/]|/(Users|home)/)")
        live_key  <- .rcds_grep_lines(
          l, "census_api_key\\(\\s*[\"'](?!YOUR|<)", not = "#")
        sort(unique(c(font_path, live_key)))
      }
    ),
    list(
      code = "A8", severity = "info",
      message = "ggsave() without an explicit bg = (risks a transparent/white halo).",
      fix = "Use rcds_export() (sets bg to the canvas and syncs showtext DPI).",
      check = function(l) {
        if (any(grepl("rcds_export\\(", l))) return(integer())
        # find ggsave calls lacking a bg argument on the same line
        idx <- .rcds_grep_lines(l, "ggsave\\(", not = "bg\\s*=")
        idx
      }
    )
  )
}
