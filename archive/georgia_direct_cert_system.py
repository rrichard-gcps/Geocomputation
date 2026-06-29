import requests
from bs4 import BeautifulSoup
import re
import os
import urllib.parse
import pandas as pd

# Target URL for scraping
url = "https://gosa.georgia.gov/dashboards-data-report-card/downloadable-data"

# Headers to simulate a browser visit
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36"
}

# Directory to store downloaded files
download_dir = "downloads"
os.makedirs(download_dir, exist_ok=True)

# Send a GET request to the webpage
response = requests.get(url, headers=headers)

# List to store dataframes for combining later
dataframes = []

# Check if the request was successful
if response.status_code == 200:
    # Parse the HTML content of the page
    soup = BeautifulSoup(response.content, "html.parser")
    
    # Find all links on the page
    links = soup.find_all("a", href=True)
    
    # Iterate through all found links
    for link in links:
        # Check if the link href matches the pattern for Direct Certification data
        if re.search(r'directly_certified_district|direct_certification_d', link['href'], re.IGNORECASE):
            # Get the href attribute (the actual link)
            file_url = urllib.parse.urljoin(url, link['href'])
            
            # Define the local filename to save the file
            filename = os.path.join(download_dir, os.path.basename(link['href']))
            
            # Download the file
            with requests.get(file_url, headers=headers, stream=True) as r:
                if r.status_code == 200:
                    with open(filename, 'wb') as f:
                        for chunk in r.iter_content(chunk_size=8192):
                            f.write(chunk)
                    print(f"Downloaded: {filename}")

                    # Load the downloaded file into a DataFrame and add it to the list
                    try:
                        if filename.endswith('.csv'):
                            df = pd.read_csv(filename)
                        elif filename.endswith('.xls') or filename.endswith('.xlsx'):
                            df = pd.read_excel(filename)
                        else:
                            print(f"Unsupported file format for {filename}")
                            continue

                        # Add a column for the year based on the filename
                        year_match = re.search(r'\b(\d{4}-\d{2}|\d{4})\b', filename)
                        if year_match:
                            year = year_match.group(1)
                            if year == '2014':
                                df.rename(columns={'SCHOOL_YEAR': 'FISCAL_YEAR'}, inplace=True)
                            df['Year'] = year

                        # Keep only the necessary columns
                        required_columns = [
                            "FISCAL_YEAR", "SYSTEM_ID", "SYSTEM_NAME", "direct_cert_perc", 
                            "K12_POVERTY_STUDENT_CT", "K12_STUDENT_COUNT", "SCHOOL_YEAR"
                        ]
                        df = df[[col for col in required_columns if col in df.columns]]

                        dataframes.append(df)
                    except Exception as e:
                        print(f"Failed to load {filename} into DataFrame: {e}")
                else:
                    print(f"Failed to download file from {file_url}")
else:
    print(f"Failed to retrieve webpage. Status code: {response.status_code}")

# Combine all dataframes into one
if dataframes:
    combined_df = pd.concat(dataframes, ignore_index=True)
    combined_filename = os.path.join(download_dir, "georgia_direct_cert_system.csv")
    combined_df.to_csv(combined_filename, index=False)
    print(f"Combined data saved to {combined_filename}")
else:
    print("No dataframes were loaded to combine.")
