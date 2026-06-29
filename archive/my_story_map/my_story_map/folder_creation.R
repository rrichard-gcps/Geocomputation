#!/usr/bin/env Rscript

# Create root project folder
dir.create("my_story_map")

# Set working directory to the root project folder
setwd("my_story_map")

# Create main directories
dir.create("data")
dir.create("notebooks")
dir.create("src")
dir.create("html_exports")
dir.create("assets")
dir.create("docs")
dir.create("tests")
dir.create("env")
dir.create("results")

# Create subdirectories for data
dir.create("data/raw")
dir.create("data/processed")
dir.create("data/geojson")

# Create subdirectories for notebooks and initial files
dir.create("notebooks")
file.create("notebooks/initial_exploration.ipynb")
file.create("notebooks/data_cleaning.rmd")
file.create("notebooks/mapping_concept.rmd")

# Create subdirectories for source code and initial files
dir.create("src/d3/utils", recursive = TRUE)
dir.create("src/d3/css")
dir.create("src/python")
file.create("src/d3/storymap.js")
file.create("src/d3/utils/util_functions.js")
file.create("src/python/folium_script.py")
file.create("src/python/dash_app.py")

# Create subdirectories for HTML exports and initial HTML files
dir.create("html_exports")
file.create("html_exports/folium_map.html")
file.create("html_exports/storymap_preview.html")

# Create subdirectories for assets
dir.create("assets/images", recursive = TRUE)
dir.create("assets/icons")
dir.create("assets/media")
dir.create("assets/basemaps")

# Create subdirectories for documentation and initial documentation files
dir.create("docs")
file.create("docs/readme.md")
file.create("docs/technical_design.md")
file.create("docs/setup_guide.md")

# Create subdirectories for testing
dir.create("tests/python_tests", recursive = TRUE)
dir.create("tests/js_tests")

# Create subdirectories for environment files and initial environment files
dir.create("env")
file.create("env/requirements.txt")
file.create("env/environment.yml")
file.create("env/.Rprofile")

# Create subdirectories for results and initial result files
dir.create("results/visualizations", recursive = TRUE)
dir.create("results/plots")
file.create("results/analysis_summary.csv")

