# generate_templates.R — GCPS Theme Studio project-template builders.
#
# Pure string/zip builders driven by a *theme list* in the shape emitted by the
# embedded studio's JS bridge (see www/theme-studio-app.js `render()` -> Shiny
# `input$ts_theme`). No Shiny here; the app.R server wires them into
# downloadHandlers. Deterministic, no network calls.
#
# Theme list shape (all fields optional — gcps_resolve_theme fills defaults):
#   source, type, canvas, surface, sunken, border, border_strong,
#   text, text_2, text_3, dark, accent, accent_hover, accent_tint,
#   font_label, font_stack, font_google, base_size, ratio, heading_weight,
#   scale {micro,caption,body,bodyLg,h3,h2,h1,display},
#   palette [{n,hex,name}], palette_hex [...]
#
# Part C also uses gcps_config_theme_from_studio() to route build_config().

# ─────────────────────────────────────────────────────────────────────────────
# Normalizer + default theme (first-paint / pre-emit fallback)
# ─────────────────────────────────────────────────────────────────────────────

# The GCPS default — Warm Paper surfaces, District Maroon accent, Source Sans 3,
# 15px @ 1.2 ratio, teal sequential ramp. MUST match the studio's first paint
# (state defaults in www/theme-studio-app.js lines 12-24).
gcps_default_theme <- function() {
  sc <- list(
    micro = 10.4,
    caption = 12.5,
    body = 15,
    bodyLg = 16.6,
    h3 = 18,
    h2 = 21.6,
    h1 = 25.9,
    display = 31.1
  )
  pal_hex <- c("#B8DBE0", "#79B8C3", "#3F9CA9", "#007C91", "#005E70")
  list(
    source = "Teal",
    type = "sequential",
    canvas = "#F7F6F3",
    surface = "#FFFFFF",
    sunken = "#F1EFEA",
    border = "#E4E1D9",
    border_strong = "#CFCBC0",
    text = "#1F2120",
    text_2 = "#5C5A54",
    text_3 = "#8A8780",
    dark = FALSE,
    accent = "#660000",
    accent_hover = "#540000",
    accent_tint = "#EBD8D8",
    font_label = "Source Sans 3",
    font_stack = "'Source Sans 3',system-ui,sans-serif",
    font_google = "Source+Sans+3:wght@400;500;600;700",
    base_size = 15,
    ratio = "1.2",
    heading_weight = 600,
    scale = sc,
    palette = lapply(seq_along(pal_hex), function(i) {
      list(n = i, hex = pal_hex[i], name = NULL)
    }),
    palette_hex = pal_hex
  )
}

# Null-safe resolver: returns the studio theme if it looks complete, else default.
gcps_resolve_theme <- function(ts = NULL) {
  d <- gcps_default_theme()
  if (is.null(ts)) {
    return(d)
  }
  if (!is.list(ts)) {
    return(d)
  }
  # Require at least accent + canvas to consider the studio emitted.
  if (is.null(ts$accent) || is.null(ts$canvas)) {
    return(d)
  }
  # Fill any missing top-level field from the default.
  for (k in names(d)) {
    if (is.null(ts[[k]])) ts[[k]] <- d[[k]]
  }
  # Scale: ensure every named size is present.
  if (!is.list(ts$scale)) {
    ts$scale <- d$scale
  }
  for (k in names(d$scale)) {
    if (is.null(ts$scale[[k]])) ts$scale[[k]] <- d$scale[[k]]
  }
  # Palette: fall back to default if empty.
  if (length(ts$palette_hex) == 0) {
    ts$palette_hex <- d$palette_hex
    ts$palette <- d$palette
  }
  ts
}

# ─────────────────────────────────────────────────────────────────────────────
# Shared content builders
# ─────────────────────────────────────────────────────────────────────────────

