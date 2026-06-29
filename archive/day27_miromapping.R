
library(mapgl)

map <-mapboxgl(
  center = c(-84.38, 33.75), zoom = 10
) |> 
  fly_to(
    center = c(-84.0557096, 34.0159032),
    zoom = 17.5,
    pitch = 75,
    bearing = 300, 
    duration = 5000
  )

map

htmlwidgets::saveWidget(map, file = "J_Alvin_Wilbanks_ISC_Map.html")


# Save the map as a PNG image using webshot
# Install webshot and its dependencies if not already installed
if (!requireNamespace("webshot", quietly = TRUE)) {
  install.packages("webshot")
  webshot::install_phantomjs()
}

# Save the map as a PNG
webshot::webshot( file = "J_Alvin_Wilbanks_ISC_Map.png", vwidth = 1920, vheight = 1080)

