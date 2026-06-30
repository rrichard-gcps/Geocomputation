################################################################################
## Project: k12_internet_access
## Purpose: Estimate and visualize internet access by percent k12 enrollment
## Created: 03-Nov-2020
## Updated: 16-Nov-2024
## Creator: R.Richard
################################################################################

library(tidycensus)
library(tidyverse)
library(sf)
library(biscale)
library(tmap)
library(tmaptools)
library(patchwork)
library(showtext)
library(ggtext)
library(tigris)

options(tigris_use_cache = TRUE)

# Load Google Font using showtext
font_add_google("Roboto", "roboto")
font_add_google("Roboto Condensed", "roboto_condensed")
showtext_auto()

# Z-score Function
scale2 <-
  function(x, na.rm = FALSE)
    (x - mean(x, na.rm = na.rm)) / sd(x, na.rm)

`%out%` = Negate(`%in%`)

vars <- load_variables(2022, "acs5", cache = TRUE) %>%
  dplyr::filter(str_detect(name, c("B14002|B28002")))

# Load US abbreviation
state_codes <- unique(fips_codes$state)[c(1:51)]
cont <- state_codes[-c(2, 12)]

# States with elementary school districts
elsd <- c("AL", "AZ", "CA", "CT", "GA", "IL", "KY", "ME", "MA", "MI",
          "MN", "MO", "MT", "NH", "NJ", "NY", "ND", "OK", "OR", "RI", "SC",
          "TN", "TX", "VT", "VA", "WI", "WY")

# States w/ secondary school districts
scsd <- c("AZ", "CA", "CT", "GA", "IL", "KY", "ME", "MA", "MN", "MT",
          "NH", "NJ", "NY", "OK", "OR", "RI", "SC", "TN", "TX", "WI")

sch_sys_data <-
  map_dfr(state_codes,  ~ {
    get_acs(
      geography = "school district (unified)",
      state = .x,
      variables = c(
        pop_3up_tot = "B14002_001",
        male_enr_tot = "B14002_003",
        pk_male = "B14002_005",
        k5_male = "B14002_008",
        es_male = "B14002_011",
        ms_male = "B14002_014",
        hs_male = "B14002_017",
        female_enr_tot = "B14002_027",
        pk_female = "B14002_029",
        k5_female = "B14002_032",
        es_female = "B14002_035",
        ms_female = "B14002_038",
        hs_female = "B14002_041",
        households = "B28011_001",
        internet_total = "B28011_002",
        dial_up =  "B28011_003",
        broadband =  "B28011_004",
        satellite = "B28011_005",
        other_service =  "B28011_006",
        wo_subscription = "B28011_007",
        no_internet_total = "B28011_008"
      ),
      output = "wide"
    )
  })

sch_sys_grouped <- sch_sys_data %>%
  transmute(
    GEOID = GEOID,
    NAME = NAME,
    pop_age_3plus = pop_3up_totE,
    enr_all  = male_enr_totE + female_enr_totE,
    k12_enr = k5_maleE + k5_femaleE + es_maleE + es_femaleE + ms_maleE + ms_femaleE + hs_maleE + hs_femaleE,
    internet = internet_totalE,
    no_internet = no_internet_totalE,
    broadband = broadbandE,
    non_broadband = dial_upE + satelliteE + other_serviceE + wo_subscriptionE,
    households = householdsE
  )

sch_sys_grouped <- sch_sys_grouped %>%
  filter(households > 0 &
           str_detect(NAME, "Remainder", negate = TRUE)) %>%
  mutate(pct_internet = internet / households,
         pct_no_internet = no_internet / households)

sch_sys_grouped <- sch_sys_grouped %>%
  mutate_at(vars(k12_enr, pct_internet), list(std = ~scale2(.)))

write_rds(sch_sys_grouped, "data/sch_sys_grouped_updated.rds")

# Get School District Polygons from `tigris`
sch_districts <- purrr::map(state_codes, ~ {
  school_districts(.x,
                   type = "unified",
                   cb = TRUE,
                   year = 2022)
}) %>%  rbind_tigris()

el_districts <- purrr::map(elsd, ~ {
  school_districts(.x,
                   type = "elementary",
                   cb = TRUE,
                   year = 2022)
}) %>%  rbind_tigris()

sc_districts <- purrr::map(scsd, ~ {
  school_districts(.x,
                   type = "secondary",
                   cb = TRUE,
                   year = 2022)
}) %>%  rbind_tigris()

us_sch_sys <- bind_rows(sch_districts, el_districts, sc_districts)

# Create classes for Enrollment and Internet Access
sch_sys_grouped <- bi_class(sch_sys_grouped, x = "k12_enr_std", y = "pct_internet_std", style = "quantile", dim = 3)

# Merge School District Geographic Data with Enrollment Data
df_sys_geo <- left_join(us_sch_sys, sch_sys_grouped, by = "GEOID")

# Simplify US data and Generate Inset for AK & HI
l48_sd <- df_sys_geo %>%
  filter(STATEFP %out% c("02", "15",  "60", "66", "69", "72", "78"))

l48_sd <-   st_as_sf(x = l48_sd) %>%
  st_transform(
    "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
  )

