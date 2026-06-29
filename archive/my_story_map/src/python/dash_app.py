# dash_app.py
import dash
import dash_core_components as dcc
import dash_html_components as html
import plotly.express as px
import pandas as pd

# Sample data for the story map
data = pd.DataFrame({
    'name': ['Morehouse College'],
    'lat': [33.7460],
    'lon': [-84.4153],
    'info': ['Public Health Sciences Institute']
})

fig = px.scatter_mapbox(data, lat='lat', lon='lon', hover_name='name',
                        hover_data=['info'], zoom=10, height=500)
fig.update_layout(mapbox_style="carto-positron")

app = dash.Dash(__name__)

app.layout = html.Div([
    html.H1("Public Health Story Map"),
    dcc.Graph(figure=fig)
])

if __name__ == '__main__':
    app.run_server(debug=True)
