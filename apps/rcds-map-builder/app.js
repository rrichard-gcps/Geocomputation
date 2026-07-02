(() => {
"use strict";

/* ---------------------------------------------------------------------- *
 * Seeded RNG (deterministic per dataset/field so the synthetic demo is stable)
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
 * Datasets & fields (mirrors the GCPS Map Studio handoff doc). When real
 * geometry is present (window.RCDS_GEODATA, produced by prep/export_geojson.R)
 * the real layer and its real columns are used instead of the synthetic ones.
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

function prettify(k) {
  return k.replace(/[_\.]+/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function formatValue(field, v) {
  if (v == null || !isFinite(v)) return "n/a";
  switch (field.unit) {
    case "pct": return v.toFixed(1) + "%";
    case "usd": return "$" + Math.round(v).toLocaleString();
    case "idx": return v.toFixed(2);
    case "count": return Math.round(v).toLocaleString();
    case "sqmi": return Math.round(v).toLocaleString() + "/mi²";
    case "score": return String(Math.round(v));
    case "per1000": return v.toFixed(1);
    case "pct01": return (v * 100).toFixed(1) + "%";   // stored as a 0-1 proportion
    case "num": return Math.abs(v) >= 1000 ? Math.round(v).toLocaleString() : v.toFixed(1);
    default: return Math.abs(v) >= 1000 ? Math.round(v).toLocaleString() : v.toFixed(2);
  }
}

/* Field dictionary for real repo columns: id -> [friendly label, kind].
 * kind drives units: rate (auto %/proportion/count by range), usd, count,
 * sqmi, index, num, auto. Lookup is case-insensitive. */
const FIELD_DICT = {
  frpl: ["Free/reduced-price meals", "rate"], free: ["Free-meal eligible", "rate"],
  reduced: ["Reduced-price eligible", "rate"], fsl: ["Free/reduced (FSL)", "rate"],
  ell: ["English learners", "rate"], lep: ["Limited English proficiency", "rate"],
  lep_hh: ["Households, limited English", "rate"], sped: ["Students with disabilities", "rate"],
  swd: ["Students with disabilities", "rate"], gifted: ["Gifted & talented", "rate"],
  attrate: ["Attendance rate", "rate"], dropout: ["Dropout rate", "rate"],
  acgr: ["4-year graduation rate", "rate"], mobile: ["Student mobility", "rate"],
  mobility: ["Student mobility", "rate"], poverty: ["Poverty rate", "rate"],
  pov_u18: ["Child poverty (under 18)", "rate"], unemp: ["Unemployment rate", "rate"],
  snap: ["SNAP participation", "rate"], noins: ["Uninsured", "rate"],
  no_internet: ["Households without internet", "rate"], crowded: ["Crowded housing", "rate"],
  vacant: ["Vacant housing", "rate"], pct_renter: ["Renter-occupied", "rate"],
  exp_homes: ["Expensive homes", "rate"], working_class: ["Working-class households", "rate"],
  low_ed: ["Low educational attainment", "rate"], high_ed: ["High educational attainment", "rate"],
  gt30com: ["Commute over 30 min", "rate"], riskrate: ["Risk rate", "rate"],
  hhm: ["Household mobility", "rate"], sphh: ["Single-parent households", "rate"],
  fhh_child: ["Female-headed w/ children", "rate"], resp_rate: ["ACS response rate", "rate"],
  title_i: ["Title I share", "rate"], pct_apib: ["AP/IB participation", "rate"],
  pct_exam: ["Exam participation", "rate"], pct_3plus: ["AP score 3+", "rate"],
  birth_rate: ["Birth rate", "num"], gini: ["Income inequality (Gini)", "index"],
  segregation: ["Segregation index", "index"], nbh_diversity: ["Neighborhood diversity", "index"],
  sch_diversity: ["School diversity", "index"], lshan: ["Local Shannon diversity", "index"],
  nshan: ["Neighborhood Shannon diversity", "index"], lsimp: ["Local Simpson diversity", "index"],
  mhhinc: ["Median household income", "usd"], mfinc: ["Median family income", "usd"],
  ave_sale17: ["Avg home sale, 2017", "usd"],
  totpop: ["Total population", "count"], population: ["Total population", "count"],
  pop2010: ["Population, 2010", "count"], k12_enr_n: ["K-12 enrollment", "count"],
  students: ["Students", "count"], n_stu_19: ["Students, 2019", "count"],
  teachers: ["Teachers", "count"], households: ["Households", "count"],
  families: ["Families", "count"], hse_units: ["Housing units", "count"],
  pop_dens: ["Population density", "sqmi"], pop_sqmi: ["Population density", "sqmi"],
  pop10_sqmi: ["Population density, 2010", "sqmi"],
  stu_tch_ratio: ["Student-teacher ratio", "num"], tsr: ["Student-teacher ratio", "num"],
  staff_score: ["Staff score", "num"], ccrpi: ["CCRPI score", "num"],
  star_rtg: ["Star rating", "num"], climate: ["School climate", "num"],
  overall: ["Overall rating", "num"], med_age: ["Median age", "num"],
  ave_hh_sz: ["Avg household size", "num"], stu_tch: ["Student-teacher ratio", "num"],
  sat_comp: ["SAT composite", "num"], sat_total: ["SAT total", "num"],
  sat_math: ["SAT math", "num"], sat_erw: ["SAT reading/writing", "num"],
  psat_math: ["PSAT math", "num"], psat_rw: ["PSAT reading/writing", "num"],
  white: ["White", "rate"], black: ["Black", "rate"], hisp: ["Hispanic", "rate"],
  hispanic: ["Hispanic", "rate"], asian: ["Asian", "rate"], native: ["Native American", "rate"],
  multi: ["Two or more races", "rate"], other: ["Other race", "rate"],
};

const PREFERRED = ["frpl", "ell", "poverty", "pov_u18", "mhhinc", "unemp", "gini",
  "totpop", "population", "pop_dens", "sped", "gifted", "attrate", "acgr", "dropout",
  "no_internet", "mobile", "ccrpi", "star_rtg", "sat_comp", "birth_rate", "segregation"];

// non-metric flag / key columns to hide from the field picker
const FLAG_LIKE = /^(es|ms|hs|level|cluster|grade|parent|locale|locale_code|sys_id|sch_id|zone_area|title_i_sch|k12_tot|n_free|n_reduced|resp_rate)$/i;
function isExcludedField(k) { return ID_LIKE.test(k) || FLAG_LIKE.test(k); }

function gradeLabel(id) {
  let m = /^grd_?(\d+)_(ma|la)(?:_pd)?$/i.exec(id);
  if (m) return `Grade ${m[1]} ${m[2].toLowerCase() === "ma" ? "math" : "ELA"} proficiency`;
  m = /^grd_?(\d+)_reading$/i.exec(id);
  if (m) return `Grade ${m[1]} reading`;
  return null;
}
function resolveUnit(kind, min, max) {
  switch (kind) {
    case "usd": return "usd";
    case "count": return "count";
    case "sqmi": return "sqmi";
    case "index": return "idx";
    case "num": return "num";
    case "rate":
      if (max <= 1.5) return "pct01";      // stored 0-1
      if (max <= 100) return "pct";        // stored 0-100
      return "count";                       // large -> actually a count (e.g. counties)
    default:
      if (max <= 1.5 && min >= -1.5) return "idx";
      if (max > 5000) return "count";
      return "num";
  }
}
function describeField(id, vals) {
  const min = Math.min(...vals), max = Math.max(...vals);
  const entry = FIELD_DICT[id.toLowerCase()];
  const gl = gradeLabel(id);
  let label, kind;
  if (entry) { label = entry[0]; kind = entry[1]; }
  else if (gl) { label = gl; kind = "rate"; }
  else { label = prettify(id); kind = "auto"; }
  return { id, label, unit: resolveUnit(kind, min, max), known: !!(entry || gl) };
}
function fieldSort(a, b) {
  const pa = PREFERRED.indexOf(a.id.toLowerCase()), pb = PREFERRED.indexOf(b.id.toLowerCase());
  const ra = pa < 0 ? 999 : pa, rb = pb < 0 ? 999 : pb;
  if (ra !== rb) return ra - rb;
  if (a.known !== b.known) return a.known ? -1 : 1;
  return a.label.localeCompare(b.label);
}

/* ---------------------------------------------------------------------- *
 * Real geometry (from window.RCDS_GEODATA). Projects lon/lat to the SVG
 * viewBox and discovers numeric columns as mappable fields.
 * ---------------------------------------------------------------------- */
const VB_W = 800, VB_H = 600, MARGIN = 30;
const REALGEO = {};

function eachCoord(geom, cb) {
  const t = geom.type, c = geom.coordinates;
  if (t === "Polygon") c.forEach((r) => r.forEach(cb));
  else if (t === "MultiPolygon") c.forEach((p) => p.forEach((r) => r.forEach(cb)));
}

function fitProjection(bbox) {
  const [minX, minY, maxX, maxY] = bbox;
  const midLat = (minY + maxY) / 2;
  const kx = Math.cos((midLat * Math.PI) / 180) || 1;
  const dLon = (maxX - minX) * kx || 1e-9;
  const dLat = (maxY - minY) || 1e-9;
  const W = VB_W - MARGIN * 2, H = VB_H - MARGIN * 2;
  const scale = Math.min(W / dLon, H / dLat);
  const ox = MARGIN + (W - dLon * scale) / 2;
  const oy = MARGIN + (H - dLat * scale) / 2;
  return ([lon, lat]) => [ox + (lon - minX) * kx * scale, oy + (maxY - lat) * scale];
}

function ringToPath(ring, project) {
  return ring.map((pt, i) => (i ? "L" : "M") + project(pt).map((n) => n.toFixed(1)).join(",")).join(" ") + " Z";
}
function geomToPath(geom, project) {
  if (geom.type === "Polygon") return geom.coordinates.map((r) => ringToPath(r, project)).join(" ");
  if (geom.type === "MultiPolygon") return geom.coordinates.map((poly) => poly.map((r) => ringToPath(r, project)).join(" ")).join(" ");
  return "";
}

const ID_LIKE = /(^|_)(id|geoid|fid|objectid|gid|fips|ncessch|nces|statefp|countyfp|tractce|aland|awater)($|_)|area|shape_|st_area|geometry/i;

function findNameKey(props) {
  const keys = Object.keys(props[0] || {});
  const named = keys.filter((k) => /name|_nm$|^nm|school|zone|cluster|county|label|tract/i.test(k) &&
    props.some((p) => typeof p[k] === "string"));
  if (named.length) return named[0];
  const anyStr = keys.filter((k) => props.filter((p) => typeof p[k] === "string").length > props.length * 0.6);
  return anyStr[0] || null;
}

function prepareReal(fc) {
  const feats = fc.features.filter((f) => f.geometry && f.geometry.coordinates && f.geometry.coordinates.length);
  if (!feats.length) return null;
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  feats.forEach((f) => eachCoord(f.geometry, ([x, y]) => {
    if (x < minX) minX = x; if (y < minY) minY = y; if (x > maxX) maxX = x; if (y > maxY) maxY = y;
  }));
  if (!isFinite(minX)) return null;
  const project = fitProjection([minX, minY, maxX, maxY]);

  const cells = feats.map((f, i) => {
    const g = f.geometry;
    const ring = g.type === "Polygon" ? g.coordinates[0] : g.coordinates[0][0];
    let sx = 0, sy = 0;
    ring.forEach((pt) => { const p = project(pt); sx += p[0]; sy += p[1]; });
    return { id: i, d: geomToPath(g, project), cx: sx / ring.length, cy: sy / ring.length };
  });
  const props = feats.map((f) => f.properties || {});

  const counts = {};
  props.forEach((p) => Object.keys(p).forEach((k) => {
    const v = p[k];
    if (typeof v === "number" && isFinite(v)) counts[k] = (counts[k] || 0) + 1;
  }));
  const minPresent = Math.max(3, feats.length * 0.5);
  const fieldIds = Object.keys(counts).filter((k) => counts[k] >= minPresent && !isExcludedField(k))
    .filter((k) => { // drop constant columns
      const vals = props.map((p) => p[k]).filter((v) => typeof v === "number" && isFinite(v));
      return vals.length && Math.max(...vals) !== Math.min(...vals);
    });
  const fields = fieldIds.map((k) => {
    const vals = props.map((p) => p[k]).filter((v) => typeof v === "number" && isFinite(v));
    return describeField(k, vals);
  }).sort(fieldSort);
  const nameKey = findNameKey(props);
  const names = nameKey ? props.map((p) => (p[nameKey] != null ? String(p[nameKey]) : null)) : null;

  return { cells, props, fields, names };
}

function initRealGeo() {
  const src = (typeof window !== "undefined" && window.RCDS_GEODATA) ? window.RCDS_GEODATA : {};
  Object.keys(src).forEach((id) => {
    let fc = src[id];
    if (typeof fc === "string") { try { fc = JSON.parse(fc); } catch (e) { return; } }
    if (!fc || !Array.isArray(fc.features) || !fc.features.length) return;
    try { const prepped = prepareReal(fc); if (prepped) REALGEO[id] = prepped; } catch (e) { /* skip bad layer */ }
  });
}

/* ---------------------------------------------------------------------- *
 * Synthetic geometry (fallback when no real data is present)
 * ---------------------------------------------------------------------- */
function cellPath(points) {
  return "M " + points.map((p) => `${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(" L ") + " Z";
}
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
      cells.push({ id: idx++, d: cellPath([p1, p2, p3, p4]), cx, cy });
    }
  }
  return cells;
}
function buildBlobCell(seed) {
  const rng = seededRng(seed);
  const cx = VB_W / 2, cy = VB_H / 2;
  const rx = VB_W / 2 - MARGIN * 2, ry = VB_H / 2 - MARGIN * 2;
  const n = 16, points = [];
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    const jr = 0.75 + rng() * 0.25;
    points.push({ x: cx + Math.cos(a) * rx * jr, y: cy + Math.sin(a) * ry * jr });
  }
  return [{ id: 0, d: cellPath(points), cx, cy }];
}
function syntheticCells(ds) {
  if (ds.id === "outline") return buildBlobCell(ds.seed);
  return buildGridCells(ds.rows, ds.cols, ds.seed);
}
function hashSeed(a, b) { return ((a * 2654435761 + b * 40503) >>> 0) % 100000; }
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
 * Unified field/value access (real when available, synthetic otherwise)
 * ---------------------------------------------------------------------- */
function getCells(ds) {
  return REALGEO[ds.id] ? REALGEO[ds.id].cells : syntheticCells(ds);
}
function getFields(ds) {
  if (REALGEO[ds.id]) return REALGEO[ds.id].fields;
  return ds.hasFields ? fieldsForDataset(ds.id) : [];
}
function datasetHasFields(ds) { return getFields(ds).length > 0; }
function getValues(ds, field) {
  if (REALGEO[ds.id]) {
    return REALGEO[ds.id].props.map((p) => {
      const v = Number(p[field.id]);
      return isFinite(v) ? v : null;
    });
  }
  return valuesForField(syntheticCells(ds), ds, field);
}
function featureName(ds, i) {
  if (REALGEO[ds.id] && REALGEO[ds.id].names && REALGEO[ds.id].names[i]) return REALGEO[ds.id].names[i];
  if (ds.id === "outline") return ds.label;
  return `${ds.featureNoun} ${i + 1}`;
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
      w++; sum += val; sumSquares += val * val;
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
  if (v == null || !isFinite(v)) return -1;
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
function hexToRgb(hex) { const n = parseInt(hex.slice(1), 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255]; }
function rgbToHex([r, g, b]) { return "#" + [r, g, b].map((v) => Math.round(v).toString(16).padStart(2, "0")).join("").toUpperCase(); }
function lerpColor(c1, c2, t) { const a = hexToRgb(c1), b = hexToRgb(c2); return rgbToHex(a.map((v, i) => v + (b[i] - v) * t)); }
function sampleRamp(stops, n) {
  if (n === 1) return [stops[Math.floor(stops.length / 2)]];
  const out = [];
  for (let i = 0; i < n; i++) {
    const t = i / (n - 1), pos = t * (stops.length - 1);
    const i0 = Math.floor(pos), i1 = Math.min(i0 + 1, stops.length - 1);
    out.push(lerpColor(stops[i0], stops[i1], pos - i0));
  }
  return out;
}
function colorDistance(hex1, hex2) { const a = hexToRgb(hex1), b = hexToRgb(hex2); return Math.sqrt(a.reduce((s, v, i) => s + (v - b[i]) ** 2, 0)); }

const NODATA_FILL = "#E4EAF0";

/* ---------------------------------------------------------------------- *
 * State
 * ---------------------------------------------------------------------- */
const state = {
  datasetId: "es", fieldId: "frpl", classification: "quantile", nClasses: 5,
  direction: "sequential", reverse: false, mapTitle: "", legendTitle: "", zoom: 1,
};

const els = {};
["ctl-dataset", "ctl-field", "ctl-classification", "ctl-nclasses", "nclasses-val", "ctl-reverse",
 "ctl-title", "ctl-legend", "dataset-hint", "svg-interactive", "svg-static", "legend-interactive",
 "legend-static", "map-tooltip", "static-title", "static-caption", "reference-note",
 "dist-bars", "dist-breaks", "mqs-num", "mqs-band", "mqs-meters", "zoom-in", "zoom-out",
 "add-to-report", "add-report-hint", "report-title-in", "report-intro-in", "report-layout",
 "report-count", "report-list", "report-doc", "rp-print", "rp-png", "rp-html"]
  .forEach((id) => { els[id] = document.getElementById(id); });

/* ---------------------------------------------------------------------- *
 * Controls
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
  const fields = getFields(ds);
  const has = fields.length > 0;
  els["ctl-field"].innerHTML = fields.map((f) => `<option value="${f.id}">${f.label}</option>`).join("");
  if (has && !fields.some((f) => f.id === state.fieldId)) state.fieldId = fields[0].id;
  els["ctl-field"].value = state.fieldId;
  els["ctl-field"].disabled = !has;
  ["ctl-classification", "ctl-nclasses", "ctl-legend"].forEach((id) => { els[id].disabled = !has; });
  document.querySelectorAll('input[name="direction"]').forEach((r) => { r.disabled = !has; });
  els["ctl-reverse"].disabled = !has;
}

/* ---------------------------------------------------------------------- *
 * Compute + render
 * ---------------------------------------------------------------------- */
function computeState() {
  const ds = DATASETS.find((d) => d.id === state.datasetId);
  const cells = getCells(ds);
  const fields = getFields(ds);
  const real = !!REALGEO[ds.id];
  if (!fields.length) return { ds, cells, hasFields: false, real };

  const field = fields.find((f) => f.id === state.fieldId) || fields[0];
  state.fieldId = field.id;
  const values = getValues(ds, field);
  const present = values.filter((v) => v != null && isFinite(v));
  if (!present.length) return { ds, cells, hasFields: false, real };

  const breaks = computeBreaks(present, state.classification, state.nClasses);
  const stops = RAMPS[state.direction];
  let colors = sampleRamp(stops, state.nClasses);
  if (state.reverse) colors = [...colors].reverse();
  const classes = values.map((v) => classIndexFor(v, breaks));

  return { ds, field, cells, values, present, breaks, colors, classes, hasFields: true, real };
}

function drawPolys(svg, computed, { interactive }) {
  svg.innerHTML = "";
  const ns = "http://www.w3.org/2000/svg";
  const g = document.createElementNS(ns, "g");
  g.setAttribute("id", "zoom-group");
  svg.appendChild(g);

  computed.cells.forEach((cell, i) => {
    const path = document.createElementNS(ns, "path");
    path.setAttribute("d", cell.d);
    path.setAttribute("class", "demo-poly");
    let fill;
    if (!computed.hasFields) fill = i % 2 === 0 ? "#DCE3EB" : "#EAEEF3";
    else { const cls = computed.classes[i]; fill = cls < 0 ? NODATA_FILL : computed.colors[cls]; }
    path.setAttribute("fill", fill);
    path.setAttribute("fill-rule", "evenodd");
    if (interactive && computed.hasFields) {
      path.addEventListener("mousemove", (e) => showTooltip(e, computed, i));
      path.addEventListener("mouseleave", hideTooltip);
    }
    g.appendChild(path);
  });
}

function showTooltip(e, computed, i) {
  const tip = els["map-tooltip"];
  const stage = tip.parentElement.getBoundingClientRect();
  tip.style.left = (e.clientX - stage.left) + "px";
  tip.style.top = (e.clientY - stage.top) + "px";
  const v = computed.values[i], cls = computed.classes[i];
  const clsTxt = cls < 0 ? "no data" : `Class ${cls + 1} of ${computed.breaks.length - 1}`;
  tip.innerHTML = `<b>${featureName(computed.ds, i)}</b><br>${computed.field.label}: <b>${formatValue(computed.field, v)}</b><br>${clsTxt}`;
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
  const vals = computed.present;
  const min = Math.min(...vals), max = Math.max(...vals);
  const bins = new Array(nBins).fill(0);
  vals.forEach((v) => { bins[Math.min(nBins - 1, Math.floor(((v - min) / (max - min || 1)) * nBins))]++; });
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
  const s = mqsScores(computed);
  els["mqs-num"].textContent = s.overall;
  els["mqs-band"].textContent = s.band;
  els["mqs-band"].className = "band " + (s.band === "pass" ? "band-pass" : "band-warn");
  els["mqs-meters"].innerHTML = s.meters.map(([label, val]) =>
    `<div class="meter-row"><span class="meter-label">${label}</span><span class="meter-track"><span class="meter-fill" style="width:${val}%"></span></span><span class="meter-val mono">${val}</span></div>`
  ).join("");
}

function mqsScores(computed) {
  const gvf = goodnessOfVarianceFit(computed.present, computed.breaks);
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
  return {
    overall, band: overall >= 80 ? "pass" : "review",
    meters: [["Class separation", separationScore], ["Palette contrast", contrastScore],
      ["Label legibility", legibilityScore], ["Source citation", citationScore]],
  };
}

function sourceLine(computed) {
  return computed.real
    ? `Source: ${computed.ds.label} (GCPS repo boundary data)`
    : `Source: ${computed.ds.label} (illustrative demo data)`;
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
  els["static-caption"].innerHTML = `RCDS Map Builder${computed.hasFields ? " · rcds + ggplot2" : ""}<br>${sourceLine(computed)}`;

  const isRef = !computed.hasFields;
  els["reference-note"].style.display = isRef ? "block" : "none";
  if (isRef) {
    els["reference-note"].textContent = `${computed.ds.label} is a reference layer — no choropleth field. In the full tool it's used as a boundary overlay under a data layer, not mapped on its own.`;
  }
  els["legend-interactive"].style.display = isRef ? "none" : "block";
  els["legend-static"].style.display = isRef ? "none" : "block";

  els["add-to-report"].disabled = isRef;
  els["add-report-hint"].textContent = isRef
    ? "Reference layers can't be added — pick a data layer."
    : "Adds the current map (as configured) to the report below.";
  applyZoom();
}

function applyZoom() {
  document.querySelectorAll("#svg-interactive #zoom-group, #svg-static #zoom-group").forEach((g) => {
    g.setAttribute("transform", `translate(${VB_W / 2},${VB_H / 2}) scale(${state.zoom}) translate(${-VB_W / 2},${-VB_H / 2})`);
  });
}

/* ---------------------------------------------------------------------- *
 * Wiring
 * ---------------------------------------------------------------------- */
function setDefaultTitles() {
  const ds = DATASETS.find((d) => d.id === state.datasetId);
  const fields = getFields(ds);
  const field = fields.find((f) => f.id === state.fieldId) || fields[0];
  if (field) {
    state.mapTitle = `${ds.label} — ${field.label}`;
    state.legendTitle = field.label;
  } else {
    state.mapTitle = ds.label;
    state.legendTitle = "";
  }
  els["ctl-title"].value = state.mapTitle;
  els["ctl-legend"].value = state.legendTitle;
}
function datasetHintText(ds) {
  const geoNote = REALGEO[ds.id] ? "GCPS repo boundary data" : "illustrative demo geometry";
  return datasetHasFields(ds) ? `${ds.group} · ${geoNote}` : `${ds.group} · boundary overlay, no choropleth field`;
}
function onDatasetChange() {
  state.datasetId = els["ctl-dataset"].value;
  const ds = DATASETS.find((d) => d.id === state.datasetId);
  els["dataset-hint"].textContent = datasetHintText(ds);
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
 * Gallery + palette showcase
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
    </div>`).join("");
}
function renderPaletteRow(id, colors) {
  document.getElementById(id).innerHTML = colors.map((c) => `<span style="background:${c}" title="${c}"></span>`).join("");
}

/* ---------------------------------------------------------------------- *
 * Report Builder — snapshot maps, assemble, export (print / PNG / HTML)
 * ---------------------------------------------------------------------- */
const report = { title: "GCPS Map Builder report", intro: "", layout: "stack", entries: [] };

function esc(s) { return String(s == null ? "" : s).replace(/[&<>"]/g, (m) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[m])); }

function snapshotCurrent() {
  const c = computeState();
  if (!c.hasFields) return null;
  return {
    uid: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
    title: state.mapTitle || `${c.ds.label} — ${c.field.label}`,
    fieldLabel: c.field.label,
    legendTitle: state.legendTitle || c.field.label,
    sourceLine: sourceLine(c),
    field: c.field,
    breaks: c.breaks.slice(),
    colors: c.colors.slice(),
    cellFills: c.cells.map((cell, i) => ({ d: cell.d, fill: c.classes[i] < 0 ? NODATA_FILL : c.colors[c.classes[i]] })),
    mqs: mqsScores(c),
    notes: "",
  };
}

const FIG_W = 800, FIG_H = 690;
function buildFigureSVG(e) {
  const paths = e.cellFills.map((cf) =>
    `<path d="${cf.d}" fill="${cf.fill}" stroke="#15233B" stroke-opacity="0.35" stroke-width="0.6" fill-rule="evenodd"/>`).join("");
  const n = e.colors.length;
  const lx0 = 24, sw = Math.min(48, 500 / n), ly = 632;
  let sw_rects = "", labels = "";
  for (let i = 0; i < n; i++) sw_rects += `<rect x="${(lx0 + i * sw).toFixed(1)}" y="${ly}" width="${sw.toFixed(1)}" height="12" fill="${e.colors[i]}"/>`;
  for (let i = 0; i < e.breaks.length; i++) {
    const anchor = i === 0 ? "start" : i === e.breaks.length - 1 ? "end" : "middle";
    labels += `<text x="${(lx0 + i * sw).toFixed(1)}" y="${ly + 20}" font-size="9" fill="#3F4F66" font-family="monospace" text-anchor="${anchor}">${esc(formatValue(e.field, e.breaks[i]))}</text>`;
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${FIG_W} ${FIG_H}" width="${FIG_W}" height="${FIG_H}" font-family="'Inter',system-ui,sans-serif">`
    + `<rect width="${FIG_W}" height="${FIG_H}" fill="#FFFFFF"/>`
    + `<text x="24" y="32" font-size="20" font-weight="600" fill="#15233B">${esc(e.title)}</text>`
    + `<text x="24" y="52" font-size="12" fill="#3F4F66">${esc(e.fieldLabel)}</text>`
    + `<g transform="translate(16,60) scale(0.9)">${paths}</g>`
    + `<text x="24" y="624" font-size="11" font-weight="600" fill="#15233B">${esc(e.legendTitle)}</text>`
    + sw_rects + labels
    + `<text x="${FIG_W - 16}" y="${FIG_H - 14}" font-size="10" fill="#7B8799" text-anchor="end" font-family="monospace">${esc(e.sourceLine)}</text>`
    + `</svg>`;
}

function renderReportDoc() {
  const doc = els["report-doc"];
  if (!report.entries.length) {
    doc.innerHTML = `<div class="report-empty">Your report is empty. Build a map above and click “+ Add to report”.</div>`;
    return;
  }
  const date = new Date().toLocaleDateString(undefined, { year: "numeric", month: "long", day: "numeric" });
  const figs = report.entries.map((e) =>
    `<figure class="report-fig"><div class="fig-svg">${buildFigureSVG(e)}</div>${e.notes ? `<figcaption>${esc(e.notes)}</figcaption>` : ""}</figure>`).join("");
  doc.innerHTML =
    `<div class="report-head"><div class="report-kicker mono">RCDS Map Builder</div>`
    + `<h1>${esc(report.title || "Untitled report")}</h1><div class="report-date mono">${date}</div>`
    + `${report.intro ? `<p class="report-intro">${esc(report.intro)}</p>` : ""}</div>`
    + `<div class="report-figs layout-${report.layout}">${figs}</div>`
    + `<div class="report-foot mono">Made with the RCDS Map Builder · Richard Cartographic Design System</div>`;
}

function entryCardHtml(e, i) {
  return `<div class="report-item" data-uid="${e.uid}">
    <div class="ri-head"><span class="ri-num mono">${i + 1}</span><span class="ri-title" title="${esc(e.title)}">${esc(e.title)}</span><span class="ri-mqs mono">MQS ${e.mqs.overall}</span></div>
    <input class="ri-notes" data-uid="${e.uid}" type="text" placeholder="Caption / note…" value="${esc(e.notes)}">
    <div class="ri-controls">
      <button data-act="up" data-uid="${e.uid}" title="Move up">↑</button>
      <button data-act="down" data-uid="${e.uid}" title="Move down">↓</button>
      <button data-act="png" data-uid="${e.uid}">PNG</button>
      <button data-act="remove" data-uid="${e.uid}" class="danger">Remove</button>
    </div></div>`;
}

function renderReport() {
  els["report-count"].textContent = report.entries.length;
  els["report-list"].innerHTML = report.entries.length
    ? report.entries.map(entryCardHtml).join("")
    : `<div class="report-empty">No maps yet.</div>`;
  renderReportDoc();
}

/* export helpers */
function downloadBlob(blob, name) {
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = name;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
function svgToPng(svgString, scale, cb) {
  const blob = new Blob([svgString], { type: "image/svg+xml;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const img = new Image();
  img.onload = () => {
    const canvas = document.createElement("canvas");
    canvas.width = FIG_W * scale; canvas.height = FIG_H * scale;
    const ctx = canvas.getContext("2d");
    ctx.fillStyle = "#FFFFFF"; ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
    URL.revokeObjectURL(url);
    canvas.toBlob((b) => cb(b), "image/png");
  };
  img.onerror = () => { URL.revokeObjectURL(url); cb(null); };
  img.src = url;
}
function slug(s) { return (s || "map").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 48) || "map"; }
function exportEntryPng(e) {
  svgToPng(buildFigureSVG(e), 2, (b) => { if (b) downloadBlob(b, `${slug(e.title)}.png`); });
}
function exportAllPng() {
  if (!report.entries.length) return;
  let i = 0;
  const next = () => {
    if (i >= report.entries.length) return;
    const e = report.entries[i++];
    svgToPng(buildFigureSVG(e), 2, (b) => { if (b) downloadBlob(b, `${String(i).padStart(2, "0")}-${slug(e.title)}.png`); setTimeout(next, 350); });
  };
  next();
}
const REPORT_EXPORT_CSS =
  "body{margin:0;background:#eef1f5;font-family:'Inter',system-ui,sans-serif;color:#15233B;padding:24px}"
  + ".report-doc{background:#fff;max-width:860px;margin:0 auto;padding:40px;border-radius:6px;box-shadow:0 2px 10px rgba(21,35,59,.12)}"
  + ".report-head{border-bottom:2px solid #3E5C76;padding-bottom:16px;margin-bottom:28px}"
  + ".report-kicker{font-size:11px;letter-spacing:.18em;text-transform:uppercase;color:#3E5C76;font-family:monospace}"
  + ".report-head h1{font-size:32px;margin:8px 0 0}.report-date{font-size:12px;color:#7B8799;margin-top:4px;font-family:monospace}"
  + ".report-intro{margin-top:12px;font-size:14px;color:#3F4F66;line-height:1.6}"
  + ".report-figs.layout-stack{display:flex;flex-direction:column;gap:40px}"
  + ".report-figs.layout-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:24px}"
  + ".report-fig{margin:0;break-inside:avoid}.report-fig svg{width:100%;height:auto;display:block;border:1px solid #D7DEE7;border-radius:6px}"
  + ".report-fig figcaption{margin-top:8px;font-size:12px;color:#3F4F66}"
  + ".report-foot{margin-top:40px;padding-top:12px;border-top:1px solid #D7DEE7;font-size:11px;color:#7B8799;font-family:monospace}"
  + "@media print{body{background:#fff;padding:0}.report-doc{box-shadow:none;max-width:none;padding:0}.report-fig{page-break-inside:avoid}}";
function exportHtml() {
  if (!report.entries.length) return;
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>${esc(report.title || "RCDS report")}</title><style>${REPORT_EXPORT_CSS}</style></head><body>${els["report-doc"].outerHTML}</body></html>`;
  downloadBlob(new Blob([html], { type: "text/html;charset=utf-8" }), `${slug(report.title)}.html`);
}

function bindReport() {
  els["report-title-in"].value = report.title;
  els["report-title-in"].addEventListener("input", () => { report.title = els["report-title-in"].value; renderReportDoc(); });
  els["report-intro-in"].addEventListener("input", () => { report.intro = els["report-intro-in"].value; renderReportDoc(); });
  els["report-layout"].addEventListener("change", () => { report.layout = els["report-layout"].value; renderReportDoc(); });
  els["add-to-report"].addEventListener("click", () => {
    const snap = snapshotCurrent();
    if (!snap) return;
    report.entries.push(snap);
    renderReport();
    els["report-title-in"].scrollIntoView({ behavior: "smooth", block: "nearest" });
  });
  els["rp-print"].addEventListener("click", () => { renderReportDoc(); window.print(); });
  els["rp-png"].addEventListener("click", exportAllPng);
  els["rp-html"].addEventListener("click", exportHtml);
  els["report-list"].addEventListener("input", (ev) => {
    const inp = ev.target.closest(".ri-notes"); if (!inp) return;
    const e = report.entries.find((x) => x.uid === inp.dataset.uid); if (e) { e.notes = inp.value; renderReportDoc(); }
  });
  els["report-list"].addEventListener("click", (ev) => {
    const btn = ev.target.closest("button[data-act]"); if (!btn) return;
    const uid = btn.dataset.uid, idx = report.entries.findIndex((x) => x.uid === uid);
    if (idx < 0) return;
    const act = btn.dataset.act;
    if (act === "remove") report.entries.splice(idx, 1);
    else if (act === "up" && idx > 0) { const t = report.entries[idx - 1]; report.entries[idx - 1] = report.entries[idx]; report.entries[idx] = t; }
    else if (act === "down" && idx < report.entries.length - 1) { const t = report.entries[idx + 1]; report.entries[idx + 1] = report.entries[idx]; report.entries[idx] = t; }
    else if (act === "png") { exportEntryPng(report.entries[idx]); return; }
    renderReport();
  });
}

/* ---------------------------------------------------------------------- *
 * Boot
 * ---------------------------------------------------------------------- */
initRealGeo();
populateDatasetSelect();
populateFieldSelect();
setDefaultTitles();
els["ctl-nclasses"].value = state.nClasses;
els["nclasses-val"].textContent = state.nClasses;
els["dataset-hint"].textContent = datasetHintText(DATASETS.find((d) => d.id === state.datasetId));

bindControls();
renderGallery();
renderPaletteRow("pal-seq", RAMPS.sequential);
renderPaletteRow("pal-div", RAMPS.diverging);
renderPaletteRow("pal-chrome", ["#3E5C76", "#1E6FB8", "#F1B24A"]);
bindReport();
renderReport();
render();

})();