# CSS custom-properties export (mirrors the studio's CSS export tab).
# Used verbatim by flexdashboard styles.css and the Shiny starter www/theme.css.
gcps_css_vars_export <- function(t) {
  sc <- t$scale
  hexes <- t$palette_hex
  sg <- gcps_slug(t)
  paste0(
    ":root{\n",
    "  /* surfaces */\n",
    "  --canvas:",
    t$canvas,
    ";\n",
    "  --surface:",
    t$surface,
    ";\n",
    "  --sunken:",
    t$sunken,
    ";\n",
    "  --border:",
    t$border,
    ";\n",
    "  --border-strong:",
    t$border_strong,
    ";\n",
    "  /* text */\n",
    "  --text:",
    t$text,
    ";\n",
    "  --text-2:",
    t$text_2,
    ";\n",
    "  --text-3:",
    t$text_3,
    ";\n",
    "  /* accent */\n",
    "  --accent:",
    t$accent,
    ";\n",
    "  --accent-hover:",
    t$accent_hover,
    ";\n",
    "  --accent-tint:",
    t$accent_tint,
    ";\n",
    "  /* type */\n",
    "  --font-sans:",
    t$font_stack,
    ";\n",
    "  --fs-display:",
    sc$display,
    "px; --fs-h1:",
    sc$h1,
    "px; --fs-h2:",
    sc$h2,
    "px; --fs-h3:",
    sc$h3,
    "px;\n",
    "  --fs-body-lg:",
    sc$bodyLg,
    "px; --fs-body:",
    sc$body,
    "px; --fs-caption:",
    sc$caption,
    "px; --fs-micro:",
    sc$micro,
    "px;\n",
    "  /* spacing & radius */\n",
    "  --s1:4px; --s2:8px; --s3:12px; --s4:16px; --s5:24px; --s6:32px; --s7:48px; --s8:64px;\n",
    "  --r-sm:6px; --r-md:10px; --r-lg:14px;\n",
    "  /* data palette · ",
    t$source,
    " ",
    t$type,
    " */\n",
    paste0(
      "  --gcps-",
      sg,
      "-",
      seq_along(hexes),
      ": ",
      hexes,
      ";",
      collapse = "\n"
    ),
    "\n",
    "}\n"
  )
}

# Slug for R/JS palette variable names (matches studio's slug()).
gcps_slug <- function(t) {
  s <- tolower(paste0(t$source, "_", t$type))
  s <- gsub("[^a-z0-9]+", "_", s)
  s <- gsub("^_|_$", "", s)
  s
}

# R/theme_gcps.R — ggplot2 theme + palette scales + tokens.
# Mirrors the studio's R export tab (buildExport() R branch).
gcps_theme_r_file <- function(t) {
  sc <- t$scale
  pal <- t$palette
  hexes <- t$palette_hex
  sg <- gcps_slug(t)
  has_sem <- any(vapply(
    pal,
    function(p) !is.null(p$name) && !is.na(p$name) && nchar(p$name) > 0,
    logical(1)
  ))
  gradient <- t$type %in% c("sequential", "continuous", "tints", "diverging")

  out <- c(
    paste0("# GCPS ", t$source, " theme — generated by GCPS Theme Studio"),
    "# Mirror of the studio's R export tab. Edit in the studio, then re-export.",
    "library(ggplot2)",
    "",
    "gcps_tokens <- list(",
    paste0(
      "  canvas = \"",
      t$canvas,
      "\", surface = \"",
      t$surface,
      "\", sunken = \"",
      t$sunken,
      "\","
    ),
    paste0(
      "  border = \"",
      t$border,
      "\", text = \"",
      t$text,
      "\", text_muted = \"",
      t$text_2,
      "\", accent = \"",
      t$accent,
      "\""
    ),
    ")",
    ""
  )

  if (has_sem) {
    entries <- vapply(
      pal,
      function(p) {
        nm <- if (!is.null(p$name) && !is.na(p$name) && nchar(p$name) > 0) {
          p$name
        } else {
          paste0("series_", p$n)
        }
        paste0("  \"", nm, "\" = \"", p$hex, "\"")
      },
      character(1)
    )
    out <- c(out, paste0(sg, " <- c("), paste(entries, collapse = ",\n"), ")")
  } else {
    out <- c(
      out,
      paste0(sg, " <- c("),
      paste0("  ", paste0("\"", hexes, "\"", collapse = ", ")),
      ")"
    )
  }
  out <- c(out, "")

  if (gradient) {
    out <- c(
      out,
      paste0(
        "scale_fill_gcps  <- function(...) scale_fill_gradientn(colours = ",
        sg,
        ", ...)"
      ),
      paste0(
        "scale_color_gcps <- function(...) scale_color_gradientn(colours = ",
        sg,
        ", ...)"
      ),
      ""
    )
  } else {
    out <- c(
      out,
      paste0(
        "scale_fill_gcps  <- function(...) scale_fill_manual(values = ",
        sg,
        ", ...)"
      ),
      paste0(
        "scale_color_gcps <- function(...) scale_color_manual(values = ",
        sg,
        ", ...)"
      ),
      ""
    )
  }

  out <- c(
    out,
    paste0(
      "theme_gcps <- function(base_size = ",
      t$base_size,
      ", base_family = \"",
      t$font_label,
      "\") {"
    ),
    "  theme_minimal(base_size = base_size, base_family = base_family) +",
    "    theme(",
    "      plot.background  = element_rect(fill = gcps_tokens$canvas, colour = NA),",
    "      panel.background = element_rect(fill = gcps_tokens$surface, colour = NA),",
    "      panel.grid.minor = element_blank(),",
    "      panel.grid.major = element_line(colour = gcps_tokens$border),",
    "      text             = element_text(colour = gcps_tokens$text),",
    "      plot.title       = element_text(face = \"bold\", colour = gcps_tokens$text),",
    "      axis.text        = element_text(colour = gcps_tokens$text_muted)",
    "    )",
    "}"
  )
  paste(out, collapse = "\n")
}

