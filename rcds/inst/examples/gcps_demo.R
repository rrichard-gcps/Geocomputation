################################################################################
## rcds example: GCPS end-to-end demo (no Shiny) -- static PNG + interactive HTML
## Runs anywhere: demo data is sf::nc (North Carolina SIDS), no API keys.
## Swap `nc` for a GCPS/GA sf layer to localise.
################################################################################

library(rcds)
library(sf)
library(ggplot2)
library(leaflet)

# GCPS is the default brand; pick a map theme + palette.
MAP_THEME <- "civic"        # "civic" | "paper" | "bold"
PALETTE   <- "gcps_teal"    # any gcps_<family>

nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
nc <- st_transform(nc, 4326)
nc$births <- nc$BIR74

# --- 1. Static map (PNG) -----------------------------------------------------
mt <- gcps_tokens()$map_themes[[MAP_THEME]]
p <- ggplot(nc) +
  geom_sf(aes(fill = births), colour = mt$dist_stroke, linewidth = 0.2) +
  scale_fill_rcds_c(PALETTE, name = "Births (1974)",
                    labels = scales::label_comma()) +
  labs(title = "North Carolina Births by County, 1974",
       subtitle = "rcds GCPS demo",
       caption = rcds_signature("GCPS Map Studio", tool = "R / rcds",
                                sources = "sf::nc")) +
  theme_gcps_map(MAP_THEME, base = 15)
ggsave("gcps_demo_static.png", p, width = 11, height = 7, dpi = 200,
       bg = mt$canvas, type = "cairo")

# --- 2. Interactive map (self-contained HTML) --------------------------------
basemap <- if (MAP_THEME == "bold") "CartoDB.DarkMatter" else "CartoDB.Positron"
m <- leaflet(nc) |> addProviderTiles(basemap)
m <- rcds_leaflet_choropleth(m, nc, value = "births", palette = PALETTE,
                             legend_title = "Births (1974)")
m <- htmlwidgets::prependContent(
  m, htmltools::tags$style(gcps_interactive_css(MAP_THEME)))
rcds_save_widget(m, "gcps_demo_interactive.html")

message("Wrote gcps_demo_static.png and gcps_demo_interactive.html")
