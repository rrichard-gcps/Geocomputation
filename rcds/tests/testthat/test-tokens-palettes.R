test_that("rcds_color resolves dotted paths and errors on bad ones", {
  expect_equal(rcds_color("canvas.dark"), "#1C1C1C")
  expect_equal(rcds_color("accent.blue"), "#1E6FB8")
  expect_error(rcds_color("canvas.nope"), "Unknown token")
  expect_error(rcds_color("nonsense"), "Unknown token")
})

test_that("rcds_tokens has the expected structure", {
  tk <- rcds_tokens()
  expect_true(all(c("canvas", "ink", "accent", "space") %in% names(tk)))
  expect_true(all(grepl("^#", unlist(tk$canvas))))
  expect_named(tk$space, c("xs", "sm", "md", "lg", "xl", "xxl"))
})

test_that("%out% negates %in%", {
  expect_equal(c(1, 2, 3) %out% c(2, 3), c(TRUE, FALSE, FALSE))
})

test_that("rcds_pal returns valid hex of requested length", {
  p <- rcds_pal("seq_blue", 5)
  expect_length(p, 5)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", p)))
})

test_that("continuous families interpolate, qualitative families cap", {
  expect_length(rcds_pal("div_balance", 11), 11)        # interpolated up
  expect_length(rcds_pal("qual_brand", 4), 4)           # subset
  expect_error(rcds_pal("qual_brand", 99), "categories")
  expect_error(rcds_pal("does_not_exist", 3), "Unknown palette")
})

test_that("reverse flips the ramp", {
  a <- rcds_pal("seq_amber", 6)
  b <- rcds_pal("seq_amber", 6, reverse = TRUE)
  expect_equal(a, rev(b))
})

test_that("bivariate palette is a named 3x3 grid", {
  biv <- rcds_pal("biv_dkblue")
  expect_length(biv, 9)
  expect_true(all(paste(rep(1:3, each = 3), rep(1:3, 3), sep = "-") %in% names(biv)))
})

test_that("rcds_palettes catalogues every defined family", {
  cat <- unlist(rcds_palettes(), use.names = FALSE)
  expect_true(all(c("seq_blue", "div_temp", "qual_soft", "biv_dkblue") %in% cat))
})
