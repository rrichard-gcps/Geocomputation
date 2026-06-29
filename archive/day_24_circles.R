# Load required libraries
library(tidycensus)
library(sf)
library(tidyverse)
library(ggplot2)
library(showtext)  # For using custom fonts

# Set your Census API key (please replace with your actual key)
# census_api_key("YOUR_CENSUS_API_KEY", install = TRUE)

# Set caching to save the geometry for future use
options(tigris_use_cache = TRUE)

# Add Uchrony-Circle font from your system
font_add(family = "uchrony_circle", regular = "C:/Users/e201401047/AppData/Local/Microsoft/Windows/Fonts/UchronyCircle-Regular-FFP.ttf")  # Update with correct font path if needed
showtext_auto()

# Step 1: Get data for all school districts in Georgia
# Here, we are looking for school district data by population (total population as a proxy for enrollment)
school_districts <- get_acs(
  geography = "school district (unified)",
  state = "GA",
  variables = "B01003_001", # Total population variable
  geometry = TRUE,
  year = 2021,
  survey = "acs5"
)

# Transform the projection for better visualization
school_districts <- st_transform(school_districts, crs = 3857)

# Step 2: Calculate centroids for each school district
centroids <- school_districts %>% st_centroid()

# Step 3: Create circular geometries around centroids with radius proportional to population, resembling a cartogram
create_circle <- function(centroid, population, scale_factor = 0.1) {
  radius <- sqrt(population) * scale_factor  # Radius scaled by square root of population for better visualization
  st_buffer(centroid, dist = radius)
}

# Apply the function to each centroid to create circles that form a cartogram-like visualization
circles <- centroids %>%
  rowwise() %>%
  mutate(circle = list(create_circle(geometry, estimate, scale_factor = 50))) %>%  # Increase scale factor for more pronounced cartogram effect
  unnest(circle)

# Step 4: Plot the circles on a map without a legend, only showing the circles
# Use a vibrant color palette with a full-width grey background
ggplot() +
  geom_sf(data = circles, aes(geometry = circle, fill = estimate), shape = 21, color = NA, alpha = 0.8) +
  labs(
    title = "Georgia School Districts by Population",
    subtitle = "2022 ACS 5-Year Estimates (using Tidycensus)",
    caption = "#30DayMapChallenge 2024 Day 24: Only circular shapes\nData Source: US Census Bureau\nTool: R\nCreated By: Roland Richard"
  ) +
  scale_fill_gradient(low = "#00BFFF", high = "#FF4500", guide = 'none') +  # Apply color gradient for population values
  theme_void() +
  theme(
    panel.background = element_rect(fill = "#2e2e2e", color = NA),  # Full-width dark grey background
    plot.background = element_rect(fill = "#2e2e2e", color = NA),
    plot.margin = margin(t = 20, r = 80, b = 50, l = 100),  # Widen margins to fit all labels within the plot area
    text = element_text(family = "uchrony_circle", color = "#ffffff"),
    plot.title = element_text(family = "uchrony_circle", face = "bold", size = 50, color = "#ffffff", hjust = 0.5),
    plot.subtitle = element_text(family = "uchrony_circle", size = 36, color = "#ffffff", hjust = 0.5),
    plot.caption = element_text(family = "uchrony_circle", size = 24, color = "#ffffff", lineheight = 0.55)
  ) +
  coord_sf(clip = "off")

ggsave(plot = last_plot(),
       filename = "day24_circles.png",
       type = "cairo",
       bg = "#2e2e2e",
       width = 11,
       height = 14,
       units = "in",
       dpi = 200)
