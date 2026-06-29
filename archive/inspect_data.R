################################################################################
## Quick data inspection to confirm column names for the new map
################################################################################

library(tidyverse)
library(sf)
library(rio)
library(here)
library(tigris)
library(janitor)

metro_es_zones <- read_sf("data/metro_es_sspi.gpkg")
load(here("data", "metro_boundaries.rdata"))

sys_dc <- import("2024_directly_certified_district.xls")
sysDC <- sys_dc |> clean_names() |> mutate(sys_id = sprintf("%03i", system_id))

ga_sch_systems <- school_districts(state = "13", type = "unified", cb = TRUE)

cat("==== ga_sch_systems columns ====\n")
print(colnames(ga_sch_systems))
cat("\n==== ga_sch_systems sample (Gwinnett/Atlanta/Henry) ====\n")
print(
  ga_sch_systems |>
    filter(GEOID %in% c("1302550", "1300120", "1302820")) |>
    st_drop_geometry()
)

cat("\n==== sysDC columns ====\n")
print(colnames(sysDC))
cat("\n==== sysDC sample ====\n")
print(head(sysDC))

cat("\n==== metro_es_zones columns ====\n")
print(colnames(metro_es_zones))

cat("\n==== metro_boundaries.rdata objects ====\n")
print(ls())

if (exists("dist_bounds")) {
  cat("\n==== dist_bounds columns ====\n")
  print(colnames(dist_bounds))
}
