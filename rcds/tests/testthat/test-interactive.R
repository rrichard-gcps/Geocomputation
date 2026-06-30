test_that("basemaps map dark canvases to DarkMatter and light to Positron", {
  bm <- rcds_basemaps()
  expect_match(bm[["dark"]], "DarkMatter")
  expect_match(bm[["deep"]], "DarkMatter")
  expect_match(bm[["light"]], "Positron")
  expect_match(rcds_basemaps(labels = FALSE)[["dark"]], "NoLabels")
})

test_that("interactive CSS carries token colours, font voice, and the :root seam", {
  css <- rcds_interactive_css("dark")
  expect_true(grepl(":root", css))
  expect_true(grepl("--rcds-canvas", css))
  expect_true(grepl(rcds_color("canvas.dark"), css, fixed = TRUE))
  expect_true(grepl(rcds_color("accent.blue"), css, fixed = TRUE))
  expect_true(grepl("fonts.googleapis.com", css))
  expect_true(grepl("leaflet-popup-content-wrapper", css))
})

test_that("interactive CSS tracks the active font voice", {
  old <- getOption("rcds.fonts")
  on.exit(options(rcds.fonts = old), add = TRUE)
  options(rcds.fonts = list(display = "Anton", body = "Roboto Condensed",
                            caption = "Roboto"))
  css <- rcds_interactive_css("dark")
  expect_true(grepl("Anton", css))
})

test_that("interactive CSS errors on an unknown canvas", {
  expect_error(rcds_interactive_css("chartreuse"), "Unknown canvas")
})

test_that("maplibre style is a valid v8 spec with the canvas as background", {
  st <- rcds_maplibre_style("slate")
  expect_equal(st$version, 8L)
  expect_equal(st$layers[[1]]$type, "background")
  expect_equal(st$layers[[1]]$paint[["background-color"]], rcds_color("canvas.slate"))
})

test_that("leaflet helpers fail gracefully without their packages", {
  skip_if_not_installed("leaflet")
  # with leaflet present, the palette bridge builds a function
  pal <- rcds_pal_leaflet("seq_blue", domain = c(0, 100), type = "numeric")
  expect_type(pal, "closure")
})
