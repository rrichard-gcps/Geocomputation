################################################################################
## Project: gcps_demog_maps
## Purpose: generate and export maps by school attendance zone
## Created: 04-Mar-2022
## Updated: 09-Mar-2022
## Creator: R.Richard
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
# library(tmap)
library(tmaptools)
library(patchwork)
library(cowplot)
library(extrafont)
library(extrafontdb)
library(ggtext)
library(tigris)
library(colorspace)
library(ggmap)
library(magick)
options(tigris_use_cache = TRUE)
options(scipen = 999, digits = 1)

loadfonts(device = "win")

`%out%` <- Negate(`%in%`)

load(here("data", "prep", "gcps_absm_geo.RData"))

gwin_bb <- getbb("Gwinnett")

# tlr <- c('#009392','#72aaa1','#b1c7b3','#f1eac8','#e5b9ad','#d98994','#d0587e')
# tlr <- c( "#ECDFDF", "#D9BFBF", "#C69F9F", "#B38080", "#9F6060", "#8C4040", "#792020", "#660000")
# c("#FFFAE2", "#FFC1AA", "#FA8A76", "#BE5545", "#A03C2F", "#832119", "#660000")
# tlr <-  c("#550000", "#722d26", "#8e524a", "#a97870", "#c29f99", "#dac7c4", "#f1f1f1")

tlr <- c(
  "#303030",
  "#6A6A6A",
  "#ABABAB",
  "#F1F1F1",
  "#DAACA5",
  "#BB695F",
  "#942020"
)

# div_cols <- c("#990033", "#FF6666", "#FF9999", "#FFFFFF", "#CCCCCC", "#999999", "#666666")

cont_cols <- c(
  "#790000",
  "#953728",
  "#af5f4e",
  "#c78677",
  "#dcada2",
  "#efd6d0",
  "#ffffff"
)
div_cols <- c(
  "#00393a",
  "#107a7a",
  "#58bebe",
  "#f5f5f5",
  "#f1958d",
  "#b34947",
  "#66000e"
)

rdylbu <- c(
  '#00429d',
  '#5681b9',
  '#93c4d2',
  '#ffffe0',
  '#ffa59e',
  '#dd4c65',
  '#93003a'
)

#FFCCCC

# Rounding
rnd <- function(x, y) {
  round2 <- ifelse(x >= 0, round(x + 0.000000001, y), round(x - 0.000000001, y))
  return(round2)
}


# Load SPatiall Data and set coordinates ------------------------------------------------------

es_absms_norm <- es_absms_norm |> st_transform(crs = 2240) |> st_set_crs(2240)
ms_absms_norm <- ms_absms_norm |> st_transform(crs = 2240) |> st_set_crs(2240)

gcps_outline <- st_as_sf(gcps_outline) |>
  st_transform(crs = 2240) |>
  st_set_crs(2240)


ga_counties <- st_as_sf(counties(state = "13", cb = TRUE)) %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 2240)

gwin <- ga_counties |>
  filter(NAME == "Gwinnett") |>
  st_transform(crs = 2240) |>
  st_set_crs(2240)


ga_outline <- st_as_sf(states(cb = TRUE)) %>%
  filter(STUSPS == "GA") %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 2240) |>
  st_set_crs(2240)


sysBounds <- st_as_sf(sysBounds) |> st_transform(crs = 2240)

ga_inset <- ggplot() +
  geom_sf(
    data = gwin,
    fill = "#CC5252",
    color = '#CC0000',
    lwd = 0.75,
    alpha = 0.65
  ) +
  geom_sf(data = ga_counties, fill = NA, color = '#333333', lwd = 0.25) +
  theme(legend.position = F) +
  theme_void()

ga_inset


# list 5 Metro Atlanta counties in study area

metro_5_co <- c('Fulton', 'DeKalb', 'Gwinnett', 'Cobb', 'Forsyth')
metro_fips <- c("13121", "13089", "13135", "13067", "13117")

#School District FIPS codes
metro_districts <- c(
  "1300120",
  "1300600",
  "1301290",
  "1301680",
  "1301740",
  "1302220",
  "1302550",
  "1303510",
  "1302280"
)


# Load Road Data
gwin_roads <- roads("GA", "135")

gwin_interstates <- gwin_roads |> filter(RTTYP == "I")
gwin_roads_main <- gwin_roads |> filter(RTTYP == "M")
gwin_us_hwys <- gwin_roads |>
  filter(
    RTTYP == "U" &
      FULLNAME %out% c("US Hwy 29 Alt", "Old US Hwy 29 NW", "Old US Hwy 78 SW")
  )
gwin_st_hwys <- gwin_roads |> filter(RTTYP == "S")


# Highway Symbols

# Interstates

I_85 <- image_read("data/I-85.png")
I_985 <- image_read("data/I-985.png")

# US HWYs
US_23 <- image_read("data/US_23.png")
US_29 <- image_read("data/US_29.png")
US_78 <- image_read("data/US_78.png")


# ABSM LABELS

