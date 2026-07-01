# Self-hosted fonts for GCPS Theme Studio

This app deploys to **Posit Connect**, which has **no runtime CDN access**. The
five Google families used by the embedded Theme Studio must be vendored as
`woff2` files in this folder. The `@font-face` declarations in
`../theme-studio.css` reference the exact filenames below.

Each font's CSS stack already ends in a system family (`system-ui` / `Georgia`),
so a **missing file degrades gracefully** — the app still renders. But for full
fidelity, vendor all 18 files listed below.

## Required files (filename → family · weight)

```
Spectral-500.woff2         → Spectral · 500
Spectral-600.woff2         → Spectral · 600
Spectral-700.woff2         → Spectral · 700
SourceSans3-400.woff2      → Source Sans 3 · 400
SourceSans3-500.woff2      → Source Sans 3 · 500
SourceSans3-600.woff2      → Source Sans 3 · 600
SourceSans3-700.woff2      → Source Sans 3 · 700
Lexend-300.woff2           → Lexend · 300
Lexend-400.woff2           → Lexend · 400
Lexend-500.woff2           → Lexend · 500
Lexend-600.woff2           → Lexend · 600
Lexend-700.woff2           → Lexend · 700
IBMPlexSans-400.woff2      → IBM Plex Sans · 400
IBMPlexSans-500.woff2      → IBM Plex Sans · 500
IBMPlexSans-600.woff2      → IBM Plex Sans · 600
IBMPlexSans-700.woff2      → IBM Plex Sans · 700
IBMPlexMono-400.woff2      → IBM Plex Mono · 400
IBMPlexMono-500.woff2      → IBM Plex Mono · 500
```

## How to fetch (run on a machine with internet, then commit the files)

Using [google-webfonts-helper](https://gwfh.mranftl.com/) or the
`@fontsource/*` npm packages, download the woff2 for each family/weight above
and rename to the filenames shown. Example with `@fontsource`:

```bash
npm pack @fontsource/source-sans-3     # extract files/woff2/*.woff2
```

Only the weights actually used by the studio are listed (see
`www/theme-studio.js` → `FONTS` and `SCALE_RATIOS`); do not vendor extra weights.

## Verification

After dropping the files in:

1. Load the app on a network with **no external access**.
2. Open the 🎨 Theme & Typography Studio tab → Typography sub-tab.
3. All five font cards should render in their real typeface (not the fallback).
4. Browser DevTools → Network → no requests to `fonts.googleapis.com` or
   `fonts.gstatic.com` should appear.