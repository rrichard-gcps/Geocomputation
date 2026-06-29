################################################################################
## Project: day12_time_space
## Purpose:
## Created:
## Updated:
## Creator:
################################################################################

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

# Load Google Fonts for styling
showtext_auto()
showtext_opts(dpi = 300)
font_add_google("Bebas Neue", "bebas_neue")     # Bold, similar to album cover font
font_add_google("Playfair Display", "playfair_display") # Classy serif font for subtitle
font_add_google("Open Sans", "open_sans")       # Clean, sans-serif for general text

# Load Data ---------------------------------------------------------------

# Load Georgia school districts geometry
options(tigris_use_cache = TRUE)
crs_value <- 4269  # Define CRS value as a parameter for flexibility
ga_school_districts <- school_districts(state = "GA", class = "sf") %>% 
  clean_names() %>%
  st_transform(crs = crs_value) %>%  # Set the CRS to NAD83 (EPSG: 4269)
  mutate(nces_district_id  = sprintf("%07i", as.integer(geoid)))  # Assuming geoid is the matching key

ga_sys_nces <- read_csv("ga_systems_nces.csv") |> clean_names()

ga_dc <- read_csv('downloads/georgia_direct_cert_system.csv') |> clean_names() |> 
  mutate(
    system_id = sprintf("%03i", as.integer(system_id)),
    school_year = case_when(is.na(fiscal_year) ~ 2014, TRUE ~ fiscal_year)
  ) |> 
  select(-fiscal_year)

ga_sys_nces <- ga_sys_nces |> mutate(system_id = str_trim(str_remove(state_district_id, pattern = "GA-"), side = 'both'))

df_ga_dc <- left_join(ga_dc, ga_sys_nces, by = "system_id")
df_ga_dc <- df_ga_dc |> select(
  -c(
    "zip_4_digit",
    "phone",
    "students",
    "teachers",
    "schools",
    "student_teacher_ratio",
    "type"
  )
)

# Extracting metro district IDs for better readability and maintainability
metro_district_ids <- c(
  "1300120", "1300290", "1300510", "1300840", "1300870", "1300900", "1301110", "1301230",
  "1301290", "1301500", "1301680", "1301740", "1301860", "1302130", "1302220", "1302280",
  "1302310", "1302550", "1302610", "1302820", "1303510", "1303930", "1304020", "1304410",
  "1302520", "1305390", "1300330", "1300600", "1304540"
)

df_metro_dc <- df_ga_dc |>
  filter(nces_district_id %in% metro_district_ids) |> 
  mutate(nces_district_id = sprintf("%07i", as.integer(nces_district_id)))

# Join the shapefile with direct certification data and ensure valid geometry
metro_dc_geo <- df_metro_dc %>% 
  left_join(ga_school_districts, by = "nces_district_id") %>% 
  filter(!is.na(geometry)) %>% 
  st_as_sf()

# Check and filter for data consistency
metro_dc_geo <- metro_dc_geo %>%
  filter(!is.na(direct_cert_perc))

# Custom color scale based on album color scheme (Reversed Green tones for 7 breaks, darker for higher values)
custom_palette <- c("#EDF1EC", "#CED9CA", "#A9B89F", "#7A8F79", "#4A6A5B", "#355B45", "#1F3D2B")

# Define breaks and labels to align across facets, grouped by school year
breaks <- c(5.0, 19.9, 27.5, 38.3, 46.9, 55.4, 62.4, 100)

labels <- c(
  "5.0-19.9",
  "19.9-27.5",
  "27.5-38.3",
  "38.3-46.9",
  "46.9-55.4",
  "55.4-62.4",
  "62.4-76.4"
)

# Add class breaks and fill color columns to the dataframe
metro_dc_geo <- metro_dc_geo %>%
  mutate(
    class_break = cut(
      direct_cert_perc,
      breaks = breaks,
      include.lowest = TRUE,
      labels = labels
    ),
    fill_color = custom_palette[as.numeric(class_break)]
  )

