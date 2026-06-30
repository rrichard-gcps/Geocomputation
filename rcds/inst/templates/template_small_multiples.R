################################################################################
## RCDS Template: Small Multiples / Faceted Maps
## For time series or category comparison (cf. Day 25 enrollment-by-year,
## Day 26 projections). One shared scale, one shared legend.
################################################################################

library(rcds)
library(ggplot2)
library(sf)

rcds_fonts("editorial")

# geo_long : long-format sf with a `facet` column (year, scenario, category...)
#            and a `value` column on a SHARED scale across panels.

main <- ggplot(geo_long) +
  geom_sf(aes(fill = value), colour = NA) +
  facet_wrap(~ facet, ncol = 5) +
  scale_fill_rcds_c(
    palette = "seq_amber", name = "<LEGEND TITLE>",
    labels = scales::label_comma(),
    guide = guide_colorbar(title.position = "top", title.hjust = 0.5,
                           barwidth = unit(20, "cm"), barheight = unit(0.5, "cm"))) +
  labs(
    title    = "<TITLE>",
    subtitle = "<SUBTITLE>",
    caption  = rcds_signature(
      challenge = "#30DayMapChallenge 2024 Day <N>: Small Multiples",
      sources   = "<SOURCE>")
  ) +
  theme_rcds_map(base = 16, canvas = "dark")

rcds_export(main, "day<N>_small_multiples.png", preset = "poster_land", canvas = "dark")
