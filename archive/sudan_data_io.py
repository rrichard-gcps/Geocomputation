import requests
import urllib3
import zipfile
import io

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

url = "https://s3.dualstack.us-east-1.amazonaws.com/production-raw-data-api/ISO3/SDN/education_facilities/points/hotosm_sdn_education_facilities_points_shp.zip"

try:
    response = requests.get(url, verify=False)
    response.raise_for_status()
    z = zipfile.ZipFile(io.BytesIO(response.content))
    z.extractall("path_to_extract")  # Replace with your desired path
    print("Download and extraction successful")
except requests.exceptions.SSLError as e:
    print(f"SSL Error: {e}")
except Exception as e:
    print(f"An error occurred: {e}")
