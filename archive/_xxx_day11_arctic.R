# Load required libraries
library(tidycensus)
library(tigris)
library(ggplot2)
library(dplyr)
library(sf)
library(showtext)
library(ggspatial)
library(rosm)
library(patchwork)

# Set up census API key
# census_api_key("YOUR_CENSUS_API_KEY", install = TRUE)

# Add fonts that have a Game of Thrones look using showtext
font_add_google("Cinzel", "cinzel")
font_add_google("MedievalSharp", "medieval")
showtext_auto()

# Set the appropriate CRS for Alaska (Albers Equal Area projection for Alaska)
alaska_crs <- 3338

# Get Alaska's school districts using the tigris package
alaska_school_districts <- school_districts(state = "AK", class = "sf")

# Filter for North Slope Borough School District
north_slope <- alaska_school_districts %>%
  filter(NAME == "North Slope Borough School District")

# Transform projection to Albers Equal Area for Alaska to correct projection issues
alaska_school_districts <- st_transform(alaska_school_districts, crs = alaska_crs)
north_slope <- st_transform(north_slope, crs = alaska_crs)

# Define Arctic Circle latitude
arctic_circle_lat <- 66.5622

# Create a column to identify areas north and south of the Arctic Circle
alaska_school_districts <- alaska_school_districts %>%
  mutate(region = ifelse(st_coordinates(st_centroid(geometry))[,2] > arctic_circle_lat, "North", "South"))

# Create a data frame with school information
schools <- data.frame(
  name = c("Alak School", "Barrow High School", "Eben Hopson Middle School", "Fred Ipalook Elementary",
           "Harold Kaveolook School", "Kali School", "Kiita Learning Community", "Meade River School",
           "Nuiqsut Trapper School", "Nunamiut School", "Tikigaq School"),
  address = c("1001 W 2nd Ave", "1965 Takpuk St", "6501 North Star St", "5241 Karluk St",
              "1000 1st St", "1000 Qasigialik St", "7300 Dewline Rd", "1000 Uqpiq St",
              "2230 2nd Ave", "114 Lakeview Dr", "1000 Tikigaq St"),
  city = c("Wainwright", "Utqiaġvik", "Utqiaġvik", "Utqiaġvik",
           "Kaktovik", "Point Lay", "Utqiaġvik", "Atqasuk",
           "Nuiqsut", "Anaktuvuk", "Point Hope"),
  latitude = c(70.6369, 71.2906, 71.2906, 71.2906,
               70.1322, 69.7372, 71.2906, 70.4692,
               70.2175, 68.1433, 68.3475),
  longitude = c(-160.0383, -156.7886, -156.7886, -156.7886,
                -143.6100, -163.0056, -156.7886, -157.3958,
                -151.0056, -151.7350, -166.8083)
)

# Convert to an sf object
schools_sf <- st_as_sf(schools, coords = c("longitude", "latitude"), crs = 4326)

# Transform to match the map's CRS
schools_sf <- st_transform(schools_sf, crs = alaska_crs)

# Load the 10 largest school districts by enrollment using tigris
largest_districts_info <- data.frame(
  district_name = c("Broward County School District", "Clark County School District", "Houston Independent School District", 
                    "Hillsborough County Public Schools", "Orange County Public Schools", "Palm Beach County School District", 
                    "Los Angeles Unified School District", "Hawaii Department of Education", "Chicago Public Schools", 
                    "Miami-Dade County Public Schools"),
  state = c("FL", "NV", "TX", "FL", "FL", "FL", "CA", "HI", "IL", "FL")
)

# Use tigris to get shapefiles for these school districts
largest_districts_sf_list <- list()

for (i in 1:nrow(largest_districts_info)) {
  district_sf <- school_districts(state = largest_districts_info$state[i], class = "sf") %>%
    filter(grepl(largest_districts_info$district_name[i], NAME, ignore.case = TRUE)) %>%
    st_transform(crs = alaska_crs)
  largest_districts_sf_list[[i]] <- district_sf
}

# Combine the largest districts into a single sf object
largest_districts_sf <- do.call(rbind, largest_districts_sf_list)

# Plot the main map using ggplot2 with corrected projection
gg_main <- ggplot() +
  annotation_map_tile(type = "cartolight", zoom = 6) +  # Add a terrain baselayer with grey/white theme using OpenStreetMap data
  geom_sf(data = alaska_school_districts %>% filter(region == "North"), fill = "white", color = "grey90", size = 0.2) +  # Areas north of the Arctic Circle in white
  geom_sf(data = alaska_school_districts %>% filter(region == "South"), fill = "#d0e6f2", color = "grey90", size = 0.2) +  # Areas south of the Arctic Circle in grey-blue
  geom_sf(data = north_slope, fill = "#A0D6E8", color = "black", size = 0.5) +  # North Slope Borough in arctic blue
  geom_sf(data = schools_sf, color = "#003366", size = 3) +  # Plot schools as darker blue points to fit the "North...beyond the wall" theme
  annotate("text", x = -1800000, y = 3000000, label = "North", size = 6, color = "black", fontface = "bold", family = "cinzel") +  # Annotate 'North' on the map with Game of Thrones style font
  theme_bw() +
  labs(title = "North Slope Borough School District in Alaska",
       subtitle = "Largest School District in the United States by Land Area",
       caption = "Data Source: Tigris & tidycensus, Wikipedia") +
  theme(
    plot.title = element_text(size = 16, face = "bold", family = "cinzel"),
    plot.subtitle = element_text(size = 12, family = "medieval"),
    plot.caption = element_text(size = 10, family = "medieval"),
    axis.text = element_text(size = 10, family = "medieval"),
    axis.title = element_text(size = 12, family = "medieval"),
    panel.grid.major = element_line(color = "grey80", linetype = "dotted")
  )

# Create an artistic inset map for North Slope with the 10 largest districts styled within it
# Instead of geographic accuracy, arrange the 10 largest districts artistically within the North Slope boundary
gg_inset <- ggplot() +
  geom_sf(data = north_slope, fill = "#A0D6E8", color = "black", size = 0.5) +  # North Slope Borough in arctic blue
  geom_sf(data = largest_districts_sf, aes(geometry = st_geometry(largest_districts_sf)), fill = "#666699", color = "black", alpha = 0.7, size = 0.3, position = "identity") +  # Arrange 10 largest districts artistically within North Slope boundary
  theme_void() +
  labs(title = "Inset: North Slope with Top 10 US Districts by Enrollment (Artistic Representation)") +
  theme(
    plot.title = element_text(size = 10, face = "bold", family = "cinzel")
  )

# Combine main map and inset map using patchwork
combined_plot <- gg_main + inset_element(gg_inset, left = 0.6, bottom = 0.6, right = 0.98, top = 0.98, align_to = "full")

# Print combined plot
print(combined_plot)

# # Save spatial features as GeoPackage files for use in ArcGIS Pro
# st_write(alaska_school_districts, "alaska_school_districts.gpkg", delete_layer = TRUE)
# st_write(north_slope, "north_slope.gpkg", delete_layer = TRUE)
# st_write(schools_sf, "schools_sf.gpkg", delete_layer = TRUE)