# Quarto theme SCSS — /*-- scss:defaults --*/ + /*-- scss:rules --*/.
gcps_theme_scss <- function(t) {
  sc <- t$scale
  glink <- if (!is.null(t$font_google) && nchar(t$font_google) > 0) {
    paste0(
      "\n@import url('https://fonts.googleapis.com/css2?family=",
      t$font_google,
      "&display=swap');"
    )
  } else {
    ""
  }
  paste0(
    "/*-- scss:defaults --*/",
    glink,
    "\n$body-bg:        ",
    t$canvas,
    ";",
    "\n$body-color:     ",
    t$text,
    ";",
    "\n$primary:        ",
    t$accent,
    ";",
    "\n$border-color:   ",
    t$border,
    ";",
    "\n$link-color:     ",
    t$accent,
    ";",
    "\n$font-family-sans-serif: ",
    t$font_stack,
    ";",
    "\n$font-size-base: ",
    sc$body,
    "px;",
    "\n$h1-font-size:   ",
    sc$h1,
    "px;",
    "\n$h2-font-size:   ",
    sc$h2,
    "px;",
    "\n$h3-font-size:   ",
    sc$h3,
    "px;",
    "\n\n/*-- scss:rules --*/",
    "\n.card, .callout-note {",
    "\n  background-color: ",
    t$surface,
    " !important;",
    "\n  border: 1px solid ",
    t$border,
    " !important;",
    "\n  border-radius: 12px;",
    "\n}",
    "\n.valuebox { background-color: ",
    t$accent,
    " !important; }",
    "\n.navbar { background-color: ",
    t$surface,
    " !important; border-bottom: 1px solid ",
    t$border,
    "; }",
    "\n"
  )
}

# _brand.yml (Quarto >=1.6). SCSS above is the reliable fallback.
gcps_brand_yml <- function(t) {
  sc <- t$scale
  google <- sub(":wght@.*$", "", t$font_google %||% "")
  # Quarto _brand.yml schema: palette must be a NAMED object (id -> hex);
  # only background/foreground/primary are valid color keys; typography.base
  # takes family+size, headings takes family+weight (NO size); google fonts go
  # under typography.fonts with source: google.
  pal_names <- paste0("color-", seq_along(t$palette_hex))
  pal_yaml <- paste0(
    "    ",
    pal_names,
    ": \"",
    t$palette_hex,
    "\"",
    collapse = "\n"
  )
  fstk <- paste0("\"", t$font_stack, "\"")
  fonts_block <- if (nchar(google) > 0) {
    paste0(
      "  fonts:\n",
      "    - family: ",
      gsub("\\+", " ", google),
      "\n",
      "      source: google\n"
    )
  } else {
    ""
  }
  paste0(
    "color:\n",
    "  palette:\n",
    pal_yaml,
    "\n",
    "  background: \"",
    t$canvas,
    "\"\n",
    "  foreground: \"",
    t$text,
    "\"\n",
    "  primary:    \"",
    t$accent,
    "\"\n",
    "typography:\n",
    fonts_block,
    "  base:\n",
    "    family: ",
    fstk,
    "\n",
    "    size: ",
    sc$body,
    "px\n",
    "  headings:\n",
    "    family: ",
    fstk,
    "\n",
    "    weight: ",
    t$heading_weight,
    "\n"
  )
}

# Shared README header used by every bundle.
gcps_readme_header <- function(t) {
  paste0(
    "# GCPS Themed Starter — ",
    t$source,
    " / ",
    t$type,
    "\n\n",
    "Baked from the GCPS Theme Studio. Surfaces, accent, typography, and the\n",
    "active data palette are all set to your current studio selections.\n\n",
    "- **Surfaces:** ",
    t$canvas,
    " / ",
    t$surface,
    " / ",
    t$sunken,
    "\n",
    "- **Accent:** ",
    t$accent,
    "\n",
    "- **Font:** ",
    t$font_label,
    " @ ",
    t$base_size,
    "px (ratio ",
    t$ratio,
    ")\n",
    "- **Palette:** ",
    paste(t$palette_hex, collapse = ", "),
    "\n"
  )
}

# ─────────────────────────────────────────────────────────────────────────────
# Template builders (each returns a NAMED list of path -> content strings)
# ─────────────────────────────────────────────────────────────────────────────

