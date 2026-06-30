################################################################################
## Project: day3_polygons_districts  (REVISED)
## Fixes:  (1) highlight labels moved OFF the red fills into clear space with a
##             white halo + leader lines (no more dark-on-maroon);
##         (2) the 26 minor districts are numbered on-map and named in a tidy
##             side legend instead of cluttering the map;
##         (3) lighter metro ring, warm-paper background, credits at the bottom,
##             locator inset with clearly visible highlights + a locator ring.
##
## Assumes the same objects your original script builds:
##   dfGeoSys        - sf of the 29 metro school systems (EPSG:2240), with a
##                     `GEOID`, a name column, `is_highlight`, and `label_hi`.
##   metro_20_bounds - sf of the 20-county metro ring.
##   ga_counties     - sf of Georgia counties (EPSG:2240) for the inset.
## Adjust the `name` column reference (NAME / system_name) to match your data.
################################################################################

library(tidyverse)
library(sf)
library(ggplot2)
library(ggrepel)
library(shadowtext)   # install.packages("shadowtext") -- halo text
library(cowplot)
library(showtext)
library(sysfonts)

# ── Fonts ─────────────────────────────────────────────────────────────────────
font_add(family = "Montserrat",
         regular = "Poppins/Poppins-Regular.ttf",
         bold    = "Poppins/Poppins-Bold.ttf")
font_add(family = "Bungee", regular = "Poppins/Poppins-ExtraBold.ttf")
showtext_auto(); showtext_opts(dpi = 500)

# ── Palette (warm paper, refined maroon) ──────────────────────────────────────
pal <- list(
  bg        = "#EFE9DC",  # paper background  (was flat #CCCCCC)
  dist_fill = "#F4EFE3",  # other districts
  dist_line = "#D6CDBA",
  ring      = "#9A9080",  # 20-county ring  (lighter than the old #333)
  hi_fill   = "#8C2F39",  # refined maroon
  hi_line   = "#581E25",
  ink       = "#2B2722",  # primary text
  sub       = "#6E665A",  # secondary text
  faint     = "#9A9080",  # numbers
  halo      = "#EFE9DC"   # halo == background, so labels read over any fill
)

# ── Short names + numbering for the side legend ───────────────────────────────
# NOTE: swap `NAME` for whichever column holds the system name in your data.
namecol <- "NAME"
dfGeoSys <- dfGeoSys |>
  mutate(short = str_remove(.data[[namecol]], " School District$"))

others <- dfGeoSys |>
  filter(!is_highlight) |>
  arrange(short) |>
  mutate(num = row_number())

# label points GUARANTEED inside each polygon (st_centroid can fall outside)
others_pts <- others |>
  mutate(geometry = st_point_on_surface(st_geometry(others))) |>
  st_as_sf()

hi <- dfGeoSys |> filter(is_highlight)
hi_pts <- hi |>
  mutate(geometry = st_point_on_surface(st_geometry(hi))) |>
  st_as_sf() |>
  bind_cols(as_tibble(st_coordinates(st_point_on_surface(st_geometry(hi)))))

# Hand-placed off-shape anchors for the 3 hero labels (State-Plane ft).
# Tune these nudges to drop the labels into open space next to each district.
hi_lab <- hi_pts |>
  mutate(
    nx = c("1302550" = -120000, "1300120" = -150000, "1302820" =  120000)[GEOID],
    ny = c("1302550" =  150000, "1300120" =   30000, "1302820" = -120000)[GEOID]
  )

# ── Main map ──────────────────────────────────────────────────────────────────
metro_map <- ggplot() +
  geom_sf(data = dfGeoSys, fill = pal$dist_fill, color = pal$dist_line, lwd = 0.3) +
  geom_sf(data = st_transform(metro_20_bounds, 2240),
          fill = NA, color = pal$ring, lwd = 0.4) +                 # lighter ring
  geom_sf(data = hi, fill = pal$hi_fill, color = pal$hi_line, linewidth = 0.9) +

  # numbers for the 26 minor districts (halo keeps them legible on any fill)
  geom_shadowtext(data = others_pts,
                  aes(label = num, geometry = geometry), stat = "sf_coordinates",
                  size = 2.6, family = "Montserrat", fontface = "bold",
                  color = pal$faint, bg.colour = pal$halo, bg.r = 0.14) +

  # hero labels: placed OFF the shapes, dark ink + halo, thin leader lines
  geom_text_repel(data = hi_lab,
                  aes(label = label_hi, geometry = geometry), stat = "sf_coordinates",
                  nudge_x = hi_lab$nx, nudge_y = hi_lab$ny,
                  size = 6.0, lineheight = 0.9, fontface = "bold",
                  family = "Montserrat", color = pal$hi_line,
                  bg.color = pal$halo, bg.r = 0.12,          # ggrepel >=0.9.2 halo
                  segment.color = pal$hi_line, segment.size = 0.5,
                  min.segment.length = 0, box.padding = 0.7,
                  point.padding = 0.4, max.overlaps = Inf, seed = 42) +
  coord_sf(crs = 2240, expand = TRUE) +
  theme_void()