absm_labs <- c(
  frpl = "Free/Reduced Priced Meals",
  free = "Free Meal Eligibility",
  reduced = "Reduced Meal Eligibility",
  ell = "English Learners",
  hhm = "Homeless/Highly Mobile",
  sped = "Special Education",
  riskrate = "Attendance Risk",
  sch_diversity = "School Diversity",
  gifted = "Gifted Participation",
  attrate = "Attendance Rate",
  grd3_la_pd = "Grade 3 ELA Performance",
  grd4_la_pd = "Grade 4 ELA Performance",
  grd5_la_pd = "Grade 5 ELA Performance",
  grd3_ma_pd = "Grade 3 Math Performance",
  grd4_ma_pd = "Grade 4 Math Performance",
  grd5_ma_pd = "Grade 5 Math Performance",
  tsr = "Teacher-Student Relationships",
  fsl = "Family Support For Learning",
  staff_score = "Staff Survey Total Score",
  birth_rate = "Birth Rate",
  crowded = "Crowded Homes",
  dropout = "Dropout",
  exp_homes = "Expensive Homes",
  gini = "Gini Index",
  gt30com = "Commute Time of 30 Minutes or Greater",
  high_ed = "College Degree or Higher",
  lep_hh = "Limited English Proficiency Households",
  low_ed = "High School Diploma or Lower",
  mhhinc = "Median Household Income",
  mobile = "Mobility",
  nbh_diversity = "Neighborhood Diversity",
  no_internet = "No Internet Service",
  noins = "No Health Insurance",
  pct_renter = "Renter Occupied Homes",
  pop_dens = "Population Density",
  pov_u18 = "Child Poverty",
  poverty = "Poverty Rate",
  resp_rate = "Census Response Rate",
  snap = "SNAP Eligibility",
  sphh = "Single-Parent Households",
  totpop = "Total Population",
  unemp = "Unemployment",
  vacant = "Vacant Homes",
  working_class = "Adults in Working Class Occupations"
)


metroSysBounds <- sysBounds |> filter(geoid %in% metro_districts)
metroCountyBounds <- ga_counties |> filter(NAME %in% metro_5_co)

buford <- sysBounds |> filter(sys_nms == "Buford City Schools")
buford <- cbind(buford, st_coordinates(st_centroid(buford)))

buford_cty <- st_difference(gcps_outline, gwin)


clusters <- cbind(
  hs_absms |> select(cluster),
  st_coordinates(st_centroid(hs_absms))
)

gcps_coord <- st_coordinates(st_as_sf(gcps_outline))

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
# Add Legend Breaks♣
es_absm_map <- es_absm_map |>
  mutate(
    absm_label = map2(data, absm, ~ recode(.y, !!!absm_labs)),
    legend_breaks = map2(
      data,
      absm,
      ~ levels(
        cut(
          rnd(.x$std_value, 4),
          breaks = c(quantile(
            rnd(.x$std_value, 4),
            probs = seq(0, 1, length = 8)
          )),
          include.lowest = T,
          dig.lab =
        )
      )
    )
  ) |>
  mutate(filename = glue('output/maps/es_{absm}.pdf'))

es_absm_map <- es_absm_map |>
  mutate(
    legend_break_labs = map2(
      absm,
      legend_breaks,
      ~ str_replace(
        str_remove_all(.y, "\\(|\\]|\\["),
        ",",
        "-"
      )
    )
  )


es_absm_map <- es_absm_map |>
  mutate(
    legend_break_labs = map2(
      absm,
      legend_break_labs,
      ~ str_replace(.y, "0-", "0.00-")
    )
  ) |>
  mutate(
    legend_break_labs = map2(
      absm,
      legend_break_labs,
      ~ str_replace(.y, "-1", "-1.00")
    )
  )


es_absm_map <- es_absm_map |>
  mutate(
    legend_break_labs = map2(
      absm_label,
      legend_break_labs,
      ~ c(
        paste0(.y[[1]][[1]], '\n(Very Low)'),
        .y[[2]][[1]],
        .y[[3]][[1]],
        .y[[4]][[1]],
        .y[[5]][[1]],
        .y[[6]][[1]],
        paste0(.y[[7]][[1]], '\n(Very High)')
      )
    )
  )

