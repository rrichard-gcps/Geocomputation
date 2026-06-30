test_that("rcds_signature assembles the canonical four-part block", {
  s <- rcds_signature(
    challenge = "#30DayMapChallenge 2024 Day 16: Choropleth",
    sources = c("U.S. Census Bureau", "NCES"))
  lines <- strsplit(s, "\n", fixed = TRUE)[[1]]
  expect_equal(lines[1], "#30DayMapChallenge 2024 Day 16: Choropleth")
  expect_equal(lines[2], "Tool: R")
  expect_equal(lines[3], "Created By: Roland Richard")
  expect_match(lines[4], "Data Sources: U.S. Census Bureau; NCES")
})

test_that("rcds_signature handles a social handle and omits empty sources", {
  s <- rcds_signature("Day 1", handle = "@rorich")
  expect_match(s, "Created By: Roland Richard \\(@rorich\\)")
  expect_false(grepl("Data Sources", s))
})

test_that("rcds_grade maps scores to letters at the cut points", {
  expect_equal(rcds_grade(100), "A+")
  expect_equal(rcds_grade(93), "A")
  expect_equal(rcds_grade(83), "B")
  expect_equal(rcds_grade(72), "C-")
  expect_equal(rcds_grade(50), "F")
  expect_true(is.na(rcds_grade(NA_real_)))
})

test_that("rcds_score weights, totals, and grades a complete rating", {
  res <- rcds_score(
    layout = 1, hierarchy = 1, typography = 1, colour = 1, accessibility = 1,
    legends = 1, labelling = 1, balance = 1, storytelling = 1, technical = 1,
    map = "perfect")
  expect_equal(res$score, 100)
  expect_equal(res$grade, "A+")
  expect_equal(sum(res$breakdown$weight), 100)
  expect_equal(res$map, "perfect")
})

test_that("rcds_score re-normalises when criteria are missing", {
  expect_warning(
    res <- rcds_score(layout = 1, hierarchy = 1),
    "re-normalised")
  # only two criteria supplied, both perfect -> 100
  expect_equal(res$score, 100)
})

test_that("rcds_score validates inputs", {
  expect_error(rcds_score(layout = 2), "in \\[0, 1\\]")
  expect_error(rcds_score(bogus = 0.5), "Unknown criteria")
})

test_that("rcds_score_template lists all ten weighted criteria summing to 100", {
  tmpl <- rcds_score_template()
  expect_equal(nrow(tmpl), 10)
  expect_equal(sum(tmpl$weight), 100)
})

test_that("rcds_type_scale is monotone increasing and scales with base", {
  ts <- rcds_type_scale(11)
  ord <- c("micro", "caption", "body", "subtitle", "title", "hero")
  vals <- ts[ord]
  expect_true(all(diff(vals) > 0))
  expect_equal(rcds_type_scale(22)[["title"]], rcds_type_scale(11)[["title"]] * 2)
})
