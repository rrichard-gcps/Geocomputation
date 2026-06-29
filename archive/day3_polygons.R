################################################################################
## Project: day3_polygons
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
library(janitor)
library(cowplot)

# Load Data ---------------------------------------------------------------    

metro_es_zones <- read_sf("data/metro_es_sspi.gpkg")
metro_20_bounds <- read_sf("data/metro_20_counties.gpkg")
load(here("data","metro_boundaries.rdata"))

sys_dc <- import("2024_directly_certified_district.xls")
sch_dc <- import("2024_directly_certified_school.xls")

ga_sch_systems <- school_districts(state = "13", type = "unified", cb = TRUE)

state_ids <- metro_es_zones |>
  select(nces_sys_id, sys_id, orig_state_id) |>
  distinct(.keep_all = F) |>
  st_drop_geometry()

metro_ids <- state_ids |> filter(nces_sys_id %in% c(
  "1300120",
  "1300290",
  "1300510",
  "1300840",
  "1300870",
  "1300900",
  "1301110",
  "1301230",
  "1301290",
  "1301500",
  "1301680",
  "1301740",
  "1301860",
  "1302130",
  "1302220",
  "1302280",
  "1302310",
  "1302550",
  "1302610",
  "1302820",
  "1303510",
  "1303930",
  "1304020",
  "1304410",
  "1302520",
  "1305390",
  "1300330",
  "1300600",
  "1304540"
)) |> distinct(nces_sys_id, .keep_all = T)

metro_systems <- ga_sch_systems |> filter(
  GEOID %in% c(
    "1300120",
    "1300290",
    "1300510",
    "1300840",
    "1300870",
    "1300900",
    "1301110",
    "1301230",
    "1301290",
    "1301500",
    "1301680",
    "1301740",
    "1301860",
    "1302130",
    "1302220",
    "1302280",
    "1302310",
    "1302550",
    "1302610",
    "1302820",
    "1303510",
    "1303930",
    "1304020",
    "1304410",
    "1302520",
    "1305390",
    "1300330",
    "1300600",
    "1304540"
  )
)

metro_systems <- metro_systems |> right_join(metro_ids, by = join_by(GEOID == nces_sys_id ))

schoolDC <- sch_dc |> clean_names() |> 
  mutate(orig_state_id = glue('GA-{system_id}-{sprintf("%04i",school_id)}'))

sysDC <- sys_dc |> clean_names() |> mutate(sys_id = sprintf("%03i", system_id))

metro_es <-   metro_es_zones |> 
  select(nces_sch_id:cluster) |>
  st_drop_geometry() |> 
  distinct(.keep_all = T)

dfGeo <- metro_es_zones %>% left_join(schoolDC, by = 'orig_state_id') 

dfGeo <- dfGeo |> filter(!is.na(direct_cert_perc))

dfGeoSys <- metro_systems |> left_join(sysDC,by = join_by(sys_id == sys_id))

# for inset map
es_bb <- st_as_sfc(st_bbox(dfGeo))

# Color Schemes
tlr <- c('#009392','#72aaa1','#b1c7b3','#f1eac8','#e5b9ad','#d98994','#d0587e')
clr <- c("#005f57", "#1a8177", "#36a499", "#5ec7ba", "#9fe4da", "#f1cac3", "#e89c8d", "#da6b58", "#b94634", "#8e2a1b")

ga_counties <- st_as_sf(counties(state = "13", cb = TRUE)) %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 2240)

ga_outline <- st_as_sf(states(cb = TRUE)) %>%
  filter(STUSPS == "GA") %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 2240)

ga_inset <- ggplot() +
  geom_sf(
    data = dfGeoSys |> filter(!is.na(direct_cert_perc)),
    aes(fill = cut(
      direct_cert_perc,
      breaks = c(quantile(
        direct_cert_perc,
        probs = seq(0, 1, length = 10),
        na.rm = T
      )),
      include.lowest = T
    )),
    color = NA,
    show.legend = F
  ) +
  scale_fill_manual(name = "Mobility Rate:", values = c(clr))+
  geom_sf(
    data = ga_counties ,
    fill = NA,
    color = '#333333',
    lwd = 0.25
  ) +
  theme(legend.position = F) +
  theme_void()

