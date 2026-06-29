
# Load necessary libraries
library(ggplot2)
library(sf)
library(geosphere)
library(dplyr)
library(ggspatial)
library(showtext)
library(tigris)

# Load the datasets
cities_df <- read.csv('cities.csv')
cfb_df <- read.csv('data/cfb.csv')

# Filter out Alaska, Hawaii, and territories, and keep only the lower 48 states
continental_us_bbox <- st_bbox(c(xmin = -125, xmax = -66, ymin = 24, ymax = 50))
cities_df <- cities_df %>% filter(INTPTLON >= continental_us_bbox['xmin'], INTPTLON <= continental_us_bbox['xmax'],
                                  CENTLAT >= continental_us_bbox['ymin'], CENTLAT <= continental_us_bbox['ymax'])

# Convert cities and teams dataframes to spatial dataframes
cities_sf <- st_as_sf(cities_df, coords = c('INTPTLON', 'CENTLAT'), crs = 4326)
teams_sf <- st_as_sf(cfb_df, coords = c('Location.Longitude', 'Location.Latitude'), crs = 4326)

# Transform the projection to EPSG 5070 (Albers Equal Area)
cities_sf <- st_transform(cities_sf, crs = 5070)
teams_sf <- st_transform(teams_sf, crs = 5070)

# Load US state polygons (lower 48 states only)
us_states <- states(cb = TRUE) %>% filter(!(NAME %in% c("Alaska", "Hawaii", "Puerto Rico", "Guam", "American Samoa", "Virgin Islands", "Northern Mariana Islands"))) %>% st_transform(crs = 5070)

# Load US places polygons using tigris (lower 48 states only)
us_places <- places(cb = TRUE) %>% filter(!(STATEFP %in% c("02", "15", "72", "60", "66", "78", "69"))) %>% st_transform(crs = 5070)

# Function to calculate the nearest team and assign a color
assign_team_color <- function(city, teams_df) {
  distances <- st_distance(city, teams_df)
  nearest_index <- which.min(distances)
  team_color <- teams_df$Color[nearest_index]
  alt_color <- teams_df$Alt.Name1[nearest_index]
  
  if (tolower(team_color) == '#000000' || is.na(team_color) || team_color == "") {
    return(alt_color)
  }
  return(team_color)
}

# Assign nearest team color to each place
us_places_centroids <- st_centroid(us_places)
us_places$TeamColor <- apply(st_coordinates(us_places_centroids), 1, function(coords) {
  city_point <- st_sfc(st_point(coords), crs = 5070)
  assign_team_color(city_point, teams_sf)
})

# Ensure there are no missing or empty colors in TeamColor
us_places <- us_places %>% mutate(TeamColor = ifelse(is.na(TeamColor) | TeamColor == "", "#999999", TeamColor))

# Add a sports-like font
font_add_google("Bebas Neue", "bebas")
showtext_auto()

# Plot the map using ggplot2 with enhanced styling, only showing the continental US in EPSG 5070
ggplot() +
  geom_sf(data = us_places, aes(fill = TeamColor), color = "black", size = 0.2, alpha = 0.8) +
  geom_sf(data = teams_sf, shape = 21, fill = 'white', color = 'black', size = 2, stroke = 1.5) +
  geom_sf(data = us_states, fill = NA, color = "white", size = 0.5) +
  scale_fill_identity() +
  coord_sf(crs = st_crs(5070), xlim = c(-2500000, 2500000), ylim = c(-2000000, 1500000)) +
  labs(title = "Nearest FBS Team Colors for US Places",
       caption = "Data source: CFB Program Data and US Cities Data") +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 22, family = "bebas", color = "white"),
    plot.caption = element_text(size = 10, face = "italic", hjust = 1, color = "white"),
    panel.grid.major = element_line(color = "grey80", linetype = "dotted"),
    panel.background = element_rect(fill = "#1c1c1c"),
    axis.text = element_blank(),
    axis.title = element_blank(),
    legend.position = "none",
    plot.background = element_rect(fill = "#1c1c1c"),
    text = element_text(color = "white")
  )
