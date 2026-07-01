test_that("gcps_ui_themes lists the six shells", {
  ut <- gcps_ui_themes()
  expect_length(ut, 6)
  expect_true(all(c("editorial", "clarity", "dark", "soft", "bold", "civic")
                  %in% names(ut)))
})

test_that("gcps_bs_theme builds a bslib theme from a shell", {
  skip_if_not_installed("bslib")
  th <- gcps_bs_theme("civic")
  expect_s3_class(th, "bs_theme")
})

test_that("gcps_bs_theme rejects an unknown shell", {
  skip_if_not_installed("bslib")
  expect_error(gcps_bs_theme("chartreuse"))
})
