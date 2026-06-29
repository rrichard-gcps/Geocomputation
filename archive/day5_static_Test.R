# Load necessary libraries
library(ggplot2)
library(sf)
library(geosphere)
library(ggimage)
library(ggrepel)
library(curl)

# Load logo paths
logo_paths <- list.files("logos/", full.names = TRUE)

# Ensure the number of logos matches the number of teams
logo_paths <- logo_paths[1:18]

# Example data frame with team locations and additional information (colors and logos)
teams <- data.frame(
  team = c("Boston College", "California", "Clemson", "Duke", "Florida State", "Georgia Tech", "Louisville", "Miami", "North Carolina", "NC State", "Notre Dame", "Pittsburgh", "SMU", "Stanford", "Syracuse", "Virginia", "Virginia Tech", "Wake Forest"),
  lat = c(42.3355, 37.8715, 34.6834, 36.0014, 30.4383, 33.7756, 38.2527, 25.7216, 35.9049, 35.7847, 41.7056, 40.4440, 32.7767, 37.4275, 43.0342, 38.0336, 37.2296, 36.1327),
  lon = c(-71.1685, -122.2730, -82.8374, -78.9382, -84.2807, -84.3963, -85.7585, -80.2788, -79.0500, -78.6821, -86.2353, -79.9607, -96.7970, -122.1697, -76.1360, -78.5080, -80.4234, -80.2757),
  primary_color = c("#98002E", "#003262", "#F66733", "#012169", "#782F40", "#B3A369", "#AD0000", "#F47321", "#4B9CD3", "#CC0000", "#002649", "#003594", "#0033A0", "#8C1515", "#D44500", "#E57200", "#630031", "#9E7E38"),
  secondary_color = c("#B3A369", "#FDB515", "#522D80", "#FFFFFF", "#CEB888", "#121212", "#000000", "#005030", "#FFFFFF", "#000000", "#B1B2B4", "#FFB81C", "#D41A24", "#FFFFFF", "#FFFFFF", "#232D4B", "#F68026", "#CBB67C"),
  logo = logo_paths # Use the loaded logo paths
)

# Location of ACC Tournament (Charlotte, NC)
acc_tournament <- data.frame(
  location = "Spectrum Center",
  lat = 35.2271,
  lon = -80.8431,
  logo = "ACC_Basketball.png" # Use ACC logo from main directory
)

# Plotting
library(ggimage)

# Plotting the map
p <- ggplot() +
  borders("state", colour = "gray80", fill = "gray95") +
  coord_sf(crs = st_crs(5070)) + # Use Albers projection
geom_image(data = teams, aes(x = lon, y = lat, image = logo), size = 0.05, na.rm = TRUE) +
  geom_text_repel(data = teams, aes(x = lon, y = lat, label = team, color = primary_color), max.overlaps = 20) +
  geom_segment(data = teams, aes(x = lon, y = lat, xend = acc_tournament$lon, yend = acc_tournament$lat, color = secondary_color), arrow = arrow(length = unit(0.2, "cm"))) +
  geom_image(data = acc_tournament, aes(x = lon, y = lat, image = logo), size = 0.1, na.rm = TRUE) +
  scale_color_identity() +
  theme_minimal() +
  labs(title = "ACC Basketball Team Travel to the 2024-25 ACC Tournament", x = "Longitude", y = "Latitude")

# Filter teams within the original ACC footprint
acc_footprint_teams <- teams[teams$team %in% c("Duke", "North Carolina", "NC State", "Virginia", "Virginia Tech", "Wake Forest"), ]

# Create inset map of the original ACC footprint
p_inset <- ggplot() +
  borders("state", regions = c("virginia", "north carolina"), colour = "gray80", fill = "gray95") +
  coord_sf(crs = st_crs(5070)) + # Use Albers projection
  geom_image(data = acc_footprint_teams, aes(x = lon, y = lat, image = logo), size = 0.08, na.rm = TRUE) +
  geom_text_repel(data = acc_footprint_teams, aes(x = lon, y = lat, label = team, color = primary_color), max.overlaps = 20) +
  geom_segment(data = acc_footprint_teams, aes(x = lon, y = lat, xend = acc_tournament$lon, yend = acc_tournament$lat, color = secondary_color), arrow = arrow(length = unit(0.2, "cm"))) +
  geom_image(data = acc_tournament, aes(x = lon, y = lat, image = logo), size = 0.1, na.rm = TRUE) +
  scale_color_identity() +
  theme_minimal() +
  labs(title = "North Carolina and Virginia Teams Detail Inset Travel to the 2024-25 ACC Tournament", x = "Longitude", y = "Latitude")

# Create combined map using patchwork
library(cowplot)
combined_map <- ggdraw() +
  draw_plot(p) +
  draw_plot(p_inset, x = 0.6, y = 0.6, width = 0.35, height = 0.35)

ggsave("combined_map.png", combined_map, width = 12, height = 10, units = "in")
