# This code is a starting template to create a map similar to the W.E.B. Du Bois 1890 "Negro Population of Georgia by Counties" map, using ggplot2.
# This version uses the tigris package to get school district and student population data.

# Load necessary libraries
library(ggplot2)
library(sf)  # for handling spatial data
library(dplyr)  # for data manipulation
library(showtext)  # for custom fonts
library(tigris)  # for accessing spatial data
library(tidyverse)  # for data wrangling and visualization
library(tidycensus)  # for accessing Census data
library(grid)  # for custom grobs

# Set up Census API key (replace 'YOUR_CENSUS_API_KEY' with your actual key)
# census_api_key("YOUR_CENSUS_API_KEY", install = TRUE, overwrite = TRUE)
readRenviron("~/.Renviron")

# Add Google fonts for custom title
font_add_google(name = "Bebas Neue", family = "bebas")
showtext_auto()

# Get Georgia school districts shapefile using tigris
options(tigris_use_cache = TRUE)
georgia_school_districts <- school_districts(state = "GA", year = 2020, class = "sf")

# Get Georgia counties shapefile using tigris for county outlines
georgia_counties <- counties(state = "GA", year = 2020, class = "sf")

# Load population data for Black student population in Georgia using tidycensus
# You will need to ensure the variable names match those available in the ACS dataset
data_black_students <- get_acs(geography = "school district (unified)", 
                               variables = "B02009_001",  # Black or African American population variable
                               state = "GA",
                               year = 2020, 
                               survey = "acs5", 
                               output = "wide")


lvls <- c(
  `1` = "Over 30,000",
  `2` = "Between 20,000 and 30,000",
  `3` = "15,000 to 20,000",
  `4` = "10,000 to 15,000",
  `5` = "5,000 to 10,000",
  `6` = "2,500 to 5,000",
  `7` = "1,000 to 2,500",
  `8` = "Under 1,000"
)



# Join the ACS data with the school district shapefile
population_data <- georgia_school_districts %>%
  left_join(data_black_students, by = c("GEOID" = "GEOID")) %>%
  mutate(
    black_student_population = B02009_001E,
    population_category = case_when(
      black_student_population > 30000 ~ "Over 30,000",
      black_student_population > 20000 ~ "Between 20,000 and 30,000",
      black_student_population > 15000 ~ "15,000 to 20,000",
      black_student_population > 10000 ~ "10,000 to 15,000",
      black_student_population > 5000 ~ "5,000 to 10,000",
      black_student_population > 2500 ~ "2,500 to 5,000",
      black_student_population > 1000 ~ "1,000 to 2,500",
      TRUE ~ "Under 1,000"
    )
  )


population_data <- population_data |> mutate(population_category = recode_factor(population_category,!!!lvls))

# Define custom color palette to match the color categories in the original Du Bois map
# Updated with web-safe hex values
dubois_colors <- c(
  "Over 30,000" = "#000000",        # black
  "Between 20,000 and 30,000" = "#00008B",  # dark blue
  "15,000 to 20,000" = "#4B3621",    # brown
  "10,000 to 15,000" = "#D2B48C",    # light brown
  "5,000 to 10,000" = "#FF0000",     # red
  "2,500 to 5,000" = "#FFC0CB",      # pink
  "1,000 to 2,500" = "#FFFF00",      # yellow
  "Under 1,000" = "#006400"          # dark green
)

# Create the ggplot map with a vintage background theme and Georgia county outlines
p <- ggplot() +
  geom_sf(data = population_data, aes(fill = population_category), color = "white", size = 0.0001) +
  geom_sf(data = georgia_counties, fill = NA, color = "#4B3621", size = 0.5) +  # adding county outlines in dark brown
  scale_fill_manual(values = dubois_colors, na.value = "#D3D3D3") +  # gray80 equivalent in hex
  labs(
    title = "BLACK STUDENT POPULATION OF GEORGIA BY SCHOOL DISTRICT\n2020",
    caption = "\n#30DayMapChallenge 2024 Day 7: Vintage\nData Source: National Center for Education Statistics (NCES)\nTool: R\nCreated By: Roland Richard", 
    fill = NULL  # Remove fill legend title to match original map aesthetics
    
  ) +
  guides(fill = guide_legend(ncol = 2, byrow = FALSE, override.aes = list(shape = 21)))+
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#F5DEB3", color = NA),  # wheat color for vintage look
    panel.background = element_rect(fill = "#F5DEB3", color = NA),
    plot.title = element_text(family = "bebas", hjust = 0.5, size = 60, face = "bold", color = "#332310"),  # darker brown color for title
    plot.caption = element_text(size = rel(1.2), family = "roboto", color = "#332310", hjust = 0),
    legend.position = "bottom",
    plot.margin = margin(t = 20, r = 40, b = 40, l = 40),
    legend.text = element_text(family = "bebas",size = 30, color = "#332310"),  # matching color for legend text
    legend.key.width = unit(1, "cm"),
    legend.box = "horizontal"
  ) 
# Print the map
print(p)


# Save the Final Map
ggsave(p,
       filename = "day7_vintage.png",
       type = "cairo",
       scale = 0.75,
       width = 14,
       height = 18,
       units = "in",
       dpi = 150)
