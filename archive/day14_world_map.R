################################################################################
## Project: day14_world_map
## Purpose:
## Created:
## Updated:
## Creator:
################################################################################

# Step-by-Step R Code for Mapping Global Education Data - Academic Year Start and End Months with ggplot2

# Load Required Libraries
# You'll need libraries for data manipulation, reading shapefiles, and mapping
library(tidyverse)        # For data manipulation and visualization
library(rnaturalearth)    # For getting world shapefiles easily
library(sf)               # Simple Features for working with geospatial data
library(ggplot2)          # For visualization
library(lubridate)        # For date manipulation
library(scales)           # For color scaling and custom palettes
library(gt)               # For creating tables
library(patchwork)        # For combining ggplot2 objects
library(showtext)         # For custom fonts in plots
# Load libraries
library(tidyverse)
library(sf)
library(tigris)
library(janitor)
library(ggplot2)
library(ggspatial)   # Adds spatial context elements like north arrows and scale bars
library(ggtext)      # Enhanced text formatting
library(rcartocolor) # Beautiful color palettes for cartography
library(cowplot)     # Enhanced plot annotation
library(ggnewscale)  # Adding new fill or color scales
library(patchwork)   # Combine multiple plots
library(showtext)    # Use Google Fonts for enhanced typography
library(scales)      # Provides functions for custom scales


# Add Google Fonts using showtext
font_add_google(name = "Oswald", family = "oswald")
showtext_auto()

# Step 1: Load a Global Education Dataset
# Load the dataset from UNESCO with country-level data on start and end months of the academic year
# (CSV file: 'NATMON_DS_14112024133836046.csv')
edu_data <- read_csv("NATMON_DS_14112024133836046.csv")

# The dataset should have columns like: "LOCATION" (ISO3 code), "Indicator", "Value" (Numeric Month), and "TIME".

# Step 2: Filter the Dataset
# Filter to keep only the indicators of interest and the latest year (2023)
edu_data_filtered <- edu_data %>%
  filter(
    Indicator %in% c(
      "End month of the academic school year (pre-primary to post-secondary non-tertiary education)",
      "Start month of the academic school year (pre-primary to post-secondary non-tertiary education)"
    ),
    TIME == 2023
  )

# Rename columns for clarity
edu_data_filtered <- edu_data_filtered %>%
  rename(country_iso3 = LOCATION, month_numeric = Value, indicator = Indicator)

# Step 3: Generate Month Label Variable Using lubridate
# Drop rows with NA values in month_numeric
edu_data_filtered <- edu_data_filtered %>%
  filter(!is.na(month_numeric)) %>%
  mutate(
    month_label = month(month_numeric, label = TRUE, abbr = FALSE),
    season_label = case_when(
      month_numeric %in% c(12, 1, 2) ~ "Winter",
      month_numeric %in% c(3, 4, 5) ~ "Spring",
      month_numeric %in% c(6, 7, 8) ~ "Summer",
      month_numeric %in% c(9, 10, 11) ~ "Fall"
    )
  )

# Step 4: Load World Map Data from 'rnaturalearth'
world <- ne_countries(scale = "medium", returnclass = "sf")

# Step 5: Join the Education Dataset with World Data
# Ensure both datasets have a common identifier, ideally ISO3 country codes
# We will join on "iso_a3" (in the world dataset) and "country_iso3" (in the education dataset)
world_edu <- world %>%
  left_join(edu_data_filtered, by = c("iso_a3" = "country_iso3"))

# Step 6: Create an Updated Color Palette
# Define a color palette based on the given color scheme
# - Cooler shades for winter months and warmer shades for summer months
updated_palette <- c(
  "January" = "#004c6d",  # Winter - Dark Blue
  "February" = "#466586", # Winter - Blue-Grey
  "March" = "#727f9d",    # Early Spring - Greyish Blue
  "April" = "#999bb4",    # Spring - Light Blue-Grey
  "May" = "#beb9cc",      # Late Spring - Soft Grey
  "June" = "#e0d9e4",     # Early Summer - Pale
  "July" = "#fffbff",     # Midsummer - Lightest Shade
  "August" = "#f6deef",   # Late Summer - Light Pink
  "September" = "#f1bfda", # Early Fall - Soft Pink
  "October" = "#eea0bf",  # Mid Fall - Pinkish Red
  "November" = "#e9809e", # Late Fall - Warm Pink
  "December" = "#e15f79"   # Winter Transition - Red-Pink
)

# Step 7: Create the Faceted Map Using ggplot2 with a Cool Projection
# Convert `month_label` to a factor to ensure it is treated as categorical
world_edu <- world_edu %>%
  mutate(month_label = factor(month_label, levels = names(updated_palette)))

