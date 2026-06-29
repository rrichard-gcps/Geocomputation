# Load required libraries
library(tidyverse)     # For data wrangling and visualization
library(ipumsr)        # For accessing IPUMS PUMS microdata
library(tidycensus)    # For accessing ACS tract-level data
library(survey)        # For weighted analysis of survey data
library(sf)            # For spatial data analysis
library(tmap)          # For mapping
library(knitr)         # For reporting

# Set your Census API Key (only needed for tidycensus)
# census_api_key("your_census_api_key_here", install = TRUE, overwrite = TRUE)

# Choose data source: 'ipums' or 'tidycensus'
data_source <- 'ipums'  # Change to 'tidycensus' if you want to use tidycensus

# ----------------------------
# 1. Extract Data from IPUMS PUMS (If selected)
# ----------------------------
if (data_source == 'ipums') {
  
  # Load IPUMS PUMS Data (Download PUMS extract from https://usa.ipums.org/usa/)
  ddi <- read_ipums_ddi("path/to/your/acs_pums.xml")
  pums <- read_ipums_micro(ddi)
  
  # Filter Foreign-born, Non-citizens likely to be unauthorized
  unauthorized <- pums %>%
    filter(NATIVITY == 2, CITIZEN != 1) %>%  # Foreign-born, not US citizen
    mutate(
      unauthorized_likely = case_when(
        # Apply logical filters to exclude lawful populations
        YEAR == 2022 & YEAR_OF_ENTRY >= 2000 & 
          COUNTRY %in% c("MEXICO", "GUATEMALA", "HONDURAS", "EL SALVADOR") ~ 1,
        TRUE ~ 0
      )
    )
  
  # Create a survey design object for weighted estimation
  survey_design <- svydesign(ids = ~1, data = unauthorized, weights = ~PERWT)
  
  # Estimate the number of unauthorized immigrants by PUMA
  unauthorized_estimates <- svyby(
    ~unauthorized_likely, ~PUMA, survey_design, svytotal
  )
  
  # Rename columns for clarity
  unauthorized_estimates <- unauthorized_estimates %>%
    rename(unauthorized_population = unauthorized_likely) %>%
    mutate(PUMA = as.character(PUMA))
  
  # Display a preview of the estimates
  kable(head(unauthorized_estimates))
}

# ----------------------------
# 2. Extract Data from tidycensus (If selected)
# ----------------------------
if (data_source == 'tidycensus') {
  
  # Variables to pull from ACS 5-Year Estimates
  variables <- c(
    "B05001_006" = "Foreign-born, Not a U.S. Citizen",
    "B05001_002" = "Total Foreign-born Population"
  )
  
  # Get ACS data for census tracts in a specific state (change "state = 'GA'" to desired state)
  unauthorized_tracts <- get_acs(
    geography = "tract",
    variables = variables,
    year = 2022, 
    state = "GA", 
    survey = "acs5", 
    output = "wide", 
    geometry = TRUE
  )
  
  # Calculate share of likely unauthorized immigrants
  unauthorized_tracts <- unauthorized_tracts %>%
    mutate(
      unauthorized_population = B05001_006E,  # Foreign-born, not a US citizen
      total_foreign_born = B05001_002E,       # Total foreign-born population
      percent_unauthorized = unauthorized_population / total_foreign_born * 100
    ) %>%
    select(GEOID, NAME, unauthorized_population, total_foreign_born, percent_unauthorized, geometry)
  
  # Display a preview of the data
  kable(head(unauthorized_tracts))
}

# ----------------------------
# 3. Merge Data with Geography for Mapping (Optional)
# ----------------------------

if (data_source == 'ipums') {
  
  # Download PUMA shapefiles (replace with path to your shapefile)
  puma_shapefile <- st_read("path/to/puma_shapefile.shp")
  
  # Merge unauthorized population estimates with PUMA shapefiles
  unauthorized_map <- puma_shapefile %>%
    left_join(unauthorized_estimates, by = c("PUMA" = "PUMA"))
  
} else if (data_source == 'tidycensus') {
  
  # No need to download shapefile since tidycensus gets the geometry for us
  unauthorized_map <- unauthorized_tracts
}

# ----------------------------
# 4. Map the Results
# ----------------------------
if (!is.null(unauthorized_map)) {
  tmap_mode("view")
  tm_shape(unauthorized_map) +
    tm_fill(
      "unauthorized_population", 
      palette = "Reds", 
      title = "Unauthorized Population"
    ) +
    tm_borders() +
    tm_layout(
      title = paste0("Estimated Unauthorized Immigrants (", data_source, ")"),
      legend.outside = TRUE
    )
}
