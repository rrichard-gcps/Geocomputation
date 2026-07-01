test_that("gcps is the out-of-the-box default brand", {
  # .onLoad sets this; be explicit in case another test changed it
  old <- getOption("rcds.brand"); on.exit(options(rcds.brand = old), add = TRUE)
  options(rcds.brand = NULL)
  # simulate a fresh load
  if (is.null(getOption("rcds.brand"))) options(rcds.brand = "gcps")
  expect_equal(rcds_brand(), "gcps")
  expect_equal(rcds_default_voice(), "gcps_civic")
  expect_equal(rcds_default_palette("sequential"), "gcps_teal")
  expect_equal(rcds_default_palette("qualitative"), "qual_gcps")
})

test_that("rcds_brand('archive') flips every default", {
  old <- getOption("rcds.brand"); on.exit(options(rcds.brand = old), add = TRUE)
  suppressMessages(rcds_brand("archive"))
  expect_equal(rcds_brand(), "archive")
  expect_equal(rcds_default_voice(), "default")
  expect_equal(rcds_default_palette("sequential"), "seq_blue")
  expect_equal(rcds_default_palette("diverging"), "div_balance")
})

test_that("rcds_brand rejects unknown brands", {
  expect_error(rcds_brand("chartreuse"))
})

test_that("theme_map dispatches to the active brand's theme", {
  old <- getOption("rcds.brand"); on.exit(options(rcds.brand = old), add = TRUE)
  suppressMessages(rcds_brand("gcps"))
  expect_s3_class(theme_map(register_fonts = FALSE), "theme")
  suppressMessages(rcds_brand("archive"))
  expect_s3_class(theme_map(), "theme")
})

test_that("brand-default scales build against the active palette", {
  old <- getOption("rcds.brand"); on.exit(options(rcds.brand = old), add = TRUE)
  suppressMessages(rcds_brand("gcps"))
  expect_s3_class(scale_fill_map_c(), "ScaleContinuous")
  expect_s3_class(scale_fill_map_d(), "ScaleDiscrete")
})

test_that("rcds_fonts(NULL) resolves to the brand default voice", {
  old <- getOption("rcds.brand"); on.exit(options(rcds.brand = old), add = TRUE)
  suppressMessages(rcds_brand("gcps"))
  roles <- suppressMessages(rcds_fonts(quiet = TRUE))
  expect_equal(unname(roles[["display"]]), "Archivo")   # gcps_civic display face
})
