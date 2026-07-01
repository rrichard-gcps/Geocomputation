################################################################################
## Project: gcps-aps-henry-map
## Purpose: Repurposed map. Shows metro Atlanta school SYSTEMS (districts)
##          with the Georgia reference/inset map. Highlights three districts of
##          interest -- Gwinnett County Public Schools, Atlanta Public Schools,
##          and Henry County Schools -- on BOTH the main map and the inset, with
##          bold larger labels, while other districts get muted plain labels.
################################################################################

library(tidyverse)
library(glue)
library(here)
library(sf)
library(rio)
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
library(showtext)
library(sysfonts)

# Fonts -------------------------------------------------------------------
# The map is styled with Montserrat/Bungee. When those families are not
# installed (e.g. a headless CLI render), register the bundled Poppins TTFs
# and alias them to the Montserrat family name so rendering still succeeds.
font_add(
  family = "Montserrat",
  regular = "Poppins/Poppins-Regular.ttf",
  bold = "Poppins/Poppins-Bold.ttf",
  italic = "Poppins/Poppins-Italic.ttf",
  bolditalic = "Poppins/Poppins-BoldItalic.ttf"
)
# Bungee fallback -> use Poppins ExtraBold (no Bungee TTF bundled)
font_add(
  family = "Bungee",
  regular = "Poppins/Poppins-ExtraBold.ttf"
)
showtext_auto()
showtext_opts(dpi = 500)

# Load Data ---------------------------------------------------------------

metro_es_zones <- read_sf("data/metro_es_sspi.gpkg")
metro_20_bounds <- read_sf("data/metro_20_counties.gpkg")
load(here("data", "metro_boundaries.rdata"))

sys_dc <- import("data/2024_directly_certified_district.xls")

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
    "Atlanta\nPublic\nSchools",
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

# Colors for a LOCATION map (no data choropleth) -------------------------
hi_fill <- "#A8BFE4" # fill color for the three districts of interest
hi_color <- "#0F3E90" # bold accent outline for the three districts

# Inset / Reference Map (Georgia) -----------------------------------------
ga_inset <- ggplot() +
  geom_sf(
    data = ga_counties,
    fill = NA,
    color = "#333333",
    lwd = 0.25
  ) +
  # fill + bold outline ONLY the three districts of interest
  geom_sf(
    data = dfGeoSys |> filter(is_highlight),
    fill = hi_fill,
    color = hi_color,
    linewidth = 0.6
  ) +
  theme_void()

ga_inset

# Interior label points (guaranteed inside each polygon) for the highlighted
# districts, so the bold labels center within their boundaries instead of
# being nudged by position-dependent offsets.
hi_label_pts <- dfGeoSys |>
  filter(is_highlight) |>
  st_point_on_surface()

# Main Map (Metro Atlanta school systems) ---------------------------------
metro_map <- ggplot() +
  # all districts outlined, NOT filled (location map)
  geom_sf(
    data = dfGeoSys,
    fill = "grey90",
    color = "grey70",
    lwd = 0.3
  ) +
  # 20-county metro ring for context
  geom_sf(
    data = metro_20_bounds |> st_transform(2240),
    fill = NA,
    color = "#333333",
    lwd = 0.6
  ) +
  # FILL + BOLD outline only the three districts of interest
  geom_sf(
    data = dfGeoSys |> filter(is_highlight),
    fill = hi_fill,
    color = hi_color,
    linewidth = 1.0
  ) +
  # Muted, plain labels for the other districts
  geom_text_repel(
    data = dfGeoSys |> filter(!is_highlight),
    aes(label = label_all, geometry = geometry),
    stat = "sf_coordinates",
    size = 1.5,
    color = "grey45",
    family = "Montserrat",
    max.overlaps = Inf,
    min.segment.length = 0,
    segment.color = "grey70",
    segment.size = 0
  ) +
  # BOLD, centered labels for the three districts of interest, placed at a
  # point guaranteed to lie inside each polygon (true centering, robust to
  # row-order changes)
  geom_sf_text(
    data = hi_label_pts,
    aes(label = label_hi),
    size = 4,
    fontface = "bold",
    color = "#2C3E50",
    family = "Montserrat",
    lineheight = 0.85
  ) +
  coord_sf(crs = 2240, expand = TRUE) +
  theme_void()

# Credits -----------------------------------------------------------------
credits <- tibble(
  label = c(
    "<span style='font-size:9pt'><strong><br><b>Created By:</b></strong> GCPS Research, Evaluation, & Analytics (REA)<br>
<span style='font-size:9pt; color:#7B7D7D;'><b>Data Sources:</b>U.S. Census Bureau TIGER/Line Shapefiles</span>"
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
  draw_plot(credits, x = -0.25, y = -0.15, width = 0.55, height = 0.35) +
  plot_annotation(
    title = "<span style='font-size:30pt; color:#2C3E50; font-family:Bungee;'>Metro Atlanta School Districts</span>",
    subtitle = "<span style='font-size:18pt; color:#2C3E50; font-family:Montserrat;'>Location map highlighting Gwinnett County, Atlanta Public Schools & Henry County</span>",
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
  filename = "gcps_aps_henry_map.png",
  type = "cairo",
  scale = 0.75,
  width = 18,
  height = 12,
  units = "in",
  dpi = 500
)
