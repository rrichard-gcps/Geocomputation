################################################################################
## RCDS Template: Categorical Points (graduated by category)
## Mirrors the Day 1 "schools by level" map, systematised.
################################################################################

library(rcds)
library(ggplot2)
library(sf)

rcds_fonts("default")

# points_sf$category : factor (ordered if it has a natural order)
# context_sf         : polygons drawn underneath as faint reference

main <- ggplot() +
  geom_sf(data = context_sf, fill = NA,
          colour = rcds_color("ink.hairline_dark"), linewidth = 0.15) +
  geom_sf(data = points_sf, aes(colour = category, size = category), alpha = 0.9) +
  scale_color_rcds_d("qual_brand", name = "<CATEGORY>") +
  scale_size_manual(values = c(1.0, 1.25, 1.5), guide = "none") +   # graduated
  guides(colour = guide_legend(override.aes = list(size = 4))) +
  labs(
    title    = "<TITLE>",
    subtitle = "<SUBTITLE>",
    caption  = rcds_signature(
      challenge = "#30DayMapChallenge 2024 Day <N>: Points",
      sources   = "<SOURCE>")
  ) +
  theme_rcds_map(base = 12, canvas = "light")   # points often read better on light

rcds_export(main, "day<N>_points.png", preset = "social_portrait", canvas = "light")