gcps_template_quarto_doc <- function(t) {
  sc <- t$scale
  qmd <- paste0(
    "---\n",
    "title: \"GCPS District Snapshot\"\n",
    "author: \"GCPS Analytics\"\n",
    "format:\n",
    "  html:\n",
    "    theme: theme.scss\n",
    "    toc: true\n",
    "    embed-resources: true\n",
    "brand: _brand.yml\n",
    "---\n\n",
    "## Introduction\n\n",
    "This report is themed with the GCPS **",
    t$source,
    "** palette and the\n",
    "**",
    t$font_label,
    "** typeface. All colors and fonts come from your\n",
    "current Theme Studio selections.\n\n",
    "::: {.callout-note appearance=\"minimal\"}\n",
    "Accent color: <span style=\"color:",
    t$accent,
    ";font-weight:600;\">",
    t$accent,
    "</span>.\n",
    ":::\n\n",
    "```{r}\n",
    "#| label: setup\n",
    "#| include: false\n",
    "source(\"R/theme_gcps.R\", chdir = TRUE)\n",
    "library(ggplot2)\n",
    "```\n\n",
    "## Proficiency trend\n\n",
    "```{r}\n",
    "#| label: trend-plot\n",
    "trend <- data.frame(\n",
    "  year = c(\"2021\", \"2022\", \"2023\", \"2024\", \"2025\"),\n",
    "  pct  = c(36.2, 37.8, 39.1, 40.4, 41.8)\n",
    ")\n",
    "ggplot(trend, aes(year, pct, fill = pct)) +\n",
    "  geom_col() +\n",
    "  scale_fill_gradientn(colours = ",
    gcps_slug(t),
    ") +\n",
    "  theme_gcps() +\n",
    "  labs(title = \"% Proficient / Distinguished\", y = NULL, x = NULL)\n",
    "```\n"
  )
  list(
    "report.qmd" = qmd,
    "theme.scss" = gcps_theme_scss(t),
    "_brand.yml" = gcps_brand_yml(t),
    "R/theme_gcps.R" = gcps_theme_r_file(t),
    "README.md" = paste0(
      gcps_readme_header(t),
      "\n## Render\n\n```\nquarto render report.qmd\n```\n"
    )
  )
}

gcps_template_quarto_site <- function(t) {
  index <- paste0(
    "---\n",
    "title: \"GCPS Analytics\"\n",
    "---\n\n",
    "## Welcome\n\n",
    "A multi-page Quarto website themed with the GCPS **",
    t$source,
    "** studio selection, using the **",
    t$font_label,
    "** typeface (accent `",
    t$accent,
    "`). See [Analysis](analysis.qmd) and [About](about.qmd).\n"
  )
  analysis <- paste0(
    "---\n",
    "title: \"Analysis\"\n",
    "---\n\n",
    "```{r}\n",
    "#| include: false\n",
    "source(\"R/theme_gcps.R\", chdir = TRUE)\n",
    "library(ggplot2)\n",
    "```\n\n",
    "```{r}\n",
    "ggplot(data.frame(x = 1:5, y = c(36, 38, 39, 40, 42)),\n",
    "       aes(x, y, fill = y)) +\n",
    "  geom_col() +\n",
    "  scale_fill_gradientn(colours = ",
    gcps_slug(t),
    ") +\n",
    "  theme_gcps() +\n",
    "  labs(title = \"Proficiency trend\", x = NULL, y = NULL)\n",
    "```\n"
  )
  about <- paste0(
    "---\n",
    "title: \"About\"\n",
    "---\n\n",
    "Generated by GCPS Theme Studio. Accent: `",
    t$accent,
    "`. Font: `",
    t$font_label,
    "`.\n"
  )
  yml <- paste0(
    "project:\n",
    "  type: website\n",
    "format:\n",
    "  html:\n",
    "    theme: theme.scss\n",
    "brand: _brand.yml\n",
    "website:\n",
    "  title: \"GCPS Analytics\"\n",
    "  navbar:\n",
    "    background: ",
    t$surface,
    "\n",
    "    left:\n",
    "      - href: index.qmd\n",
    "        text: Home\n",
    "      - analysis.qmd\n",
    "      - about.qmd\n"
  )
  list(
    "_quarto.yml" = yml,
    "index.qmd" = index,
    "analysis.qmd" = analysis,
    "about.qmd" = about,
    "theme.scss" = gcps_theme_scss(t),
    "_brand.yml" = gcps_brand_yml(t),
    "R/theme_gcps.R" = gcps_theme_r_file(t),
    "README.md" = paste0(
      gcps_readme_header(t),
      "\n## Preview\n\n```\nquarto preview\n```\n"
    )
  )
}

