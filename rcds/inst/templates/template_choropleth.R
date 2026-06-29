################################################################################
## RCDS Template: Sequential Choropleth
## Replace <PLACEHOLDERS>. Designed to drop straight onto the dark canvas.
################################################################################

library(rcds)
library(ggplot2)
library(sf)

# 1. FONT VOICE ---------------------------------------------------------------
rcds_fonts("editorial")           # default | editorial | vintage | fantasy | techno

# 2. DATA ---------------------------------------------------------------------
# geo <- st_read("<PATH>") |> st_transform(<CRS>)   # e.g. 5070 for CONUS
# geo$value <- <NUMERIC_FIELD>

# 3. MAP ----------------------------------------------------------------------
main <- ggplot(geo) +
  geom_sf(aes(fill = value), colour = NA) +
  geom_sf(data = <OUTLINE_SF>, fill = NA,
          colour = rcds_color("ink.hairline_dark"), linewidth = 0.2) +
  scale_fill_rcds_c(
    palette = "seq_blue",                     # seq_blue | seq_amber | seq_teal
    name = "<LEGEND TITLE>",
    labels = scales::label_comma(),
    guide = guide_colorbar(title.position = "top", title.hjust = 0.5,
                           barwidth = unit(18, "cm"), barheight = unit(0.5, "cm"))
  ) +
  labs(
    title    = "<TITLE>",
    subtitle = "<SUBTITLE>",
    caption  = rcds_signature(
      challenge = "#30DayMapChallenge 2024 Day <N>: Choropleth",
      sources   = c("<SOURCE 1>", "<SOURCE 2>"))
  ) +
  theme_rcds_map(base = 14, canvas = "dark")

# 4. LOCATOR (optional) -------------------------------------------------------
# loc <- rcds_locator(context = <CONTEXT_SF>, highlight = <AOI_SF>)

# 5. COMPOSE & EXPORT ---------------------------------------------------------
# fig <- rcds_compose(main, locator = loc, layout = "poster")
rcds_export(main, "day<N>_choropleth.png", preset = "poster_land", canvas = "dark")
