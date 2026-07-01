# =============================================================================
# R/demo_data_k12.R — Deterministic fake K-12 data for dashboard previews
# -----------------------------------------------------------------------------
# All values are fixed (no random). Used by the Architect's template previews
# and by the GCPS Theme Preview tab.
# =============================================================================

# District-level KPIs (deterministic)
demo_district_kpis <- list(
  list(key = "Enrollment", val = "82,453", delta = "\u25B2 1.2%", up = TRUE),
  list(key = "Schools", val = "84", delta = "\u2014", up = FALSE),
  list(key = "% Prof/Dist", val = "41.8", delta = "\u25B2 1.4%", up = TRUE),
  list(key = "Grad rate", val = "82.6", delta = "\u25B2 1.6%", up = TRUE)
)

# 5-year proficiency trend (deterministic)
demo_trend_years <- c(
  "2020\u201321",
  "2021\u201322",
  "2022\u201323",
  "2023\u201324",
  "2024\u201325"
)
demo_trend_pcts <- c("36.2%", "37.8%", "39.1%", "40.4%", "41.8%")
demo_trend_heights <- c("62%", "70%", "78%", "88%", "100%")

# School-level sample data (deterministic)
demo_schools <- data.frame(
  school = c(
    "Central Gwinnett",
    "Collins Hill",
    "Dacula",
    "Discovery",
    "Grayson",
    "Mill Creek",
    "Mountain View",
    "North Gwinnett",
    "Parkview",
    "Peachtree Ridge",
    "Shiloh",
    "South Gwinnett"
  ),
  enrollment = c(
    2834,
    3102,
    2567,
    2345,
    3210,
    2987,
    2654,
    2876,
    2543,
    3012,
    2234,
    2465
  ),
  proficiency = c(
    42.1,
    44.3,
    39.8,
    41.2,
    45.6,
    43.1,
    40.5,
    46.2,
    38.9,
    43.7,
    37.4,
    39.1
  ),
  stringsAsFactors = FALSE
)
