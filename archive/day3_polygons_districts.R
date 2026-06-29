################################################################################
## Project: day3_polygons_districts
## Purpose: Repurposed Day 3 map. Shows metro Atlanta school SYSTEMS (districts)
##          with the Georgia reference/inset map. Highlights three districts of
##          interest -- Gwinnett County Public Schools, Atlanta Public Schools,
##          and Henry County Schools -- on BOTH the main map and the inset, with
##          bold larger labels, while other districts get muted plain labels.
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
library(ggrepel)

# Load Data ---------------------------------------------------------------

metro_es_zones <- read_sf("data/metro_es_sspi.gpkg")
metro_20_bounds <- read_sf("data/metro_20_counties.gpkg")
load(here("data", "metro_boundaries.rdata"))

sys_dc <- import("2024_directly_certified_district.xls")

ga_sch_systems <- school_districts(state = "13", type = "unified", cb = TRUE)

# Map NCES ids -> GA state sys ids from the elementary-zone layer
state_ids <- metro_es_zones |>
  select(nces_sys_id, sys_id, orig_state_id) |>
  distinct(.keep_all = FALSE) |>
  st_drop_geometry()

metro_ids <- state_ids |>
  filter(
    nces_sys_id %in%
      c(
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
  ) |>
  distinct(nces_sys_id, .keep_all = TRUE)

metro_systems <- ga_sch_systems |>
  filter(
    GEOID %in%
      c(
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

metro_systems <- metro_systems |>
  right_join(metro_ids, by = join_by(GEOID == nces_sys_id))

# Direct certification (student mobility) at the DISTRICT level
sysDC <- sys_dc |> clean_names() |> mutate(sys_id = sprintf("%03i", system_id))

dfGeoSys <- metro_systems |> left_join(sysDC, by = join_by(sys_id == sys_id))

# Districts of interest ---------------------------------------------------
# NCES ids: Gwinnett = 1302550, Atlanta Public Schools = 1300120, Henry = 1302820
highlight_ids <- c("1302550", "1300120", "1302820")

# Clean, bold labels for the highlighted districts
clean_labels <- tibble(
  GEOID = highlight_ids,
  label_hi = c(
    "Gwinnett County\nPublic Schools",
    "Atlanta\nPublic Schools",
    "Henry County\nSchools"
  )
)

# Work in Georgia State Plane (ft) for crisp cartography and label placement
dfGeoSys <- dfGeoSys |>
  st_transform(crs = 2240) |>
  left_join(clean_labels, by = "GEOID") |>
  mutate(
    is_highlight = GEOID %in% highlight_ids,
    # muted label for every district (short name); highlight labels override below
    label_all = coalesce(label_hi, system_name)
  )

# Reference geography (Georgia counties + outline) ------------------------
ga_counties <- st_as_sf(counties(state = "13", cb = TRUE)) %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 2240)

# Shared mobility bins so legend matches on both maps --------------------
mob_breaks <- c(quantile(
  dfGeoSys$direct_cert_perc,
  probs = seq(0, 1, length = 10),
  na.rm = TRUE
))

clr <- c(
  "#0e5a73",
  "#29718c",
  "#4988a1",
  "#709eb1",
  "#9cb2bc",
  "#c7c7c7",
  "#acb0a0",
  "#939b77",
  "#7a8554",
  "#646e36",
  "#4e581f"
)

hi_color <- "#b94634" # bold accent outline for the three districts

# Inset / Reference Map (Georgia) -----------------------------------------
ga_inset <- ggplot() +
  geom_sf(
    data = dfGeoSys |> filter(!is.na(direct_cert_perc)),
    aes(
      fill = cut(
        direct_cert_perc,
        breaks = mob_breaks,
        include.lowest = TRUE
      )
    ),
    color = NA,
    show.legend = FALSE
  ) +
  scale_fill_manual(name = "Mobility Rate:", values = clr) +
  geom_sf(data = ga_counties, fill = NA, color = "#333333", lwd = 0.25) +
  # bold outline around the three districts of interest
  geom_sf(
    data = dfGeoSys |> filter(is_highlight),
    fill = NA,
    color = hi_color,
    linewidth = 0.9
  ) +
  # label only the three districts on the inset
  geom_text_repel(
    data = dfGeoSys |> filter(is_highlight),
    aes(label = label_hi, geometry = geometry),
    stat = "sf_coordinates",
    size = 2.6,
    fontface = "bold",
    color = "#2C3E50",
    family = "Montserrat",
    segment.color = hi_color,
    segment.size = 0.4,
    max.overlaps = Inf,
    min.segment.length = 0,
    nudge_x = c(120000, -90000, 90000),
    nudge_y = c(-60000, 40000, -40000),
    box.padding = 0.4
  ) +
  theme(legend.position = "none") +
  theme_void()

ga_inset

# Main Map (Metro Atlanta school systems) ---------------------------------
metro_map <- ggplot() +
  geom_sf(
    data = dfGeoSys |> filter(!is.na(direct_cert_perc)),
    aes(
      fill = cut(
        direct_cert_perc,
        breaks = mob_breaks,
        include.lowest = TRUE
      )
    ),
    color = "grey75",
    lwd = 0.2
  ) +
  scale_fill_manual(
    name = "Mobility Rate:",
    values = clr,
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
  ) +
  guides(fill = guide_legend(nrow = 1)) +
  # 20-county metro ring for context
  geom_sf(
    data = metro_20_bounds |> st_transform(2240),
    fill = NA,
    color = "#333333",
    lwd = 0.6
  ) +
  # BOLD highlight outlines for the three districts
  geom_sf(
    data = dfGeoSys |> filter(is_highlight),
    fill = NA,
    color = hi_color,
    linewidth = 1.3
  ) +
  # Muted, plain labels for the other districts
  geom_text_repel(
    data = dfGeoSys |> filter(!is_highlight, !is.na(direct_cert_perc)),
    aes(label = label_all, geometry = geometry),
    stat = "sf_coordinates",
    size = 2.7,
    color = "grey45",
    family = "Montserrat",
    max.overlaps = Inf,
    min.segment.length = 0,
    segment.color = "grey70",
    segment.size = 0.2
  ) +
  # BOLD, larger labels for the three districts of interest
  geom_text_repel(
    data = dfGeoSys |> filter(is_highlight),
    aes(label = label_hi, geometry = geometry),
    stat = "sf_coordinates",
    size = 6.2,
    fontface = "bold",
    color = "#2C3E50",
    family = "Montserrat",
    segment.color = hi_color,
    segment.size = 0.5,
    max.overlaps = Inf,
    min.segment.length = 0,
    box.padding = 0.6,
    nudge_x = c(-40000, -30000, 30000),
    nudge_y = c(-50000, 40000, -20000)
  ) +
  coord_sf(crs = 2240, expand = TRUE) +
  theme_void() +
  theme(
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(
      size = 12,
      family = "Montserrat",
      face = "bold",
      colour = "#333333"
    ),
    legend.text = element_text(
      size = 10,
      family = "Montserrat",
      colour = "#333333"
    ),
    legend.spacing.x = unit(0.5, "cm"),
    legend.box = "horizontal"
  )

# Credits -----------------------------------------------------------------
credits <- tibble(
  label = c(
    "<span style='font-size:10pt'><strong>#30DayMapChallenge 2024 Day 3: Polygons</strong><br>
    <b>Tool:</b> R <br> <b>Created By:</b> Roland Richard<br>
<span style='font-size:10pt; color:#7B7D7D;'><b>Data Sources:<br></b> GA Governor's Office of Student Achievement (GOSA)<br>U.S. Census Bureau 2022 TIGER/Line Shapefiles</span>"
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

# Combine Maps using Cowplot ----------------------------------------------
day3_map <- ggdraw() +
  draw_plot(metro_map) +
  draw_plot(ga_inset, x = 0.75, y = 0.75, width = 0.3, height = 0.3) +
  draw_plot(credits, x = -0.25, y = 0.60, width = 0.51, height = 0.35) +
  plot_annotation(
    title = "<span style='font-size:34pt; color:#2C3E50; font-family:Bungee;'>Student Mobility by School System</span>",
    subtitle = "<span style='font-size:20pt; color:#1F618D; font-family:Montserrat;'>Metro Atlanta School Districts | Highlighting Gwinnett, Atlanta & Henry</span>",
    theme = theme(
      plot.title = element_markdown(
        size = 28,
        family = "Bungee",
        face = "bold",
        hjust = 0
      ),
      plot.subtitle = element_markdown(
        size = 20,
        family = "Montserrat",
        hjust = 0
      ),
      plot.caption = element_markdown(colour = "#333333")
    )
  ) &
  theme(
    text = element_text(family = "Montserrat"),
    plot.background = element_rect(fill = "#CCCCCC", color = NA),
    panel.border = element_blank()
  )

day3_map

# Save the Final Map
ggsave(
  day3_map,
  filename = "day3_polygons_districts.png",
  type = "cairo",
  scale = 0.75,
  width = 18,
  height = 12,
  units = "in",
  dpi = 500
)
