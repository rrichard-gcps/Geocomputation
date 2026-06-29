################################################################################
## Project: day5_journeys
## Purpose: 
## Created: 
## Updated: 
## Creator: 
################################################################################

# Load necessary libraries
library(ggplot2)
library(sf)
library(ggimage)
library(ggrepel)
library(tigris)
library(dplyr)
library(gt)
library(geosphere)
library(showtext)
library(ggtext)
library(cowplot)

# Define the CRS projection as a constant variable
crs_proj <- st_crs('+proj=eqdc +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +datum=WGS84 +units=m +no_defs')

# Load logo paths
logo_paths <- list.files("logos/", full.names = TRUE)

# Sort the logos and team names alphabetically to ensure they align correctly
logo_paths <- logo_paths[order(c("Boston College", "California", "Clemson", "Duke", "Florida State", "Georgia Tech", "Louisville", "Miami", "Notre Dame", "NC State", "North Carolina", "Pittsburgh", "SMU", "Stanford", "Syracuse", "Virginia", "Virginia Tech", "Wake Forest"))]

# Example data frame with team locations, additional information, and logos
teams <- data.frame(
  team = c("Boston College", "California", "Clemson", "Duke", "Florida State", "Georgia Tech", "Louisville", "Miami", "Notre Dame", "NC State", "North Carolina", "Pittsburgh", "SMU", "Stanford", "Syracuse", "Virginia", "Virginia Tech", "Wake Forest"),
  lat = c(42.3355, 37.8715 + 0.02, 34.6834, 36.0014, 30.4383, 33.7756, 38.2527, 25.7216, 41.7056, 35.7847, 35.9049, 40.4440, 32.7767, 37.4275 - 0.02, 43.0342, 38.0336, 37.2296, 36.1327),
  lon = c(-71.1685, -122.2730 - 0.02, -82.8374, -78.9382, -84.2807, -84.3963, -85.7585, -80.2788, -86.2353, -78.6821, -79.0500, -79.9607, -96.7970, -122.1697 + 0.02, -76.1360, -78.5080, -80.4234, -80.2757),
  primary_color = c("#98002E", "#003262", "#F66733", "#012169", "#782F40", "#B3A369", "#AD0000", "#F47321", "#002649", "#CC0000", "#4B9CD3", "#003594", "#0033A0", "#8C1515", "#D44500", "#E57200", "#630031", "#9E7E38"),
  secondary_color = c("#B3A369", "#FDB515", "#522D80", "#FFFFFF", "#CEB888", "#121212", "#000000", "#005030", "#B1B2B4", "#000000", "#FFFFFF", "#FFB81C", "#D41A24", "#FFFFFF", "#FFFFFF", "#232D4B", "#F68026", "#CBB67C"),
  logo = logo_paths
)

