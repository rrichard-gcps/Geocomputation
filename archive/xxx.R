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

library(tidyverse)
library(sf)
library(ggrepel)
library(ggthemes)
library(showtext)
library(ggsci)
library(ggspatial)
library(tigris)


options(tigris_use_cache = TRUE)
options(scipen = 999, digits = 1)

loadfonts(device = "win")
font_add_google("Montserrat", "montserrat")
showtext_auto()

`%out%` = Negate(`%in%`)    

load(here("data", "gcps_absm_geo.RData"))

gwin_bb <- getbb("Gwinnett")

# tlr <- c('#009392','#72aaa1','#b1c7b3','#f1eac8','#e5b9ad','#d98994','#d0587e')

tlr <- c( "#ECDFDF", "#D9BFBF", "#C69F9F", "#B38080", "#9F6060", 
          "#8C4040", "#792020", "#660000")

# Rounding
rnd <-  function(x, y) {
  round2 <- ifelse(x >= 0, round(x + 0.000000001, y),round(x - 0.000000001, y))
  return(round2)
}


# Ensure unique breaks before using them in cut or mutate
if (exists("legend_breaks")) {
  legend_breaks <- unique(legend_breaks)
}


# Load SPatiall Data and set coordinates ------------------------------------------------------

es_absms_norm <- es_absms_norm |> st_transform(crs = 2240) |>   st_set_crs(2240)
ms_absms_norm <- ms_absms_norm |> st_transform(crs = 2240) |>   st_set_crs(2240)

gcps_outline <- st_as_sf(gcps_outline) |> st_transform(crs = 2240) |>   st_set_crs(2240)


ga_counties <- st_as_sf(counties(state = "13", cb = TRUE)) %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 2240)

gwin <- ga_counties |> filter(NAME == "Gwinnett") |>   st_transform(crs = 2240) |>   st_set_crs(2240)



ga_outline <- st_as_sf(states(cb = TRUE)) %>%
  filter(STUSPS == "GA") %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 2240) |> 
  st_set_crs(2240)


sysBounds <- st_as_sf(sysBounds) |> st_transform(crs = 2240)

ga_inset <- ggplot()+
  geom_sf(data = gwin , fill = "#CC5252", color = '#CC0000', lwd = 0.75, alpha = 0.65)+
  geom_sf(data = ga_counties , fill = NA, color = '#333333', lwd = 0.25) +
  theme(legend.position = F) +
  theme_void()

# ga_inset


# list 5 Metro Atlanta counties in study area

metro_5_co <- c('Fulton','DeKalb','Gwinnett','Cobb','Forsyth')
metro_fips <- c("13121","13089", "13135", "13067", "13117")

#School District FIPS codes
metro_districts <- c("1300120", "1300600", "1301290", "1301680", "1301740", "1302220",
                     "1302550", "1303510", "1302280")



# Load Road Data
gwin_roads <- roads("GA", "135")

gwin_interstates <- gwin_roads |> filter(RTTYP == "I")
gwin_roads_main <- gwin_roads |> filter(RTTYP == "M")
gwin_us_hwys <- gwin_roads |> filter(RTTYP == "U" & FULLNAME %out% c("US Hwy 29 Alt", "Old US Hwy 29 NW", "Old US Hwy 78 SW"))
gwin_st_hwys <- gwin_roads |> filter(RTTYP == "S")


# Highway Symbols

# Interstates

I_85 <- image_read("data/I-85.png")
I_985 <- image_read("data/I-985.png")

# US HWYs
US_23 <- image_read("data/US_23.png")
US_29 <- image_read("data/US_29.png")
US_78 <- image_read("data/US_78.png")


metroSysBounds <- sysBounds |> filter(geoid %in% metro_districts)
metroCountyBounds <- ga_counties |> filter(NAME %in% metro_5_co)

buford <- sysBounds |> filter(sys_nms == "Buford City Schools") |> st_as_sf()
buford <- cbind(buford, st_coordinates(st_centroid(buford)))

buford_cty <- st_difference(gcps_outline,gwin)


clusters <- cbind(hs_absms |> select(cluster), st_coordinates(st_centroid(hs_absms)))

gcps_coord  <- st_coordinates(st_as_sf(gcps_outline))

# Create Maps ---------------------------------------------------------------------------------


