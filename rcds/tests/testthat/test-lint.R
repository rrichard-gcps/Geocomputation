test_that("a clean script produces no findings", {
  clean <- c(
    'library(rcds)',
    'rcds_fonts("default")',
    'p <- ggplot(d) + geom_sf(aes(fill = v), linewidth = 0.2) +',
    '  scale_fill_rcds_c("seq_blue") +',
    '  labs(caption = rcds_signature("Day 1", sources = "Census")) +',
    '  theme_rcds_map(canvas = "dark")',
    'rcds_export(p, "m.png", preset = "web", canvas = "dark")')
  res <- suppressMessages(rcds_lint(clean))
  expect_equal(nrow(res), 0)
  expect_true(attr(res, "clean"))
})

test_that("A6 flags deprecated size= on geom_sf", {
  res <- suppressMessages(rcds_lint('geom_sf(data = x, color = NA, size = 0.2)'))
  expect_true("A6" %in% res$rule)
})

test_that("A1 flags rainbow palettes", {
  res <- suppressMessages(rcds_lint('scale_fill_distiller(palette = "Spectral")'))
  expect_true("A1" %in% res$rule)
  res2 <- suppressMessages(rcds_lint('region_colors <- paletteer_d("ggsci::planetexpress_futurama")'))
  expect_true("A1" %in% res2$rule)
})

test_that("A7 flags hardcoded font paths and inline census keys as high severity", {
  res <- suppressMessages(rcds_lint(
    'font_add(family = "x", regular = "C:/Users/me/Fonts/Thing.ttf")'))
  expect_true("A7" %in% res$rule)
  expect_equal(res$severity[res$rule == "A7"], "high")

  res2 <- suppressMessages(rcds_lint('census_api_key("abc123def456")'))
  expect_true("A7" %in% res2$rule)

  # the documented placeholder is NOT a finding
  res3 <- suppressMessages(rcds_lint('# census_api_key("YOUR_CENSUS_API_KEY", install = TRUE)'))
  expect_false("A7" %in% res3$rule)
})

test_that("A5 flags inline signatures but not rcds_signature()", {
  drift <- suppressMessages(rcds_lint('labs(caption = "Created By: Roland Richard")'))
  expect_true("A5" %in% drift$rule)
  ok <- suppressMessages(rcds_lint('labs(caption = rcds_signature("Day 7"))'))
  expect_false("A5" %in% ok$rule)
})

test_that("A8 flags ggsave without bg= but not rcds_export()", {
  res <- suppressMessages(rcds_lint('ggsave("m.png", width = 10, height = 8)'))
  expect_true("A8" %in% res$rule)
  ok <- suppressMessages(rcds_lint('ggsave("m.png", width = 10, bg = "#1C1C1C")'))
  expect_false("A8" %in% ok$rule)
})

test_that("ignore= suppresses named rules", {
  code <- 'geom_sf(size = 0.2)'
  res <- suppressMessages(rcds_lint(code, ignore = "A6"))
  expect_false("A6" %in% res$rule)
})

test_that("findings are ordered by line and carry a fix", {
  code <- c('ggsave("m.png")', 'geom_sf(size = 0.2)')
  res <- suppressMessages(rcds_lint(code))
  expect_true(all(diff(res$line) >= 0))
  expect_true(all(nzchar(res$fix)))
})