# Plot map of direct certification rates faceted by school year (no redundant labels)
main_map <- ggplot(metro_dc_geo) +
  geom_sf(aes(geometry = geometry, fill = class_break),
          color = "black", size = 0.5) +
  scale_fill_manual(
    name = "% Direct Cert:",
    values = custom_palette,
    labels = labels
  ) + 
  guides(fill = guide_legend(nrow = 1, byrow = TRUE, label.position = "bottom", title.position = "left", title.hjust = 0.5)) +
  labs(
    title = "<span style='font-family:bebas_neue; font-size:26pt;'>Direct Certification Rates by Metro Atlanta School District </span>",
    subtitle = "<span style='font-family:playfair_display; font-size:20pt;'>School Years 2014-2024</span>",
    caption = ""
  ) +
  theme_minimal(base_family = "open_sans") +
  theme(
    plot.title = element_markdown(hjust = 0, face = "bold", color = "black"),
    plot.subtitle = element_markdown(hjust = 0, color = "#1F3D2B"),
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 20, face = "bold", color = "#1F3D2B", family = "playfair_display"),
    panel.background = element_rect(fill = "grey90", color = NA),
    plot.background = element_rect(fill = "grey97", color = NA),
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(size = 24, family = "playfair_display", face = "bold", colour = "#333333"),
    legend.text = element_text(size = 20, family = "playfair_display", colour = "#333333"),
    legend.spacing.x = unit(0.5, 'cm'),
    legend.box = "horizontal"
  ) +
  coord_sf(crs = 4326, clip = "on") +
  facet_wrap(~ school_year)

# # Create unified north arrow and scale bar for entire set of maps
# annotations <- ggplot() +
#   theme_void() +
#   coord_sf(crs = 4326) +
#   annotation_scale(location = "bl", width_hint = 0.5, text_col = "black", line_col = "black", pad_x = unit(2, "cm"), pad_y = unit(2, "cm")) +
#   annotation_north_arrow(location = "tl", which_north = "true", style = north_arrow_minimal(), pad_x = unit(2, "cm"), pad_y = unit(2, "cm"))

# Create map credits using ggtext and patchwork (styled as an inset in the right margin, taking up minimal space, allowing for HTML/Markdown styling, and left justified)
credits_text <- wrap_elements(
  ggplot() +
    theme_void() +
    geom_richtext(
      aes(x = 0, y = 0.2, label = 
            "<span style='font-size:10pt'><strong>#30DayMapChallenge 2024 Day 12: Time & Space</strong><br>
          <b>Tool:</b> R [ggplot2, patchwork] <br> <b>Created By:</b> Roland Richard<br>
        <span style='font-size:10pt; color:#7B7D7D;'><b>Data Sources:<br>
      </b> GA Governor’s Office of Student Achievement (GOSA)<br>
      U.S. Census Bureau 2022 TIGER/Line Shapefiles</span>"),
      family = "open_sans", size = 3, hjust = 0.5, color = "#EDF1EC", fill = NA, label.color = NA
    ) +
    theme(
      panel.background = element_rect(fill = "#1F3D2B", color = "black", linewidth = 1, linetype = "solid"),
      plot.background = element_rect(fill = NA, color = NA)
    )
) %>% 
  inset_element(left = 0.8, bottom = -0.1875, right = 1.0, top = -0.1, on_top = TRUE)  # Move the credits down slightly and left justify

# Combine main map, annotations, and credits using patchwork for better positioning
final_plot <- (main_map) / credits_text +
  plot_layout(heights = c(10, 1))

final_plot

# Save the plot as a high-resolution poster
ggsave(
  filename = "day12_time_space.png",
  plot = final_plot,
  width = 22,       # Poster size width in inches
  height = 17,      # Poster size height in inches
  dpi = 300,        # High resolution for printing
  units = "in",    # Units in inches
  limitsize = FALSE # Allow saving large images
)
