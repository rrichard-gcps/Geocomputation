library(fuzzyjoin)
library(dplyr)
library(stringdist)
library(janitor)

hbcu_loc_colors <- read.csv("hbcu_loc_colors.csv")

hbcu_loc_colors <- hbcu_loc_colors |> select(-c(primary_color,secondary_color))


hbcu_school_colors <- read.csv("hbcu_school_colors.csv")

# Renaming columns for consistency
colnames(hbcu_loc_colors)[which(names(hbcu_loc_colors) == "College_Name")] <- "school"

# Fuzzy join based on school names
merged_data <- stringdist_join(hbcu_loc_colors, hbcu_school_colors, 
                               by = "school",
                               method = "jw", # Jaro-Winkler similarity
                               max_dist = 0.15, # Set threshold for matching
                               distance_col = "dist") %>%
  # Use dplyr to clean and select the desired columns
  select(-dist)


df <- merged_data |> select(-c(school.y, X)) |> rename(school = school.x) |> clean_names()

df <- df |> distinct(school,.keep_all = TRUE)

write.csv(df, "hbcu_school_locations.csv")
