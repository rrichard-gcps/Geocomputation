// ============================================================================
// palette-data.js — GCPS Palette Library source data (mock)
// Repurposed from tableau_palettes.xml, cluster_colors_and_logos.csv, DimSchool.csv
// ============================================================================

// 11 REA analytics bases (from app.R gcps_base)
const GCPS_BASE = {
  maroon:"#660000", blue:"#2F5FB3", teal:"#007C91", green:"#5E8C31",
  violet:"#6A4CC3", orange:"#D96A1D", neutral:"#7A828C",
  gold:"#C49A22", plum:"#7B2D8B", slate:"#4A6D8C", emerald:"#1A7D5A"
};
const BASE_ORDER = ["maroon","blue","teal","green","violet","orange","neutral","gold","plum","slate","emerald"];
const BASE_DESC = {
  maroon:"District signature", blue:"Cool neutral category", teal:"Density & intensity",
  green:"Growth, positive", violet:"Distinct categorical", orange:"Attention, secondary",
  neutral:"Structure & gridlines", gold:"Warm highlight, recognition",
  plum:"Deep contrast, workforce & literacy", slate:"Steel-blue, operations & infrastructure",
  emerald:"Deep green, sustainability & wellness"
};
// diverging partner for the 11 bases (mirrors gcps_diverging)
const DIVERGE_PAIR = { maroon:"teal", teal:"maroon", blue:"orange", orange:"blue", green:"violet", violet:"green", neutral:"maroon",
  gold:"teal", plum:"green", slate:"orange", emerald:"maroon" };

// Curated GCPS qualitative palette (gcps_viz_palette_test)
const GCPS_QUALITATIVE = ["#374E8E","#4FBBAE","#DF7C18","#AC004F","#1B87AA","#E3B13E","#CE4631","#8D7A81","#7E7E8F"];

// 21 cluster brand colors (cluster_colors_and_logos.csv + GCPS Clusters XML; Norcross = navy #1D2252 not the CSV's grey)
const CLUSTERS = {
  "Archer":"#CC3333","Berkmar":"#003366","Brookwood":"#660000","Central Gwinnett":"#FFCC33",
  "Collins Hill":"#336633","Dacula":"#CCCC99","Discovery":"#66CC33","Duluth":"#330066",
  "Grayson":"#336633","Lanier":"#CC6600","Meadowcreek":"#6699CC","Mill Creek":"#993333",
  "Mountain View":"#CCCC66","Norcross":"#1D2252","North Gwinnett":"#CC3333","Parkview":"#FF6633",
  "Peachtree Ridge":"#000066","Seckinger":"#0099CC","Shiloh":"#000000","South Gwinnett":"#000033",
  "Special Entity":"#CCCCCC"
};
const CLUSTER_ORDER = Object.keys(CLUSTERS);

// All-clusters categorical (for cluster/school mode) — dedupe identical hexes
const ALL_CLUSTERS_CAT = [...new Set(Object.values(CLUSTERS))];

