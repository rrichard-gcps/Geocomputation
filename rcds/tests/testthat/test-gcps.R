test_that("gcps_tokens has the full 11-family system", {
  tk <- gcps_tokens()
  expect_equal(tk$signature, "#660000")
  expect_length(tk$base, 11)
  expect_equal(tk$base[["maroon"]], "#660000")
  expect_true(all(lengths(tk$ramps) == 5))
  expect_length(tk$ramps, 11)
  expect_length(tk$diverging, 10)            # every family except neutral
  expect_true(all(lengths(tk$diverging) == 5))
  expect_true(all(grepl("^#", unlist(tk$base))))
})

test_that("gcps map and ui themes are present and well-formed", {
  tk <- gcps_tokens()
  expect_named(tk$map_themes, c("paper", "civic", "bold"))
  expect_equal(tk$map_themes$bold$canvas, "#14161B")
  expect_equal(tk$map_themes$paper$accent, "#8C2F39")
  expect_equal(tk$map_themes$civic$voice, "gcps_civic")
  expect_length(tk$ui_themes, 6)
})

test_that("GCPS palettes are registered into the rcds palette system", {
  expect_length(rcds_pal("gcps_teal", 5), 5)
  expect_true(all(grepl("^#", rcds_pal("gcps_maroon"))))
  expect_length(rcds_pal("gcps_blue_div", 7), 7)        # continuous interpolation
  # qual_gcps is categorical: discrete subset, capped at 11
  expect_length(rcds_pal("qual_gcps", 4), 4)
  expect_error(rcds_pal("qual_gcps", 99), "categories")
})

test_that("the palette catalogue lists the GCPS groups", {
  pals <- rcds_palettes()
  expect_true("gcps_sequential" %in% names(pals))
  expect_true("gcps_teal" %in% pals$gcps_sequential)
  expect_true("gcps_blue_div" %in% pals$gcps_diverging)
  expect_equal(pals$gcps_qualitative, "qual_gcps")
})

test_that("GCPS palettes flow through the rcds colour helpers", {
  # accessibility resolver recognises GCPS palette names
  expect_length(rcds:::.rcds_resolve_colors("gcps_emerald"), 5)
})

test_that("theme_gcps_map returns a ggplot theme without needing fonts", {
  th <- theme_gcps_map("paper", register_fonts = FALSE)
  expect_s3_class(th, "theme")
})

test_that("gcps_interactive_css carries the theme's canvas, accent, and fonts", {
  css <- gcps_interactive_css("civic")
  expect_true(grepl("#EEF1F5", css, fixed = TRUE))   # civic canvas
  expect_true(grepl("#1F5C8B", css, fixed = TRUE))   # civic accent
  expect_true(grepl("Archivo", css))
  expect_true(grepl(":root", css))
  expect_error(gcps_interactive_css("nope"))
})
