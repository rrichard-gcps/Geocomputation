# Load necessary libraries
library(ggplot2)
library(sf)
library(geosphere)
library(dplyr)
library(tigris)
library(showtext)
library(future.apply)
library(rmapshaper)  # For geometry simplification

# Load the datasets
# cities_df <- read.csv('cities.csv')
cfb_df <- read.csv('data/cfb.csv')

# Install httr and dplyr if not already installed
if (!requireNamespace("httr", quietly = TRUE)) {
  install.packages("httr")
}

if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}

# Load necessary libraries
library(httr)
library(dplyr)


# Create a directory to store logos
logos_directory <- "cfb_logos"
if (!dir.exists(logos_directory)) {
  dir.create(logos_directory)
}

# Iterate through each row, download logos, and add local paths to the dataframe
cfb_df <- cfb_df %>%
  rowwise() %>%
  mutate(local_logo_path = {
    logo_url <- Logos.1.  # Assuming column name is 'logo_url'
    file_name <- basename(logo_url)  # Extract file name from URL
    
    # Sanitize the file name to ensure no special characters
    file_name <- gsub("[^a-zA-Z0-9\\.\\-]", "_", file_name)
    
    # Create the local path where the image will be saved
    local_path <- file.path(logos_directory, file_name)
    
    # Download the file if it doesn't already exist
    if (!file.exists(local_path)) {
      tryCatch({
        # Download the file using httr::GET and save it locally
        response <- httr::GET(logo_url, write_disk(local_path, overwrite = TRUE))
        
        # Check for any HTTP errors
        if (httr::http_error(response)) {
          warning(paste("Failed to download:", logo_url))
          return(NA)  # Return NA if download fails
        }
      }, error = function(e) {
        warning(paste("Error downloading", logo_url, ":", e$message))
        return(NA)  # Return NA if there's an error
      })
    }
    
    # Return the local path to the dataframe
    local_path
  }) %>%
  ungroup()


write.csv(cfb_df, "data/cfb_with_local_paths.csv", row.names = FALSE)


# Load US census block groups using tigris for continental US only
us_block_groups <- block_groups(cb = TRUE) %>%  # Use low-res data for performance
  filter(!(STATEFP %in% c("02", "15", "72", "60", "66", "78", "69"))) %>%
  st_transform(crs = 5070)  # Use EPSG 5070 (NAD83 / Conus Albers) for suitable US projection

# Simplify block group geometries
us_block_groups <- st_simplify(us_block_groups, dTolerance = 500)

# Load US state boundaries
us_states <- states(cb = TRUE) %>%
  filter(!(STATEFP %in% c("02", "15", "72", "60", "66", "78", "69"))) %>%
  st_transform(crs = 5070)

# Convert teams dataframe to a spatial dataframe
teams_sf <- st_as_sf(cfb_df, coords = c('Location.Longitude', 'Location.Latitude'), crs = 4326) %>%
  st_transform(crs = 5070)

teams_sf <- teams_sf |> filter(School != "Hawai'i")

# Function to calculate the nearest team and assign a color
assign_team_color <- function(block_group, teams_df) {
  distances <- st_distance(block_group, teams_df)  # Use geodesic distance
  nearest_index <- which.min(distances)
  team_color <- teams_df$Color[nearest_index]
  alt_color <- teams_df$Alt.Name1[nearest_index]
  
  if (tolower(team_color) == '#000000' || is.na(team_color) || team_color == "") {
    return(alt_color)
  }
  return(team_color)
}

# Set up future for multicore processing
plan(multisession)  # Use multisession for parallel processing

# Parallelized function to assign colors
assign_colors_parallel <- function(block_groups, teams_df) {
  centroids <- st_centroid(block_groups)  # Use centroids for distance calculations
  results <- future_sapply(1:nrow(centroids), function(i) {
    coords <- st_coordinates(centroids[i, ])
    block_point <- st_sfc(st_point(coords), crs = 5070)
    assign_team_color(block_point, teams_df)
  })
  return(results)
}

# Assign nearest team color to each block group using multicore processing
us_block_groups$TeamColor <- assign_colors_parallel(us_block_groups, teams_sf)

# Ensure there are no missing or empty colors in TeamColor
us_block_groups <- us_block_groups %>%
  mutate(TeamColor = ifelse(is.na(TeamColor) | TeamColor == "", "#999999", TeamColor))

# Save us_block_groups with TeamColor as a shapefile
st_write(us_block_groups, "us_block_groups_with_team_colors.shp", delete_layer = TRUE)

# Save teams_sf as a shapefile
st_write(teams_sf, "teams_with_team_colors.shp", delete_layer = TRUE)

# Save cfb_sf (spatial version of cfb_df) as a shapefile
st_write(cfb_sf, "cfb_teams_with_locations.shp", delete_layer = TRUE)

# Add a sports-like font
font_add_google("Bebas Neue", "bebas")
showtext_auto()

# Plot the map using ggplot2 with enhanced styling for the continental US in EPSG 5070
map <- ggplot() +
  geom_sf(data = us_block_groups, aes(fill = TeamColor), color = NA, size = 0.2, alpha = 0.8) +
  geom_sf(data = teams_sf, shape = 21, fill = '#FFFFFF', size = 2, stroke = 1) +
  geom_sf(data = us_states, fill = NA, color = "white", size = 0.5) +
  scale_fill_identity() +
  coord_sf(crs = st_crs(5070), xlim = c(-2200000, 2200000), ylim = c(-800000, 3200000)) +
  labs(title = "Nearest FBS Team Colors for US Places",
       caption = "Data source: CFB Program Data and US Cities Data") +
  theme_void(base_size = 18) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 28, family = "bebas", color = "white"),
    plot.caption = element_text(size = 14, face = "italic", hjust = 1, color = "white"),
    panel.grid.major = element_line(color = "grey80", linetype = "dotted"),
    panel.background = element_rect(fill = "#1c1c1c"),
    axis.text = element_blank(),
    axis.title = element_blank(),
    legend.position = "none",
    plot.background = element_rect(fill = "#1c1c1c"),
    text = element_text(color = "white")
  )
ggsave("day30_cfb.png", map, width = 20, height = 15, dpi = 300)  # High resolution for print quality
