#' The RCDS Map Quality Score
#'
#' A weighted, 100-point rubric for evaluating any map -- archived or new --
#' against the same criteria, so quality is tracked instead of guessed. Score a
#' map by rating each criterion 0-1 (fraction of points earned); the function
#' applies the weights and returns the total, letter grade, and a tidy breakdown.
#'
#' Weights (sum to exactly 100):
#' \tabular{lr}{
#'   Layout \tab 15 \cr Visual hierarchy \tab 15 \cr Colour \tab 15 \cr
#'   Typography \tab 10 \cr Accessibility \tab 10 \cr Labelling \tab 10 \cr
#'   Balance & composition \tab 10 \cr Legends \tab 5 \cr
#'   Storytelling \tab 5 \cr Technical execution \tab 5 \cr
#' }
#'
#' @param ... Named criterion ratings in `[0, 1]`. Valid names are returned by
#'   [rcds_score_template()]. Omitted criteria are treated as `NA` and excluded
#'   from the (re-normalised) total, with a warning.
#' @param map Optional map identifier for the returned record.
#' @return A list with `map`, `score` (0-100), `grade`, and `breakdown`
#'   (a data.frame of criterion / weight / rating / points).
#' @examples
#' rcds_score(layout = 0.8, hierarchy = 0.7, typography = 0.9, colour = 0.6,
#'            accessibility = 0.5, legends = 0.7, labelling = 0.6,
#'            balance = 0.8, storytelling = 0.6, technical = 0.9, map = "day16")
#' @export
rcds_score <- function(..., map = NA_character_) {
  weights <- .rcds_score_weights()
  ratings <- list(...)
  unknown <- setdiff(names(ratings), names(weights))
  if (length(unknown)) {
    stop("Unknown criteria: ", paste(unknown, collapse = ", "),
         ". See rcds_score_template().", call. = FALSE)
  }
  bad <- vapply(ratings, function(v) !is.numeric(v) || v < 0 || v > 1, logical(1))
  if (any(bad)) stop("All ratings must be numeric in [0, 1].", call. = FALSE)

  r <- stats::setNames(rep(NA_real_, length(weights)), names(weights))
  r[names(ratings)] <- unlist(ratings)
  if (anyNA(r)) {
    warning("Missing criteria excluded and total re-normalised: ",
            paste(names(r)[is.na(r)], collapse = ", "), call. = FALSE)
  }
  used <- !is.na(r)
  pts <- r * weights
  total <- if (any(used)) sum(pts[used]) / sum(weights[used]) * 100 else NA_real_

  breakdown <- data.frame(
    criterion = names(weights),
    weight = unname(weights),
    rating = unname(r),
    points = unname(round(pts, 2)),
    row.names = NULL, stringsAsFactors = FALSE)

  list(map = map, score = round(total, 1), grade = rcds_grade(total),
       breakdown = breakdown)
}

#' Convert a 0-100 RCDS score to a letter grade
#' @param score Numeric score in `[0, 100]`.
#' @return A single-character grade.
#' @export
rcds_grade <- function(score) {
  if (length(score) != 1 || is.na(score)) return(NA_character_)
  cuts <- c(97, 93, 90, 87, 83, 80, 77, 73, 70, 67, 63, 60, 0)
  labs <- c("A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-",
            "D+", "D", "D-", "F")
  labs[which(score >= cuts)[1]]
}

#' A blank scoring template (criterion names + weights + guidance)
#' @return A data.frame describing every criterion.
#' @export
rcds_score_template <- function() {
  data.frame(
    criterion = names(.rcds_score_weights()),
    weight = unname(.rcds_score_weights()),
    asks = c(
      "Margins, alignment, grid, panel proportions, white space",
      "Does the eye land on the message first? Clear primary/secondary order",
      "Consistent role-based fonts, sensible scale, no clashing faces",
      "Perceptually ordered, appropriate scale type, on-brand, not over-saturated",
      "Colourblind-safe, greyscale-survivable, sufficient contrast on canvas",
      "Ordered, titled, right symbol sizes, integrated not bolted on",
      "Placement, density, collision handling, halos, abbreviations",
      "Overall balance, framing, focal points, inset/credit integration",
      "Is there a clear point? Does the map argue it?",
      "Projection correctness, geometry validity, resolution, export hygiene"
    ),
    row.names = NULL, stringsAsFactors = FALSE)
}

#' @keywords internal
#' Weights sum to exactly 100: three pillars at 15 (Layout, Visual hierarchy,
#' Colour), four craft/growth dimensions at 10 (Typography, Accessibility,
#' Labelling, Balance), three supporting dimensions at 5 (Legends, Storytelling,
#' Technical). (The brief's listed weights summed to 110; this is the corrected,
#' normalised allocation.)
.rcds_score_weights <- function() {
  c(layout = 15, hierarchy = 15, typography = 10, colour = 15,
    accessibility = 10, legends = 5, labelling = 10, balance = 10,
    storytelling = 5, technical = 5)
}
