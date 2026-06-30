################################################################################
## RCDS Template: GCPS-branded Choropleth
## Uses the imported Gwinnett County Public Schools design system: a GCPS data
## ramp + one of the three cartographic poster themes (paper | civic | bold).
################################################################################

library(rcds)
library(ggplot2)
library(sf)

THEME <- "paper"     # "paper" (editorial) | "civic" (light) | "bold" (dark)
mt <- gcps_tokens()$map_themes[[THEME]]

# geo : sf polygons with a numeric <value> column
main <- ggplot(geo) +
  geom_sf(aes(fill = value), colour = mt$dist_stroke, linewidth = 0.3) +
  scale_fill_rcds_c(
    palette = "gcps_teal",            # gcps_<family>: maroon blue teal green violet
    name = "<LEGEND TITLE>",          #   orange neutral gold plum slate emerald
    labels = scales::label_comma(),
    guide = guide_colorbar(title.position = "top", title.hjust = 0.5,
                           barwidth = unit(16, "cm"), barheight = unit(0.5, "cm"))
  ) +
  # highlight a feature in the theme accent (district signature):
  # geom_sf(data = aoi, fill = NA, colour = mt$accent, linewidth = mt$hi_sw) +
  labs(
    title    = "<TITLE>",
    subtitle = "<SUBTITLE>",
    caption  = rcds_signature(
      challenge = "Gwinnett County Public Schools",
      tool = "R / rcds", sources = "<SOURCE>")
  ) +
  theme_gcps_map(THEME, base = 14)

ggsave("gcps_choropleth.png", main, width = 12, height = 9, dpi = 300,
       bg = mt$canvas, type = "cairo")

## Interactive version (same identity):
# library(leaflet)
# rcds_leaflet() |>                                  # base map
#   htmlwidgets::prependContent(htmltools::tags$style(gcps_interactive_css(THEME))) |>
#   rcds_leaflet_choropleth(geo, value = "value", palette = "gcps_teal") |>
#   rcds_save_widget("gcps_choropleth.html")
