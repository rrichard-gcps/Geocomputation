################################################################################
## Project: gcps_cluster_reference_map
## Purpose: Clean reference / location map of GCPS high school clusters with
##          road infrastructure for orientation. No data choropleth is shown —
##          a single uniform muted polygon fill is used so that cluster
##          boundaries, roads, and labels all remain highly legible.
##          Styled after the gcps-aps-henry-map aesthetic.
##
## Inputs:
##   data/prep/gcps_absm_geo.RData  -> hs_absms (20 HS cluster polygons),
##                                     gcps_outline, sysBounds (Buford)
##   tigris::roads("GA","135")      -> Gwinnett County road network
##   tigris::counties(state="13")   -> Georgia counties for the inset
##   data/I-85.png, I-985.png, US_23.png, US_29.png, US_78.png (highway shields)
##
## Output:
##   gcps_cluster_reference_map.png (high-resolution PNG)
################################################################################

# Libraries ----------------------------------------------------------------
library(tidyverse)
library(glue)
library(here)
library(sf)
library(tigris)
library(cowplot)
library(patchwork)
library(ggtext)
library(showtext)
library(sysfonts)
library(magick)
library(ggspatial)

options(tigris_use_cache = TRUE)

`%out%` <- Negate(`%in%`)

# Fonts --------------------------------------------------------------------
# Same approach as gcps-aps-henry-map.R: register the bundled Poppins TTFs and
# alias them to Montserrat / Bungee so rendering succeeds even headless.
font_add(
  family = "Montserrat",
  regular = "Poppins/Poppins-Regular.ttf",
  bold = "Poppins/Poppins-Bold.ttf",
  italic = "Poppins/Poppins-Italic.ttf",
  bolditalic = "Poppins/Poppins-BoldItalic.ttf"
)
font_add(
  family = "Bungee",
  regular = "Poppins/Poppins-ExtraBold.ttf"
)
showtext_auto()
showtext_opts(dpi = 500)


# Load Spatial Data --------------------------------------------------------
load(here("data", "prep", "gcps_absm_geo.RData"))

# GCPS district outline (SpatialPolygonsDataFrame -> sf)
gcps_outline <- st_as_sf(gcps_outline) |>
  st_transform(crs = 2240) |>
  st_set_crs(2240)

# High school cluster polygons (already NAD83 / Georgia West (ftUS) = EPSG:2240)
clusters_sf <- hs_absms |>
  st_transform(crs = 2240) |>
  st_set_crs(2240)

# School system bounds (for Buford City Schools reference)
sysBounds_sf <- st_as_sf(sysBounds) |> st_transform(crs = 2240)
buford <- sysBounds_sf |> filter(sys_nms == "Buford City Schools")

# Georgia counties (for inset) --------------------------------------------
# st_simplify lightens the geometry for a cleaner inset.
ga_counties <- st_as_sf(counties(state = "13", cb = TRUE)) %>%
  st_transform(crs = 2240) %>%
  st_simplify(dTolerance = 200)

gwinnett <- ga_counties |> filter(NAME == "Gwinnett")


# Roads --------------------------------------------------------------------
# tigris pulls the Census TIGER/Line road layer for Gwinnett County (FIPS 135).
gwin_roads <- roads("GA", "135") |> st_transform(crs = 2240)

gwin_interstates <- gwin_roads |> filter(RTTYP == "I")
gwin_roads_main <- gwin_roads |> filter(RTTYP == "M")
gwin_us_hwys <- gwin_roads |>
  filter(
    RTTYP == "U" &
      FULLNAME %out% c("US Hwy 29 Alt", "Old US Hwy 29 NW", "Old US Hwy 78 SW")
  )

# Highway shield images
I_85 <- image_read("data/I-85.png")
I_985 <- image_read("data/I-985.png")
US_23 <- image_read("data/US_23.png")
US_29 <- image_read("data/US_29.png")
US_78 <- image_read("data/US_78.png")


# Label Points -------------------------------------------------------------
# Use st_point_on_surface so labels are guaranteed inside each polygon
# (more robust than centroids for irregular shapes).
cluster_pts <- clusters_sf |>
  select(cluster) |>
  st_point_on_surface() |>
  st_coordinates() |>
  as_tibble() |>
  bind_cols(cluster = clusters_sf$cluster) |>
  # Meadowcreek is small; nudge its label slightly so it clears its boundary.
  mutate(
    X = if_else(cluster == "Meadowcreek", X - 3500, X),
    Y = if_else(cluster == "Meadowcreek", Y - 2500, Y)
  )

buford_pts <- buford |>
  st_point_on_surface() |>
  st_coordinates() |>
  as_tibble() |>
  bind_cols(label = "Buford City\nSchools")


# Color Palette ------------------------------------------------------------
# Single muted fill for all clusters — this is a location/reference map, so no
# data choropleth. Outlines do the work of distinguishing the clusters.
cluster_fill <- "#E8EEF5" # very soft blue-grey
cluster_color <- "#5B6B7B" # slate outline for each cluster
outline_color <- "#1A202C" # bold GCPS district outline
road_col <- "#9AA5B1" # muted grey for roads


