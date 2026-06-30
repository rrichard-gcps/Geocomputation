test_that(".rcds_resolve_colors accepts names and hex, rejects junk", {
  expect_length(rcds:::.rcds_resolve_colors("qual_brand"), 6)
  expect_equal(rcds:::.rcds_resolve_colors(c("#1E6FB8", "#E8852B")),
               c("#1E6FB8", "#E8852B"))
  expect_error(rcds:::.rcds_resolve_colors(c("#1E6FB8", "notacolour")),
               "invalid")
})

test_that("greyscale check reports monotone decreasing luminance for seq_blue", {
  df <- suppressMessages(rcds_greyscale_check("seq_blue", plot = FALSE))
  expect_true(all(c("colour", "grey", "luminance") %in% names(df)))
  expect_true(all(diff(df$luminance) < 0))   # light -> dark
  expect_true(all(grepl("^#", df$grey)))
})

test_that("greyscale check on a well-separated qualitative set is quiet", {
  # black / mid-grey / white are maximally distinct in luminance
  expect_silent(suppressMessages(
    rcds_greyscale_check(c("#000000", "#808080", "#FFFFFF"), plot = FALSE)))
})

test_that("greyscale check flags confusable greys in a qualitative set", {
  # two colours with near-identical luminance
  expect_warning(
    suppressMessages(rcds_greyscale_check(c("#1E6FB8", "#1F70B9"), plot = FALSE)),
    "near-identical greys")
})

test_that("min pairwise delta finds the closest pair", {
  md <- rcds:::.rcds_min_pairwise_delta(c("#000000", "#FFFFFF", "#FEFEFE"))
  expect_equal(sort(c(md$i, md$j)), c(2, 3))   # the two near-whites
  expect_true(md$min < 5)
})

test_that("cvd check returns the right shape and flags blue-vs-green", {
  skip_if_not_installed("colorspace")
  rows <- suppressWarnings(suppressMessages(
    rcds_cvd_check(c("#1E6FB8", "#3FA34D"), plot = FALSE)))
  # 2 colours x (Original + 3 sims) = 8 rows
  expect_equal(nrow(rows), 8)
  rep <- attr(rows, "report")
  expect_true("deutan" %in% rep$type)
})
