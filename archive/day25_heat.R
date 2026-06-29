# Load necessary libraries
# install.packages(c("tidyverse", "sf", "ggplot2", "tigris", "RColorBrewer", "classInt", "scales", "paletti", "patchwork"))
library(tidyverse)
library(ggplot2)
library(sf)
library(tigris)  # To get school district shapefiles
library(janitor)
library(RColorBrewer)  # For better color schemes
library(classInt)  # For natural breaks classification
library(scales)  # For better legend formatting
library(paletteer)  # For customizable color palettes
library(patchwork)  # For combining plots

# Load Enrollment Data
enrollment_data <- read_csv("downloads/georgia_enrollment_data_by_grade_level_combined.csv") |> clean_names() 

# Load Georgia school districts geometry
options(tigris_use_cache = TRUE)
crs_value <- 4269  # Define CRS value as a parameter for flexibility
ga_school_districts <- school_districts(state = "GA", class = "sf")|> 
  clean_names()|>
  st_transform(crs = crs_value)|>  # Set the CRS to NAD83 (EPSG: 4269)
  mutate(nces_district_id  = sprintf("%07i", as.integer(geoid)))  # Assuming geoid is the matching key

ga_sys_nces <- read_csv("ga_systems_nces.csv") |> clean_names() 

ga_sys_nces <- ga_sys_nces |> mutate(nces_district_id = as.character(nces_district_id))

school_districts <- left_join(ga_school_districts,ga_sys_nces, by = join_by(geoid == nces_district_id ))
school_districts <- school_districts |> mutate(system_id = str_trim(str_remove(state_district_id, "GA-"),side = "both"))

# Prepare and Standardize District Names for Joining
enrollment_summary_1 <- enrollment_data  |>
  mutate(system_id = sprintf("%03i", as.integer(school_dstrct_cd))) |>
  filter(detail_lvl_desc == "District" & enrollment_period == "Fall") |> 
  select(-c(number_rpt_name, detail_lvl_desc, instn_number, instn_name, grades_served_desc, grade_level)) |> 
  group_by(system_id, long_school_year) |> 
  summarise(enr_n = sum(as.double(enrollment_count), na.rm = TRUE), .groups = 'drop')

enrollment_summary_2 <- enrollment_data  |>
  mutate(system_id = sprintf("%03i", as.integer(school_dstrct_cd))) |>
  filter(detail_lvl_desc == "District") |> 
  select(-c(number_rpt_name, detail_lvl_desc, instn_number, instn_name, grades_served_desc, grade_level)) |> 
  group_by(system_id, long_school_year, enrollment_period) |> 
  summarise(enr_n = sum(as.double(enrollment_count), na.rm = TRUE), .groups = 'drop')

# Join Enrollment Data with School District Shapefile
merged_data <- school_districts |>
  right_join(enrollment_summary_1, by = join_by(system_id))

merged_data_2 <- school_districts |>
  right_join(enrollment_summary_2, by = join_by(system_id))

# Prepare a set of ggplot2 maps faceted by School Year
# Define manual breaks for better legend readability
breaks <- c(10000, 20000, 30000, 40000, 50000, 100000, 150000, max(merged_data$enr_n, na.rm = TRUE))

# Load necessary library for fonts
# install.packages("showtext")
library(showtext)

# Add Google fonts (e.g., Anton or Roboto Condensed)
font_add_google("Anton", "anton")
font_add_google("Roboto Condensed", "roboto_condensed")

# Automatically use showtext for all plots
showtext_auto()

# Update the dark_theme to use the new font
dark_theme <- theme_minimal() +
  theme(
    panel.background = element_rect(fill = "#2b2b2b", color = NA),
    plot.background = element_rect(fill = "#2b2b2b", color = NA),
    plot.title = element_text(family = 'anton',size = 48, face = 'bold'), 
    plot.subtitle = element_text(family = 'anton', size = 40,face = 'plain'),
    plot.caption = element_text(size = 18, lineheight = 0.8),
    panel.grid = element_blank(),  # Remove gridlines
    text = element_text(family = "anton", color = "#FFFFFF"),  # Use "Anton" font as an example
    strip.text = element_text(size = 32, family = "anton", color = "#FFFFFF", face = "bold", hjust = 0),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    legend.position = "bottom",
    legend.background = element_rect(fill = "#2b2b2b", color = NA),
    legend.text = element_text(family = "roboto_condensed", color = "#FFFFFF", size = 24),
    legend.title = element_text(family = "roboto_condensed", color = "#FFFFFF", size = 28),
    legend.key.width = unit(3, "cm"),  # Widen the legend to prevent compression
    legend.spacing.x = unit(1, 'cm')  # Add more spacing between legend items for better readability
  )

# Use paletti to create a custom color palette
palette <-paletteer_d("dichromat::BluetoDarkOrange_18", n = 18)

# Create the main plot using the custom color palette from paletti
main_plot <- ggplot(data = merged_data) +
  geom_sf(aes(fill = enr_n), color = NA) +
  scale_fill_gradientn(
    colors = palette,
    name = "Enrollment Count",
    breaks = breaks,
    na.value = "grey30",
    guide = guide_colorbar(
      title.position = "top",
      title.hjust = 0.5,
      barwidth = unit(20, "cm"),  # Increase bar width for better spacing and readability
      barheight = unit(0.6, "cm"),  # Adjust bar height for improved legend readability
      label.theme = element_text(color = "#FFFFFF")  # Set legend label color for visibility on dark background
    )
  )  +
  dark_theme +
  facet_wrap( ~ long_school_year, ncol = 5) +
  labs(title = "Enrollment Change Across Georgia School Districts by Year",
       subtitle = "Total District Enrollment - Fall Enrollment Period",
       caption = "#30DayMapChallenge 2024 Day 3: Polygons\nTool: R | Created By: Roland Richard\nData Sources: GA Governor’s Office of Student Achievement (GOSA)\nU.S. Census Bureau 2022 TIGER/Line Shapefiles")


print(main_plot)

gc(full= TRUE)


# Save the Final Map
ggsave(main_plot,
       filename = "day25_heat.png",
       type = "cairo",
       scale = 0.75,
       width = 14,
       height = 12,
       units = "in",
       dpi = 300)

