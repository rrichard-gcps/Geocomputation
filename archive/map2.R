library(tidyverse)
library(sf)
library(ggrepel)
library(ggthemes)
library(showtext)
library(ggsci)
library(ggspatial)
library(tigris)



ga_sch_systems <- school_districts(state = "13", type = "unified", cb = TRUE)

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
  geom_sf(data = ga_sch_systems, fill = NA, color = "#999999", size = 0.1) +  # Shade districts by locale
  geom_sf(
    data = ga_schools, 
    aes(color = LEVEL, geometry = geometry, size = LEVEL), 
    alpha = 0.9
  ) +  # Graduated point sizes by level
  scale_color_manual(
    values = c(
      "Elementary" = "#FFA500",  # Orange for Elementary
      "Middle" = "#1E90FF",  # Dodger Blue for Middle
      "High" = "#32CD32"  # Lime Green for High
    )
  ) +
  guides(color = guide_legend(override.aes = list(size = 4))) +
  scale_size_manual(
    values = c(
      "Elementary" = 1.0,  # Smallest size for Elementary
      "Middle" = 1.25,  # Medium size for Middle
      "High" = 1.5  # Largest size for High
    ),
    guide = "none"  # Remove the size legend
  ) +
  # annotation_scale(location = "bl", plot_unit = "mi") +
  # annotation_north_arrow(location = "tr", style = north_arrow_fancy_orienteering) +  # Move north arrow to top right
  theme_map(base_family = "roboto") +
  theme(
    plot.title = element_text(size = rel(2.8), family = "roboto_black", face = "bold", color = "#333333"),
    plot.subtitle = element_text(size = rel(2.0), family = "roboto", color = "#555555"),
    plot.caption = element_text(size = rel(1.2), family = "roboto", color = "#666666", hjust = 0),
    legend.title = element_text(size = rel(1.8), family = "roboto", face = "bold", color = "#333333"),
    legend.text = element_text(size = rel(1.6), family = "roboto", color = "#555555"),
    legend.position = "bottom",  # Move the legend to below the plot
    legend.direction = "horizontal",  # Set legend layout to horizontal
    legend.box = "horizontal",  # Arrange multiple legend elements horizontally
    panel.background = element_rect(fill = "#F8F8F8", color = NA),
    plot.background = element_rect(fill = "#F0F0F0", color = NA),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.background = element_blank(),
    plot.margin = margin(t = 20, r = 10, b = 30, l = 10)  # Adjust plot margins to give space for the legend
  ) +
  labs(
    title = "US Public Schools in Georgia, School Year 2022-23",
    subtitle = "By Educational Level",
    fill = "School System Locale",
    color = "Educational Level",
    caption = "#30DayMapChallenge 2024 Day 1: Points\nData Source: National Center for Education Statistics (NCES)\nTool: R\nCreated By: Roland Richard"
  )

# Exporting as a square image at high resolution for social media
ggsave(
  filename = "ga_schools_map_square.png",
  plot = last_plot(),  # Use last_plot() if you want to save the most recent ggplot
  width = 12,          # Width in inches
  height = 12,         # Height in inches to ensure a 1:1 aspect ratio
  dpi = 300,           # Set high resolution (300 dpi)
  units = "in",        # Units in inches
  bg = "#F0F0F0"        # Background color to avoid transparency issues
)


ggsave(plot = last_plot(),
       filename = "day1_points.png",
       type = "cairo",
       bg = "#F0F0F0",
       width = 11,
       height = 14,
       units = "in",
       dpi = 96)
