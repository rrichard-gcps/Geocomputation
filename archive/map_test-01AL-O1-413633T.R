library(tidyverse)
library(sf)
library(ggrepel)
library(ggthemes)
library(showtext)
library(ggsci)
library(ggspatial)
library(tigris)



# # Static map with ggplot
# # Plot schools in Georgia with different colors by level
# ggplot(data = ga_schools) +
#   geom_sf(aes(color = LEVEL, geometry = geometry), size = 0.5, alpha = 0.6) +
#   scale_color_manual(values = c("Elementary" = "orange", "Middle" = "green", "High" = "blue")) +
#   theme_minimal() +
#   labs(
#     title = "US Public Schools in Georgia, School Year 2022-23",
#     subtitle = "Categorized by Educational Level",
#     color = "Educational Level",
#     caption = "Data Source: National Center for Education Statistics (NCES)"
#   )


ga_sch_systems <- school_districts(state = "13", type = "unified")

# Determine the predominant locale type for each school system
locale_by_system <- ga_schools %>%
  group_by(NCESID = substr(NCESSCH, 1, 7)) %>%  # Assuming first 7 digits identify the school district
  count(LOCALE) %>%
  ungroup() |> 
  slice_max(n, by = "LOCALE", with_ties = FALSE)

# Join the locale information with the school system boundaries
ga_sch_systems <- ga_sch_systems %>%
  left_join(locale_by_system, by = c("GEOID" = "NCESID"))

# Static map with ggplot and additional enhancements
# Set up Google fonts using showtext
font_add_google("Roboto Condensed", "roboto")
showtext_auto()

# Plot schools in Georgia with different colors by level
ggplot() +
  geom_sf(data = ga_sch_systems, aes(fill = LOCALE), color = "#999999", size = 0.1) +  # Shade districts by locale
  scale_fill_manual(values = c("City" = "#FFD700", "Suburb" = "#87CEEB", "Town" = "#32CD32", "Rural" = "#FFA07A"), na.value = "#E0E0E0") +  # Fill colors for locale types
  # geom_sf(data = ga_schools, aes(color = LEVEL, geometry = geometry), size = 1.2, alpha = 0.9) +  # Increase size and alpha to make points pop
  #   scale_color_manual(values = c("Elementary" = "#E69F00", "Middle" = "#56B4E9", "High" = "#009E73")) +
  annotation_scale(location = "bl", width_hint = 0.3) +
  annotation_north_arrow(location = "tr", style = north_arrow_fancy_orienteering) +  # Move north arrow to top right
  theme_map(base_family = "roboto") +
  theme(
    plot.title = element_text(size = 20, face = "bold", color = "#333333"),
    plot.subtitle = element_text(size = 14, color = "#555555"),
    legend.title = element_text(size = 12, face = "bold", color = "#333333"),
    legend.text = element_text(size = 10, color = "#555555"),
    legend.position = "topright",  # Move the legend to the top right corner
    panel.background = element_rect(fill = "#F8F8F8", color = NA),
    plot.background = element_rect(fill = "#F0F0F0", color = NA),
    panel.grid.major = element_line(color = "#DDDDDD", size = 0.3),
    panel.grid.minor = element_blank()
  ) +
  labs(
    title = "US Public Schools in Georgia, School Year 2022-23",
    subtitle = "Categorized by Educational Level and Locale",
    fill = "School System Locale",
    color = "Educational Level",
    caption = "Data Source: National Center for Education Statistics (NCES)"
  )