# ── Side legend: numbered list of the 26 minor systems (two columns) ──────────
leg_df <- others |> st_drop_geometry() |> select(num, short) |>
  mutate(col = if_else(num <= ceiling(n()/2), 1L, 2L),
         row = if_else(col == 1L, num, num - ceiling(n()/2)))

legend_plot <- ggplot(leg_df, aes(x = (col-1)*1.0, y = -row)) +
  geom_text(aes(label = sprintf("%2d", num)), hjust = 1, nudge_x = -0.04,
            family = "Montserrat", color = pal$hi_fill, size = 3.0) +
  geom_text(aes(label = short), hjust = 0, nudge_x = 0.03,
            family = "Montserrat", color = pal$sub, size = 3.0) +
  annotate("text", x = 0, y = 1.4, label = "OTHER METRO SCHOOL SYSTEMS",
           hjust = 0, family = "Montserrat", fontface = "bold",
           color = pal$faint, size = 2.6) +
  scale_x_continuous(limits = c(-0.1, 1.9)) +
  scale_y_continuous(limits = c(-ceiling(nrow(leg_df)/2) - 1, 2)) +
  theme_void()

# ── "Districts of interest" key ───────────────────────────────────────────────
key_df <- tibble(y = c(2,1,0),
                 lab = c("Gwinnett County Public Schools",
                         "Atlanta Public Schools", "Henry County Schools"))
key_plot <- ggplot(key_df, aes(0, y)) +
  geom_point(shape = 22, size = 5, fill = pal$hi_fill, color = pal$hi_line) +
  geom_text(aes(x = 0.25, label = lab), hjust = 0, family = "Montserrat",
            fontface = "bold", color = pal$ink, size = 3.1) +
  annotate("text", x = 0, y = 3.2, label = "DISTRICTS OF INTEREST", hjust = 0,
           family = "Montserrat", fontface = "bold", color = pal$faint, size = 2.6) +
  scale_x_continuous(limits = c(-0.2, 5)) +
  scale_y_continuous(limits = c(-0.6, 3.6)) +
  theme_void()

# ── Locator inset (Georgia) with visible highlights + locator ring ────────────
hi_union  <- st_union(hi)
ring_geom <- st_buffer(st_centroid(hi_union),
                       dist = as.numeric(max(st_distance(st_centroid(hi_union),
                                                         st_cast(hi_union, "POINT")))) * 1.25)
ga_inset <- ggplot() +
  geom_sf(data = ga_counties, fill = "#E7DFCD", color = "#CDC3AD", lwd = 0.2) +
  geom_sf(data = hi, fill = pal$hi_fill, color = pal$hi_line, linewidth = 0.5) +
  geom_sf(data = ring_geom, fill = NA, color = pal$hi_line, linewidth = 0.7) +
  theme_void()

# ── Credits (now at the BOTTOM) ───────────────────────────────────────────────
credits <- ggplot() +
  annotate("text", x = 0, y = 0, hjust = 0, vjust = 0, family = "Montserrat",
           size = 2.6, color = pal$sub,
           label = "Created by GCPS Research, Evaluation & Analytics (REA)\nData: U.S. Census Bureau TIGER/Line Shapefiles") +
  theme_void()

# ── Compose (title top, map right, legend/inset/key left, credits bottom) ─────
day3_map <- ggdraw() +
  draw_plot(metro_map,   x = 0.30, y = 0.00, width = 0.70, height = 0.92) +
  draw_plot(ga_inset,    x = 0.03, y = 0.62, width = 0.26, height = 0.26) +
  draw_plot(key_plot,    x = 0.03, y = 0.44, width = 0.26, height = 0.16) +
  draw_plot(legend_plot, x = 0.03, y = 0.10, width = 0.26, height = 0.34) +
  draw_plot(credits,     x = 0.03, y = 0.02, width = 0.26, height = 0.06) +
  draw_label("Metro Atlanta School Districts", x = 0.03, y = 0.965, hjust = 0,
             fontfamily = "Bungee", size = 30, color = pal$ink) +
  draw_label("Location map highlighting Gwinnett County, Atlanta Public Schools & Henry County",
             x = 0.03, y = 0.925, hjust = 0, fontfamily = "Montserrat",
             size = 14, color = pal$sub) +
  theme(plot.background = element_rect(fill = pal$bg, color = NA))

ggsave(day3_map, filename = "day3_polygons_districts.png", type = "cairo",
       scale = 0.75, width = 18, height = 12, units = "in", dpi = 500)
