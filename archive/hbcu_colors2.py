# Re-importing necessary modules due to the previous execution interruption
import pandas as pd

# Load the files again
file_path_1 = "hbcu_loc_colors.csv"
file_path_2 = "hbcu_school_colors.csv"

hbcu_loc_colors = pd.read_csv(file_path_1)
hbcu_school_colors = pd.read_csv(file_path_2)

# Display columns to understand structure
hbcu_loc_colors.columns, hbcu_school_colors.columns

# Display column names again to verify their availability and check for any discrepancies
print("Columns in hbcu_loc_colors:", hbcu_loc_colors.columns)
print("Columns in hbcu_school_colors:", hbcu_school_colors.columns)

# Ensure consistency in naming
# Renaming the 'school' related columns to standardize across both DataFrames if needed
if 'College_Name' in hbcu_loc_colors.columns:
    hbcu_loc_colors.rename(columns={"College_Name": "school"}, inplace=True)
if 'school' not in hbcu_school_colors.columns:
    # Checking if there's a similarly named column that needs renaming
    similar_columns = [col for col in hbcu_school_colors.columns if 'school' in col.lower()]
    if similar_columns:
        hbcu_school_colors.rename(columns={similar_columns[0]: 'school'}, inplace=True)

# Attempt fuzzy matching again after ensuring columns are consistent
hbcu_school_colors["matched_school"] = hbcu_school_colors["school"].apply(
    lambda x: fuzzy_match(x, hbcu_loc_colors["school"].tolist())
)

# Merging both dataframes based on matched school names
merged_df = pd.merge(
    hbcu_loc_colors,
    hbcu_school_colors,
    left_on="school",
    right_on="matched_school",
    how="left"
)

# Display the merged dataframe to the user for review
import ace_tools as tools
tools.display_dataframe_to_user(name="Merged HBCU School Data with Colors (Final Attempt)", dataframe=merged_df)
