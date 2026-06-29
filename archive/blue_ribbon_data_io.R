library(rvest)
library(dplyr)
library(httr)
library(sf)
library(ggplot2)
library(tidyverse)
library(rnaturalearth)
library(rnaturalearthdata)
library(showtext)
library(patchwork)
library(glue)

# Define base URL
base_url <- "https://nationalblueribbonschools.ed.gov/awardwinners/history"

# Make an initial request to the website
page <- read_html(base_url)

# Extract the table from the page
table_node <- page %>% html_node("#myTable")

# Parse the data into a dataframe
awards_df <- table_node %>%
  html_table(fill = TRUE)

# Clean Data -------------------------------------------------------------
blue_ribbon_schools <- awards_df %>%
  filter(!is.na(State)) %>%
  rename(
    state = State,
    district = District,
    city = City,
    school_name = School,
    type = Type,
    awards = `No. Awards`,
    award_year = `Award Year(s) / Application Link(s)`
  ) %>%
  mutate(
    latitude = runif(n(), min = 25, max = 49),  # Placeholder for latitudes
    longitude = runif(n(), min = -125, max = -66) # Placeholder for longitudes
  ) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Save Blue Ribbon Schools as Shapefile ----------------------------------
st_write(blue_ribbon_schools, "blue_ribbon_schools.shp", delete_layer = TRUE)

# Suggested Colors ------------------------------------------------------
blue <- "#0047AB"
white <- "#FFFFFF"

# Load Fonts -------------------------------------------------------------
font_add_google("Roboto", "roboto")
showtext_auto()

# Subset for GCPS Schools ------------------------------------------------
gcps_blue_ribbon <- blue_ribbon_schools %>%
  filter(district == "Gwinnett County Public Schools")

# Save GCPS Blue Ribbon Schools as Shapefile -----------------------------
st_write(gcps_blue_ribbon, "gcps_blue_ribbon_schools.shp", delete_layer = TRUE)

# U.S. State Boundaries --------------------------------------------------
us_states <- rnaturalearth::ne_states(country = "united states of america", returnclass = "sf") %>%
  st_transform(crs = st_crs(4326))  # Use WGS84 for consistency

# Save US State Boundaries as Shapefile ----------------------------------
st_write(us_states, "us_states_boundaries.shp", delete_layer = TRUE)

# GCPS Boundaries (placeholder, replace with actual shapefile) -----------
rea_spatial <- "S:/SPA/REA/_DataAnalytics/SpatialData/SY2023/"
rea_spatial2 <- "S:/SPA/REA/_DataAnalytics/SpatialData/School_Shapefiles/"

gcps_boundaries <- read_sf(glue('{rea_spatial}High_School_Clusters_SY2223.shp')) |>
  st_transform(crs = st_crs(4326))

# Save GCPS Boundaries as Shapefile --------------------------------------
st_write(gcps_boundaries, "gcps_boundaries.shp", delete_layer = TRUE)
