# =============================================================================
# R/boe_preview.R — Board of Education report preview component
# =============================================================================
# Renders a BOE-style report preview. Used by the Architect's Preview tab
# when preview_mode == "template".

render_boe_preview <- function(
  template_id = "boe_area_snapshot",
  theme_id = "gcps_board_report",
  embedded = FALSE
) {
  theme <- theme_registry[[theme_id]]
  if (is.null(theme)) {
    theme <- theme_registry[[1]]
  }

  tpl <- template_registry[[template_id]]
  if (is.null(tpl)) {
    tpl <- template_registry[[1]]
  }

  bg <- theme$bg_page %||% "#FFFFFF"
  card_bg <- theme$bg_card %||% "#F7F6F3"
  accent <- theme$accent %||% "#660000"
  ff <- theme$font_family %||% "'Segoe UI', system-ui, sans-serif"

  # Deterministic K-12 data
  kpis <- demo_district_kpis

  kpi_cards <- paste(
    lapply(seq_along(kpis), function(i) {
      kpi <- kpis[[i]]
      sprintf(
        '<div style="flex:1;background:%s;border-radius:6px;padding:16px;border-left:3px solid %s;">
          <div style="font-size:12px;color:#6B6560;">%s</div>
          <div style="font-size:24px;font-weight:700;color:%s;">%s</div>
          <div style="font-size:12px;color:#10B981;">%s</div>
        </div>',
        card_bg,
        accent,
        kpi$label,
        "#1F2120",
        kpi$value,
        kpi$delta
      )
    }),
    collapse = ""
  )

  trend_bars <- paste(
    lapply(seq_along(demo_trend_pcts), function(i) {
      sprintf(
        '<div style="display:flex;flex-direction:column;align-items:center;flex:1;">
          <div style="width:100%%;height:%s;background:%s;border-radius:3px 3px 0 0;"></div>
          <span style="font-size:11px;color:#6B6560;margin-top:4px;">%s</span>
          <span style="font-size:11px;font-weight:600;">%s</span>
        </div>',
        demo_trend_heights[[i]],
        accent,
        demo_trend_years[[i]],
        demo_trend_pcts[[i]]
      )
    }),
    collapse = ""
  )

  school_rows <- paste(
    lapply(seq_len(min(nrow(demo_schools), 8)), function(i) {
      sprintf(
        '<tr><td style="padding:6px 12px;border-bottom:1px solid #E5E7EB;font-size:13px;">%s</td>
         <td style="padding:6px 12px;border-bottom:1px solid #E5E7EB;font-size:13px;text-align:right;">%s</td>
         <td style="padding:6px 12px;border-bottom:1px solid #E5E7EB;font-size:13px;text-align:right;">%s%%</td></tr>',
        demo_schools$school[i],
        format(demo_schools$enrollment[i], big.mark = ","),
        demo_schools$proficiency[i]
      )
    }),
    collapse = ""
  )

  html <- sprintf(
    '<div style="font-family:%s;background:%s;padding:24px;max-width:900px;margin:0 auto;">
      <div style="display:flex;align-items:center;gap:12px;margin-bottom:24px;">
        <div style="width:40px;height:40px;background:%s;border-radius:6px;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:14px;">G</div>
        <div>
          <div style="font-size:18px;font-weight:700;color:%s;">%s</div>
          <div style="font-size:12px;color:#6B6560;">Gwinnett County Public Schools</div>
        </div>
      </div>
      <div style="display:flex;gap:16px;margin-bottom:24px;">%s</div>
      <div style="background:%s;border-radius:8px;padding:16px;margin-bottom:24px;">
        <div style="font-size:14px;font-weight:600;margin-bottom:12px;color:%s;">Proficiency Trend</div>
        <div style="display:flex;gap:8px;align-items:flex-end;height:120px;">%s</div>
      </div>
      <div style="background:%s;border-radius:8px;padding:16px;">
        <div style="font-size:14px;font-weight:600;margin-bottom:12px;color:%s;">School Comparison</div>
        <table style="width:100%%;border-collapse:collapse;">
          <tr style="background:#F3F4F6;">
            <th style="padding:8px 12px;text-align:left;font-size:12px;font-weight:600;">School</th>
            <th style="padding:8px 12px;text-align:right;font-size:12px;font-weight:600;">Enrollment</th>
            <th style="padding:8px 12px;text-align:right;font-size:12px;font-weight:600;">Proficiency</th>
          </tr>
          %s
        </table>
      </div>
    </div>',
    ff,
    bg,
    accent,
    "#1F2120",
    tpl$name,
    kpi_cards,
    card_bg,
    "#1F2120",
    trend_bars,
    card_bg,
    "#1F2120",
    school_rows
  )

  if (embedded) html else HTML(html)
}
