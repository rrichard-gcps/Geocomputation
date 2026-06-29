# Create root project folder
New-Item -Path "public_health_story_map" -ItemType Directory

# Navigate into the root folder
Set-Location "public_health_story_map"

# Create main directories
New-Item -ItemType Directory -Name "data", "notebooks", "src", "html_exports", "assets", "docs", "tests", "env", "results"

# Create subdirectories for data
New-Item -ItemType Directory -Path "data/raw", "data/processed", "data/geojson"

# Create subdirectories for notebooks and initial files
New-Item -ItemType Directory -Path "notebooks"
New-Item -ItemType File -Path "notebooks/initial_exploration.ipynb", "notebooks/data_cleaning.rmd", "notebooks/mapping_concept.rmd"

# Create subdirectories for source code and initial files
New-Item -ItemType Directory -Path "src/d3/utils", "src/d3/css", "src/python"
New-Item -ItemType File -Path "src/d3/storymap.js", "src/d3/utils/util_functions.js", "src/python/folium_script.py", "src/python/dash_app.py"

# Create subdirectories for HTML exports and initial HTML files
New-Item -ItemType Directory -Path "html_exports"
New-Item -ItemType File -Path "html_exports/folium_map.html", "html_exports/storymap_preview.html"

# Create subdirectories for assets
New-Item -ItemType Directory -Path "assets/images", "assets/icons", "assets/media"

# Create subdirectories for documentation and initial documentation files
New-Item -ItemType Directory -Path "docs"
New-Item -ItemType File -Path "docs/readme.md", "docs/technical_design.md", "docs/setup_guide.md"

# Create subdirectories for testing
New-Item -ItemType Directory -Path "tests/python_tests", "tests/js_tests"

# Create subdirectories for environment files and initial environment files
New-Item -ItemType Directory -Path "env"
New-Item -ItemType File -Path "env/requirements.txt", "env/environment.yml", "env/.Rprofile"

# Create subdirectories for results and initial result files
New-Item -ItemType Directory -Path "results/visualizations", "results/plots"
New-Item -ItemType File -Path "results/analysis_summary.csv"

# Completion message
Write-Output "Folder structure created successfully!"