// School → serving cluster (DimSchool.csv "Cluster" column; NA → Special Entity)
const SCHOOL_CLUSTER = {
  "Alcova ES":"Dacula","Alford ES":"Discovery","Anderson-Livsey ES":"Shiloh","Annistown ES":"Shiloh",
  "Arcado ES":"Parkview","Baggett ES":"Discovery","Baldwin ES":"Norcross","Beaver Ridge ES":"Norcross",
  "Benefield ES":"Discovery","Berkeley Lake ES":"Duluth","Bethesda ES":"Berkmar","Britt ES":"South Gwinnett",
  "Brookwood ES":"Brookwood","Burnette ES":"Peachtree Ridge","Camp Creek ES":"Parkview","Cedar Hill ES":"Discovery",
  "Centerville ES":"Shiloh","Chattahoochee ES":"Duluth","Chesney ES":"Duluth","Cooper ES":"Archer",
  "Corley ES":"Berkmar","Craig ES":"Brookwood","Dacula ES":"Dacula","Duncan Creek ES":"Mill Creek",
  "Dyer ES":"Mountain View","Ferguson ES":"Meadowcreek","Fort Daniel ES":"Mill Creek","Freeman's Mill ES":"Mountain View",
  "Graves ES":"Meadowcreek","Grayson ES":"Grayson","Gwin Oaks ES":"Brookwood","Harbins ES":"Archer",
  "Harmony ES":"Seckinger","Harris ES":"Duluth","Head ES":"Brookwood","Hopkins ES":"Berkmar",
  "Ivy Creek ES":"Seckinger","Jackson ES":"Peachtree Ridge","Jenkins ES":"Central Gwinnett","Kanoheda ES":"Berkmar",
  "Knight ES":"Parkview","Lawrenceville ES":"Central Gwinnett","Level Creek ES":"North Gwinnett","Lilburn ES":"Meadowcreek",
  "Lovin ES":"Archer","Magill ES":"South Gwinnett","Mason ES":"Peachtree Ridge","McKendree ES":"Collins Hill",
  "Meadowcreek ES":"Meadowcreek","Minor ES":"Berkmar","Mountain Park ES":"Parkview","Mulberry ES":"Dacula",
  "Nesbit ES":"Meadowcreek","Norcross ES":"Norcross","North Metro Academy":"Norcross","Norton ES":"South Gwinnett",
  "Parsons ES":"Peachtree Ridge","Partee ES":"Shiloh","Patrick ES":"Seckinger","Peachtree ES":"Norcross",
  "Pharr ES":"Grayson","Puckett's Mill ES":"Mill Creek","Riverside ES":"North Gwinnett","Roberts ES":"North Gwinnett",
  "Rock Springs ES":"Collins Hill","Rockbridge ES":"Meadowcreek","Rosebud ES":"South Gwinnett","Shiloh ES":"Shiloh",
  "Simonton ES":"Central Gwinnett","Simpson ES":"Norcross","Starling ES":"Grayson","Stripling ES":"Norcross",
  "Sugar Hill ES":"Lanier","Suwanee ES":"North Gwinnett","Sycamore ES":"Lanier","Taylor ES":"Collins Hill",
  "Trip ES":"Grayson","Walnut Grove ES":"Collins Hill","White Oak ES":"Lanier","Winn Holt ES":"Central Gwinnett",
  "Woodward Mill ES":"Mountain View",
  "Bay Creek MS":"Grayson","Berkmar MS":"Berkmar","Coleman MS":"Duluth","Couch MS":"Grayson",
  "Creekland MS":"Collins Hill","Crews MS":"Brookwood","Dacula MS":"Dacula","Duluth MS":"Duluth",
  "Five Forks MS":"Brookwood","Grace Snell MS":"South Gwinnett","Hull MS":"Peachtree Ridge","Jones MS":"Seckinger",
  "Jordan MS":"Central Gwinnett","Lanier MS":"Lanier","Lilburn MS":"Meadowcreek","McConnell MS":"Archer",
  "Moore MS":"Central Gwinnett","North Gwinnett MS":"North Gwinnett","Northbrook MS":"Peachtree Ridge","Osborne MS":"Mill Creek",
  "Pinckneyville MS":"Norcross","Radloff MS":"Meadowcreek","Richards MS":"Discovery","Shiloh MS":"Shiloh",
  "Snellville MS":"South Gwinnett","Summerour MS":"Norcross","Sweetwater MS":"Berkmar","Trickum MS":"Parkview",
  "Twin Rivers MS":"Mountain View",
  "Archer HS":"Archer","Berkmar HS":"Berkmar","Brookwood HS":"Brookwood","Central Gwinnett HS":"Central Gwinnett",
  "Collins Hill HS":"Collins Hill","Dacula HS":"Dacula","Discovery HS":"Discovery","Duluth HS":"Duluth",
  "GSMST":"Discovery","Grayson HS":"Grayson","Lanier HS":"Lanier","McClure Health Science HS":"Meadowcreek",
  "Meadowcreek HS":"Meadowcreek","Mill Creek HS":"Mill Creek","Mountain View HS":"Mountain View","Norcross HS":"Norcross",
  "North Gwinnett HS":"North Gwinnett","Parkview HS":"Parkview","Paul Duke STEM HS":"Norcross","Peachtree Ridge HS":"Peachtree Ridge",
  "Seckinger HS":"Seckinger","Shiloh HS":"Shiloh","South Gwinnett HS":"South Gwinnett",
  "Buice Center":"Special Entity","Devereux - GCPS":"Special Entity","GIVE East":"Mountain View","GIVE West":"Norcross",
  "GOC":"Special Entity","Grayson Tech":"Special Entity","ITC":"Special Entity","Maxwell HS":"Discovery",
  "Oakland Meadow":"Central Gwinnett","Phoenix HS":"Central Gwinnett","New Life Academy":"Duluth"
};
const SCHOOL_ORDER = Object.keys(SCHOOL_CLUSTER).sort();