es_absm_map <-
  es_absms_norm |>
  select(sch_id, school, frpl:working_class) |>
  pivot_longer(
    cols = -c(sch_id, school, geometry),
    names_to = 'absm',
    values_to = 'std_value'
  ) |> 
  group_by(absm) |> 
  nest()


# Add Legend Breaks

es_absm_map <- es_absm_map |> 
  mutate(
    absm_label = map2(
      data, 
      absm, 
      ~ recode(.y, !!!absm_labs))
  )


credits <-
  tibble(
    label = c(
      "<span style='font-size:10pt'><strong>GCPS Office of Research & Evaluation</strong>, March 2022<br>
      <b>Data Sources:</b><br>GCPS Administrative Data<br>
      U.S. Census Bureau 2019 TIGER/Line Shapefiles</span>"
    )
  ) %>%
  ggplot() +
  geom_richtext(
    aes(x = 1,
        y = 0,
        label = label),
    colour = "#333333",
    hjust = 0,
    vjust = 0,
    fill = NA,
    label.color = NA,
    show.legend = FALSE
  ) +
  theme_void(base_family = "Montserrat")

es_map <-
  ggplot() +
  geom_sf(data = hs_absms, fill = NA, color = '#303030', lwd = 0.65) +
  geom_sf(data = buford, fill = "#2f2f2f", color = '#2f2f2f', lwd = 0.65) +
  geom_sf(data = gcps_outline, fill = NA, color = '#FF4500', size = 1.2) +  # County boundary (Orange-Red)
  geom_sf(data = gwin_roads, color = "#C0C0C0", size = 0.1, alpha = 0.3) +  # Minor Roads (Silver)
  geom_sf(data = gwin_roads_main, color = "#00FFFF", size = 0.6, alpha = 0.7) +  # State Highways (Bright Cyan)
  geom_sf(data = gwin_us_hwys, color = "#32CD32", size = 1.5, alpha = 0.8) +  # U.S. Highways (Lime Green)
  geom_sf(data = gwin_interstates, color = "#FF00FF", size = 2.5, alpha = 0.9) +  # Interstates (Neon Magenta)
  geom_sf(data = gwin_interstates |> slice(1, 2), color = "#800080", size = 0.9, linetype = "dashed") +  # Dashed Interstates (Purple)
  coord_sf(crs = 2240,expand = TRUE) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#2f2f2f", color = NA),
    plot.title = element_text(size = 44, family = "Montserrat", face = "bold", colour = "#F0F0F0"),
    plot.subtitle = element_text(size = 40, family = "Montserrat", colour = "#F0F0F0")
  ) 
  
gc(full = TRUE)

es_absm_map <-
  ggdraw() +
  draw_plot(es_map) +
  draw_image(I_85, x = 0.372, y = 0.49, width = 0.03, height = 0.03,hjust = 0) +
  draw_image(I_985, x = 0.595, y = 0.75, width = 0.03, height = 0.03,hjust = 0) +
  draw_image(US_23, x = 0.31, y = 0.575, width = 0.02, height = 0.02) +
  draw_image(US_29, x = 0.52, y = 0.452, width = 0.02, height = 0.02) +
  draw_image(US_78, x = 0.52575, y = 0.29575, width = 0.02, height = 0.02) +
  draw_plot(credits, x = 0.5, y = -0.135, width = 0.5, height = 0.3) +
  plot_annotation(
    title = "Gwinnett County Road Network",
    subtitle = "Within the Gwinnett County Public School District Boundary",
    theme = theme(
      plot.title = element_text(
        size = 44,
        family = "Montserrat",
        face = "bold",
        colour = "#303030",
        hjust = 0.025, 
        vjust = 0.1
      ),
      plot.subtitle = element_text(size = 40, family = "Montserrat",colour = "#303030",hjust = 0.025, vjust = 0.1),
      plot.caption = element_text(colour = "#303030")
    )
  ) &
  theme(text = element_text(family = 'Montserrat'),
        plot.background = element_rect(fill = "#FFFFFF" , color = NA),
        panel.border = element_blank())


gc(full = TRUE)


# es_absm_map

ggsave(plot = es_absm_map,
       filename = "day2_lines.png",
       type = "cairo",
       bg = "#F0F0F0",
       width = 17,
       height = 11,
       units = "in",
       dpi = 150)
















































.# ggsave(es_absm_map,
#        filename = "output/maps/gcps_es_frm.pdf",
#        device = cairo_pdf,
#        # scale = 0.65,
#        width = 22,
#        height = 28,
#        units = "in",
#        dpi = 320)