# Inset / Reference Map (Georgia) -----------------------------------------
ga_inset <- ggplot() +
  geom_sf(
    data = ga_counties,
    fill = NA,
    color = "#333333",
    lwd = 0.25
  ) +
  geom_sf(
    data = gwinnett,
    fill = "#A8BFE4",
    color = "#0F3E90",
    linewidth = 0.6
  ) +
  theme_void()


# Main Map -----------------------------------------------------------------
cluster_map <- ggplot() +
  # (1) Cluster polygons — uniform muted fill, clean slate outlines
  geom_sf(
    data = clusters_sf,
    fill = cluster_fill,
    color = cluster_color,
    lwd = 0.35
  ) +
  # (2) GCPS district outline on top for a crisp outer edge
  geom_sf(
    data = gcps_outline,
    fill = NA,
    color = outline_color,
    lwd = 0.9
  ) +
  # (3) Road layers for reference (muted greys, drawn under the labels)
  geom_sf(
    data = gwin_roads_main,
    inherit.aes = FALSE,
    color = road_col,
    size = 0.1,
    alpha = 0.45
  ) +
  geom_sf(
    data = gwin_us_hwys,
    inherit.aes = FALSE,
    color = road_col,
    size = 0.9,
    alpha = 0.55
  ) +
  geom_sf(
    data = gwin_interstates,
    inherit.aes = FALSE,
    color = "#6B7280",
    size = 2.2,
    alpha = 0.65
  ) +
  # (4) Cluster labels — bold, centered, dark
  geom_text(
    data = cluster_pts,
    aes(x = X, y = Y, label = cluster),
    fontface = "bold",
    family = "Montserrat",
    size = 3.4,
    color = "#2C3E50",
    lineheight = 0.85
  ) +
  # (5) Buford City Schools reference label (muted)
  geom_text(
    data = buford_pts,
    aes(x = X, y = Y, label = label),
    fontface = "bold",
    family = "Montserrat",
    size = 2.4,
    color = "#6B7280",
    lineheight = 0.85
  ) +
  coord_sf(crs = 2240, expand = TRUE) +
  # ggspatial::annotation_north_arrow(
  #   location = "br",
  #   which_north = "true",
  #   height = unit(2.6, "cm"),
  #   width = unit(2.6, "cm"),
  #   pad_x = unit(0.35, "in"),
  #   pad_y = unit(0.35, "in"),
  #   style = ggspatial::north_arrow_fancy_orienteering()
  # ) +
  theme_void()


# Credits ------------------------------------------------------------------
credits <- tibble(
  label = c(
    "<span style='font-size:9pt'><strong><br><b>Created By:</b></strong> GCPS Research, Evaluation, & Analytics (REA)<br>
<span style='font-size:9pt; color:#7B7D7D;'><b>Data Sources:</b> U.S. Census Bureau TIGER/Line Shapefiles<br>GCPS Administrative Data</span>"
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


# Combine Maps with Cowplot ------------------------------------------------
# The draw_image coordinates for highway shields are tuned to the GCPS map
# extent (same area as gcps-demog-maps.R). Fine-tune if the extent changes.
final_map <- ggdraw() +
  draw_plot(cluster_map) +
  # draw_plot(ga_inset, x = 0.75, y = 0.75, width = 0.3, height = 0.3) +
  # Interstate shields
  draw_image(
    I_85,
    x = 0.372,
    y = 0.49,
    width = 0.03,
    height = 0.03,
    hjust = 0
  ) +
  draw_image(
    I_985,
    x = 0.595,
    y = 0.75,
    width = 0.03,
    height = 0.03,
    hjust = 0
  ) +
  # US highway shields
  draw_image(US_23, x = 0.31, y = 0.575, width = 0.02, height = 0.02) +
  draw_image(US_29, x = 0.52, y = 0.452, width = 0.02, height = 0.02) +
  draw_image(US_78, x = 0.52575, y = 0.29575, width = 0.02, height = 0.02) +
  # draw_plot(credits, x = -0.25, y = -0.15, width = 0.55, height = 0.35) +
  # plot_annotation(
  #   title = "<span style='font-size:30pt; color:#2C3E50; font-family:Bungee;'>GCPS High School Clusters</span>",
  #   subtitle = "<span style='font-size:18pt; color:#2C3E50; font-family:Montserrat;'>Reference map of Gwinnett County Public Schools attendance zones</span>",
  #   theme = theme(
  #     plot.title = element_markdown(
  #       size = 28,
  #       family = "Bungee",
  #       face = "bold",
  #       hjust = 0
  #     ),
  #     plot.subtitle = element_markdown(
  #       size = 20,
  #       family = "Montserrat",
  #       hjust = 0
  #     ),
  #     plot.caption = element_markdown(colour = "#333333")
  #   )
  # ) &
  theme(
    text = element_text(family = "Montserrat"),
    plot.background = element_rect(fill = "#FFFFFF", color = NA),
    panel.border = element_blank()
  )


# Save ---------------------------------------------------------------------
ggsave(
  final_map,
  filename = "gcps_cluster_reference_map.png",
  type = "cairo",
  scale = 0.85,
  width = 18,
  height = 14,
  units = "in",
  dpi = 500
)