# Use a different projection for a unique look (Mollweide projection)
base_layer <- ggplot(data = world) +
  geom_sf(fill = "grey90", color = "black", size = 0.2) +
  coord_sf(crs = "+proj=moll") + 
  theme_void()

# Use ggplot2 to create the choropleth map faceted by the start and end months of the academic year
p_facet <- base_layer +
  geom_sf(data = filter(world_edu, !is.na(month_label)), aes(fill = month_label), color = "black", size = 0.2) +
  scale_fill_manual(values = updated_palette, na.value = NA) +
  facet_wrap(~fct_rev(stringr::str_replace(indicator, '\\(', '\n(')), ncol = 1, strip.position = "top") +
  theme_minimal() +
  theme(
    legend.position = "none",
    text = element_text(family = "oswald", size = 14, face = "bold"),
    strip.text = element_text(size = 16, face = "bold"),
    plot.background = element_rect(fill = "#f0f0f0")
  )

# Step 8: Create a Summary Table Using ggplot2 and patchwork
# Calculate totals for start and end months
edu_summary <- edu_data_filtered %>%
  group_by(month_label, indicator) %>%
  summarise(total = n(), .groups = 'drop') %>%
  pivot_wider(names_from = indicator, values_from = total, values_fill = 0) %>%
  rename(`# Start` = `Start month of the academic school year (pre-primary to post-secondary non-tertiary education)`,
         `# End` = `End month of the academic school year (pre-primary to post-secondary non-tertiary education)`)

# Ensure the `indicator` column exists for faceting the summary table
edu_summary_long <- edu_summary %>%
  pivot_longer(cols = c(`# Start`, `# End`), names_to = "type", values_to = "count") %>%
  mutate(indicator = ifelse(type == "# Start", "Start Month",
                            "End Month"))

# Create a faceted summary table with ggplot2
legend_table <- ggplot(edu_summary_long, aes(y = fct_rev(month_label))) +
  geom_col(aes(x = count, fill = month_label), color = "black", position = position_dodge(width = 0.8)) +
  scale_fill_manual(values = updated_palette) +
  labs(title = "Academic Year Start and End Months Summary", x = "Count", y = "Month") +
  theme_minimal() +
  theme(
    axis.text.y = element_text(angle = 0, hjust = 1, family = "oswald", size = 12),
    legend.position = "none",
    plot.title = element_text(hjust = 0, size = 14, face = 'bold', family = "oswald")
  ) +
  facet_wrap(~fct_rev(indicator), nrow = 2) 
# Use patchwork to combine the map and the table
credits_text <- wrap_elements(
  ggplot() +
    theme_void() +
    geom_richtext(
      aes(x = 0, y = 0.2, label = 
            "<span style='font-size:9pt'><strong>#30DayMapChallenge 2024 Day 14: A world map</strong><br>
          <b>Tool:</b> R [ggplot2, patchwork] <br> <b>Created By:</b> Roland Richard<br>
        <span style='font-size:9pt; color:#333333;'><b>Data Source:</b> UNESCO Institute for Statistics (UIS) </span>"),
      family = "oswald", size = 1, hjust = 0.5, color = "#333333", fill = NA, label.color = NA
    )
)

p_combined <- (
  p_facet + inset_element(
    credits_text,
    left = 0.005,
    bottom = 0.42,
    right = 0.275,
    top = 0.52, 
    align_to = "full"
  ) | legend_table
) + plot_layout(widths = c(3, 1)) +
  plot_annotation(
    title = 'Global Start and End Months of Academic Year (2023)',
    subtitle = 'United Nations Educational, Scientific and Cultural Organization (UNESCO), 2023',
    theme = theme(plot.title = element_text(
      hjust = 0,
      size = 20,
      face = 'bold',
      family = "oswald"
    ))
  )

# Print the Combined Plot
print(p_combined)

# Save the Combined Plot as a Poster with Legible Text
output_file <- "day14_world_map.png"
ggsave(output_file, plot = p_combined, width = 30, height = 20, units = "in", dpi = 150)


# Notes:
# - The color palette has been updated to reflect a gradient from cooler to warmer colors, matching the seasonal transition.
# - The map projection has been changed to the Mollweide projection for a more visually striking presentation.
# - Font styles have been updated to use the 'Oswald' Google Font for an attention-grabbing appearance using showtext.
# - The map is faceted by the indicator variable to visualize both the start and end months in the same plot, with the start month displayed at the top facet.
# - The legend is replaced with a ggplot2 summary table summarizing start and end counts for each month, faceted similarly to the map, and appended to the right side of the map using patchwork.
