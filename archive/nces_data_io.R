# Load the necessary libraries
library(tidyverse)
library(sf)
library(leaflet)
library(httr)

# # Load school data from NCES
# # List of URLs
# urls <- c(
#   "https://nces.ed.gov/ccd/data/zip/ccd_sch_029_2223_w_1a_083023.zip",
#   "https://nces.ed.gov/ccd/data/zip/ccd_sch_052_2223_l_1a_083023.zip",
#   "https://nces.ed.gov/ccd/data/zip/ccd_sch_059_2223_l_1a_083023.zip",
#   "https://nces.ed.gov/ccd/data/zip/ccd_sch_129_2223_w_1a_083023.zip",
#   "https://nces.ed.gov/ccd/data/zip/ccd_sch_033_2223_l_1a_083023.zip"
# )
# 
# # Directory to save the downloaded files
# output_dir <- "data"
# if (!dir.exists(output_dir)) {
#   dir.create(output_dir)
# }
# 
# # Download each file with extended timeout
# for (url in urls) {
#   file_name <- basename(url)
#   dest_file <- file.path(output_dir, file_name)
#   response <- GET(url, write_disk(dest_file, overwrite = TRUE), timeout(300))
#   
#   # Check if download was successful
#   if (status_code(response) == 200) {
#     message(paste("Downloaded:", file_name))
#   } else {
#     warning(paste("Failed to download:", file_name))
#   }
# }
# 
# # Optional: Unzip the downloaded files
# for (url in urls) {
#   zip_file <- file.path(output_dir, basename(url))
#   if (file.exists(zip_file)) {
#     unzip(zip_file, exdir = output_dir)
#   }
# }

# Read CSV files into a list of data frames
csv_files <- list.files(path = "data", pattern = "\\.csv$", full.names = TRUE)
nces_data_list <- lapply(csv_files, read_csv)

# Use only the main school dataset; typically the dataset with the most complete information.
school_details <- nces_data_list[[1]]

# Assuming you already have a shapefile with school coordinates
# Load spatial coordinates (e.g., from shapefile or any other geo format)
# Note: Replace `us_sch.shp` with the correct filename you have
school_coords <- read_sf("data/us_sch.shp")

# Verify that both datasets have a common key
school_coords <- school_coords %>% select(NCESSCH, LAT, LON, LOCALE)
school_details <- school_details %>% select(NCESSCH, SCH_NAME, STATENAME, LEVEL)

# Left join school details with coordinates
us_schools <- school_details %>% left_join(school_coords, by = "NCESSCH")

# Filter for schools in Georgia
ga_schools <- us_schools %>% filter(STATENAME == "GEORGIA")

# Remove rows with missing lat/lon
ga_schools <- ga_schools %>% filter(!is.na(LAT) & !is.na(LON))