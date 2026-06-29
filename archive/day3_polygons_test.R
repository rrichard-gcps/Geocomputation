################################################################################
## Project: day3_polygons
## Purpose: 
## Created: 
## Updated: 
## Creator: 
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

# Load Data ---------------------------------------------------------------    

metro_es_zones <- read_sf("data/metro_es_sspi.gpkg")
metro_20_bounds <- read_sf("data/metro_20_counties.gpkg")
load(here("data","metro_boundaries.rdata"))

sys_dc <- import("2024_directly_certified_district.xls")
sch_dc <- import("2024_directly_certified_school.xls")

ga_sch_systems <- school_districts(state = "13", type = "unified", cb = TRUE)

state_ids <- metro_es_zones |>
  select(nces_sys_id, sys_id, orig_state_id) |>
  distinct(.keep_all = F) |>
  st_drop_geometry()


metro_ids <- state_ids |> filter(nces_sys_id %in% c(
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
)) |> distinct(nces_sys_id, .keep_all = T)

metro_systems <- ga_sch_systems |> filter(
  GEOID %in% c(
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


metro_systems <- metro_systems |> right_join(metro_ids, by = join_by(GEOID == nces_sys_id ))



schoolDC <- sch_dc |> clean_names() |> 
  mutate(orig_state_id = glue('GA-{system_id}-{sprintf("%04i",school_id)}'))

sysDC <- sys_dc |> clean_names() |> mutate(sys_id = sprintf("%03i", system_id))

metro_es <-   metro_es_zones |> 
  select(nces_sch_id:cluster) |>
  st_drop_geometry() |> 
  distinct(.keep_all = T)



dfGeo <- metro_es_zones %>% left_join(schoolDC, by = 'orig_state_id') 

dfGeo <- dfGeo |> filter(!is.na(direct_cert_perc))

dfGeoSys <- metro_systems |> left_join(sysDC,by = join_by(sys_id == sys_id))

# for inset map
es_bb <- st_as_sfc(st_bbox(dfGeo))


# cut(
#   dfDiversity$Segregation,
#   breaks = c(quantile(dfDiversity$Segregation, probs = seq(0, 1, length = 8))),
#   include.lowest = T
# )

tlr <- c('#009392','#72aaa1','#b1c7b3','#f1eac8','#e5b9ad','#d98994','#d0587e')
clr <- c("#0e5a73", "#29718c", "#4988a1", "#709eb1", "#9cb2bc", "#c7c7c7", "#acb0a0", "#939b77", "#7a8554", "#646e36", "#4e581f")

ga_counties <- st_as_sf(counties(state = "13", cb = TRUE)) %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 2240)

ga_outline <- st_as_sf(states(cb = TRUE)) %>%
  filter(STUSPS == "GA") %>%
  simplify_shape(0.2) %>%
  st_transform(crs = 2240)


ga_inset <- ggplot() +
  # geom_sf(data = dfGeoSys , fill = "#d98994", color = '#d0587e', lwd = 0.75)+
  geom_sf(
    data = dfGeoSys |> filter(!is.na(direct_cert_perc)),
    aes(fill = cut(
      direct_cert_perc,
      breaks = c(quantile(
        direct_cert_perc,
        probs = seq(0, 1, length = 10),
        na.rm = T
      )),
      include.lowest = T
    )),
    color = NA,
    show.legend = F
  ) +
  scale_fill_manual(name = "Mobility Rate:", values = c(clr))
geom_sf(
  data = ga_counties ,
  fill = NA,
  color = '#333333',
  lwd = 0.25
) +
  theme(legend.position = F) +
  theme_void()

ga_inset


