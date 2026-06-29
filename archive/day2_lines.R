################################################################################
## Project: day2_lines
## Purpose: 
## Created: 
## Updated: 
## Creator: 
################################################################################

library(tidyverse)
library(tidycensus)
library(tidygeocoder)
library(osmdata)
library(osrm)
library(glue)
library(here)
library(sf)
library(rio)
library(hexbin)
library(magick)
library(tmaptools)
library(patchwork)
library(cowplot)
library(extrafont)
library(extrafontdb)
library(ggtext)
library(tigris)
library(colorspace)
library(ggmap)
library(rmapshaper)
library(showtext)
library(RColorBrewer)

options(tigris_use_cache = TRUE)
options(scipen = 999, digits = 1)

loadfonts(device = "win")
font_add_google("Montserrat", "montserrat")
showtext_auto()

`%out%` = Negate(`%in%`)    

load(here("data", "gcps_absm_geo.RData"))

# Create color palette using Spectral palette from RColorBrewer
spectral_colors <- brewer.pal(8, "Spectral")

# Rounding Function
rnd <-  function(x, y) {
  round2 <- ifelse(x >= 0, round(x + 0.000000001, y), round(x - 0.000000001, y))
  return(round2)
}

# Load Spatial Data and set coordinates ------------------------------------------------------

es_absms_norm <- es_absms_norm |> st_transform(crs = 2240) |> st_set_crs(2240)
ms_absms_norm <- ms_absms_norm |> st_transform(crs = 2240) |> st_set_crs(2240)

# Simplify shape details for better rendering
gcps_outline <- st_as_sf(gcps_outline) |> ms_simplify(keep = 0.2) |> st_transform(crs = 2240)

ga_counties <- st_as_sf(counties(state = "13", cb = TRUE)) %>%
  ms_simplify(keep = 0.2) %>%
  st_transform(crs = 2240)

gwin <- ga_counties |> filter(NAME == "Gwinnett") |> st_transform(crs = 2240)

ga_outline <- st_as_sf(states(cb = TRUE)) %>%
  filter(STUSPS == "GA") %>%
  ms_simplify(keep = 0.2) %>%
  st_transform(crs = 2240)

sysBounds <- st_as_sf(sysBounds) |> st_transform(crs = 2240)

ga_inset <- ggplot() +
  geom_sf(data = gwin, fill = spectral_colors[2], color = spectral_colors[2], lwd = 0.75, alpha = 0.65) +
  geom_sf(data = ga_counties, fill = NA, color = '#FFFFFF', lwd = 0.25) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#2f2f2f", color = NA)
  )

# List Metro Atlanta counties
metro_5_co <- c('Fulton','DeKalb','Gwinnett','Cobb','Forsyth')
metro_fips <- c("13121","13089", "13135", "13067", "13117")

# School District FIPS codes
metro_districts <- c("1300120", "1300600", "1301290", "1301680", "1301740", "1302220", "1302550", "1303510", "1302280")

# Load Road Data
gwin_roads <- roads("GA", "135") |> st_transform(crs = 2240)
gwin_roads <- ms_simplify(gwin_roads, keep = 0.05)

gwin_interstates <- gwin_roads |> filter(RTTYP == "I")
gwin_roads_main <- gwin_roads |> filter(RTTYP == "M")
gwin_us_hwys <- gwin_roads |> filter(RTTYP == "U" & FULLNAME %out% c("US Hwy 29 Alt", "Old US Hwy 29 NW", "Old US Hwy 78 SW"))
gwin_st_hwys <- gwin_roads |> filter(RTTYP == "S")

# Highway Symbols
I_85 <- image_read("data/I-85.png")
I_985 <- image_read("data/I-985.png")
US_23 <- image_read("data/US_23.png")
US_29 <- image_read("data/US_29.png")
US_78 <- image_read("data/US_78.png")

metroSysBounds <- sysBounds |> filter(geoid %in% metro_districts)
metroCountyBounds <- ga_counties |> filter(NAME %in% metro_5_co)

buford <- sysBounds |> filter(sys_nms == "Buford City Schools") |> st_as_sf()
buford <- cbind(buford, st_coordinates(st_centroid(buford)))


# Create Main Map ---------------------------------------------------------------------------------
es_map <- ggplot() +
  geom_sf(data = hs_absms, fill = NA, color = spectral_colors[1], lwd = 0.65) +  # Dark Red
  geom_sf(data = gcps_outline, fill = NA, color = spectral_colors[3], size = 1.2) +  # Yellow
  geom_sf(data = gwin_roads, color = spectral_colors[4], size = 0.1, alpha = 0.3) +  # Green
  geom_sf(data = gwin_roads_main, color = spectral_colors[5], size = 0.6, alpha = 0.7) +  # Light Green
  geom_sf(data = gwin_us_hwys, color = spectral_colors[6], size = 1.5, alpha = 0.8) +  # Light Blue
  geom_sf(data = gwin_interstates, color = spectral_colors[7], size = 2.5, alpha = 0.9) +  # Dark Blue
  geom_sf(data = gwin_interstates |> slice(1, 2), color = spectral_colors[8], size = 0.9, linetype = "dashed") +  # Purple
  geom_sf(data = buford, fill = "#2f2f2f", color = "#2f2f2f", lwd = 0.65) +  # Orange
  coord_sf(crs = 2240, expand = TRUE) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#2f2f2f", color = NA),
    plot.title = element_text(size = 52, family = "bungee", face = "bold", colour = "#FFFFFF"),  # Updated to Bungee
    plot.subtitle = element_text(size = 44, family = "bungee", colour = "#FFFFFF")  # Updated to Bungee
  ) +
  labs(
    title = "Gwinnett County Road Network",
    subtitle = "Within the Gwinnett County Public School District Boundary"
  )

#30DayMapChallenge 2024 Day 2: Lines\nData Source: National Center for Education Statistics (NCES)\n\nCreated By: Roland Richard"

# Update Credits Section to Use the New Font
credits <- tibble(
  label = c(
  "<span style='font-size:10pt'><b>#30DayMapChallenge 2024 Day 2: Lines</b><br>
    <b>Tool:</b> R <span>&#124;</span> <b>Created By:</b> Roland Richard<br>
    <b>Data Sources:</b> GCPS Administrative Data;U.S. Census Bureau 2019 TIGER/Line Shapefiles</span>"
  )
) %>%
  ggplot() +
  geom_richtext(
    aes(x = 1, y = 0, label = label),
    colour = "#F0F0F0",
    hjust = 0,
    vjust = 0,
    fill = NA,
    label.color = NA,
    show.legend = FALSE
  ) +
  theme_void(base_family = "bungee") +
  theme(
    plot.background = element_rect(fill = "#2f2f2f", color = NA)
  )

# Combine Main Map, Inset, and Credits with Patchwork
es_absm_map <- (es_map + ga_inset + plot_layout(widths = c(3, 1))) / credits +
    plot_layout(heights = c(5, 1)) +
  plot_annotation(theme = theme(
    text = element_text(family = 'bungee'),
    plot.background = element_rect(fill = "#2f2f2f", color = NA)
  ))



# Save the Final Map
ggsave(
  plot = es_absm_map,
  filename = "day2_lines.png",
  type = "cairo",
  bg = "#2f2f2f",
  width = 17,
  height = 11,
  units = "in",
  dpi = 300
)
