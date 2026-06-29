################################################################################
## Project: day26_projections
## Purpose: 
## Created: 
## Updated: 
## Creator: 
################################################################################

library(sf)
library(ggplot2)
library(patchwork)
library(ggtext)        # To allow for rich text formatting in ggplot
library(grid)               # For adding labels and decorative elements
library(showtext)      # To use Google Fonts and other fonts in ggplot
library(paletteer)     # For the color palette
library(dplyr)         # For data manipulation

# Add custom fonts
font_add_google("Uncial Antiqua", "uncial")   # Example: Add a cartography-themed font
font_add_google("Cormorant SC", "cormorant")  # Another elegant font for cartography
showtext_auto()

# Load your spatial data
us_data <- us_states

# Assign colors by more granular regions (custom grouping)
region_mapping <- data.frame(
  state = c("Maine", "New Hampshire", "Vermont", "Massachusetts", "Rhode Island", "Connecticut", 
            "New York", "New Jersey", "Pennsylvania", "Delaware", "Maryland", "West Virginia", 
            "Virginia", "Kentucky", "North Carolina", "South Carolina", "Tennessee", "Georgia", 
            "Florida", "Alabama", "Mississippi", "Arkansas", "Louisiana", "Texas", "Oklahoma", 
            "Missouri", "Kansas", "Nebraska", "South Dakota", "North Dakota", "Minnesota", 
            "Iowa", "Wisconsin", "Illinois", "Indiana", "Michigan", "Ohio", "Washington", 
            "Oregon", "Idaho", "Montana", "Wyoming", "Nevada", "Utah", "Colorado", "New Mexico", 
            "Arizona", "California", "Hawaii", "Alaska"),
  region = c("New England", "New England", "New England", "New England", "New England", "New England", 
             "Mid-Atlantic", "Mid-Atlantic", "Mid-Atlantic", "Mid-Atlantic", "Mid-Atlantic", "Appalachia", 
             "South Atlantic", "Appalachia", "South Atlantic", "South Atlantic", "Appalachia", "South Atlantic", 
             "South Atlantic", "Deep South", "Deep South", "Deep South", "Deep South", "Southwest", "Southwest", 
             "Midwest", "Midwest", "Midwest", "Great Plains", "Great Plains", "Midwest", 
             "Midwest", "Midwest", "Midwest", "Midwest", "Midwest", "Midwest", "Pacific Northwest", 
             "Pacific Northwest", "Mountain West", "Mountain West", "Mountain West", "Mountain West", "Mountain West", "Mountain West", 
             "Mountain West", "Pacific", "Pacific", "Pacific", "Pacific")
)

# Join region mapping to spatial data
us_data <- us_data %>%
  left_join(region_mapping, by = c("NAME" = "state")) %>%
  mutate(color_group = factor(region))

# Assign colors by region
region_colors <- paletteer_d(rev("ggsci::planetexpress_futurama"), n = length(unique(us_data$region)))  # Use distinct colors for regions

# List of CRS codes for different projections
crs_list <- c('EPSG:5070', 'EPSG:4326', 'EPSG:3857', 'ESRI:54009', 'ESRI:54030', 'ESRI:54024', 'ESRI:54052', 'EPSG:32633', 'EPSG:3031', 'ESRI:54008', 'ESRI:54012')

# Create an empty plot list
plot_list <- list()

# Generate plots for each projection and add to the list
for (i in seq_along(crs_list)) {
  crs_code <- crs_list[i]
  projected_data <- st_transform(us_data, crs = as.character(crs_code))
  plot_list[[i]] <- ggplot() +
    geom_sf(data = projected_data, aes(fill = color_group), color = "white", size = 0.2) +
    scale_fill_manual(values = region_colors) +  # Using a palette with enough colors for regions
    ggtitle(paste(switch(crs_code, 
                         'EPSG:5070' = 'Albers Equal Area Conic', 
                         'EPSG:4326' = 'WGS84', 
                         'EPSG:3857' = 'Pseudo-Mercator', 
                         'ESRI:54009' = 'Mollweide', 
                         'ESRI:54030' = 'Robinson', 
                         'ESRI:54024' = 'Bonne', 
                         'ESRI:54052' = "Goode's Homolosine", 
                         'EPSG:32633' = 'Transverse Mercator', 
                         'EPSG:3031' = 'Stereographic', 
                         'ESRI:54008' = 'Sinusoidal', 
                         'ESRI:54012' = 'Eckert IV'))) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 54, face = "bold", family = "uncial", color = "#D1E8E2"),
      plot.background = element_rect(fill = "#2C3E50", color = NA),
      panel.background = element_rect(fill = "#2C3E50"),
      legend.position = "none",
      axis.text = element_blank(),
      axis.ticks = element_blank(),
      axis.title = element_blank()
    )
}

# Combine all plots using patchwork
combined_plot <- wrap_plots(plot_list) +
  plot_layout(ncol = 3) +
  plot_annotation(
    title = "Different Projections of the Continental US",
    subtitle = "#30DayMapChallenge - Day 26: Projections",
    theme = theme(
      plot.title = element_text(
        size = 80,
        face = "bold",
        family = "cormorant",
        color = "#EAECEE"),
      plot.subtitle = element_text(
        size = 72,
        family = "cormorant",
        color = "#D6DBDF"      ),
      plot.background = element_rect(fill = "#2C3E50", color = NA)
    )
  )

# Print the combined plot
print(combined_plot)

# To save the glossy and beautiful map for printing
ggsave("day26_projections.png", combined_plot, width = 20, height = 15, dpi = 300) # High resolution for print quality