credits <-
  tibble(
    label = c(
      "<span style='font-size:10pt'><strong>GCPS Office of Research & Evaluation</strong>, March 2022<br>
      <b>Data Sources:</b><br>GCPS Administrative Data<br>
      U.S. Census Bureau 2019 TIGER/Line Shapefiles<br>
      American Community Survey 2015-2019 5-Year Estimates</span>"
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
  theme_void(base_family = "Roboto Condensed")


# Make Maps

es_absm_map <- es_absm_map |>
  mutate(
    absm_map = map2(
      data,
      absm,
      ~ ggplot() +
        geom_sf(
          data = .x,
          aes(
            fill = cut(
              std_value,
              breaks = c(quantile(std_value, probs = seq(0, 1, length = 8))),
              include.lowest = T
            )
          ),
          color = NA,
          lwd = 0.1,
          alpha = 0.7,
          show.legend = "polygon",
          inherit.aes = FALSE
        ) +
        geom_sf(data = hs_absms, fill = NA, color = '#303030', lwd = 0.65) +
        geom_sf(
          data = st_as_sf(gcps_outline),
          fill = NA,
          color = '#333333',
          lwd = 1
        ) +
        geom_sf(
          data = gwin_roads_main,
          inherit.aes = FALSE,
          color = "#666666",
          size = .1,
          alpha = .4
        ) +
        geom_sf(
          data = gwin_us_hwys,
          inherit.aes = FALSE,
          color = "#666666",
          size = 1.25,
          alpha = .6
        ) +
        geom_sf(
          data = gwin_interstates,
          inherit.aes = FALSE,
          color = "#666666",
          size = 2.5,
          alpha = .8
        ) +
        geom_sf(
          data = gwin_interstates |> slice(1, 2),
          inherit.aes = FALSE,
          color = "#000000",
          size = 0.5,
          linetype = 6
        ) +
        geom_sf_text(
          data = clusters,
          aes(x = X, y = Y, label = str_wrap(cluster, "\n")),
          # label.padding = unit(0.35, "mm"),
          fontface = "bold",
          family = "Roboto Condensed",
          size = 8,
          color = "#000000",
          nudge_y = if_else(clusters$cluster == "Meadowcreek", -5000, 0),
          nudge_x = if_else(clusters$cluster == "Meadowcreek", -6000, 0)
        ) +
        geom_sf_text(
          data = buford,
          aes(x = X, y = Y, label = str_wrap(sys_nms, "\n")),
          fontface = "bold",
          family = "Roboto Condensed",
          size = 5,
          color = "#666666"
        ) +
        scale_fill_manual(
          name = paste0(.data$absm_label, " ", "(Standardized): "),
          values = rev(cont_cols),
          labels = unlist(.data$legend_break_labs),
          guide = guide_legend(ncol = 7, label.position = "bottom")
        ) +
        coord_sf(crs = 2240, expand = TRUE) +
        theme_void() +
        theme(
          legend.position = c(0.25, -0.015),
          legend.text = element_text(size = 18),
          legend.title = element_text(
            face = "bold",
            vjust = 1,
            family = "Roboto Condensed",
            size = 20
          )
        ) +
        ggspatial::annotation_north_arrow(
          location = "br",
          which_north = "true",
          height = unit(3, "cm"),
          width = unit(3, "cm"),
          pad_x = unit(0.4, "in"),
          pad_y = unit(0.4, "in"),
          style = ggspatial::north_arrow_fancy_orienteering()
        )
    )
  )


# annotate with cowplot -----------------------------------------------------------------------------

gc(full = TRUE)

es_absm_map <- es_absm_map |>
  mutate(
    absm_map_fnl = map2(
      absm_map,
      absm_label,
      ~ ggdraw() +
        draw_plot(.x) +
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

        draw_image(US_23, x = 0.31, y = 0.575, width = 0.02, height = 0.02) +
        draw_image(US_29, x = 0.52, y = 0.452, width = 0.02, height = 0.02) +
        draw_image(
          US_78,
          x = 0.52575,
          y = 0.29575,
          width = 0.02,
          height = 0.02
        ) +
        draw_plot(credits, x = 0.5, y = -0.135, width = 0.5, height = 0.3) +
        plot_annotation(
          title = glue('{.y} by Elementary School'),
          subtitle = "Gwinnett County Public Schools Attendance Zones, School Year 2020-21",
          theme = theme(
            plot.title = element_text(
              size = 44,
              family = "Roboto Condensed",
              face = "bold",
              colour = "#303030",
              hjust = 0,
              vjust = 0.1
            ),
            plot.subtitle = element_text(
              size = 40,
              family = "Roboto Condensed",
              colour = "#303030",
              hjust = 0,
              vjust = 0.1
            ),
            plot.caption = element_text(colour = "#303030")
          )
        ) &
        theme(
          text = element_text(family = 'Roboto Condensed'),
          plot.background = element_rect(fill = "#FFFFFF", color = NA),
          panel.border = element_blank()
        )
    )
  )


# walk2(
#   .x = es_absm_map$absm_map_fnl,
#   .y = es_absm_map$filename,
#   ~ ggsave(
#     filename = .y[1],
#     plot = .x,
#     device = cairo_pdf,
#     width = 22,
#     height = 28,
#     units = "in",
#     dpi = 320
#   )
# )

ggsave(
  es_absm_map$absm_map_fnl[[2]],
  filename = "map.pdf",
  device = cairo_pdf,
  # scale = 0.65,
  width = 22,
  height = 28,
  units = "in",
  dpi = 320
)

#
# ggsave(es_absm_map,
#        filename = "output/maps/gcps_es_frm.pdf",
#        device = cairo_pdf,
#        # scale = 0.65,
#        width = 22,
#        height = 28,
#        units = "in",
#        dpi = 320)
