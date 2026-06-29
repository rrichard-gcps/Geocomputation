import pandas as pd

# List of HBCUs with their details
hbcus = [
    {'Institution': 'Alabama A&M University', 'City': 'Normal', 'State': 'AL', 'Founded': 1875, 'Type': 'Public'},
    {'Institution': 'Alabama State University', 'City': 'Montgomery', 'State': 'AL', 'Founded': 1867, 'Type': 'Public'},
    {'Institution': 'Albany State University', 'City': 'Albany', 'State': 'GA', 'Founded': 1903, 'Type': 'Public'},
    {'Institution': 'Alcorn State University', 'City': 'Lorman', 'State': 'MS', 'Founded': 1871, 'Type': 'Public'},
    {'Institution': 'Allen University', 'City': 'Columbia', 'State': 'SC', 'Founded': 1870, 'Type': 'Private'},
    {'Institution': 'American Baptist College', 'City': 'Nashville', 'State': 'TN', 'Founded': 1924, 'Type': 'Private'},
    {'Institution': 'Arkansas Baptist College', 'City': 'Little Rock', 'State': 'AR', 'Founded': 1884, 'Type': 'Private'},
    {'Institution': 'Benedict College', 'City': 'Columbia', 'State': 'SC', 'Founded': 1870, 'Type': 'Private'},
    {'Institution': 'Bennett College', 'City': 'Greensboro', 'State': 'NC', 'Founded': 1873, 'Type': 'Private'},
    {'Institution': 'Bethune-Cookman University', 'City': 'Daytona Beach', 'State': 'FL', 'Founded': 1904, 'Type': 'Private'},
    {'Institution': 'Bishop State Community College', 'City': 'Mobile', 'State': 'AL', 'Founded': 1927, 'Type': 'Public'},
    {'Institution': 'Bluefield State College', 'City': 'Bluefield', 'State': 'WV', 'Founded': 1895, 'Type': 'Public'},
    {'Institution': 'Bowie State University', 'City': 'Bowie', 'State': 'MD', 'Founded': 1865, 'Type': 'Public'},
    {'Institution': 'Central State University', 'City': 'Wilberforce', 'State': 'OH', 'Founded': 1887, 'Type': 'Public'},
    {'Institution': 'Cheyney University of Pennsylvania', 'City': 'Cheyney', 'State': 'PA', 'Founded': 1837, 'Type': 'Public'},
    {'Institution': 'Claflin University', 'City': 'Orangeburg', 'State': 'SC', 'Founded': 1869, 'Type': 'Private'},
    {'Institution': 'Clark Atlanta University', 'City': 'Atlanta', 'State': 'GA', 'Founded': 1988, 'Type': 'Private'},
    {'Institution': 'Clinton College', 'City': 'Rock Hill', 'State': 'SC', 'Founded': 1894, 'Type': 'Private'},
    {'Institution': 'Coahoma Community College', 'City': 'Clarksdale', 'State': 'MS', 'Founded': 1949, 'Type': 'Public'},
    {'Institution': 'Coppin State University', 'City': 'Baltimore', 'State': 'MD', 'Founded': 1900, 'Type': 'Public'},
    {'Institution': 'Delaware State University', 'City': 'Dover', 'State': 'DE', 'Founded': 1891, 'Type': 'Public'},
    {'Institution': 'Denmark Technical College', 'City': 'Denmark', 'State': 'SC', 'Founded': 1947, 'Type': 'Public'},
    {'Institution': 'Dillard University', 'City': 'New Orleans', 'State': 'LA', 'Founded': 1869, 'Type': 'Private'},
    {'Institution': 'Edward Waters University', 'City': 'Jacksonville', 'State': 'FL', 'Founded': 1866, 'Type': 'Private'},
    {'Institution': 'Elizabeth City State University', 'City': 'Elizabeth City', 'State': 'NC', 'Founded': 1891, 'Type': 'Public'},
    {'Institution': 'Fayetteville State University', 'City': 'Fayetteville', 'State': 'NC', 'Founded': 1867, 'Type': 'Public'},
    {'Institution': 'Florida A&M University', 'City': 'Tallahassee', 'State': 'FL', 'Founded': 1887, 'Type': 'Public'},
    {'Institution': 'Florida Memorial University', 'City': 'Miami Gardens', 'State': 'FL', 'Founded': 1879, 'Type': 'Private'},
    {'Institution': 'Fort Valley State University', 'City': 'Fort Valley', 'State': 'GA', 'Founded': 1895, 'Type': 'Public'},
    {'Institution': 'Grambling State University', 'City': 'Grambling', 'State': 'LA', 'Founded': 1901, 'Type': 'Public'},
    {'Institution': 'Hampton University', 'City': 'Hampton', 'State': 'VA', 'Founded': 1868, 'Type': 'Private'},
    {'Institution': 'Harris-Stowe State University', 'City': 'St. Louis', 'State': 'MO', 'Founded': 1857, 'Type': 'Public'},
    {'Institution': 'Howard University', 'City': 'Washington', 'State': 'DC', 'Founded': 1867, 'Type': 'Private'},
    {'Institution': 'Huston-Tillotson University', 'City': 'Austin', 'State': 'TX', 'Founded': 1875, 'Type': 'Private'},
    {'Institution': 'Jackson State University', 'City': 'Jackson', 'State': 'MS', 'Founded': 1877, 'Type': 'Public'},
    {'Institution': 'Jarvis Christian College', 'City': 'Hawkins', 'State': 'TX', 'Founded': 1912, 'Type': 'Private'},
    {'Institution': 'Johnson C. Smith University', 'City': 'Charlotte', 'State': 'NC', 'Founded': 1867, 'Type': 'Private'},
    {'Institution': 'Kentucky State University', 'City': 'Frankfort', 'State': 'KY', 'Founded': 1886, 'Type': 'Public'},
    {'Institution': 'Lane College', 'City': 'Jackson', 'State': 'TN', 'Founded': 1882, 'Type': 'Private'},
    {'Institution': 'Langston University', 'City': 'Langston', 'State': 'OK', 'Founded': 1897, 'Type': 'Public'},
    {'Institution': 'LeMoyne-Owen College', 'City': 'Memphis', 'State': 'TN', 'Founded': 1862, 'Type': 'Private'},
    {'Institution': 'Lincoln University', 'City': 'Lincoln University', 'State': 'PA', 'Founded': 1854, 'Type': 'Public'},
    {'Institution': 'Lincoln University of Missouri', 'City': 'Jefferson City', 'State': 'MO', 'Founded': 1866, 'Type': 'Public'},
    {'Institution': 'Livingstone College', 'City': 'Salisbury', 'State': 'NC', 'Founded': 1879, 'Type': 'Private'},
    {'Institution': 'Meharry Medical College', 'City': 'Nashville', 'State': 'TN', 'Founded': 1876, 'Type': 'Private'},
    {'Institution': 'Miles College', 'City': 'Fairfield', 'State': 'AL', 'Founded': 1898, 'Type': 'Private'},
    {'Institution': 'Mississippi Valley State University', 'City': 'Itta Bena', 'State': 'MS', 'Founded': 1950, 'Type': 'Public'},
    {'Institution': 'Morehouse College', 'City': 'Atlanta', 'State': 'GA', 'Founded': 1867, 'Type': 'Private'},
    {'Institution': 'Morgan State University', 'City': 'Baltimore', 'State': 'MD', 'Founded': 1867, 'Type': 'Public'},
    {'Institution': 'Morris College', 'City': 'Sumter', 'State': 'SC', 'Founded': 1908, 'Type': 'Private'},
    {'Institution': 'Norfolk State University', 'City': 'Norfolk', 'State': 'VA', 'Founded': 1935, 'Type': 'Public'},
    {'Institution': 'North Carolina A&T State University', 'City': 'Greensboro', 'State': 'NC', 'Founded': 1891, 'Type': 'Public'},
    {'Institution': 'North Carolina Central University', 'City': 'Durham', 'State': 'NC', 'Founded': 1910, 'Type': 'Public'},
    {'Institution': 'Oakwood University', 'City': 'Huntsville', 'State': 'AL', 'Founded': 1896, 'Type': 'Private'},
    {'Institution': 'Paine College', 'City': 'Augusta', 'State': 'GA', 'Founded': 1882, 'Type': 'Private'},
    {'Institution': 'Paul Quinn College', 'City': 'Dallas', 'State': 'TX', 'Founded': 1872, 'Type': 'Private'},
    {'Institution': 'Philander Smith College', 'City': 'Little Rock', 'State': 'AR', 'Founded': 1877, 'Type': 'Private'},
    {'Institution': 'Prairie View A&M University', 'City': 'Prairie View', 'State': 'TX', 'Founded': 1876, 'Type': 'Public'},
    {'Institution': 'Rust College', 'City': 'Holly Springs', 'State': 'MS', 'Founded': 1866, 'Type': 'Private'},
    {'Institution': 'Saint Augustine\'s University', 'City': 'Raleigh', 'State': 'NC', 'Founded': 1867, 'Type': 'Private'},
    {'Institution': 'Savannah State University', 'City': 'Savannah', 'State': 'GA', 'Founded': 1890, 'Type': 'Public'},
    {'Institution': 'Shaw University', 'City': 'Raleigh', 'State': 'NC', 'Founded': 1865, 'Type': 'Private'},
    {'Institution': 'South Carolina State University', 'City': 'Orangeburg', 'State': 'SC', 'Founded': 1896, 'Type': 'Public'},
    {'Institution': 'Southern University and A&M College', 'City': 'Baton Rouge', 'State': 'LA', 'Founded': 1880, 'Type': 'Public'},
    {'Institution': 'Spelman College', 'City': 'Atlanta', 'State': 'GA', 'Founded': 1881, 'Type': 'Private'},
    {'Institution': 'Stillman College', 'City': 'Tuscaloosa', 'State': 'AL', 'Founded': 1876, 'Type': 'Private'},
    {'Institution': 'Talladega College', 'City': 'Talladega', 'State': 'AL', 'Founded': 1867, 'Type': 'Private'},
    {'Institution': 'Tennessee State University', 'City': 'Nashville', 'State': 'TN', 'Founded': 1912, 'Type': 'Public'},
    {'Institution': 'Texas Southern University', 'City': 'Houston', 'State': 'TX', 'Founded': 1927, 'Type': 'Public'},
    {'Institution': 'Tougaloo College', 'City': 'Tougaloo', 'State': 'MS', 'Founded': 1869, 'Type': 'Private'},
    {'Institution': 'Tuskegee University', 'City': 'Tuskegee', 'State': 'AL', 'Founded': 1881, 'Type': 'Private'},
    {'Institution': 'University of Arkansas at Pine Bluff', 'City': 'Pine Bluff', 'State': 'AR', 'Founded': 1873, 'Type': 'Public'},
    {'Institution': 'Virginia State University', 'City': 'Petersburg', 'State': 'VA', 'Founded': 1882, 'Type': 'Public'},
    {'Institution': 'Virginia Union University', 'City': 'Richmond', 'State': 'VA', 'Founded': 1865, 'Type': 'Private'},
    {'Institution': 'Voorhees College', 'City': 'Denmark', 'State': 'SC', 'Founded': 1897, 'Type': 'Private'},
    {'Institution': 'West Virginia State University', 'City': 'Institute', 'State': 'WV', 'Founded': 1891, 'Type': 'Public'},
    {'Institution': 'Wilberforce University', 'City': 'Wilberforce', 'State': 'OH', 'Founded': 1856, 'Type': 'Private'},
    {'Institution': 'Wiley College', 'City': 'Marshall', 'State': 'TX', 'Founded': 1873, 'Type': 'Private'},
    {'Institution': 'Winston-Salem State University', 'City': 'Winston-Salem', 'State': 'NC', 'Founded': 1892, 'Type': 'Public'},
    {'Institution': 'Xavier University of Louisiana', 'City': 'New Orleans', 'State': 'LA', 'Founded': 1915, 'Type': 'Private'},
    # You can add more institutions if necessary
]

# Convert the list to a pandas dataframe
df = pd.DataFrame(hbcus)

# Display the dataframe
print(df)
from geopy.geocoders import Nominatim
from geopy.extra.rate_limiter import RateLimiter

# Initialize geocoder
geolocator = Nominatim(user_agent="hbcus_locator")
geocode = RateLimiter(geolocator.geocode, min_delay_seconds=1)

# Function to get latitude and longitude
def get_coordinates(row):
    try:
        location = geolocator.geocode(f"{row['Institution']}, {row['City']}, {row['State']}")
        if location:
            return pd.Series({'Latitude': location.latitude, 'Longitude': location.longitude})
        else:
            # If not found, geocode using city and state only
            location = geolocator.geocode(f"{row['City']}, {row['State']}")
            if location:
                return pd.Series({'Latitude': location.latitude, 'Longitude': location.longitude})
            else:
                return pd.Series({'Latitude': None, 'Longitude': None})
    except Exception as e:
        print(f"Error geocoding {row['Institution']}: {e}")
        return pd.Series({'Latitude': None, 'Longitude': None})

# Apply the function to each row
df[['Latitude', 'Longitude']] = df.apply(get_coordinates, axis=1)

# Now you can use df to map the locations
print(df)

