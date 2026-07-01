# =============================================================================
# GCPS Map Studio -- a runnable rcds dashboard demo (deployable to Posit
# Connect Cloud). Shows the imported GCPS identity end to end: a bslib UI shell,
# an interactive Leaflet choropleth, and a static ggplot map, all sharing the
# GCPS tokens/palettes/themes from the rcds package.
#
# Demo data: North Carolina SIDS (ships with the `sf` package) so the app runs
# anywhere with no API keys. Swap `nc` for your GCPS/GA sf layer to localise --
# see README.md.
# =============================================================================

library(shiny)
library(bslib)
library(leaflet)
library(sf)
library(ggplot2)
library(htmltools)
library(htmlwidgets)
library(rcds)

# --- data (bundled, no network) ---------------------------------------------
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
nc <- sf::st_transform(nc, 4326)
nc$births <- nc$BIR74
nc$sids   <- nc$SID74

# --- choices -----------------------------------------------------------------
SHELLS <- names(gcps_ui_themes())
MAP_THEMES <- c("Civic (light)" = "civic", "Paper (editorial)" = "paper",
                "Bold (dark)" = "bold")
PALETTES <- c("Teal" = "gcps_teal", "Maroon" = "gcps_maroon", "Blue" = "gcps_blue",
              "Green" = "gcps_green", "Gold" = "gcps_gold", "Plum" = "gcps_plum",
              "Slate" = "gcps_slate", "Emerald" = "gcps_emerald",
              "Orange" = "gcps_orange", "Violet" = "gcps_violet")
basemap_for <- function(theme) if (theme == "bold") "CartoDB.DarkMatter" else "CartoDB.Positron"

# --- UI ----------------------------------------------------------------------
ui <- page_sidebar(
  title = "GCPS Map Studio",
  theme = gcps_bs_theme("civic"),
  sidebar = sidebar(
    width = 300,
    selectInput("shell", "Dashboard shell", choices = SHELLS, selected = "civic"),
    selectInput("map_theme", "Map theme", choices = MAP_THEMES, selected = "civic"),
    selectInput("palette", "Data palette", choices = PALETTES, selected = "gcps_teal"),
    helpText("Shell themes the app chrome; map theme + palette drive the maps.",
             "All from the imported GCPS design system via {rcds}.")
  ),
  layout_columns(
    fill = FALSE,
    value_box("Counties", textOutput("n_counties"), theme = "primary"),
    value_box("Total births (1974)", textOutput("n_births")),
    value_box("Total SIDS (1974)", textOutput("n_sids"))
  ),
  navset_card_tab(
    title = "Maps",
    nav_panel("Interactive", leafletOutput("map", height = 520)),
    nav_panel("Static", plotOutput("static", height = 520))
  )
)

# --- server ------------------------------------------------------------------
server <- function(input, output, session) {

  # live-swap the dashboard shell
  observeEvent(input$shell, {
    session$setCurrentTheme(gcps_bs_theme(input$shell))
  })

  output$n_counties <- renderText(nrow(nc))
  output$n_births   <- renderText(format(sum(nc$births), big.mark = ","))
  output$n_sids     <- renderText(format(sum(nc$sids), big.mark = ","))

  output$map <- renderLeaflet({
    m <- leaflet(nc) |> addProviderTiles(basemap_for(input$map_theme))
    m <- rcds_leaflet_choropleth(
      m, nc, value = "births", palette = input$palette,
      legend_title = "Births (1974)")
    m |> htmlwidgets::prependContent(
      htmltools::tags$style(gcps_interactive_css(input$map_theme)))
  })

  output$static <- renderPlot({
    mt <- gcps_tokens()$map_themes[[input$map_theme]]
    ggplot(nc) +
      geom_sf(aes(fill = births), colour = mt$dist_stroke, linewidth = 0.2) +
      scale_fill_rcds_c(input$palette, name = "Births (1974)",
                        labels = scales::label_comma()) +
      labs(title = "North Carolina Births by County, 1974",
           subtitle = "Demo data (sf::nc) · swap for GCPS/GA layers",
           caption = rcds_signature("GCPS Map Studio", tool = "R / rcds",
                                    sources = "sf::nc (Cressie 1993)")) +
      theme_gcps_map(input$map_theme, base = 15, register_fonts = FALSE)
  }, res = 96)
}

shinyApp(ui, server)
