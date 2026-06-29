################################################################################
## Project: day8_hdx
## Purpose: Visualize population data by gender in Haiti (Ages 5-19)
## Created: 
## Updated: 
## Creator: Roland Richard
################################################################################

# Load necessary libraries
library(raster)       # To work with raster data (such as GeoTIFF files)
library(sf)           # For handling spatial vector data
library(ggplot2)      # For visualization
library(tmap)         # For thematic mapping
library(dplyr)        # For data manipulation
library(rio)          # For importing Excel files
library(patchwork)    # For arranging multiple plots
library(janitor)      # For cleaning column names
library(ggrepel)      # For better annotation placement
library(showtext)     # For custom fonts
library(paletteer)

# Load custom font
font_add_google("Karla", "karla")
showtext_auto()

# Store Annotations as Tibble
annotations <- tibble(
commune = c("Port-au-Prince", "Cap-Haitien", "Grand-Boucan", "Gonaives", "Pointe a Raquette"),
note = c(
"Port-au-Prince: Highest concentration",
"Cap-Haitien: High coastal population",
"Grand-Boucan: Low population",
"Gonaives: Noticeable male-female disparity",
"Pointe a Raquette: Low female population"
)
)



# Load the CSV, GeoJSON, and Gazetteer data
haiti_population_data <- read.csv("day8_hdx/hti_admpop_adm2_2024.csv") %>%
  clean_names()

haiti_boundaries <- st_read("day8_hdx/hti_admbndl_admALL_cnigs_itos_20181129.shp") %>%
  clean_names()

haiti_gazetter <- import_list("day8_hdx/hti_admgz.xlsx", setclass = "data.frame")

# Extract each sheet from gazetteer as a separate data frame
gazetteer_data_frames <- lapply(names(haiti_gazetter), function(sheet) {
  assign(sheet, haiti_gazetter[[sheet]], envir = .GlobalEnv)
})

# Filter for Population Data by Gender (Ages 5-19)
haiti_total_population <- haiti_population_data %>%
  select(adm2_pcode, adm2_en, f_05_09, f_10_14, f_15_19, m_05_09, m_10_14, m_15_19) %>%
  mutate(
    female_population = f_05_09 + f_10_14 + f_15_19,
    male_population = m_05_09 + m_10_14 + m_15_19,
    total_population = female_population + male_population
  ) %>%
  select(adm2_pcode, adm2_en, total_population, female_population, male_population)

# Load the boundaries for visualization
haiti_communes <- st_read("day8_hdx/hti_admbnda_adm2_cnigs_20181129.shp") |> clean_names()
haiti_outline <- st_read("day8_hdx/hti_admbnda_adm0_cnigs_20181129.shp") |> clean_names()

# Join Population Data with Spatial Data
haiti_communes <- left_join(haiti_communes, haiti_total_population, by = join_by(adm2_pcode, adm2_en))

# Create Individual Maps Using ggplot2 with geom_sf
current_palette <- "scico::hawaii"

# Total Population Map
total_population_map <- ggplot(haiti_communes) +
  geom_sf(aes(fill = total_population), color = NA, lwd = 0.001) +
  geom_sf(data = haiti_outline, fill = NA, color = "#FFFFFF", lwd = 1) +
  scale_fill_paletteer_c(
    palette = current_palette,
    name = "Population (Ages 5-19)",
    guide = guide_colorbar(title.position = "top", barwidth = 15, barheight = 1)
  ) +
  labs(title = "Total Population") +
  theme_void() +
  theme(
    panel.background = element_rect(fill = "#121212", color = NA),
    plot.background = element_rect(fill = "#121212", color = NA),
    legend.background = element_rect(fill = "#121212"),
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5, size = 30, face = "bold", color = "#FFFFFF", family = "karla"),
    legend.text = element_text(size = 14, color = "#FFFFFF", family = "karla"),
    legend.title = element_text(size = 16, face = "bold", color = "#FFFFFF", family = "karla"),
    plot.margin = margin(20, 20, 20, 20)
  )

# Male Population Map
male_population_map <- ggplot(haiti_communes) +
  geom_sf(aes(fill = male_population), color = NA, lwd = 0.001, show.legend = F) +
  geom_sf(data = haiti_outline, fill = NA, color = "#FFFFFF", lwd = 1) +
  scale_fill_paletteer_c(
    palette = current_palette,
    name = "Male Population",
    guide = guide_colorbar(title.position = "top", barwidth = 15, barheight = 1)
  ) +
  labs(title = "Male Population") +
  theme_void() +
  theme(
    panel.background = element_rect(fill = "#121212", color = NA),
    plot.background = element_rect(fill = "#121212", color = NA),
    plot.title = element_text(hjust = 0.5, size = 30, face = "bold", color = "#FFFFFF", family = "karla"),
    plot.margin = margin(20, 20, 20, 20)
  )

# Female Population Map
female_population_map <- ggplot(haiti_communes) +
  geom_sf(aes(fill = female_population), color = NA, lwd = 0.001, show.legend = F) +
  geom_sf(data = haiti_outline, fill = NA, color = "#FFFFFF", lwd = 1) +
  scale_fill_paletteer_c(
    palette = current_palette,
    name = "Female Population",
    guide = guide_colorbar(title.position = "top", barwidth = 15, barheight = 1)
  ) +
  labs(title = "Female Population") +
  theme_void() +
  theme(
    panel.background = element_rect(fill = "#121212", color = NA),
    plot.background = element_rect(fill = "#121212", color = NA),
    plot.title = element_text(hjust = 0.5, size = 30, face = "bold", color = "#FFFFFF", family = "karla"),
    plot.margin = margin(20, 20, 20, 20)
  )

# Arrange Maps Using Patchwork
combined_map <- ((total_population_map) | (female_population_map / male_population_map)) +
  plot_layout(guides = 'collect') +
  plot_annotation(
    title = "Distribution of School-Age Population (Ages 5-19) in Haiti",
    subtitle = "Female, Male, and Total Population By Commune",
    theme = theme_void(), 
    caption = "#30DayMapChallenge 2024 Day 8: HDX\nTool: R | Created By: Roland Richard\nData Sources: Humanitarian Data Exchange (HDX)\nHDX HAPI Data for Haiti"
  ) & theme(
    panel.background = element_rect(fill = "#121212", color = NA),
    plot.background = element_rect(fill = "#121212", color = NA),
    plot.title = element_text(size = 34, face = "bold", color = "#FFFFFF", family = "karla"),
    plot.subtitle = element_text(size = 26, color = "#FFFFFF", family = "karla"),
    plot.caption = element_text(size = 12, color = "#FFFFFF", family = "karla", hjust = 0, vjust = -1),
    legend.position = 'bottom',
    legend.direction = "horizontal",
    legend.text = element_text(size = 14, color = "#FFFFFF", family = "karla"),
    legend.title = element_text(size = 16, face = "bold", color = "#FFFFFF", family = "karla"),
    plot.margin = margin(20, 20, 20, 20)
  )

# Display the Combined Map
print(combined_map)

# Save the Final Map
ggsave(combined_map,
       filename = "day8_hdx.png",
       type = "cairo",
       scale = 0.75,
       width = 18,
       height = 14,
       units = "in",
       dpi = 150)
