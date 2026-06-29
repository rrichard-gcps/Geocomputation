################################################################################
## Project: Black Student Population in School Districts
## Purpose: Replicating WEB DuBois' style map with Black student population data
## Created: 
## Updated: 
## Creator: Roland Richard
################################################################################

# Load necessary packages
library(tidycensus)
library(dplyr)
library(sf)
library(tidyverse)
library(glue)
library(here)
library(rio)
library(ggmap)
library(hexbin)
library(tmap)
library(tmaptools)
library(patchwork)
library(extrafont)
library(extrafontdb)
library(ggtext)
library(tigris)
library(colorspace)
library(janitor)
library(showtext)

# Set up options
tidyverse_use_cache = TRUE
options(scipen = 999, digits = 1)
loadfonts(device = "win")
font_add_google("Montserrat", "montserrat")
showtext_auto()

# Load Census API key
# census_api_key("your_census_api_key_here")

# Pull Black Student Population Data by School District
black_student_population <- get_acs(geography = "school district (unified)",
                                    variables = "B02009_001",  # Black or African American alone
                                    year = 2021,
                                    state = "GA")

# Load Georgia school district boundaries
ga_school_districts <- school_districts(state = "GA", type = "unified", cb = TRUE)

# Merge Black student population data with Georgia school district boundaries
merged_data <- left_join(ga_school_districts, black_student_population, by = "GEOID") %>%
  rename(black_student_population = estimate)

# Create a Vintage-style Map similar to WEB DuBois
font_add_google("Cinzel Decorative", "cinzel") # Suggested vintage-style font
showtext_auto()

vintage_map <- ggplot() +
  geom_sf(data = merged_data, aes(fill = black_student_population), color = "#2C3E50", size = 0.4) +
  scale_fill_gradient(low = "#FFD700", high = "#8B0000", name = "Black Student Population") +
  coord_sf() +
  theme_void(base_family = "cinzel") +
  theme(
    plot.title = element_text(size = 28, face = "bold", color = "#4B0082"),
    plot.subtitle = element_text(size = 18, color = "#8B0000"),
    plot.caption = element_text(size = 10, color = "#4B0082"),
    legend.position = "bottom",
    legend.title = element_text(size = 14, face = "bold", color = "#4B0082"),
    legend.text = element_text(size = 12, color = "#4B0082")
  ) +
  labs(
    title = "Black Student Enrollment in Georgia School Districts",
    subtitle = "Based on 2021 American Community Survey Data",
    caption = "Data Sources: U.S. Census Bureau, NCES"
  )

# Display the vintage-style map
vintage_map

# Save the map
ggsave(vintage_map,
       filename = "day7_vintage_black_student_population.png",
       type = "cairo",
       width = 15,
       height = 12,
       units = "in",
       dpi = 300)
