# =============================================================================
# R/template_registry.R — K-12 report templates for the Dashboard Architect
# =============================================================================

template_registry <- list(
  boe_area_snapshot = list(
    name = "BOE Area Snapshot",
    description = "Board of Education area performance snapshot",
    sections = c("kpi_strip", "trend_bars", "school_table")
  ),
  district_summary = list(
    name = "District Summary",
    description = "District-wide performance summary",
    sections = c("kpi_strip", "trend_bars")
  ),
  school_detail = list(
    name = "School Detail",
    description = "Individual school performance detail",
    sections = c("kpi_strip", "metric_table")
  )
)
