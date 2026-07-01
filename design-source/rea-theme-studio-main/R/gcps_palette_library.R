# =============================================================================
# R/gcps_palette_library.R — OKLCH palette generators (deterministic)
# Mirrors palette-library/GCPS Palette Library v2.html exactly.
# Depends on R/gcps_palette_data.R (source it first in app.R).
#
# Public API:
#   gcps_source_color(mode, key)              -> hex of the chosen source
#   gcps_build_palette(source_hex, type, ...) -> data.frame(index, stop, semantic, hex)
#   gcps_powerbi_theme(df, name, accent)      -> JSON string
#   gcps_dax_measure(df, measure_name)        -> DAX SWITCH string
#   gcps_css_vars(df, prefix)                 -> :root{} CSS string
#
# Verified against the approved mock (see ACCEPTANCE assertions at bottom).
# =============================================================================

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# ---- sRGB <-> OKLCH --------------------------------------------------------
.s2l <- function(c) ifelse(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055)^2.4)
.l2s <- function(c) ifelse(c <= 0.0031308, 12.92 * c, 1.055 * c^(1 / 2.4) - 0.055)

.hex_to_rgb <- function(hex) {
  hex <- sub("^#", "", hex)
  if (nchar(hex) == 3) hex <- paste(rep(strsplit(hex, "")[[1]], each = 2), collapse = "")
  c(strtoi(substr(hex, 1, 2), 16L), strtoi(substr(hex, 3, 4), 16L), strtoi(substr(hex, 5, 6), 16L))
}
.rgb_to_hex <- function(r, g, b) {
  # floor(v + 0.5) matches JS Math.round (round half up); base R round() is
  # half-to-even and would differ by 1 on exact .5 boundaries.
  cl <- function(v) max(0, min(255, floor(v + 0.5)))
  sprintf("#%02X%02X%02X", cl(r), cl(g), cl(b))
}
hex_to_oklch <- function(hex) {
  rgb <- .hex_to_rgb(hex) / 255
  r <- .s2l(rgb[1]); g <- .s2l(rgb[2]); b <- .s2l(rgb[3])
  l <- 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
  m <- 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
  s <- 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
  l_ <- l^(1 / 3); m_ <- m^(1 / 3); s_ <- s^(1 / 3)
  L <- 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
  A <- 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
  B <- 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
  H <- atan2(B, A) * 180 / pi
  if (H < 0) H <- H + 360
  c(L = L, C = sqrt(A * A + B * B), H = H)
}
oklch_to_hex <- function(L, C, H) {
  hr <- H * pi / 180; A <- C * cos(hr); B <- C * sin(hr)
  l_ <- L + 0.3963377774 * A + 0.2158037573 * B
  m_ <- L - 0.1055613458 * A - 0.0638541728 * B
  s_ <- L - 0.0894841775 * A - 1.2914855480 * B
  l <- l_^3; m <- m_^3; s <- s_^3
  r <-  4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
  g <- -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
  b <- -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
  .rgb_to_hex(.l2s(r) * 255, .l2s(g) * 255, .l2s(b) * 255)
}
.lerp <- function(a, b, t) a + (b - a) * t
.clamp <- function(x, lo, hi) max(lo, min(hi, x))

# WCAG contrast vs white (for labelling) ------------------------------------
gcps_contrast_white <- function(hex) {
  rgb <- .hex_to_rgb(hex) / 255
  L <- 0.2126 * .s2l(rgb[1]) + 0.7152 * .s2l(rgb[2]) + 0.0722 * .s2l(rgb[3])
  (1.0 + 0.05) / (L + 0.05)
}

.df <- function(stop, hex, semantic = NA_character_) {
  data.frame(index = seq_along(hex), stop = stop, semantic = semantic,
             hex = toupper(hex), stringsAsFactors = FALSE)
}

