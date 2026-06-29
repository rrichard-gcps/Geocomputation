import numpy as np
import geopandas as gpd
import matplotlib.pyplot as plt
from scipy.spatial import Voronoi, voronoi_plot_2d
from shapely.geometry import Polygon, Point
from geopandas import GeoDataFrame

# Extract latitude and longitude values for each school
latitudes = cfb_data['Location Latitude'].values
longitudes = cfb_data['Location Longitude'].values

# Combine latitudes and longitudes to create coordinates array
coordinates = np.column_stack((longitudes, latitudes))

# Create Voronoi diagram using Scipy
vor = Voronoi(coordinates)

# Create a base map of the United States using GeoPandas
world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))
usa = world[world.name == "United States of America"]

# Plotting the Voronoi diagram on top of the map of the United States
fig, ax = plt.subplots(figsize=(12, 8))

# Plot the base map of the USA
usa.plot(ax=ax, color='white', edgecolor='black')

# Draw the Voronoi diagram
voronoi_plot_2d(vor, ax=ax, show_vertices=False, line_colors='orange', line_width=1.5, line_alpha=0.6)

# Plot the school locations on top of the Voronoi diagram
plt.scatter(longitudes, latitudes, color='blue', marker='o', s=20, label='School Locations')

# Set plot parameters for better readability
plt.title('Voronoi Influence Zones of College Football Programs in the USA')
plt.xlabel('Longitude')
plt.ylabel('Latitude')
plt.grid(True)
plt.legend()

# Save the plot as an image
voronoi_image_path = "data/voronoi_influence_zones.png"
plt.savefig(voronoi_image_path)

# Display the path where the image can be found
voronoi_image_path
