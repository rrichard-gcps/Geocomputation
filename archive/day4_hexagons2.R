################################################################################
## Project: day4_hexagons
## Purpose: 
## Created: 
## Updated: 
## Creator: 
################################################################################

library(tidyverse)
library(tidycensus)
library(glue)
library(here)
library(sf)
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
library(showtext)

font_add_google("Lobster", "lobster")
showtext_auto()

options(tigris_use_cache = TRUE)

loadfonts(device = "win")


# load US abbreviation
state_codes <- unique(fips_codes$state)[c(1:51)]
cont_us <- state_codes[-c(2,12)]
state_fips <- unique(fips_codes$state_code)[c(1:51)]
cont_us_fips <- state_fips[-c(2,12)]

# Locale Descriptions
locale_cd <- c(
  `11` = "City-Large",
  `12` = "City-Midsize",
  `13` = "City-Small",
  `21` = "Suburban-Large",
  `22` = "Suburban-Midsize",
  `23` = "Suburban-Small",
  `31` = "Town-Fringe",
  `32` = "Town-Distant",
  `33` = "Town-Remote",
  `41` = "Rural-Fringe",
  `42` = "Rural-Distant",
  `43` = "Rural-Remote"
)

# Albers Equal Area Conic Projection
albers_proj <-
  "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"


# create state boundaries
us_outline <- st_as_sf(states(cb = TRUE)) %>%
  filter(STUSPS %in% cont_us) %>%
  simplify_shape(0.2)

us_outline <-   st_as_sf(x = us_outline)

# Load NCES Locale Data ---------------------------------------------------

f <- glue(here("data", "EDGE_Locale21_US"))


if (dir.exists(f) == FALSE) {
  temp <- download.file(
    "https://nces.ed.gov/programs/edge/data/EDGE_Locale21_US.zip",
    destfile = here('data', 'temp.zip') ,
    method = "libcurl",
    mode = 'wb'
  )
  nces_loc21 <-
    unzip(zipfile = here('data', 'temp.zip'),
          exdir = here('data'))
  file.remove(here('data', 'temp.zip'))
  
} else {
  nces_loc21 <- read_sf(glue("{f}/edge_locale21_nces_all_us.shp"))
  nces_loc21 <- nces_loc21 %>% select_all(tolower)
}


df_locale <- nces_loc21 %>%
  filter(statefp %in% cont_us_fips) %>%
  mutate(locale_desc = recode_factor(locale, !!!locale_cd),
         locale_num = as.integer(locale))

# Ensure the validity of df_locale after st_make_valid and st_simplify
df_locale <- st_make_valid(df_locale)
df_locale <- st_simplify(df_locale, dTolerance = 0.01)
if (any(!st_is_valid(df_locale))) {
  df_locale <- st_make_valid(df_locale)
}


us_hex <- us_outline  %>%
  st_make_grid(what = "polygons", square = FALSE,n = c(300,300)) %>%
  st_sf() %>%
  mutate(id_hex = 1:n()) %>%
  dplyr::select(id_hex, geometry)

# Repeat for us_hex
us_hex <- st_simplify(us_hex, dTolerance = 0.01)
if (any(!st_is_valid(us_hex))) {
  us_hex <- st_make_valid(us_hex)
}

us_loc_hex <- st_join(df_locale,us_hex)

loc_hex_count <- us_loc_hex %>% st_drop_geometry() %>% group_by(locale_desc) %>% count(id_hex)



us_hex_loc <- us_hex %>%
  inner_join(loc_hex_count) %>%
  # mutate(locale_desc = recode_factor(factor(locale),!!!locale_cd)) %>%
  st_transform(
    "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
  )

us_states <- us_outline %>%
  st_transform(
    "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
  )


# clip hexagons to fit withn us boundaries

us_hex_locale <- st_intersection(us_hex_loc, us_states)




