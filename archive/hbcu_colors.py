from bs4 import BeautifulSoup
import pandas as pd

# Load the HTML content from the provided file
with open("hbcu_colors.html", "r", encoding="utf-8") as file:
    html_content = file.read()

# Parse the HTML using BeautifulSoup
soup = BeautifulSoup(html_content, 'html.parser')

# Initialize lists to store data
schools = []
primary_colors = []
secondary_colors = []

# Extract the school names and their colors
div_cards = soup.find_all('a', class_='ColorCard_card__D6Ei5')
for card in div_cards:
    school_name = card.find_next('h3', class_='ColorCard_colorTitle__d5eqp').get_text(strip=True)
    color_divs = card.find_all('div', class_='ColorCard_colorDiv__iK_GW')
    
    # Extract colors
    colors = [div['style'].split('background-color: ')[1].split(';')[0] for div in color_divs]
    
    # Assign primary and secondary colors if available
    primary_color = colors[0] if len(colors) > 0 else None
    secondary_color = colors[1] if len(colors) > 1 else None
    
    # Append to lists
    schools.append(school_name)
    primary_colors.append(primary_color)
    secondary_colors.append(secondary_color)

# Create a DataFrame
color_data = pd.DataFrame({
    'school': schools,
    'primary_color': primary_colors,
    'secondary_color': secondary_colors
})

# Save to CSV
color_data.to_csv('/mnt/data/hbcu_school_colors.csv', index=False)

print("Data extracted and saved to hbcu_school_colors.csv")