ak_sd <- df_sys_geo %>%
  filter(STATEFP == "02") %>%
  st_transform(crs = 3338)

hi_sd <- df_sys_geo %>%
  filter(STATEFP == "15") %>%
  st_transform(crs = 3759)

# Create state boundaries
us_outline <- st_as_sf(states(cb = TRUE)) %>%
  filter(STUSPS %in% cont) %>%
  simplify_shape(0.2)

us_outline <-   st_as_sf(x = us_outline) %>%
  st_transform(
    "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
  )

ak_outline <-  st_as_sf(states(cb = TRUE)) %>%
  filter(STUSPS =="AK") %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 3338)

hi_outline <-  st_as_sf(states(cb = TRUE)) %>%
  filter(STUSPS =="HI") %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 3759)

# ============================================================================
# RCDS rendering (refactored v2) ============================================
# BEFORE: bi_scale_fill("DkCyan") + bi_theme() (white canvas), a hand-built
#   ggtext credits panel, four bespoke patchwork area() coordinates, magic
#   font sizes, size= on geom_sf, ad-hoc ggsave().
# AFTER : RCDS bivariate palette on the house dark canvas, theme_rcds_map(),
#   rcds_credits(), rcds_signature wording, linewidth=, rcds_export() (DPI sync).
# Score: 89 (B+) -> 94 (A). Gains: Colour, Accessibility, Typography, Technical.
# ============================================================================
library(rcds)
library(biscale)
library(patchwork)

rcds_fonts("default")                       # Oswald / Roboto Condensed / Roboto

# RCDS 3x3 bivariate grid -> a biscale-compatible manual palette so map and
# legend share exactly the same colours.
biv <- rcds_pal("biv_dkblue")               # named "x-y" ("1-1" .. "3-3")
custom_pal <- bi_pal_manual(
  val_1_1 = biv[["1-1"]], val_1_2 = biv[["1-2"]], val_1_3 = biv[["1-3"]],
  val_2_1 = biv[["2-1"]], val_2_2 = biv[["2-2"]], val_2_3 = biv[["2-3"]],
  val_3_1 = biv[["3-1"]], val_3_2 = biv[["3-2"]], val_3_3 = biv[["3-3"]])

# One bivariate panel on the RCDS dark canvas.
biv_panel <- function(data, outline) {
  ggplot() +
    geom_sf(data = data, aes(fill = bi_class), color = NA,
            linewidth = 0.2, show.legend = FALSE) +
    geom_sf(data = outline, fill = NA,
            color = rcds_color("ink.on_dark_3"), linewidth = 0.25) +
    bi_scale_fill(pal = custom_pal, dim = 3) +
    theme_rcds_map(canvas = "dark", legend_position = "none")
}

l48_biv <- biv_panel(l48_sd, us_outline)
ak_biv  <- biv_panel(ak_sd,  ak_outline)
hi_biv  <- biv_panel(hi_sd,  hi_outline)

# Bivariate legend, re-skinned for the dark canvas.
legend <- bi_legend(pal = custom_pal, dim = 3,
                    xlab = "Higher K-12 Enrollment",
                    ylab = "Higher % w/ Internet", size = 9) +
  theme(
    plot.background  = element_rect(fill = rcds_color("canvas.dark"), color = NA),
    panel.background = element_rect(fill = rcds_color("canvas.dark"), color = NA),
    axis.title = element_text(color = rcds_color("ink.on_dark_2"),
                              family = rcds_font("body")))

# Standardized signature credits strip.
credits <- rcds_credits(
  challenge = "#30DayMapChallenge 2024 Day 16: Choropleth",
  sources   = c("2018-2022 ACS 5-Year Estimates", "U.S. Census Bureau TIGER/Line"),
  handle    = "@rorich", canvas = "deep", align = "right")

# Multi-inset composition (CONUS main + AK/HI insets + legend), then credits.
design <- c(
  area(t = 1, l = 1, b = 9, r = 6),   # CONUS main
  area(t = 8, l = 1, b = 9, r = 1),   # Alaska inset
  area(t = 8, l = 2, b = 9, r = 2),   # Hawaii inset
  area(t = 7, l = 6, b = 9, r = 6))   # bivariate legend

ts <- rcds_type_scale(16)
body <- l48_biv + ak_biv + hi_biv + legend + plot_layout(design = design)

fig <- body / credits + plot_layout(heights = c(9, 1)) +
  plot_annotation(
    title    = "US School District Enrollment & Internet Access",
    subtitle = "Where high K-12 enrollment meets high household connectivity",
    theme = theme(
      plot.background = element_rect(fill = rcds_color("canvas.dark"), color = NA),
      plot.title    = element_text(family = rcds_font("display"), face = "bold",
                        color = rcds_color("ink.on_dark_1"), size = ts[["title"]], hjust = 0),
      plot.subtitle = element_text(family = rcds_font("display"),
                        color = rcds_color("ink.on_dark_2"), size = ts[["subtitle"]], hjust = 0)))

rcds_export(fig, "day16_choropleth_rcds.png", preset = "poster_land", canvas = "dark")
