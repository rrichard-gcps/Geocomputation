# Load required libraries
library(rvest)
library(dplyr)
library(tidyr)

# URL of the webpage containing GHSA Football Champions data
url <- 'https://www.ghsa.net/ghsa-football-champions'

# Read the HTML content of the webpage
webpage <- read_html(url)

# Extract all the tables from the webpage
tables <- html_nodes(webpage, "table")

# Initialize an empty list to hold all data extracted
data <- list()

# Function to extract championship data from all tables
extract_championship_data <- function(tables) {
  for (table in tables) {
    # Convert the HTML table to a data frame
    table_df <- html_table(table, fill = TRUE)
    
    # Append to the data list
    data <<- append(data, list(table_df))
  }
}

# Extract championship data
extract_championship_data(tables)

# Combine all tables into one data frame
championship_data <- bind_rows(data)

# Reshape the data to ensure the school names are properly aligned
championship_data <- championship_data %>% 
  pivot_longer(cols = -Year, names_to = "Classification", values_to = "Champion") %>%
  filter(!is.na(Champion) & Champion != "")

# Ensure the classification column names are uniform and concise
championship_data$Classification <- recode(championship_data$Classification,
                                           "AAAAAA" = "6A",
                                           "AAAAA" = "5A",
                                           "AAAA" = "4A",
                                           "AAA" = "3A",
                                           "AA" = "2A",
                                           "A Private" = "A_Division_I",
                                           "A Public" = "A_Division_II")

# Summarize the number of championships by school regardless of classification
championship_summary <- championship_data %>%
  group_by(Champion) %>%
  summarise(Total_Championships = n(), .groups = 'drop') %>%
  arrange(desc(Total_Championships))

# Display the championship summary
print(championship_summary)

# Summarize the number of championships by school and classification
classification_summary <- championship_data %>%
  group_by(Champion, Classification) %>%
  summarise(Classification_Championships = n(), .groups = 'drop') %>%
  pivot_wider(names_from = Classification, values_from = Classification_Championships, values_fill = list(Classification_Championships = 0)) %>%
  arrange(desc(rowSums(select(., -Champion))))

# Display the classification summary
print(classification_summary)
