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

# Create Bivariate Map w/ `biscale`
l48_biv <- ggplot() +
  geom_sf(
    data = l48_sd,
    mapping = aes(fill = bi_class),
    color = NA,
    size = 0.2,
    show.legend = FALSE
  ) +
  geom_sf(data = us_outline,
          color = "#333333",
          fill = NA) +
  bi_scale_fill(pal = "DkCyan", dim = 3) +
  bi_theme()

ak_biv <- ggplot() +
  geom_sf(
    data = ak_sd,
    mapping = aes(fill = bi_class),
    color = NA,
    size = 0.2,
    show.legend = FALSE
  ) +
  geom_sf(data = ak_outline,
          color = "#333333",
          fill = NA) +
  bi_scale_fill(pal = "DkCyan", dim = 3) +
  theme_void()

hi_biv <- ggplot() +
  geom_sf(
    data = hi_sd,
    mapping = aes(fill = bi_class),
    color = NA,
    size = 0.21,
    show.legend = FALSE
  ) +
  geom_sf(data = hi_outline,
          color = "#333333",
          fill = NA) +
  bi_scale_fill(pal = "DkCyan", dim = 3) +
  theme_void()

legend <- bi_legend(pal = "DkCyan",
                    dim = 3,
                    xlab = "Higher K-12 Enrollment",
                    ylab = "Higher % With Internet Access",
                    size = 9)

# Enhanced credits section with improved styling (Top Right Position)
credits_text <- wrap_elements(
  ggplot() +
    theme_void() +
    geom_richtext(
      aes(
        x = 1, y = 1,
        label = "<span style='font-size:10pt; color:#FFFFFF;'><strong>#30DayMapChallenge 2024</strong> | <b>Day 16: Choropleth</b></span><br>
        <span style='font-size:9pt; color:#CFCFCF;'>Tools: R [ggplot2, patchwork, tidycensus, tigris]</span><br>
        <span style='font-size:9pt; color:#CFCFCF;'>Created By: <strong>Roland Richard</strong></span><br>
        <span style='font-size:9pt; color:#CFCFCF;'>Data Sources: U.S. Census Bureau</span>"
      ),
      family = "roboto",
      hjust = 1,
      vjust = 1,
      fill = "#121212",    # Added fill to stretch the background across the width
      label.color = NA
    ) +
    theme(
      panel.background = element_rect(fill = "#121212", color = NA),
      plot.margin = unit(c(1, 1, 1, 1), "pt")  # Corrected to use 'unit' to specify the length of margins
    )
)

# Combine map with legend and credits
layout <- c(
  area(t = 1, l = 1, b = 5, r = 5),
  area(t = 4, l = 1, b = 5, r = 1),
  area(t = 4, l = 1, b = 5, r = 2),
  area(t = 4, l = 5, b = 4, r = 5)
)

day16_plt <-
  l48_biv + ak_biv + hi_biv + legend + credits_text +
  plot_layout(design = layout) +
  plot_annotation(
    title = 'US School District Enrollment and Internet Access',
    subtitle = "#30DayMapChallenge Day16: Choropleth\n Created By Roland Richard (@rorich)",
    caption =
      "Data Sources:\n2018-2022 American Community Survey 5-year Estimates\nU.S. Census Bureau 2022 TIGER/Line Shapefiles",
    theme = theme(
      plot.title = element_text(
        size = 56,
        family = "roboto_condensed",
        face = "bold"
      ),
      plot.subtitle = element_text(size = 44, family = "roboto")
    )
  ) &
  theme(text = element_text('roboto', size = 20))



ggsave(day16_plt,
       filename = "day16_polygons_k12.png",
       type = "cairo",
       scale = 1,
       width = 18,
       height = 12,
       units = "in",
       dpi = 196)
