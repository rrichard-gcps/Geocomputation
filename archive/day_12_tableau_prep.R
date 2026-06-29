# Load essential libraries
library(tidyverse)
library(sf)
library(tigris)
library(janitor)

# Load Georgia school districts geometry
options(tigris_use_cache = TRUE)
crs_value <- 4326  # WGS84 preferred for Tableau

ga_school_districts <- school_districts(state = "GA", class = "sf") %>% 
  clean_names() %>%
  st_transform(crs = crs_value) %>%
  mutate(nces_district_id = sprintf("%07i", as.integer(geoid)))

# Load supplementary data
ga_sys_nces <- read_csv("ga_systems_nces.csv") |> 
  clean_names() |> 
  mutate(system_id = str_trim(str_remove(state_district_id, "GA-"), side = 'both'))

ga_dc <- read_csv('downloads/georgia_direct_cert_system.csv') |> 
  clean_names() |> 
  mutate(
    system_id = sprintf("%03i", as.integer(system_id)),
    school_year = if_else(is.na(fiscal_year), 2014, fiscal_year)
  ) |> 
  select(-fiscal_year)

# Join direct certification data with NCES system info
df_ga_dc <- ga_dc |> 
  left_join(ga_sys_nces, by = "system_id") |> 
  select(nces_district_id, system_name, school_year, direct_cert_perc)

# Define Metro Atlanta District IDs explicitly
metro_district_ids <- c(
  "1300120", "1300290", "1300510", "1300840", "1300870", "1300900", "1301110", "1301230",
  "1301290", "1301500", "1301680", "1301740", "1301860", "1302130", "1302220", "1302280",
  "1302310", "1302550", "1302610", "1302820", "1303510", "1303930", "1304020", "1304410",
  "1302520", "1305390", "1300330", "1300600", "1304540"
)

# Filter Metro Atlanta districts
df_metro_dc <- df_ga_dc |> 
  filter(nces_district_id %in% metro_district_ids) |> 
  mutate(nces_district_id = sprintf("%07i", as.integer(nces_district_id)))


# Spatial join and ensure valid geometry
metro_dc_geo <- ga_school_districts |> 
  inner_join(df_metro_dc, by = "nces_district_id") |> 
  filter(!is.na(direct_cert_perc)) |> 
  st_make_valid()

# Add certification classification
metro_dc_geo <- metro_dc_geo |> 
  mutate(
    cert_class = case_when(
      direct_cert_perc < 19.9 ~ "5.0 - 19.9",
      direct_cert_perc < 27.5 ~ "19.9 - 27.5",
      direct_cert_perc < 38.3 ~ "27.5 - 38.3",
      direct_cert_perc < 46.9 ~ "38.3 - 46.9",
      direct_cert_perc < 55.4 ~ "46.9 - 55.4",
      direct_cert_perc < 62.4 ~ "55.4 - 62.4",
      TRUE ~ "62.4+"
    )
  )

# Simplify geometry for better Tableau performance
metro_dc_geo_simplified <- st_simplify(metro_dc_geo, dTolerance = 0.001, preserveTopology = TRUE)

# Export simplified spatial data as GeoJSON for Tableau
st_write(metro_dc_geo_simplified, "metro_atlanta_direct_certification.geojson", driver = "GeoJSON", delete_dsn = TRUE)

st_write(sch_districts, "us_school_districts.geojson", driver = "GeoJSON", delete_dsn = TRUE)

