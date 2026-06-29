import os
import requests

# List of URLs to download
urls = [
    "https://upload.wikimedia.org/wikipedia/en/9/96/Boston_College_Eagles_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/8/83/California_Golden_Bears_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/7/7c/Clemson_Tigers_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/0/01/Duke_Blue_Devils_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/d/d5/Florida_State_Seminoles_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/6/6d/Georgia_Tech_Yellow_Jackets_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/1/10/Louisville_Cardinals_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/f/f4/Miami_Hurricanes_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/e/e5/NC_State_Wolfpack_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/2/28/North_Carolina_Tar_Heels_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/6/6e/Pittsburgh_Panthers_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/f/fd/SMU_Mustangs_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/4/48/Stanford_Cardinal_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/0/0e/Syracuse_Orange_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/9/94/Virginia_Cavaliers_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/f/fc/Virginia_Tech_Hokies_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/0/0c/Wake_Forest_Demon_Deacons_logo.svg"
]

# Create 'logos' folder if it doesn't exist
os.makedirs('logos', exist_ok=True)

# Loop through the URLs and download each image
for url in urls:
    try:
        # Get the image content
        response = requests.get(url)
        response.raise_for_status()  # Check if the request was successful

        # Extract the filename from the URL
        filename = url.split("/")[-1]

        # Define the path to save the image
        filepath = os.path.join("logos", filename)

        # Save the image to the specified folder
        with open(filepath, "wb") as file:
            file.write(response.content)

        print(f"Downloaded: {filename}")
    except requests.exceptions.RequestException as e:
        print(f"Failed to download {url}: {e}")

print("All downloads completed.")
