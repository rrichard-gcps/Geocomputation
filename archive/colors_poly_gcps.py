# Access the active layer (replace 'Cluster Layer Name' with your actual layer name)
layer = QgsProject.instance().mapLayersByName('High_School_Clusters')[0]

# Define the font color mapping
label_colors = {
    "Archer": "#CC3333",
    "Berkmar": "#003366",
    "Lanier": "#CC6600",
    "Seckinger": "#0099CC",
    "Dacula": "#CCCC99",
    "Mill Creek": "#993333",
    "Parkview": "#FF6633",
    "South Gwinnett": "#000033",
    "Brookwood": "#660000",
    "Grayson": "#336633",
    "Central Gwinnett": "#FFCC33",
    "Duluth": "#330066",
    "Collins Hill": "#336633",
    "Meadowcreek": "#6699CC",
    "North Gwinnett": "#CC3333",
    "Mountain View": "#CCCC66",
    "Discovery": "#66CC33",
    "Peachtree Ridge": "#000066",
    "Shiloh": "#000000",
    "Norcross": "#CCCCCC"
}

# Enable labeling
layer_settings = QgsPalLayerSettings()
layer_settings.fieldName = 'High_Label'  # Replace with the actual field name for cluster names
layer_settings.isExpression = False
layer_settings.enabled = True

# Set up a categorized label configuration
rules = []

for cluster, color in label_colors.items():
    rule = QgsRuleBasedLabeling.Rule(QgsPalLayerSettings())
    rule.description = cluster
    rule.expression = f'"ClusterName" = \'{cluster}\''
    rule.symbol = QgsTextFormat()
    
    # Set the font color
    text_format = QgsTextFormat()
    text_format.setFont(QFont("Arial", 10))  # Change font and size if needed
   