gcps_template_quarto_dashboard <- function(t) {
  sg <- gcps_slug(t)
  qmd <- paste0(
    "---\n",
    "title: \"GCPS District Dashboard\"\n",
    "format:\n",
    "  dashboard:\n",
    "    theme: theme.scss\n",
    "brand: _brand.yml\n",
    "---\n\n",
    "```{r}\n",
    "#| include: false\n",
    "source(\"R/theme_gcps.R\", chdir = TRUE)\n",
    "library(ggplot2)\n",
    "```\n\n",
    "## Row {height=\"20%\"}\n\n",
    "::: {.valuebox color=\"",
    t$accent,
    "\"}\n",
    "Enrollment\n\n",
    "82,453\n",
    ":::\n\n",
    "::: {.valuebox color=\"",
    t$accent,
    "\"}\n",
    "Grad rate\n\n",
    "82.6%\n",
    ":::\n\n",
    "## Row\n\n",
    "### Proficiency trend\n\n",
    "```{r}\n",
    "trend <- data.frame(year = 2021:2025, pct = c(36.2, 37.8, 39.1, 40.4, 41.8))\n",
    "ggplot(trend, aes(year, pct, fill = pct)) +\n",
    "  geom_col() +\n",
    "  scale_fill_gradientn(colours = ",
    sg,
    ") +\n",
    "  theme_gcps() +\n",
    "  labs(x = NULL, y = NULL)\n",
    "```\n\n",
    "### Cluster comparison\n\n",
    "```{r}\n",
    "clusters <- data.frame(name = c(\"A\", \"B\", \"C\", \"D\"), val = c(78, 82, 74, 88))\n",
    "ggplot(clusters, aes(name, val, fill = name)) +\n",
    "  geom_col() +\n",
    "  scale_fill_manual(values = head(",
    sg,
    ", 4)) +\n",
    "  theme_gcps() +\n",
    "  labs(x = NULL, y = NULL) +\n",
    "  theme(legend.position = \"none\")\n",
    "```\n"
  )
  list(
    "dashboard.qmd" = qmd,
    "theme.scss" = gcps_theme_scss(t),
    "_brand.yml" = gcps_brand_yml(t),
    "R/theme_gcps.R" = gcps_theme_r_file(t),
    "README.md" = paste0(
      gcps_readme_header(t),
      "\n## Render\n\n```\nquarto render dashboard.qmd\n```\n"
    )
  )
}

gcps_template_flexdashboard <- function(t) {
  sg <- gcps_slug(t)
  rmd <- paste0(
    "---\n",
    "title: \"GCPS District Dashboard\"\n",
    "output:\n",
    "  flexdashboard::flex_dashboard:\n",
    "    css: styles.css\n",
    "    orientation: rows\n",
    "---\n\n",
    "```{r setup, include=FALSE}\n",
    "source(\"R/theme_gcps.R\", chdir = TRUE)\n",
    "library(flexdashboard)\n",
    "library(ggplot2)\n",
    "```\n\n",
    "Row\n",
    "-----------------------------------------------------------------------\n\n",
    "### Enrollment\n\n",
    "```{r}\n",
    "valueBox(82453, icon = \"fa-users\",\n",
    "         color = \"",
    t$accent,
    "\")\n",
    "```\n\n",
    "### Graduation rate\n\n",
    "```{r}\n",
    "valueBox(\"82.6%\", icon = \"fa-graduation-cap\",\n",
    "         color = \"",
    t$accent,
    "\")\n",
    "```\n\n",
    "Row\n",
    "-----------------------------------------------------------------------\n\n",
    "### Proficiency trend\n\n",
    "```{r}\n",
    "trend <- data.frame(year = 2021:2025, pct = c(36.2, 37.8, 39.1, 40.4, 41.8))\n",
    "ggplot(trend, aes(factor(year), pct, fill = pct)) +\n",
    "  geom_col() +\n",
    "  scale_fill_gradientn(colours = ",
    sg,
    ") +\n",
    "  theme_gcps() +\n",
    "  labs(x = NULL, y = NULL)\n",
    "```\n"
  )
  list(
    "dashboard.Rmd" = rmd,
    "styles.css" = gcps_css_vars_export(t),
    "R/theme_gcps.R" = gcps_theme_r_file(t),
    "README.md" = paste0(
      gcps_readme_header(t),
      "\n## Render\n\n```r\nrmarkdown::render(\"dashboard.Rmd\")\n```\n"
    )
  )
}

