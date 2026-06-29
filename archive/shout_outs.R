# Load required packages
library(ggplot2)
library(sf)   # To work with shapefiles
devtools::install_github("UrbanInstitute/urbnmapr") # For Urban Institute's county and state shapefiles
library(urbnmapr)
library(png)
library(grid)
library(RCurl)  # To read URLs
library(dplyr)   # To manipulate data frames
library(crosstalk)  # For linking shared data between widgets
library(reactable)  # For creating interactive tables with reactable
library(reactablefmtr) # For formatting tables with reactable
library(ggiraph)  # For creating interactive ggplot maps

# City coordinates with logo URLs
cities <- data.frame(
  city = c("Atlanta", "St. Louis", "Washington", "Durham", "Columbia", "Suwanee", "Nashville"),
  state = c("GA", "MO", "DC", "NC", "SC", "GA", "TN"),
  lat = c(33.7490, 38.6270, 38.9072, 35.9940, 34.0007, 34.0515, 36.1627),
  lon = c(-84.3880, -90.1994, -77.0369, -78.8986, -81.0348, -84.0713, -86.7816),
  logo_url = c(
    "https://morehouse.edu/marketing/brand-guidelines-and-logos/Morehouse_College_Logo.png",
    "https://www.slu.edu/marcom/tools-downloads/logos/SLU_Logo.png",
    "https://www.cdc.gov/TemplatePackage/images/cdcgov/CDC-Logo.png",
    "https://www.rtp.org/wp-content/uploads/2021/05/RTP-Logo.png",
    "https://sc.edu/about/offices_and_divisions/communications/toolbox/visual_identity/logos/UofSC_Logo.png",
    "https://fultonschools.org/cms/lib/GA50000114/Centricity/Domain/4/FCS_Logo.png",
    "https://upload.wikimedia.org/wikipedia/commons/3/3b/Nashville_Seal.png"
  )
)

# Ensure latitude and longitude are numeric
cities$lat <- as.numeric(cities$lat)
cities$lon <- as.numeric(cities$lon)

# Create a data frame with story information
stories <- cities %>%
  mutate(
    institution = case_when(
      city == "Atlanta" ~ "Morehouse College",
      city == "St. Louis" ~ "Saint Louis University",
      city == "Washington" ~ "Centers for Disease Control and Prevention",
      city == "Durham" ~ "North Carolina",
      city == "Columbia" ~ "University of South Carolina",
      city == "Suwanee" ~ "Fulton County Schools",
      city == "Nashville" ~ "Nashville R User Group"
    ),
    num_people = case_when(
      city == "Atlanta" ~ 2,
      city == "St. Louis" ~ 3,
      city == "Washington" ~ 3,
      city == "Durham" ~ 1,
      city == "Columbia" ~ 1,
      city == "Suwanee" ~ 1,
      city == "Nashville" ~ 2
    ),
    short_story = case_when(
      city == "Atlanta" ~ "I learned about data analysis during my time at Morehouse, thanks to Prof. X and Prof. Y.",
      city == "St. Louis" ~ "Saint Louis University was instrumental in shaping my understanding of statistics, with the support of Dr. A, Dr. B, and Dr. C.",
      city == "Washington" ~ "My experience at the CDC working with epidemiological data was greatly influenced by Ms. D, Dr. E, and Mr. F.",
      city == "Durham" ~ "North Carolina is where I developed my first interactive maps under the mentorship of Mr. G.",
      city == "Columbia" ~ "Dr. H at the University of South Carolina introduced me to advanced statistical models.",
      city == "Suwanee" ~ "I began applying my data visualization skills in Fulton County Schools with the help of Ms. I.",
      city == "Nashville" ~ "I started attending Nashville's R User Group where I met amazing mentors like Mr. J and Ms. K."
    ),
    Logo = logo_url
  )

# Create SharedData for story information
shared_stories <- SharedData$new(stories, key = ~city, group = "cities_group")

# Create the interactive map using ggplot2 and ggiraph
us_map <- get_urbn_map("states", sf = TRUE)  # Get US state boundaries

map_plot <- ggplot() +
  geom_sf(data = us_map, fill = "white", color = "gray80") +
  geom_point_interactive(
    data = shared_stories,
    aes(x = lon, y = lat, tooltip = city, data_id = city),
    color = "red", size = 3
  ) +
  theme_void() +
  labs(
    title = "Highlighted Cities in the United States with Logos",
    x = "Longitude",
    y = "Latitude"
  )

interactive_map <- girafe(ggobj = map_plot, options = list(
  opts_hover(css = "fill:orange;"),
  opts_selection(type = "single", css = "stroke:blue;stroke-width:2px;")
))

# Create an interactive table using reactable and reactablefmtr with crosstalk
stories_table <- reactable(
  shared_stories,
  columns = list(
    Logo = colDef(
      name = "",
      cell = function(value) {
        embed_img(value, height = 40)
      },
      width = 60
    ),
    city = colDef(name = "City"),
    institution = colDef(name = "Institution"),
    num_people = colDef(name = "Number of Influencers"),
    short_story = colDef(name = "Story")
  ),
  searchable = TRUE,
  pagination = TRUE,
  highlight = TRUE,
  defaultPageSize = 5
)

# Combine the map and table into a single HTML file using bscols
combined_widget <- bscols(widths = c(6, 6), interactive_map, stories_table)

# Save the combined HTML
htmlwidgets::saveWidget(combined_widget, "combined_interactive_map_table.html")
