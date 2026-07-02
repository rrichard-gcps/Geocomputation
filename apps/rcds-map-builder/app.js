(() => {
"use strict";

/* ---------------------------------------------------------------------- *
 * Seeded RNG (deterministic per dataset/field so the demo is stable)
 * ---------------------------------------------------------------------- */
function seededRng(seed) {
  let t = seed >>> 0;
  return function () {
    t += 0x6D2B79F5;
    let r = Math.imul(t ^ (t >>> 15), 1 | t);
    r = (r + Math.imul(r ^ (r >>> 7), 61 | r)) ^ r;
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}

/* ---------------------------------------------------------------------- *
 * Datasets & fields (mirrors the GCPS Map Studio handoff doc)
 * ---------------------------------------------------------------------- */
const ALL_ZONE_LEVELS = ["es", "ms", "hs", "metro_es", "tracts"];

const DATASETS = [
  { id: "es", group: "GCPS attendance zones", label: "Elementary (ES) attendance zones", featureNoun: "Zone", rows: 9, cols: 9, seed: 1101, hasFields: true },
  { id: "ms", group: "GCPS attendance zones", label: "Middle (MS) attendance zones", featureNoun: "Zone", rows: 5, cols: 5, seed: 2202, hasFields: true },
  { id: "hs", group: "GCPS attendance zones", label: "High school clusters (HS)", featureNoun: "Cluster", rows: 5, cols: 4, seed: 3303, hasFields: true },
  { id: "metro_es", group: "Metro comparison", label: "Metro ES zones", featureNoun: "Zone", rows: 10, cols: 10, seed: 4404, hasFields: true },
  { id: "tracts", group: "Metro comparison", label: "Census tracts (ACS 5-yr)", featureNoun: "Tract", rows: 12, cols: 12, seed: 5505, hasFields: true },
  { id: "outline", group: "Reference", label: "GCPS district outline", featureNoun: "District", rows: 0, cols: 0, seed: 6606, hasFields: false },
  { id: "counties", group: "Reference", label: "GA counties", featureNoun: "County", rows: 6, cols: 5, seed: 7707, hasFields: false },
];

const FIELDS = [
  { id: "frpl", label: "Free/reduced-price meals", unit: "pct", min: 8, max: 92, levels: ALL_ZONE_LEVELS },
  { id: "ell", label: "English learners", unit: "pct", min: 1, max: 45, levels: ALL_ZONE_LEVELS },
  { id: "poverty", label: "Poverty rate", unit: "pct", min: 4, max: 38, levels: ALL_ZONE_LEVELS },
  { id: "mhhinc", label: "Median household income", unit: "usd", min: 32000, max: 165000, levels: ALL_ZONE_LEVELS },
  { id: "unemp", label: "Unemployment rate", unit: "pct", min: 2, max: 11, levels: ALL_ZONE_LEVELS },
  { id: "gini", label: "Income inequality (Gini)", unit: "idx", min: 0.32, max: 0.52, levels: ALL_ZONE_LEVELS },
  { id: "totpop", label: "Total population", unit: "count", min: 800, max: 42000, levels: ALL_ZONE_LEVELS },
  { id: "pop_dens", label: "Population density", unit: "sqmi", min: 200, max: 9500, levels: ALL_ZONE_LEVELS },
  { id: "sped", label: "Students with disabilities", unit: "pct", min: 6, max: 18, levels: ALL_ZONE_LEVELS },
  { id: "gifted", label: "Gifted & talented", unit: "pct", min: 3, max: 22, levels: ALL_ZONE_LEVELS },
  { id: "attrate", label: "Attendance rate", unit: "pct", min: 88, max: 98, levels: ALL_ZONE_LEVELS },
  { id: "no_internet", label: "Households without internet", unit: "pct", min: 2, max: 25, levels: ALL_ZONE_LEVELS },
  { id: "birth_rate", label: "Birth rate", unit: "per1000", min: 8, max: 18, levels: ALL_ZONE_LEVELS },
  { id: "dropout", label: "Dropout rate", unit: "pct", min: 1, max: 9, levels: ["ms", "hs"] },
  { id: "acgr", label: "4-year graduation rate", unit: "pct", min: 72, max: 97, levels: ["hs"] },
  { id: "sat_comp", label: "SAT composite score", unit: "score", min: 900, max: 1260, levels: ["hs"] },
];

function fieldsForDataset(dsId) {
  return FIELDS.filter((f) => f.levels.includes(dsId));
}

function formatValue(field, v) {
  switch (field.unit) {
    case "pct": return v.toFixed(1) + "%";
    case "usd": return "$" + Math.round(v).toLocaleString();
    case "idx": return v.toFixed(2);
    case "count": return Math.round(v).toLocaleString();
    case "sqmi": return Math.round(v).toLocaleString() + "/mi²";
    case "score": return String(Math.round(v));
    case "per1000": return v.toFixed(1);
    default: return String(v.toFixed(1));
  }
}

/* ---------------------------------------------------------------------- *
 * Synthetic geometry — a jittered, shared-edge grid mosaic standing in
 * for real boundary files (none are bundled in this repo).
 * ---------------------------------------------------------------------- */
const VB_W = 800, VB_H = 600, MARGIN = 30;

function buildGridCells(rows, cols, seed) {
  const rng = seededRng(seed);
  const w = VB_W - MARGIN * 2, h = VB_H - MARGIN * 2;
  const pts = [];
  for (let i = 0; i <= rows; i++) {
    const row = [];
    for (let j = 0; j <= cols; j++) {
      const baseX = MARGIN + (j / cols) * w;
      const baseY = MARGIN + (i / rows) * h;
      const onBorder = i === 0 || i === rows || j === 0 || j === cols;
      const jx = onBorder ? 0 : (rng() - 0.5) * (w / cols) * 0.6;
      const jy = onBorder ? 0 : (rng() - 0.5) * (h / rows) * 0.6;
      row.push({ x: baseX + jx, y: baseY + jy });
    }
    pts.push(row);
  }
  const cells = [];
  let idx = 0;
  for (let i = 0; i < rows; i++) {
    for (let j = 0; j < cols; j++) {
      const p1 = pts[i][j], p2 = pts[i][j + 1], p3 = pts[i + 1][j + 1], p4 = pts[i + 1][j];
      const cx = (p1.x + p2.x + p3.x + p4.x) / 4, cy = (p1.y + p2.y + p3.y + p4.y) / 4;
      cells.push({ id: idx++, points: [p1, p2, p3, p4], cx, cy });
    }
  }
  return cells;
}

function buildBlobCell(seed) {
  const rng = seededRng(seed);
  const cx = VB_W / 2, cy = VB_H / 2;
  const rx = VB_W / 2 - MARGIN * 2, ry = VB_H / 2 - MARGIN * 2;
  const n = 16;
  const points = [];
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    const jr = 0.75 + rng() * 0.25;
    points.push({ x: cx + Math.cos(a) * rx * jr, y: cy + Math.sin(a) * ry * jr });
  }
  return [{ id: 0, points, cx, cy }];
}

function cellsForDataset(ds) {
  if (ds.id === "outline") return buildBlobCell(ds.seed);
  return buildGridCells(ds.rows, ds.cols, ds.seed);
}

function polyPoints(cell) {
  return cell.points.map((p) => `${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(" ");
}

/* ---------------------------------------------------------------------- *
 * Synthetic field values — smooth pseudo-spatial trend + noise, seeded
 * per dataset+field so the same combination always looks the same.
 * ---------------------------------------------------------------------- */
function hashSeed(a, b) {
  let h = a * 2654435761 + b * 40503;
  return (h >>> 0) % 100000;
}

function valuesForField(cells, ds, field) {
  const rng = seededRng(hashSeed(ds.seed, field.id.split("").reduce((s, c) => s + c.charCodeAt(0), 0)));
  const fx1 = rng() * 2 + 1, fy1 = rng() * 2 + 1, px = rng() * Math.PI * 2, py = rng() * Math.PI * 2;
  const fx2 = rng() * 3 + 1, fy2 = rng() * 3 + 1;
  const raw = cells.map((c) => {
    const nx = c.cx / VB_W, ny = c.cy / VB_H;
    let v = Math.sin(nx * Math.PI * fx1 + px) * Math.cos(ny * Math.PI * fy1 + py);
    v += 0.5 * Math.sin(nx * Math.PI * fx2 - ny * Math.PI * fy2 + px * 0.7);
    v += (rng() - 0.5) * 0.6;
    return v;
  });
  const lo = Math.min(...raw), hi = Math.max(...raw);
  return raw.map((v) => field.min + (field.max - field.min) * ((v - lo) / (hi - lo || 1)));
}

/* ---------------------------------------------------------------------- *
 * Classification
 * ---------------------------------------------------------------------- */
function quantileBreaks(values, k) {
  const sorted = [...values].sort((a, b) => a - b);
  const breaks = [sorted[0]];
  for (let i = 1; i < k; i++) breaks.push(sorted[Math.min(Math.floor((i * sorted.length) / k), sorted.length - 1)]);
  breaks.push(sorted[sorted.length - 1]);
  return breaks;
}

function equalBreaks(values, k) {
  const min = Math.min(...values), max = Math.max(...values);
  const step = (max - min) / k;
  return Array.from({ length: k + 1 }, (_, i) => min + step * i);
}

function jenksBreaks(values, nClasses) {
  const data = [...values].sort((a, b) => a - b);
  const n = data.length;
  if (n <= nClasses) return equalBreaks(values, nClasses);
  const lowerClassLimits = Array.from({ length: n + 1 }, () => new Array(nClasses + 1).fill(0));
  const varCombinations = Array.from({ length: n + 1 }, () => new Array(nClasses + 1).fill(0));
  for (let i = 1; i <= nClasses; i++) {
    lowerClassLimits[1][i] = 1;
    varCombinations[1][i] = 0;
    for (let j = 2; j <= n; j++) varCombinations[j][i] = Infinity;
  }
  let variance = 0;
  for (let l = 2; l <= n; l++) {
    let sum = 0, sumSquares = 0, w = 0;
    for (let m = 1; m <= l; m++) {
      const lowerLimit = l - m + 1;
      const val = data[lowerLimit - 1];
      w++;
      sum += val;
      sumSquares += val * val;
      variance = sumSquares - (sum * sum) / w;
      const i4 = lowerLimit - 1;
      if (i4 !== 0) {
        for (let p = 2; p <= nClasses; p++) {
          if (varCombinations[l][p] >= variance + varCombinations[i4][p - 1]) {
            lowerClassLimits[l][p] = lowerLimit;
            varCombinations[l][p] = variance + varCombinations[i4][p - 1];
          }
        }
      }
    }
    lowerClassLimits[l][1] = 1;
    varCombinations[l][1] = variance;
  }
  const kclass = new Array(nClasses + 1).fill(0);
  kclass[nClasses] = data[n - 1];
  kclass[0] = data[0];
  let count = n, countNum = nClasses;
  while (countNum > 1) {
    const id = lowerClassLimits[count][countNum] - 2;
    kclass[countNum - 1] = data[id];
    count = lowerClassLimits[count][countNum] - 1;
    countNum--;
  }
  return kclass;
}

function computeBreaks(values, method, k) {
  if (method === "equal") return equalBreaks(values, k);
  if (method === "jenks") return jenksBreaks(values, k);
  return quantileBreaks(values, k);
}

function classIndexFor(v, breaks) {
  for (let i = 0; i < breaks.length - 2; i++) if (v <= breaks[i + 1]) return i;
  return breaks.length - 2;
}

function goodnessOfVarianceFit(values, breaks) {
  const mean = values.reduce((a, b) => a + b, 0) / values.length;
  const sdam = values.reduce((a, v) => a + (v - mean) ** 2, 0);
  let sdcm = 0;
  for (let i = 0; i < breaks.length - 1; i++) {
    const lo = breaks[i], hi = breaks[i + 1];
    const inClass = values.filter((v) => v >= lo && v <= hi + 1e-9);
    if (!inClass.length) continue;
    const cmean = inClass.reduce((a, b) => a + b, 0) / inClass.length;
    sdcm += inClass.reduce((a, v) => a + (v - cmean) ** 2, 0);
  }
  return sdam > 0 ? 1 - sdcm / sdam : 1;
}

/* ---------------------------------------------------------------------- *
 * Color ramps
 * ---------------------------------------------------------------------- */
const RAMPS = {
  sequential: ["#E2F3F0", "#B3E0D9", "#79C7BB", "#2A9D8F", "#1C7A6E", "#0F544B"],
  diverging: ["#8F470C", "#E8852B", "#F4C79A", "#E8E8E8", "#9CC2E5", "#1E6FB8", "#0F4C84"],
};

function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
function rgbToHex([r, g, b]) {
  return "#" + [r, g, b].map((v) => Math.round(v).toString(16).padStart(2, "0")).join("").toUpperCase();
}
function lerpColor(c1, c2, t) {
  const a = hexToRgb(c1), b = hexToRgb(c2);
  return rgbToHex(a.map((v, i) => v + (b[i] - v) * t));
}
function sampleRamp(stops, n) {
  if (n === 1) return [stops[Math.floor(stops.length / 2)]];
  const out = [];
  for (let i = 0; i < n; i++) {
    const t = i / (n - 1);
    const pos = t * (stops.length - 1);
    const i0 = Math.floor(pos), i1 = Math.min(i0 + 1, stops.length - 1);
    out.push(lerpColor(stops[i0], stops[i1], pos - i0));
  }
  return out;
}
function colorDistance(hex1, hex2) {
  const a = hexToRgb(hex1), b = hexToRgb(hex2);
  return Math.sqrt(a.reduce((s, v, i) => s + (v - b[i]) ** 2, 0));
}

/* ---------------------------------------------------------------------- *
 * State
 * ---------------------------------------------------------------------- */
const state = {
  datasetId: "es",
  fieldId: "frpl",
  classification: "quantile",
  nClasses: 5,
  direction: "sequential",
  reverse: false,
  mapTitle: "",
  legendTitle: "",
  zoom: 1,
};

const els = {};
["ctl-dataset", "ctl-field", "ctl-classification", "ctl-nclasses", "nclasses-val", "ctl-reverse",
 "ctl-title", "ctl-legend", "dataset-hint", "svg-interactive", "svg-static", "legend-interactive",
 "legend-static", "map-tooltip", "static-title", "static-caption", "reference-note",
 "dist-bars", "dist-breaks", "mqs-num", "mqs-band", "mqs-meters", "zoom-in", "zoom-out"]
  .forEach((id) => { els[id] = document.getElementById(id); });

/* ---------------------------------------------------------------------- *
 * Populate static controls
 * ---------------------------------------------------------------------- */
function populateDatasetSelect() {
  const groups = {};
  DATASETS.forEach((ds) => { (groups[ds.group] = groups[ds.group] || []).push(ds); });
  els["ctl-dataset"].innerHTML = Object.entries(groups).map(([group, list]) =>
    `<optgroup label="${group}">${list.map((ds) => `<option value="${ds.id}">${ds.label}</option>`).join("")}</optgroup>`
  ).join("");
  els["ctl-dataset"].value = state.datasetId;
}

function populateFieldSelect() {
  const ds = DATASETS.find((d) => d.id === state.datasetId);
  const fields = ds.hasFields ? fieldsForDataset(ds.id) : [];
  els["ctl-field"].innerHTML = fields.map((f) => `<option value="${f.id}">${f.label}</option>`).join("");
  if (fields.length && !fields.some((f) => f.id === state.fieldId)) state.fieldId = fields[0].id;
  els["ctl-field"].value = state.fieldId;
  els["ctl-field"].disabled = !ds.hasFields;
  ["ctl-classification", "ctl-nclasses", "ctl-legend"].forEach((id) => { els[id].disabled = !ds.hasFields; });
  document.querySelectorAll('input[name="direction"]').forEach((r) => { r.disabled = !ds.hasFields; });
  els["ctl-reverse"].disabled = !ds.hasFields;
}

/* ---------------------------------------------------------------------- *
 * Core compute + render
 * ---------------------------------------------------------------------- */
function computeState() {
  const ds = DATASETS.find((d) => d.id === state.datasetId);
  const cells = cellsForDataset(ds);
  if (!ds.hasFields) return { ds, cells, hasFields: false };

  const field = FIELDS.find((f) => f.id === state.fieldId);
  const values = valuesForField(cells, ds, field);
  const breaks = computeBreaks(values, state.classification, state.nClasses);
  const stops = RAMPS[state.direction];
  let colors = sampleRamp(stops, state.nClasses);
  if (state.reverse) colors = [...colors].reverse();
  const classes = values.map((v) => classIndexFor(v, breaks));

  return { ds, field, cells, values, breaks, colors, classes, hasFields: true };
}

function featureName(ds, i) {
  if (ds.id === "outline") return ds.label;
  return `${ds.featureNoun} ${i + 1}`;
}

function drawPolys(svg, computed, { interactive }) {
  svg.innerHTML = "";
  const ns = "http://www.w3.org/2000/svg";
  const g = document.createElementNS(ns, "g");
  g.setAttribute("id", "zoom-group");
  svg.appendChild(g);

  computed.cells.forEach((cell, i) => {
    const poly = document.createElementNS(ns, "polygon");
    poly.setAttribute("points", polyPoints(cell));
    poly.setAttribute("class", "demo-poly");
    let fill = "var(--rcds-canvas-light)";
    if (computed.hasFields) fill = computed.colors[computed.classes[i]];
    else fill = i % 2 === 0 ? "#DCE3EB" : "#EAEEF3";
    poly.setAttribute("fill", fill);
    if (interactive && computed.hasFields) {
      poly.addEventListener("mousemove", (e) => showTooltip(e, computed, i));
      poly.addEventListener("mouseleave", hideTooltip);
    }
    g.appendChild(poly);
  });
}

function showTooltip(e, computed, i) {
  const tip = els["map-tooltip"];
  const stage = tip.parentElement.getBoundingClientRect();
  const x = e.clientX - stage.left, y = e.clientY - stage.top;
  const v = computed.values[i];
  const cls = computed.classes[i];
  tip.style.left = x + "px";
  tip.style.top = y + "px";
  tip.innerHTML = `<b>${featureName(computed.ds, i)}</b><br>${computed.field.label}: <b>${formatValue(computed.field, v)}</b><br>Class ${cls + 1} of ${computed.breaks.length - 1}`;
  tip.classList.add("show");
}
function hideTooltip() { els["map-tooltip"].classList.remove("show"); }

function renderLegend(container, computed) {
  if (!computed.hasFields) { container.innerHTML = ""; return; }
  const title = state.legendTitle || computed.field.label;
  let rows = "";
  for (let i = computed.breaks.length - 2; i >= 0; i--) {
    rows += `<div class="legend-row"><span class="legend-swatch" style="background:${computed.colors[i]}"></span><span class="rng">${formatValue(computed.field, computed.breaks[i])}–${formatValue(computed.field, computed.breaks[i + 1])}</span></div>`;
  }
  container.innerHTML = `<div class="legend-title">${title}</div>${rows}`;
}

function renderDistribution(computed) {
  if (!computed.hasFields) { els["dist-bars"].innerHTML = ""; els["dist-breaks"].innerHTML = ""; return; }
  const nBins = 24;
  const min = Math.min(...computed.values), max = Math.max(...computed.values);
  const bins = new Array(nBins).fill(0);
  computed.values.forEach((v) => {
    const idx = Math.min(nBins - 1, Math.floor(((v - min) / (max - min || 1)) * nBins));
    bins[idx]++;
  });
  const maxCount = Math.max(...bins);
  els["dist-bars"].innerHTML = bins.map((c) => `<div class="dist-bar" style="height:${(c / maxCount) * 100}%"></div>`).join("");
  els["dist-breaks"].innerHTML = computed.breaks.map((b) => `<span>${formatValue(computed.field, b)}</span>`).join("");
}

function renderMQS(computed) {
  if (!computed.hasFields) {
    els["mqs-num"].textContent = "–";
    els["mqs-band"].textContent = "reference layer";
    els["mqs-band"].className = "band";
    els["mqs-meters"].innerHTML = `<div class="field-hint">Reference layers aren't scored — they carry no choropleth field.</div>`;
    return;
  }
  const gvf = goodnessOfVarianceFit(computed.values, computed.breaks);
  const separationScore = Math.round(Math.max(0, Math.min(1, gvf)) * 100);

  let avgDist = 0;
  for (let i = 0; i < computed.colors.length - 1; i++) avgDist += colorDistance(computed.colors[i], computed.colors[i + 1]);
  avgDist /= Math.max(1, computed.colors.length - 1);
  const contrastScore = Math.round(Math.max(20, Math.min(100, 55 + (avgDist - 25) * 1.1)));

  const density = computed.cells.length;
  let legibilityScore = 100 - (state.nClasses - 3) * 6 - (density > 100 ? 16 : density > 50 ? 8 : 0);
  legibilityScore = Math.round(Math.max(30, Math.min(100, legibilityScore)));

  const citationScore = (state.mapTitle.trim() ? 50 : 10) + ((state.legendTitle || computed.field.label).trim() ? 50 : 10);

  const overall = Math.round(separationScore * 0.35 + contrastScore * 0.25 + legibilityScore * 0.2 + citationScore * 0.2);

  els["mqs-num"].textContent = overall;
  els["mqs-band"].textContent = overall >= 80 ? "pass" : "review";
  els["mqs-band"].className = "band " + (overall >= 80 ? "band-pass" : "band-warn");

  const meters = [
    ["Class separation", separationScore],
    ["Palette contrast", contrastScore],
    ["Label legibility", legibilityScore],
    ["Source citation", citationScore],
  ];
  els["mqs-meters"].innerHTML = meters.map(([label, val]) =>
    `<div class="meter-row"><span class="meter-label">${label}</span><span class="meter-track"><span class="meter-fill" style="width:${val}%"></span></span><span class="meter-val mono">${val}</span></div>`
  ).join("");
}

function render() {
  const computed = computeState();

  drawPolys(els["svg-interactive"], computed, { interactive: true });
  drawPolys(els["svg-static"], computed, { interactive: false });
  renderLegend(els["legend-interactive"], computed);
  renderLegend(els["legend-static"], computed);
  renderDistribution(computed);
  renderMQS(computed);

  els["static-title"].textContent = state.mapTitle || (computed.hasFields ? `${computed.ds.label} — ${computed.field.label}` : computed.ds.label);
  els["static-caption"].innerHTML = computed.hasFields
    ? `RCDS Map Builder · rcds + ggplot2<br>Source: ${computed.ds.label} (illustrative demo data)`
    : `RCDS Map Builder<br>Source: ${computed.ds.label} (illustrative demo data)`;

  els["reference-note"].style.display = computed.hasFields ? "none" : "block";
  if (!computed.hasFields) {
    els["reference-note"].textContent = `${computed.ds.label} is a reference layer — no choropleth field. In the full tool it's used as a boundary overlay under a data layer, not mapped on its own.`;
  }
  els["legend-interactive"].style.display = computed.hasFields ? "block" : "none";
  els["legend-static"].style.display = computed.hasFields ? "block" : "none";

  applyZoom();
}

function applyZoom() {
  ["zoom-group"].forEach(() => {});
  document.querySelectorAll("#svg-interactive #zoom-group, #svg-static #zoom-group").forEach((g) => {
    g.setAttribute("transform", `translate(${VB_W / 2},${VB_H / 2}) scale(${state.zoom}) translate(${-VB_W / 2},${-VB_H / 2})`);
  });
}

/* ---------------------------------------------------------------------- *
 * Wiring
 * ---------------------------------------------------------------------- */
function setDefaultTitles() {
  const ds = DATASETS.find((d) => d.id === state.datasetId);
  const field = FIELDS.find((f) => f.id === state.fieldId);
  if (ds.hasFields && field) {
    state.mapTitle = `${ds.label} — ${field.label}`;
    state.legendTitle = field.label;
  } else {
    state.mapTitle = ds.label;
    state.legendTitle = "";
  }
  els["ctl-title"].value = state.mapTitle;
  els["ctl-legend"].value = state.legendTitle;
}

function onDatasetChange() {
  state.datasetId = els["ctl-dataset"].value;
  const ds = DATASETS.find((d) => d.id === state.datasetId);
  els["dataset-hint"].textContent = ds.hasFields
    ? `${ds.group} · illustrative demo geometry`
    : `${ds.group} · boundary overlay, no choropleth field`;
  populateFieldSelect();
  setDefaultTitles();
  render();
}

function bindControls() {
  els["ctl-dataset"].addEventListener("change", onDatasetChange);
  els["ctl-field"].addEventListener("change", () => { state.fieldId = els["ctl-field"].value; setDefaultTitles(); render(); });
  els["ctl-classification"].addEventListener("change", () => { state.classification = els["ctl-classification"].value; render(); });
  els["ctl-nclasses"].addEventListener("input", () => {
    state.nClasses = Number(els["ctl-nclasses"].value);
    els["nclasses-val"].textContent = state.nClasses;
    render();
  });
  document.querySelectorAll('input[name="direction"]').forEach((r) => r.addEventListener("change", () => {
    state.direction = document.querySelector('input[name="direction"]:checked').value;
    render();
  }));
  els["ctl-reverse"].addEventListener("change", () => { state.reverse = els["ctl-reverse"].checked; render(); });
  els["ctl-title"].addEventListener("input", () => { state.mapTitle = els["ctl-title"].value; render(); });
  els["ctl-legend"].addEventListener("input", () => { state.legendTitle = els["ctl-legend"].value; render(); });

  els["zoom-in"].addEventListener("click", () => { state.zoom = Math.min(3, state.zoom + 0.3); applyZoom(); });
  els["zoom-out"].addEventListener("click", () => { state.zoom = Math.max(0.6, state.zoom - 0.3); applyZoom(); });

  document.querySelectorAll(".demo-tab").forEach((tab) => {
    tab.addEventListener("click", () => {
      document.querySelectorAll(".demo-tab").forEach((t) => t.classList.remove("active"));
      document.querySelectorAll(".demo-view").forEach((v) => v.classList.remove("active"));
      tab.classList.add("active");
      document.getElementById("view-" + tab.dataset.view).classList.add("active");
    });
  });

  document.querySelectorAll(".code-tab").forEach((tab) => {
    tab.addEventListener("click", () => {
      document.querySelectorAll(".code-tab").forEach((t) => t.classList.remove("active"));
      tab.classList.add("active");
      document.getElementById("code-static").style.display = tab.dataset.code === "static" ? "block" : "none";
      document.getElementById("code-interactive").style.display = tab.dataset.code === "interactive" ? "block" : "none";
    });
  });
}

/* ---------------------------------------------------------------------- *
 * Gallery + palette showcase (static content, no demo state)
 * ---------------------------------------------------------------------- */
const GALLERY = [
  { img: "assets/metro-atlanta-districts.png", title: "Metro Atlanta school districts", meta: "Reference · GA counties", dot: "#1E6FB8" },
  { title: "Gwinnett ES attendance zones · Free/reduced-price meals", meta: "ES zones · seq_teal", dot: "#2A9D8F" },
  { title: "HS clusters · 4-year graduation rate", meta: "HS clusters · div_balance", dot: "#E8852B" },
  { title: "Metro tracts · median household income", meta: "Census tracts · seq_amber", dot: "#E8852B" },
  { title: "Henry County · English learners", meta: "ES zones · seq_blue", dot: "#1E6FB8" },
];

function renderGallery() {
  const strip = document.getElementById("gallery-strip");
  strip.innerHTML = GALLERY.map((g) => `
    <div class="gallery-card">
      <div class="gallery-thumb${g.img ? "" : " placeholder"}">
        ${g.img ? `<img src="${g.img}" alt="${g.title}">` : `<span>Screenshot placeholder</span>`}
      </div>
      <div class="gallery-body">
        <h4>${g.title}</h4>
        <div class="gallery-meta"><span class="tag"><span class="tag-dot" style="background:${g.dot}"></span>${g.meta}</span></div>
      </div>
    </div>
  `).join("");
}

function renderPaletteRow(id, colors) {
  document.getElementById(id).innerHTML = colors.map((c) => `<span style="background:${c}" title="${c}"></span>`).join("");
}

/* ---------------------------------------------------------------------- *
 * Boot
 * ---------------------------------------------------------------------- */
populateDatasetSelect();
populateFieldSelect();
setDefaultTitles();
els["ctl-nclasses"].value = state.nClasses;
els["nclasses-val"].textContent = state.nClasses;
els["dataset-hint"].textContent = "GCPS attendance zones · illustrative demo geometry";

bindControls();
renderGallery();
renderPaletteRow("pal-seq", RAMPS.sequential);
renderPaletteRow("pal-div", RAMPS.diverging);
renderPaletteRow("pal-chrome", ["#3E5C76", "#1E6FB8", "#F1B24A"]);
render();

})();
