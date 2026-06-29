import requests
from bs4 import BeautifulSoup
import pandas as pd
import urllib3

# Suppress the SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# URL of the webpage containing GHSA Football Champions data
url = 'https://www.ghsa.net/ghsa-football-champions'

# Fetch the HTML content, ignoring SSL certificate verification
response = requests.get(url, verify=False)
soup = BeautifulSoup(response.content, 'html.parser')

# Extract the relevant table with the championship data
tables = soup.find_all('table')

# List to hold all data extracted
data = []

# Iterate over each table and extract rows
def extract_championship_data(tables):
    for table in tables:
        headers = []
        rows = table.find_all('tr')
        if len(rows) < 1:
            continue

        # Extract headers from the first row
        header_cells = rows[0].find_all(['th', 'td'])
        headers = [header.get_text(strip=True) for header in header_cells]

        # Extract data from remaining rows
        for row in rows[1:]:
            cells = row.find_all(['th', 'td'])
            row_data = [cell.get_text(strip=True) for cell in cells]
            if len(row_data) > 0:
                data.append(dict(zip(headers, row_data)))

extract_championship_data(tables)

# Convert the extracted data to a Pandas DataFrame
df = pd.DataFrame(data)

# Display the first few rows to verify the extraction
print(df.head())

# Save or further use the data as per the requirement - commenting out for R
# df.to_csv("ghsa_football_champions.csv", index=False)

# Note: The DataFrame `df` can be accessed directly from R via reticulate