# ---- Generators (mirror the JS exactly) -----------------------------------
gcps_sequential <- function(hex) {
  o <- hex_to_oklch(hex); L <- o[["L"]]; C <- o[["C"]]; H <- o[["H"]]
  .df(
    c(100, 300, 500, 700, 900),
    c(oklch_to_hex(.lerp(L, 0.97, 0.86), C * 0.30, H),
      oklch_to_hex(.lerp(L, 0.95, 0.62), C * 0.55, H),
      oklch_to_hex(.lerp(L, 0.95, 0.30), C * 0.82, H),
      toupper(hex),
      oklch_to_hex(L * 0.80, C * 0.98, H))
  )
}
gcps_tints <- function(hex) {
  o <- hex_to_oklch(hex); L <- o[["L"]]; C <- o[["C"]]; H <- o[["H"]]
  labels <- c(50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950)
  n <- length(labels)
  hex_out <- vapply(seq_len(n), function(i) {
    t <- (i - 1) / (n - 1)
    oklch_to_hex(.lerp(0.975, L * 0.78, t), C * .lerp(0.16, 1.0, t), H)
  }, character(1))
  .df(labels, hex_out)
}
gcps_continuous <- function(hex, n = 9) {
  o <- hex_to_oklch(hex); L <- o[["L"]]; C <- o[["C"]]; H <- o[["H"]]
  hex_out <- vapply(seq_len(n), function(i) {
    t <- (i - 1) / (n - 1)
    oklch_to_hex(.lerp(0.975, L * 0.80, t), C * .lerp(0.18, 1.0, t), H)
  }, character(1))
  .df(seq_len(n), hex_out)
}
gcps_diverging <- function(hex, other_hex) {
  a <- hex_to_oklch(hex); b <- hex_to_oklch(other_hex)
  n <- 7; half <- 3
  stops <- (seq_len(n) - 1) - half
  hex_out <- vapply(seq_len(n), function(i) {
    idx <- i - 1
    if (idx < half) {
      t <- idx / half
      oklch_to_hex(.lerp(a[["L"]] * 0.85, 0.94, t), .lerp(a[["C"]], a[["C"]] * 0.18, t), a[["H"]])
    } else if (idx == half) {
      "#F3F4F6"
    } else {
      t <- (idx - half) / half
      oklch_to_hex(.lerp(0.94, b[["L"]] * 0.85, t), .lerp(b[["C"]] * 0.18, b[["C"]], t), b[["H"]])
    }
  }, character(1))
  .df(stops, hex_out)
}
gcps_categorical_theory <- function(hex, scheme = "analogous", n = 8) {
  o <- hex_to_oklch(hex); H <- o[["H"]]; C <- o[["C"]]
  baseL <- 0.62
  baseC <- .clamp(if (C == 0) 0.13 else C, 0.09, 0.16)
  offs <- HARMONY[[scheme]]
  hex_out <- vapply(0:(n - 1), function(i) {
    dh <- offs[(i %% length(offs)) + 1] + floor(i / length(offs)) * 18
    Lv <- baseL + if (i %% 2 == 1) -0.07 else 0.03
    oklch_to_hex(Lv, baseC, (H + dh) %% 360)
  }, character(1))
  .df(seq_len(n), hex_out, semantic = paste("Series", seq_len(n)))
}
gcps_perf_semantic <- function(n = 4) {
  hex_out <- vapply(seq_len(n), function(i) {
    t <- (i - 1) / (n - 1)
    oklch_to_hex(.lerp(0.60, 0.66, t), .lerp(0.15, 0.13, t), .lerp(28, 150, t))
  }, character(1))
  .df(seq_len(n), hex_out, semantic = PERF_NAMES[[as.character(n)]])
}
gcps_perf_base <- function(hex, n = 4) {
  o <- hex_to_oklch(hex); L <- o[["L"]]; C <- o[["C"]]; H <- o[["H"]]
  hex_out <- vapply(seq_len(n), function(i) {
    t <- (i - 1) / (n - 1)
    oklch_to_hex(.lerp(0.86, L * 0.82, t), C * .lerp(0.4, 1.0, t), H)
  }, character(1))
  .df(seq_len(n), hex_out, semantic = PERF_NAMES[[as.character(n)]])
}
gcps_trend <- function() {
  .df(c("+", "-", "="),
      c(GCPS_BASE[["green"]], "#B42318", GCPS_BASE[["neutral"]]),
      semantic = c("Positive \u00b7 improvement", "Negative \u00b7 decline", "Neutral \u00b7 no change"))
}

# ---- Source resolution -----------------------------------------------------
gcps_source_color <- function(mode, key) {
  if (mode == "bases")        unname(GCPS_BASE[[key]])
  else if (mode == "clusters") unname(CLUSTERS[[key]])
  else                         unname(CLUSTERS[[ SCHOOL_CLUSTER[[key]] ]])  # schools inherit cluster
}
.complement <- function(hex) { o <- hex_to_oklch(hex); oklch_to_hex(o[["L"]], o[["C"]], (o[["H"]] + 180) %% 360) }

