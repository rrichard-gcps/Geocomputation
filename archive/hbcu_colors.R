# Load required libraries
library(rvest)
library(dplyr)
library(grDevices) # For converting RGB to hex

# Load the HTML content from the file
html_content <- read_html("hbcu_colors.html")

# Extract the school cards
cards <- html_nodes(html_content, "a.ColorCard_card__D6Ei5")

# Initialize vectors to store data
schools <- c()
primary_colors <- c()
secondary_colors <- c()

# Function to convert RGB to hex
convert_rgb_to_hex <- function(rgb_string) {
  rgb_values <- as.numeric(unlist(strsplit(gsub("rgb\\(|\\)", "", rgb_string), ",")))
  if (length(rgb_values) == 3) {
    return(rgb(red = rgb_values[1], green = rgb_values[2], blue = rgb_values[3], maxColorValue = 255))
  } else {
    return(NA)
  }
}

# Extract school names and colors from each card
for (card in cards) {
  # Extract school name from href attribute
  school_name <- html_attr(card, "href") %>%
    gsub("/", "", .) %>%
    gsub("-", " ", .) %>%
    tools::toTitleCase()
  
  # Extract color divs
  color_divs <- html_nodes(card, "div.ColorCard_colorDiv__iK_GW")
  
  # Extract colors with error handling for missing or malformed style attributes
  colors <- sapply(color_divs, function(div) {
    style <- html_attr(div, "style")
    if (!is.na(style) && grepl("background-color:", style)) {
      color <- strsplit(style, "background-color: ")[[1]][2]
      color <- strsplit(color, ";")[[1]][1]
      # Convert RGB to hex if necessary
      if (grepl("rgb", color)) {
        color <- convert_rgb_to_hex(color)
      }
      return(color)
    } else {
      return(NA)
    }
  })
  
  # Assign primary and secondary colors if available
  primary_color <- ifelse(length(colors) >= 1, colors[1], NA)
  secondary_color <- ifelse(length(colors) >= 2, colors[2], NA)
  
  # Append data to vectors
  schools <- c(schools, school_name)
  primary_colors <- c(primary_colors, primary_color)
  secondary_colors <- c(secondary_colors, secondary_color)
}

# Create a data frame
color_data <- data.frame(
  school = schools,
  primary_color = primary_colors,
  secondary_color = secondary_colors,
  stringsAsFactors = FALSE
)

# Save to CSV
write.csv(color_data, "hbcu_school_colors.csv", row.names = FALSE)

print("Data extracted and saved to hbcu_school_colors.csv")
