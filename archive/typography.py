import geopandas as gpd
import matplotlib.pyplot as plt
from shapely.geometry import Polygon, Point
from matplotlib.font_manager import FontProperties
from matplotlib.patheffects import withStroke
from descartes import PolygonPatch
import numpy as np

# Load Custom Fonts for the Map
font_path = '/path/to/fonts/Poppins-Regular.ttf'  # Update with your local path
poppins_font = FontProperties(fname=font_path)

# Load Spatial Data
rea_spatial = "S:/SPA/REA/_DataAnalytics/SpatialData/SY2023/"
gcps_hs = gpd.read_file(f'{rea_spatial}High_School_Clusters_SY2223.shp')

# Transform and simplify spatial data if needed
gcps_clusters = gcps_hs.to_crs(epsg=2240)

# Simplify geometry if necessary (note: shapely has simplify method for this)
gcps_clusters['geometry'] = gcps_clusters['geometry'].simplify(tolerance=0.2, preserve_topology=True)

# Plot with matplotlib
fig, ax = plt.subplots(figsize=(17, 11))
ax.set_facecolor('#2f2f2f')

# Plot each cluster and add text
for _, row in gcps_clusters.iterrows():
    # Plot the school cluster polygon
    patch = PolygonPatch(row['geometry'], edgecolor='black', facecolor='grey30', linewidth=0.8, alpha=0.5)
    ax.add_patch(patch)

    # Get the bounds of the polygon
    minx, miny, maxx, maxy = row['geometry'].bounds
    polygon = row['geometry']

    # Generate repeated text to fill the polygon
    label_text = row['High_Label'] + " "
    repeated_text = label_text * 200  # Adjust number to control text density

    # Define a grid of points within the bounds of the polygon
    x = np.linspace(minx, maxx, 100)  # Adjust 100 to change text resolution
    y = np.linspace(miny, maxy, 100)
    X, Y = np.meshgrid(x, y)
    points = np.c_[X.ravel(), Y.ravel()]

    # Filter points to keep only those inside the polygon
    inside_points = [Point(pt) for pt in points if polygon.contains(Point(pt))]

    # Plot text at the filtered points
    for point in inside_points:
        ax.text(point.x, point.y, label_text,
                fontsize=8, color='white', fontproperties=poppins_font,
                ha='center', va='center', alpha=0.5,
                path_effects=[withStroke(linewidth=3, foreground='#2f2f2f')])

# Remove axis
ax.axis('off')

# Add title
plt.title("GCPS High School Clusters with School Names",
          fontsize=24, fontproperties=poppins_font, color='#FFFFFF')

# Save the Final Map
plt.savefig("gcps_typographical_map.png", dpi=300, bbox_inches='tight', facecolor='#2f2f2f')
plt.show()