# ---- Unified builder -------------------------------------------------------
# type: sequential|tints|diverging|categorical|performance|continuous|trend
# scheme (categorical): analogous|complementary|split|triadic|tetradic|qualitative|gcps|clusters
# perf_variant: semantic|base ; perf_n: 4|5|6 ; mode/key let diverging pick its partner
gcps_build_palette <- function(source_hex, type,
                               scheme = "analogous", perf_n = 4, perf_variant = "semantic",
                               mode = "bases", key = NULL) {
  switch(type,
    sequential = gcps_sequential(source_hex),
    tints      = gcps_tints(source_hex),
    continuous = gcps_continuous(source_hex, 9),
    trend      = gcps_trend(),
    diverging  = {
      other <- if (mode == "bases" && !is.null(key)) unname(GCPS_BASE[[ DIVERGE_PAIR[[key]] ]]) else .complement(source_hex)
      gcps_diverging(source_hex, other)
    },
    performance = if (perf_variant == "semantic") gcps_perf_semantic(perf_n) else gcps_perf_base(source_hex, perf_n),
    categorical = {
      if (scheme == "gcps")          .df(seq_along(GCPS_QUALITATIVE), GCPS_QUALITATIVE, paste("Series", seq_along(GCPS_QUALITATIVE)))
      else if (scheme == "clusters") .df(seq_along(ALL_CLUSTERS_CAT), ALL_CLUSTERS_CAT, paste("Series", seq_along(ALL_CLUSTERS_CAT)))
      else                           gcps_categorical_theory(source_hex, scheme, 8)
    },
    stop("unknown palette type: ", type)
  )
}

# ---- Exporters (mirror the mock) ------------------------------------------
gcps_powerbi_theme <- function(df, name = "GCPS palette", accent = "#660000") {
  jsonlite::toJSON(list(
    name = unbox_(name), dataColors = df$hex,
    background = unbox_("#F7F6F3"), foreground = unbox_("#1F2120"),
    tableAccent = unbox_(toupper(accent))
  ), auto_unbox = TRUE, pretty = TRUE)
}
unbox_ <- function(x) x  # toJSON(auto_unbox=TRUE) handles scalars

gcps_dax_measure <- function(df, measure_name = "Series Color") {
  has_sem <- !all(is.na(df$semantic))
  rows <- if (has_sem) {
    paste0('    "', df$semantic, '", "', df$hex, '"', collapse = ",\n")
  } else {
    paste0("    ", df$index, ', "', df$hex, '"', collapse = ",\n")
  }
  sel <- if (has_sem) "SELECTEDVALUE('Table'[Category])" else "'Table'[Index]"
  paste0(measure_name, " =\nSWITCH(\n    ", sel, ",\n", rows, ",\n    \"#7A828C\"\n)")
}

gcps_css_vars <- function(df, prefix = "gcps") {
  lines <- paste0("  --", prefix, "-", df$stop, ": ", df$hex, ";", collapse = "\n")
  paste0(":root{\n", lines, "\n}")
}

# =============================================================================
# ACCEPTANCE — must match the approved mock (run interactively to verify):
#   gcps_sequential("#007C91")$hex
#     -> "#CDE7ED" "#96C5D1" "#559FB1" "#007C91" "#005C70"
#   gcps_sequential("#660000")$hex            # Brookwood
#     -> "#F0CEC8" "#CB9188" "#9A4B40" "#660000" "#510000"
#   gcps_categorical_theory("#007C91","analogous")$hex
#     -> "#3B9EB3" "#3D77A5" "#3BA297" "#616CA9" "#5CA075" "#7F639E" "#829957" "#5072A9"
#   gcps_perf_semantic(6)$hex
#     -> "#CA564B" "#C6661B" "#B77900" "#9D8C00" "#7B9C37" "#4FA866"
#   gcps_source_color("clusters","Brookwood")  -> "#660000"
#   gcps_source_color("schools","Alcova ES")   -> "#CCCC99"  (Dacula)
# Tolerance: exact (integer RGB). If a value is off by 1, check the cube-root
# (use x^(1/3); inputs are non-negative for in-gamut colors).
# =============================================================================
