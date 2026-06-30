# =============================================================================
# R/metric_registry.R — K-12 metric definitions for the Dashboard Architect
# =============================================================================

metric_registry <- list(
  enrollment = list(
    id = "enrollment",
    label = "Enrollment",
    unit = "count",
    format = "#,##0"
  ),
  proficiency = list(
    id = "proficiency",
    label = "% Proficient/Dist.",
    unit = "%",
    format = "0.0"
  ),
  graduation = list(
    id = "graduation",
    label = "Graduation Rate",
    unit = "%",
    format = "0.0"
  ),
  attendance = list(
    id = "attendance",
    label = "Attendance Rate",
    unit = "%",
    format = "0.0"
  ),
  growth = list(
    id = "growth",
    label = "Growth Index",
    unit = "index",
    format = "0.0"
  )
)
