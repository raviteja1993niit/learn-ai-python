# 📊 Plotly & Dash — Interactive Visualizations & Dashboards

## What are Plotly & Dash?
- **Plotly** — Python library for beautiful, interactive charts (zoom, hover, filter)
- **Dash** — Web app framework by Plotly for building analytical dashboards (no JS needed)

## Plotly vs Matplotlib vs Seaborn
| | Plotly | Matplotlib | Seaborn |
|-|--------|-----------|---------|
| Interactive | ✅ Yes | ❌ Static | ❌ Static |
| 3D charts | ✅ | Limited | ❌ |
| Web dashboards | ✅ (via Dash) | ❌ | ❌ |
| Learning curve | Medium | Low | Low |

## Key Plotly Charts
```python
import plotly.express as px

px.scatter(df, x="sepal_width", y="sepal_length", color="species", hover_data=["petal_width"])
px.bar(df, x="country", y="GDP", color="continent", animation_frame="year")
px.line(df, x="date", y="price", title="Stock Price")
px.choropleth(df, locations="iso_alpha", color="gdpPercap")  # world map
px.sunburst(df, path=["continent", "country"], values="pop")  # hierarchy
```

## Dash App Structure
```python
from dash import Dash, dcc, html, Input, Output
app = Dash(__name__)
app.layout = html.Div([
    dcc.Dropdown(id="dropdown", options=[...]),
    dcc.Graph(id="graph")
])
@app.callback(Output("graph","figure"), Input("dropdown","value"))
def update(value):
    return px.bar(df[df.category==value], x="x", y="y")
app.run(debug=True)
```

## Learning Path
1. `pip install plotly dash`
2. Replace matplotlib charts with Plotly Express
3. Build a single-page Dash dashboard
4. Add callbacks for interactivity
5. Deploy on Heroku / Railway

## What to Build
- [ ] Interactive EDA dashboard for any dataset
- [ ] Real-time ML model metrics dashboard
- [ ] Stock price tracker with candlestick chart
- [ ] COVID/AQI interactive map (combine with folium)

## Related Folders
- `data-science/Tensorddash-main/` — TensorBoard-style tracking
- `data-science/Autoviz-main/` — automated visualization
- `data-science/folium-master/` — geospatial maps