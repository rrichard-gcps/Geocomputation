################################################################################
## RCDS Template: Bivariate Choropleth (biscale)
## Mirrors Day 16, using the RCDS biv_dkblue 3x3 grid. Requires `biscale`.
################################################################################

library(rcds)
library(ggplot2)
library(sf)
library(biscale)
library(patchwork)

rcds_fonts("default")

# geo with two standardized numeric fields: x_var, y_var
geo <- bi_class(geo, x = x_var, y = y_var, style = "quantile", dim = 3)

# RCDS bivariate palette as a named 3x3 vector (rows = y, cols = x)
biv <- rcds_pal("biv_dkblue")

map <- ggplot() +
  geom_sf(data = geo, aes(fill = bi_class), colour = NA, show.legend = FALSE) +
  geom_sf(data = outline_sf, fill = NA, colour = rcds_color("ink.on_dark_3")) +
  scale_fill_manual(values = biv) +
  theme_rcds_map(canvas = "dark", legend_position = "none")

legend <- bi_legend(pal = "DkBlue", dim = 3,    # closest stock biscale legend
                    xlab = "Higher <X>", ylab = "Higher <Y>", size = 9)

credits <- rcds_credits(
  challenge = "#30DayMapChallenge 2024 Day <N>: Choropleth",
  sources   = "U.S. Census Bureau", canvas = "deep", align = "right")

fig <- (map + inset_element(legend, 0.02, 0.02, 0.30, 0.30)) / credits +
  plot_layout(heights = c(8, 1)) +
  plot_annotation(title = "<TITLE>", subtitle = "<SUBTITLE>",
    theme = theme(plot.background = element_rect(
      fill = rcds_color("canvas.dark"), colour = NA)))

rcds_export(fig, "day<N>_bivariate.png", preset = "poster_land", canvas = "dark")