gcps_template_shiny_app <- function(t) {
  sc <- t$scale
  sg <- gcps_slug(t)
  # bslib: use font_google only if a google family is named; else plain stack.
  font_line <- if (!is.null(t$font_google) && nchar(t$font_google) > 0) {
    fam <- sub(":wght@.*$", "", t$font_google)
    paste0("  base_font = bslib::font_google(\"", fam, "\"),")
  } else {
    paste0("  base_font = bslib::font_collection(\"", t$font_stack, "\"),")
  }
  app_r <- paste0(
    "# GCPS Theme Studio Shiny starter — font: ",
    t$font_label,
    " · accent: ",
    t$accent,
    "\n",
    "library(shiny)\n",
    "library(bslib)\n",
    "library(ggplot2)\n",
    "source(\"R/theme_gcps.R\", chdir = TRUE)\n\n",
    "ui <- page_sidebar(\n",
    "  title = \"GCPS Themed App\",\n",
    "  theme = bs_theme(\n",
    "    bg      = \"",
    t$canvas,
    "\",\n",
    "    fg      = \"",
    t$text,
    "\",\n",
    "    primary = \"",
    t$accent,
    "\",",
    font_line,
    "\n",
    "    bslib::bs_add_rules(\"www/theme.css\")\n",
    "  ),\n",
    "  sidebar = sidebar(\"Navigation\"),\n",
    "  layout_columns(\n",
    "    value_box(\"Enrollment\", \"82,453\",\n",
    "              theme_color = \"",
    t$accent,
    "\"),\n",
    "    value_box(\"Grad rate\", \"82.6%\",\n",
    "              theme_color = \"",
    t$accent,
    "\")\n",
    "  ),\n",
    "  card(card_header(\"Proficiency trend\"),\n",
    "       plotOutput(\"trend\"))\n",
    ")\n\n",
    "server <- function(input, output, session) {\n",
    "  output$trend <- renderPlot({\n",
    "    d <- data.frame(year = 2021:2025, pct = c(36.2, 37.8, 39.1, 40.4, 41.8))\n",
    "    ggplot(d, aes(factor(year), pct, fill = pct)) +\n",
    "      geom_col() +\n",
    "      scale_fill_gradientn(colours = ",
    sg,
    ") +\n",
    "      theme_gcps() +\n",
    "      labs(x = NULL, y = NULL)\n",
    "  })\n",
    "}\n\n",
    "shinyApp(ui, server)\n"
  )
  list(
    "app.R" = app_r,
    "www/theme.css" = gcps_css_vars_export(t),
    "R/theme_gcps.R" = gcps_theme_r_file(t),
    "README.md" = paste0(
      gcps_readme_header(t),
      "\n## Run\n\n```r\nshiny::runApp()\n```\n"
    )
  )
}

gcps_template_powerbi <- function(t) {
  sc <- t$scale
  theme <- list(
    name = paste0("GCPS ", t$source, " — ", t$type),
    dataColors = as.list(t$palette_hex),
    background = t$canvas,
    foreground = t$text,
    tableAccent = t$accent,
    textClasses = list(
      label = list(
        fontFace = t$font_label,
        fontSize = sc$caption,
        color = t$text_2
      ),
      title = list(fontFace = t$font_label, fontSize = sc$h3, color = t$text),
      callout = list(
        fontFace = t$font_label,
        fontSize = sc$bodyLg,
        color = t$text
      ),
      header = list(fontFace = t$font_label, fontSize = sc$body, color = t$text)
    )
  )
  json <- jsonlite::toJSON(theme, auto_unbox = TRUE, pretty = TRUE)
  list(
    "GCPS-theme.json" = json,
    "palette-swatches.txt" = paste(t$palette_hex, collapse = "\n"),
    "README.md" = paste0(
      gcps_readme_header(t),
      "\n## Import\n\n",
      "1. Power BI Desktop → **View** ribbon → **Themes** → dropdown →\n",
      "   **Browse for themes**.\n",
      "2. Select `GCPS-theme.json`.\n",
      "3. Re-apply visuals to pick up the new palette.\n"
    )
  )
}

# ─────────────────────────────────────────────────────────────────────────────
# Part D — Power BI .pbip project scaffold (PBIR enhanced-report format)
# ─────────────────────────────────────────────────────────────────────────────