ga_inset

metro_map <-
  ggplot() +
  geom_sf(data = dfGeo |> filter(!is.na(direct_cert_perc)),
          aes(fill = cut(
            direct_cert_perc,
            breaks = c(quantile(direct_cert_perc, probs = seq(0, 1, length = 10),na.rm = T)),
            include.lowest = T
          )),
          color = NA) +
  scale_fill_manual(
    name = "Mobility Rate:",
    values = c(clr),
    labels = c(
      "3.6-17.9\n(Lower Student Mobility)",
      "17.9-35.2",
      "35.2-46.9",
      "46.9-55.4",
      "55.4-62.4",
      "62.4-69.4",
      "69.4-76.4",
      "76.4-82.5",
      "82.5-95.6\n(Higher Student Mobility)"
    )
  ) + guides(fill = guide_legend(nrow = 1)) + 
  geom_sf(data = dist_bounds, fill = NA, color = '#000000', lwd = 0.25) +
  geom_sf(data = metro_20_bounds , fill = NA, color = '#333333', lwd = 0.75) +
  coord_sf(crs = 2240,expand = TRUE)+
  theme_void() +
  theme(
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(size = 12, family = "Montserrat", face = "bold", colour = "#333333"),
    legend.text = element_text(size = 10, family = "Montserrat", colour = "#333333"),
    legend.spacing.x = unit(0.5, 'cm'),
    legend.box = "horizontal"
  )

credits <- tibble(
  label = c(
    "<span style='font-size:10pt'><strong>#30DayMapChallenge 2024 Day 3: Polygons</strong><br>
    <b>Tool:</b> R <br> <b>Created By:</b> Roland Richard<br>
<span style='font-size:10pt; color:#7B7D7D;'><b>Data Sources:<br></b> GA Governor’s Office of Student Achievement (GOSA)<br>U.S. Census Bureau 2022 TIGER/Line Shapefiles</span>"
  )
) %>%
  ggplot() +
  geom_richtext(
    aes(x = 1, y = 0, label = label),
    colour = "#333333",
    hjust = 0,
    vjust = 0,
    fill = NA,
    label.color = NA,
    show.legend = FALSE
  ) +
  theme_void(base_family = "Montserrat")

# Combine Maps using Cowplot and Patchwork

day3_map <-
  ggdraw() +
  draw_plot(metro_map) +
  draw_plot(ga_inset, x = 0.75, y = 0.75, width = 0.3, height = 0.3) +
  draw_plot(credits, x =-0.25, y = 0.60, width = 0.51, height = 0.35) +  # Adjusted annotation position slightly upward
  plot_annotation(
    title = "<span style='font-size:34pt; color:#2C3E50; font-family:Bungee;'>Elementary School Student Mobility</span>",
    subtitle = "<span style='font-size:20pt; color:#1F618D; font-family:Montserrat;'>20-County Metro Atlanta Area, School Year 2023-24</span>",
    theme = theme(
      plot.title = element_markdown(
        size = 28,
        family = "Bungee",
        face = "bold",
        hjust = 0
      ),
      plot.subtitle = element_markdown(size = 20, family = "Montserrat", hjust = 0),
      plot.caption = element_markdown(colour = "#333333")
    )
  ) &
  theme(text = element_text(family = 'Montserrat'),
        plot.background = element_rect(fill ="#CCCCCC" , color = NA),
        panel.border = element_blank())

day3_map

# Save the Final Map
ggsave(day3_map,
       filename = "day3_polygons.png",
       type = "cairo",
       scale = 0.75,
       width = 18,
       height = 12,
       units = "in",
       dpi = 500)

