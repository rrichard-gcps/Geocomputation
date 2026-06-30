################################################################################
## RCDS Template: Proportional Symbols
## sqrt-scaled circles at centroids (cf. Day 24). Area, never radius, ~ value.
################################################################################

library(rcds)
library(ggplot2)
library(sf)

rcds_fonts("default")

# geo$value : numeric magnitude to encode by symbol AREA
pts <- st_centroid(geo)

main <- ggplot() +
  geom_sf(data = geo, fill = rcds_color("canvas.graphite"),
          colour = rcds_color("ink.hairline_dark"), linewidth = 0.15) +
  geom_sf(data = pts, aes(size = value), shape = 21,
          fill = rcds_color("accent.amber"), colour = "white",
          stroke = 0.3, alpha = 0.85) +
  scale_size_area(                       # area-proportional: the honest scaling
    max_size = 18, name = "<LEGEND TITLE>",
    labels = scales::label_comma(),
    guide = guide_legend(override.aes = list(colour = "white"))) +
  labs(
    title    = "<TITLE>",
    subtitle = "<SUBTITLE>",
    caption  = rcds_signature(
      challenge = "#30DayMapChallenge 2024 Day <N>: Circles",
      sources   = "<SOURCE>")
  ) +
  theme_rcds_map(base = 13, canvas = "dark")

rcds_export(main, "day<N>_proportional.png", preset = "social_portrait", canvas = "dark")