credits <-
  tibble(
    label = c(
      "<span style='font-size:10pt'><strong>#30DayMapChallenge 2024</strong><br>
      <b>Day 4:</b> Hexagons<br>
      <b>Tool:</b> R <br> 
      <b>Created By:</b> Roland Richard<br>
      <span style='font-size:10pt; color:#CFCFCF;'><b>Data Sources:</b><br>
      National Center for Education Statistics (NCES)<br>
      Education Demographic and Geographic Estimates (EDGE) program<br>
      U.S. Census Bureau 2021 TIGER/Line Shapefile</span>"
    )
  )

# Assign specific colors to match each locale description
color_values <- c(
  # City - Red/Orange shades
  "City-Large" = "#E53935",       # Bright red
  "City-Midsize" = "#FB8C00",     # Deep orange
  "City-Small" = "#FFB74D",       # Light orange
  
  # Suburban - Green shades
  "Suburban-Large" = "#43A047",   # Deep green
  "Suburban-Midsize" = "#66BB6A", # Medium green
  "Suburban-Small" = "#A5D6A7",   # Light green
  
  # Town - Purple shades
  "Town-Fringe" = "#8E24AA",      # Dark purple
  "Town-Distant" = "#BA68C8",     # Medium purple
  "Town-Remote" = "#E1BEE7",      # Light purple
  
  # Rural - Blue shades
  "Rural-Fringe" = "#1E88E5",     # Bright blue
  "Rural-Distant" = "#64B5F6",    # Medium blue
  "Rural-Remote" = "#BBDEFB"      # Light blue
)


# Updated plot with specific color assignments for each locale
day4_map <-
  ggplot() +
  geom_sf(data = us_hex_locale %>% filter(str_detect(locale_desc,"Rural")), mapping = aes(fill = locale_desc), size = 0.005) +
  geom_sf(data = us_hex_locale %>% filter(str_detect(locale_desc,"Town")), mapping = aes(fill = locale_desc), size = 0.005) +
  geom_sf(data = us_hex_locale %>% filter(str_detect(locale_desc,"Suburban")), mapping = aes(fill = locale_desc), size = 0.005) +
  geom_sf(data = us_hex_locale %>% filter(str_detect(locale_desc,"City")), mapping = aes(fill = locale_desc), size = 0.005) +
  geom_sf(data = us_outline, color = "#E0E0E0", fill = NA, size = 0.5) +
  scale_fill_manual(
    guide = guide_legend(
      title = "Locale Description:",
      direction = "horizontal",
      title.position = "top",
      label.position = "bottom",
      nrow = 1,
      title.theme = element_text(face = "bold", color = "#FFFFFF")
    ), 
    values = color_values
  ) +
  geom_richtext(
    data = credits,
    aes(
      x = -2500000,
      y = -900000,
      label = label
    ),
    family = 'lobster',
    colour = "#FFFFFF",
    hjust = 0,
    fill = NA,
    label.color = NA,
    show.legend = FALSE
  ) +
  labs(
    title = 'US Schools by Locale, School Year 2020-21',
    subtitle = "Using National Center for Education Statistics (NCES) Locale Boundaries\n"
  ) +
  theme_void(base_family = "lobster") +
  theme(
    plot.background = element_rect(fill = "#2D2D2D", color = NA),
    legend.position = "top",
    legend.direction = "horizontal",
    legend.title = element_text(size = 12, family = "lobster", face = "bold", colour = "#FFFFFF"),
    legend.text = element_text(size = 10, family = "lobster", colour = "#FFFFFF"),
    legend.spacing.x = unit(0.5, 'cm'),
    legend.box = "horizontal",
    plot.title = element_text(
      family = "lobster",
      size = 42,
      face = "bold",
      color = "#FFFFFF"
    ),
    plot.subtitle = element_text(
      family = "lobster",
      size = 28,
      color = "#CFCFCF",
      face = "plain"
    ),
    plot.caption = element_text(face = "plain", hjust = 0, color = "#CFCFCF"),
    plot.margin = margin(2, 2, 2, 2, "cm")
  )

day4_map

# ggsave(day4_map,
#        filename = "day4_nces_locale.png",
#        type = "cairo",
#        scale = 1,
#        width = 18,
#        height = 12,
#        units = "in",
#        dpi = 500)