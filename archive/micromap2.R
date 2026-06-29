# Create a base map centered in Duluth, GA
map <- mapboxgl(
  center = c(-84.1496, 34.0029), zoom = 12, pitch = 0, bearing = 0  # Start in Duluth, GA
)

# Save the map as an HTML file for hosting on GitHub or sharing on social media
htmlwidgets::saveWidget(map, file = "J_Alvin_Wilbanks_ISC_Map.html")

# Save the map as a PNG image using webshot
# Install webshot and its dependencies if not already installed
if (!requireNamespace("webshot", quietly = TRUE)) {
  install.packages("webshot")
  webshot::install_phantomjs()
}

# Save the map as a PNG
webshot::webshot(url = "J_Alvin_Wilbanks_ISC_Map.html", file = "J_Alvin_Wilbanks_ISC_Map.png", vwidth = 1920, vheight = 1080)

# Save the map as a GIF using a series of PNGs and gifski
# Install gifski and its dependencies if not already installed
if (!requireNamespace("gifski", quietly = TRUE)) {
  install.packages("gifski")
}

# Create a series of frames by adjusting the view and saving each as a PNG
frame_files <- c()
for (i in seq(0, 1, length.out = 20)) {  # Generate 20 frames
  temp_map <- mapboxgl(
    center = c(-84.1496 * (1 - i) + -84.0557096 * i, 34.0029 * (1 - i) + 34.0159032 * i),
    zoom = 12 + 5.5 * i,
    pitch = 75 * i,
    bearing = 300 * i
  )
  frame_file <- paste0("frame_", sprintf("%02d", i * 20), ".png")
  htmlwidgets::saveWidget(temp_map, "temp.html")
  webshot::webshot(url = "temp.html", file = frame_file, vwidth = 1920, vheight = 1080)
  frame_files <- c(frame_files, frame_file)
}

# Create the GIF using gifski
gifski::gifski(png_files = frame_files, gif_file = "J_Alvin_Wilbanks_ISC_Map.gif", width = 1920, height = 1080, delay = 0.1)