# Convert teams data frame to sf object and transform to match map CRS
teams_sf <- st_as_sf(teams, coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(crs = crs_proj)

# Location of ACC Tournament (Charlotte, NC)
acc_tournament <- data.frame(
  location = "Spectrum Center",
  lat = 35.2271,
  lon = -80.8431,
  logo = "ACC_Basketball.png"
)

# Convert acc_tournament to sf object and transform to match map CRS
acc_tournament_sf <- st_as_sf(acc_tournament, coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(crs = crs_proj)

# Function to calculate distances from each school to a given location (in miles)
calculate_distance <- function(lon, lat, target_lon, target_lat) {
  distHaversine(matrix(c(lon, lat), ncol = 2), c(target_lon, target_lat)) * 0.000621371
}

# Calculate distances from each school to Charlotte, NC (in miles)
teams$distance_to_charlotte <- calculate_distance(teams$lon, teams$lat, acc_tournament$lon, acc_tournament$lat)

# Create GT table with school logo and distance to Charlotte
teams_gt <- teams %>%
  select(team, logo, distance_to_charlotte) %>%
  gt() %>%
  text_transform(
    locations = cells_body(vars(logo)),
    fn = function(x) {
      web_image(url = x, height = px(30))
    }
  ) %>%
  cols_label(
    team = "School",
    logo = "Logo",
    distance_to_charlotte = "Distance to Charlotte (miles)"
  )

# Credits for the map
credits_text <- "#30DayMapChallenge 2024\nDay 5: Journeys\nTool: R\nCreated By: Roland Richard\nData Sources: The Atlantic Coast Conference (2024)"

# Use showtext to load Google fonts
font_add_google("Orbitron", "orbitron")
font_add_google("Roboto", "roboto")
showtext_auto()

# Plotting the map with ACC color scheme
acc_blue <- "#013CA6"  # ACC blue color from brand guide
acc_gray <- "#B1B3B3"  # Light gray color for background
headline_font_family <- "orbitron"
body_font_family <- "roboto"

p <- ggplot() +
  geom_sf(data = tigris::states(cb = TRUE) %>% filter(!STUSPS %in% c("AK", "HI", "GU", "PR", "VI", "MP", "AS")), fill = acc_gray, color = "gray80") +
  coord_sf(crs = crs_proj, expand = FALSE) +
  geom_image(data = teams_sf, aes(x = st_coordinates(geometry)[,1], y = st_coordinates(geometry)[,2], image = logo), size = 0.07, inherit.aes = FALSE, na.rm = TRUE) +
  geom_text_repel(data = teams_sf,
                  aes(x = st_coordinates(geometry)[,1], y = st_coordinates(geometry)[,2], label = team, color = primary_color),
                  max.overlaps = Inf, size = 16, box.padding = 2, force = 10, point.padding = 1.5, nudge_x = 0.3, nudge_y = 0.3, family = headline_font_family, fontface = "bold", hjust = 0.5) +
  geom_segment(data = teams_sf, aes(x = st_coordinates(geometry)[,1], y = st_coordinates(geometry)[,2],
                                    xend = st_coordinates(acc_tournament_sf$geometry)[,1],
                                    yend = st_coordinates(acc_tournament_sf$geometry)[,2],
                                    color = ifelse(secondary_color == "#FFFFFF", primary_color, secondary_color)), 
               arrow = arrow(length = unit(0.2, "cm")) ) +
  geom_image(data = acc_tournament_sf, aes(x = st_coordinates(geometry)[,1], y = st_coordinates(geometry)[,2], image = logo), size = 0.1, inherit.aes = FALSE) +
  scale_color_identity() +
  theme_void() +
  theme(
    plot.background = element_rect(fill = acc_blue, color = NA),
    panel.background = element_rect(fill = acc_blue, color = NA),
    plot.margin = margin(30, 30, 30, 30),
    text = element_text(color = acc_blue, face = "plain", size = 24, family = body_font_family),
    plot.title = element_text(size = 56, face = "bold", color = "#FFFFFF", family = headline_font_family, hjust = 0, margin = margin(t = 20, b = 20)),
    plot.subtitle = element_text(size = 50, face = "plain", color = "#FFFFFF", family = body_font_family, hjust = 0, margin = margin(t = 10, b = 20))
  ) +
  labs(
    title = "ACC Basketball Team Travel to the 2024-25 ACC Tournament",
    subtitle = paste("Total Cumulative Miles Traveled: ", prettyNum(round(sum(teams$distance_to_charlotte)),big.mark = ","), " miles"),
    x = "", y = ""
  )

# Add credits using cowplot
p_with_credits <- ggdraw(p) +
  draw_text(credits_text, x = 0.02, y = 0.1, hjust = 0, vjust = 0, size = 36, family = headline_font_family, color = '#CFCFCF')
# Save the map
ggsave(
  filename = "day5_journeys.png",
  plot =  p_with_credits,
  type = "cairo",
  scale = 1.4,
  width = 24,
  height = 18,
  units = "in",
  dpi = 150
)    # High DPI for better quality

# Display GT table
teams_gt

p
