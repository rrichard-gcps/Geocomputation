import csv

# Assuming 'school_data' is the list of dictionaries containing detailed school information as gathered from the scraping step.

# Save to CSV file
output_csv_path = "ghsa_schools.csv"

# Define the keys for the CSV
csv_columns = ["school_name", "address", "city_state_zip", "colors", "mascot", "email", "website", "phone", "ad_phone", "bd_phone", "fax"]

# Write the data to a CSV file
with open(output_csv_path, mode='w', newline='', encoding='utf-8') as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=csv_columns)
    writer.writeheader()
    for school in school_data:
        writer.writerow(school)

print(f"Data successfully saved to {output_csv_path}")
