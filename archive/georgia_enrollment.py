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

# Lists to store dataframes for combining later
dataframes_by_subgroups = []
dataframes_by_grade_level = []

# Check if the request was successful
if response.status_code == 200:
    # Parse the HTML content of the page
    soup = BeautifulSoup(response.content, "html.parser")
    
    # Find all links on the page
    links = soup.find_all("a", href=True)
    
    # Iterate through all found links
    for link in links:
        # Check if the link href matches the pattern for Enrollment data by subgroups
        if re.search(r'Enrollment_by_Subgroups_Programs_|Enrollment_by_Subgroup_Metrics_', link['href'], re.IGNORECASE):
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
                            df['Year'] = year

                        # Update column names to align with the latest dataset
                        df.columns = df.columns.str.upper()

                        # Keep only the necessary columns
                        required_columns = [
                            "RPT_NAME", "LONG_SCHOOL_YEAR", "DETAIL_LVL_DESC", "SCHOOL_DSTRCT_CD", "SCHOOL_DSTRCT_NM", 
                            "INSTN_NUMBER", "INSTN_NAME", "GRADES_SERVED_DESC", "ENROLL_PCT_ASIAN", "ENROLL_PCT_NATIVE", 
                            "ENROLL_PCT_BLACK", "ENROLL_PCT_HISPANIC", "ENROLL_PCT_MULTIRACIAL", "ENROLL_PCT_WHITE", 
                            "ENROLL_PCT_MIGRANT", "ENROLL_PCT_ED", "ENROLL_PCT_SWD", "ENROLL_PCT_LEP", 
                            "ENROLL_COUNT_REMEDIAL_GR_6_8", "ENROLL_PCT_REMEDIAL_GR_6_8", "ENROLL_COUNT_EIP_K_5", 
                            "ENROLL_PERCENT_EIP_K_5", "ENROLL_COUNT_REMEDIAL_GR_9_12", "ENROLL_PCT_REMEDIAL_GR_9_12", 
                            "ENROLL_COUNT_SPECIAL_ED_K12", "ENROLL_PCT_SPECIAL_ED_K12", "ENROLL_COUNT_ESOL", "ENROLL_PCT_ESOL", 
                            "ENROLL_COUNT_SPECIAL_ED_PK", "ENROLL_PCT_SPECIAL_ED_PK", "ENROLL_COUNT_VOCATION_9_12", 
                            "ENROLL_PCT_VOCATION_9_12", "ENROLL_COUNT_ALT_PROGRAMS", "ENROLL_PCT_ALT_PROGRAMS", "ENROLL_COUNT_GIFTED", 
                            "ENROLL_PCT_GIFTED", "ENROLL_PCT_MALE", "ENROLL_PCT_FEMALE", "Year"
                        ]

                        # Keep only the necessary columns that are present in the dataframe
                        df = df[[col for col in required_columns if col in df.columns]]

                        dataframes_by_subgroups.append(df)
                    except Exception as e:
                        print(f"Failed to load {filename} into DataFrame: {e}")
                else:
                    print(f"Failed to download file from {file_url}")
        # Check if the link href matches the pattern for Enrollment data by grade level
        elif re.search(r'Enrollment_by_Grade_|Enrollment_By_Grade_Level_', link['href'], re.IGNORECASE):
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
                            df['Year'] = year

                        # Update column names to align with the latest dataset
                        df.columns = df.columns.str.upper()

                        # Keep only the necessary columns that are present in the dataframe
                        dataframes_by_grade_level.append(df)
                    except Exception as e:
                        print(f"Failed to load {filename} into DataFrame: {e}")
                else:
                    print(f"Failed to download file from {file_url}")
else:
    print(f"Failed to retrieve webpage. Status code: {response.status_code}")

# Combine all dataframes into one for subgroups
if dataframes_by_subgroups:
    combined_df_subgroups = pd.concat(dataframes_by_subgroups, ignore_index=True)
    combined_df_subgroups.dropna(axis=1, how='all', inplace=True)  # Drop columns with all NaN values
    combined_filename_subgroups = os.path.join(download_dir, "georgia_enrollment_data_by_subgroups_combined.csv")
    combined_df_subgroups.to_csv(combined_filename_subgroups, index=False)
    print(f"Combined data (by subgroups) saved to {combined_filename_subgroups}")
else:
    print("No dataframes were loaded to combine for subgroups.")

# Combine all dataframes into one for grade level
if dataframes_by_grade_level:
    combined_df_grade_level = pd.concat(dataframes_by_grade_level, ignore_index=True)
    combined_df_grade_level.dropna(axis=1, how='all', inplace=True)  # Drop columns with all NaN values
    combined_filename_grade_level = os.path.join(download_dir, "georgia_enrollment_data_by_grade_level_combined.csv")
    combined_df_grade_level.to_csv(combined_filename_grade_level, index=False)
    print(f"Combined data (by grade level) saved to {combined_filename_grade_level}")
else:
    print("No dataframes were loaded to combine for grade level.")
