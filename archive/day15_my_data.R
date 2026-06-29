# Load required packages
library(ggplot2)
library(sf)
library(urbnmapr)
library(dplyr)
library(patchwork)
library(ggtext)
library(showtext)
library(grid) # To use the unit function

# Add and configure Google font
font_add_google("Lora", "lora")
showtext_auto()

# City coordinates and logos
cities <- data.frame(
  city = c(
    "Atlanta",
    "St. Louis",
    "Washington",
    "Durham",
    "Columbia",
    "Suwanee",
    "Nashville",
    "Donaldsonville"
  ),
  state = c("GA", "MO", "DC", "NC", "SC", "GA", "TN", "LA"),
  lat = c(33.7490, 38.6270, 38.9072, 35.9940, 34.0007, 34.0515, 36.1627, 30.1002),
  lon = c(
    -84.3880,
    -90.1994,
    -77.0369,
    -78.8986,
    -81.0348,
    -84.0713,
    -86.7816,
    -91.0109
  )
)

# Convert cities data to sf object for ggplot2
cities_sf <- st_as_sf(cities, coords = c("lon", "lat"), crs = 4326)

# Load and prepare base map data for contiguous U.S. states
states <- urbnmapr::get_urbn_map("states", sf = TRUE) %>%
  filter(!state_abbv %in% c("AK", "HI")) %>% # Exclude Alaska and Hawaii
  st_transform(crs = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lon_0=-96 +datum=NAD83 +units=m +no_defs")

city_colors <- c(
  "Atlanta" = "#8E4585",       # Dark Plum
  "St. Louis" = "#1D3557",     # Navy Blue
  "Washington" = "#DC143C",    # Crimson Red
  "Durham" = "#008080",        # Teal
  "Columbia" = "#556B2F",      # Olive Green
  "Suwanee" = "#CC5500",       # Burnt Orange
  "Nashville" = "#6A0DAD",     # Violet
  "Donaldsonville" = "#FFD700" # Gold
)

# Create static map with Albers Equal Area projection and minimal background
static_map <- ggplot() +
  geom_sf(
    data = states,
    fill = "#2E2E2E",
    color = "#1A1A1A",
    size = 0.3
  ) +
  geom_sf(
    data = cities_sf %>% filter(city != "Donaldsonville"),
    aes(color = city),
    size = 3,
    show.legend = FALSE
  ) +
  geom_sf(
    data = cities_sf %>% filter(city == "Donaldsonville"),
    color = "#FFD700",
    size = 5,
    shape = 18,
    show.legend = FALSE
  ) +
  scale_color_manual(values = city_colors) +
  coord_sf(crs = st_crs(
    "+proj=aea +lat_1=29.5 +lat_2=45.5 +lon_0=-96 +datum=NAD83 +units=m +no_defs"
  )) +
  labs(
    title = "My Data Journey (Part 1)",
    subtitle = "Mapping Key Locations in My Data Education Path"
  ) +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "#121212", color = NA),
    plot.title = element_text(
      size = 24,
      face = "bold",
      color = "#FFFFFF",
      family = "lora"
    ),
    plot.subtitle = element_text(
      size = 18,
      color = "#CFCFCF",
      family = "lora"
    ),
    panel.grid = element_blank(),
    axis.text = element_blank(),       # Remove axis text
    axis.title = element_blank(),      # Remove axis titles
    axis.ticks = element_blank()       # Remove axis ticks
  )

# Enhanced credits section with improved styling
credits_text <- wrap_elements(
  ggplot() +
    theme_void() +
    geom_richtext(
      aes(
        x = 0, y = 0.2,
        label = "<span style='font-size:10pt; color:#FFFFFF;'><strong>#30DayMapChallenge 2024</strong> | <b>Day 15: My Data</b></span><br>
        <span style='font-size:9pt; color:#CFCFCF;'>Tools: R [ggplot2, patchwork, urbnmapr]</span><br>
        <span style='font-size:9pt; color:#CFCFCF;'>Created By: <strong>Roland Richard</strong></span><br>
        <span style='font-size:9pt; color:#CFCFCF;'>Data Sources: U.S. Census Bureau, Urban Institute</span>"
      ),
      family = "lora",
      hjust = 0.5,
      fill = "#121212",    # Added fill to stretch the background across the width
      label.color = NA
    ) +
    theme(
      panel.background = element_rect(fill = "#121212", color = NA),
      plot.margin = unit(c(1, 200, 1, 200), "pt")  # Corrected to use 'unit' to specify the length of margins
    )
)

# Combine map and credits with patchwork
final_map <- static_map / credits_text +
  plot_layout(heights = c(5, 0.5))   # Adjusted height ratio to provide balance between map and credits

print(final_map)

# Save the final map
ggsave(
  filename = "day15_my_data.png",
  plot = final_map,
  width = 12,
  height = 10,
  dpi = 300
)