# A folder-format Power BI Project that opens directly in Power BI Desktop
# (preview features: ".pbip save option" + "PBIR enhanced metadata" enabled).
# Reuses the B2 report-theme JSON as the theme payload — single source.
# JSON/TMDL kept minimal + schema-valid; assumptions documented in README.
gcps_template_pbip <- function(t) {
  base <- "GCPS-Report"
  rep_dir <- paste0(base, ".Report")
  sm_dir <- paste0(base, ".SemanticModel")
  theme_json <- gcps_template_powerbi(t)[["GCPS-theme.json"]]

  # .pbip root pointer — version 1.0, points at the .Report folder.
  pbip <- jsonlite::toJSON(
    list(
      version = "1.0",
      artifactType = "Report",
      artifacts = list(list(
        name = base,
        reportPath = paste0("./", rep_dir),
        semanticModelPath = paste0("./", sm_dir)
      ))
    ),
    auto_unbox = TRUE,
    pretty = TRUE
  )

  # .Report/definition.pbir — report definition pointer (byPath to SemanticModel).
  pbir <- jsonlite::toJSON(
    list(
      version = "1.0",
      datasetReference = list(
        byPath = list(path = paste0("../", sm_dir)),
        byConnection = NULL
      ),
      datasetReportingUsage = "Embedded"
    ),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  # report.json — declares the GCPS theme in themeCollection.customTheme,
  # loaded from StaticResources/.../GCPS-theme.json by the StudioPublicName.
  # pathToTheme is the RELATIVE path from report.json to the theme file.
  theme_rel <- "StaticResources/SharedResources/BaseThemes/GCPS-theme.json"
  report_json <- jsonlite::toJSON(
    list(
      `$schema` = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/report/1.0.0/report.json",
      themeCollection = list(
        baseTheme = list(
          name = "CY24SU10",
          type = "SharedResources",
          referenceUri = "baseThemes/CY24SU10.json"
        ),
        customTheme = list(
          name = "GCPS-theme",
          reportStyleBuiltInId = "GCPS-theme",
          type = "SharedResources",
          referenceUri = theme_rel
        )
      )
    ),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  # pages.json — one page entry (active).
  pages_json <- jsonlite::toJSON(
    list(
      `$schema` = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/pages/1.0.0/pages.json",
      pageOrder = jsonlite::unbox("Page1")
    ),
    auto_unbox = TRUE,
    pretty = TRUE
  )

  # Page1/page.json — blank 1280x720 page.
  page_json <- jsonlite::toJSON(
    list(
      `$schema` = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/1.0.0/page.json",
      name = "Page1",
      displayName = "Page 1",
      width = 1280,
      height = 720,
      visibility = "hiddenInViewMode"
    ),
    auto_unbox = TRUE,
    pretty = TRUE
  )

  # SemanticModel/definition.pbism — minimal semantic-model pointer.
  pbism <- jsonlite::toJSON(
    list(
      `$schema` = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/semanticmodel/1.0.0/definition.pbism.json",
      version = "1.0"
    ),
    auto_unbox = TRUE,
    pretty = TRUE
  )

  # database.tmdl — minimal TMDL: a model with one empty table "Placeholder".
  tmdl <- paste0(
    "model Model\n",
    "\ttable Placeholder\n",
    "\t\tsource = []\n",
    "\t\tcolumn Column1\n",
    "\t\t\tdataType = string\n",
    "\tannotation DefaultName = \"GCPS Themed Semantic Model (placeholder)\"\n"
  )

  gitignore <- paste0(
    ".pbi/\n",
    "*.lock\n",
    "*.user\n",
    "bin/\n",
    "obj/\n"
  )

  readme <- paste0(
    gcps_readme_header(t),
    "\n## What this is\n\n",
    "A **Power BI Project (.pbip)** folder that opens directly in Power BI\n",
    "Desktop with the GCPS theme already applied. Uses the enhanced PBIR\n",
    "report format.\n\n",
    "## Requirements\n\n",
    "Power BI Desktop with TWO preview features enabled:\n\n",
    "1. **File → Options → Preview features →\n",
    "   \"Power BI Project (.pbip) save option\"**\n",
    "2. **File → Options → Preview features →\n",
    "   \"Store reports using enhanced metadata format (PBIR)\"**\n\n",
    "Restart Power BI Desktop after enabling.\n\n",
    "## Open\n\n",
    "Open `",
    base,
    ".pbip` in Power BI Desktop. The report opens with the\n",
    "GCPS theme colors/fonts visible in the formatting pane. Add data by\n",
    "replacing the `Placeholder` table or connecting your own semantic model.\n\n",
    "## Notes\n\n",
    "- The PBIR format evolves with Desktop versions. If a field is rejected,\n",
    "  re-save the project from Desktop to let it normalize the JSON, then\n",
    "  diff to see the corrected shape.\n",
    "- A `SemanticModel/definition/database.tmdl` with one empty `Placeholder`\n",
    "  table is included so Desktop opens without requiring a data source.\n",
    "- The theme JSON under `",
    rep_dir,
    "/StaticResources/.../GCPS-theme.json`\n",
    "  is identical to the standalone Power BI theme bundle.\n"
  )

  tree <- list()
  tree[[paste0(base, ".pbip")]] <- pbip
  tree[[paste0(rep_dir, "/definition.pbir")]] <- pbir
  tree[[paste0(rep_dir, "/definition/report.json")]] <- report_json
  tree[[paste0(rep_dir, "/definition/pages/pages.json")]] <- pages_json
  tree[[paste0(rep_dir, "/definition/pages/Page1/page.json")]] <- page_json
  tree[[paste0(
    rep_dir,
    "/StaticResources/SharedResources/BaseThemes/GCPS-theme.json"
  )]] <- theme_json
  tree[[paste0(sm_dir, "/definition.pbism")]] <- pbism
  tree[[paste0(sm_dir, "/definition/database.tmdl")]] <- tmdl
  tree[[".gitignore"]] <- gitignore
  tree[["README.md"]] <- readme
  tree
}

# ─────────────────────────────────────────────────────────────────────────────
# Zip writers
# ─────────────────────────────────────────────────────────────────────────────

# Write a named list of path->content into a single .zip.
gcps_write_template_zip <- function(tree, zipfile) {
  if (!requireNamespace("zip", quietly = TRUE)) {
    stop("Package 'zip' is required. Install it with install.packages('zip').")
  }
  tmp <- tempfile("gcps_tree")
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  for (path in names(tree)) {
    full <- file.path(tmp, path)
    dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
    writeLines(tree[[path]], full)
  }
  # Ensure parent dir of the destination zip exists.
  dir.create(dirname(zipfile), recursive = TRUE, showWarnings = FALSE)
  # zip::zip() with root= computes relative paths correctly and preserves the
  # folder structure cross-platform (R's list.files already normalizes to "/").
  files <- list.files(tmp, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  zip::zip(zipfile, files = files, root = tmp, recurse = FALSE)
  invisible(zipfile)
}

# Returns a named list of the six/seven trees keyed by kind.
gcps_template_all <- function(t) {
  list(
    "quarto-doc" = gcps_template_quarto_doc(t),
    "quarto-site" = gcps_template_quarto_site(t),
    "quarto-dashboard" = gcps_template_quarto_dashboard(t),
    "flexdashboard" = gcps_template_flexdashboard(t),
    "shiny-app" = gcps_template_shiny_app(t),
    "powerbi" = gcps_template_powerbi(t),
    "powerbi-pbip" = gcps_template_pbip(t)
  )
}

# Writes each tree into its own subfolder + a top-level README.md, then zips.
gcps_write_all_zip <- function(t, zipfile) {
  if (!requireNamespace("zip", quietly = TRUE)) {
    stop("Package 'zip' is required. Install it with install.packages('zip').")
  }
  tmp <- tempfile("gcps_all")
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  trees <- gcps_template_all(t)
  for (kind in names(trees)) {
    sub <- file.path(tmp, kind)
    dir.create(sub, recursive = TRUE, showWarnings = FALSE)
    for (path in names(trees[[kind]])) {
      full <- file.path(sub, path)
      dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
      writeLines(trees[[kind]][[path]], full)
    }
  }
  writeLines(
    c(
      "# GCPS Theme Studio — all project templates",
      "",
      "Each subfolder is a runnable/importable starter baked with the current",
      "studio selections. See each subfolder's README for the render/run command.",
      "",
      "- `quarto-doc/`         — single-page HTML report",
      "- `quarto-site/`        — multi-page Quarto website",
      "- `quarto-dashboard/`   — Quarto dashboard format",
      "- `flexdashboard/`      — RMarkdown flexdashboard",
      "- `shiny-app/`          — bslib Shiny starter",
      "- `powerbi/`            — importable Power BI report theme JSON",
      "- `powerbi-pbip/`       — Power BI Project (.pbip) folder (PBIR)",
      ""
    ),
    file.path(tmp, "README.md")
  )

  dir.create(dirname(zipfile), recursive = TRUE, showWarnings = FALSE)
  # zip::zip() with root= preserves folder structure cross-platform.
  files <- list.files(tmp, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  zip::zip(zipfile, files = files, root = tmp, recurse = FALSE)
  invisible(zipfile)
}

# ─────────────────────────────────────────────────────────────────────────────
# Part C helper — map studio theme into the build_config() shape
# (defined here so Part C only edits build_config() and the sidebar)
# ─────────────────────────────────────────────────────────────────────────────

gcps_config_theme_from_studio <- function(ts = NULL) {
  t <- gcps_resolve_theme(ts)
  list(
    theme = list(
      bg_page = t$canvas,
      bg_card = t$surface,
      border = t$border,
      text_primary = t$text,
      text_secondary = t$text_2,
      accent = t$accent,
      radius = "8px",
      radius_lg = "12px"
    ),
    typography = list(
      font_family_name = t$font_label,
      font_family = t$font_stack,
      font_weight = as.character(t$heading_weight),
      font_size_base = t$base_size,
      font_size_heading = t$scale$h3
    ),
    palette = list(
      base_name = t$source,
      base = t$accent,
      ramp = head(t$palette_hex, 5)
    )
  )
}
