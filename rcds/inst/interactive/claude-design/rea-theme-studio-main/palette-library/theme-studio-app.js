// ============================================================================
// theme-studio-app.js — UI state, rendering, wiring for REA Theme Studio
// Depends on palette-data.js + theme-studio.js (window.TS)
// ============================================================================
(function(){
const T = window.TS;
const $ = s => document.querySelector(s);
const $$ = s => Array.from(document.querySelectorAll(s));
const cap = s => s.charAt(0).toUpperCase()+s.slice(1);
const clamp=(x,a,b)=>Math.min(b,Math.max(a,x));

const state = {
  tab:"palette",
  // palette
  mode:"bases", baseKey:"teal", cluster:"Brookwood", school:SCHOOL_ORDER[0],
  type:"tints", catSet:"curated", perfN:4, perfV:"semantic",
  counts:{sequential:5,continuous:9,categorical:7,diverging:7},
  // typography
  font:"sourcesans", baseSize:15, ratio:"1.2", weight:600,
  // surfaces
  surface:"paper", accent:"maroon",
  // export
  exp:"r",
  // theme preview — layout (mirrors the Shiny Dashboard Architect config)
  layout:{
    canvas:{width:1600,height:900},
    header:{height:80,padding:20,logo_width:180,logo_height:50,nav_button_count:4},
    sidebar:{width:260,padding:16,nav_item_count:5},
    content:{kpi_height:100,kpi_count:4,kpi_gap:20,grid_rows:2,grid_cols:2,grid_gap:16,padding:20}
  },
  preview:{title:"District Snapshot", subtitle:"Synthetic K-12 data · live theme preview", brand:"REA"}
};

/* ---------- palette helpers ---------- */
const TYPES=[["tints","Tints & Shades"],["sequential","Sequential"],["diverging","Diverging"],["categorical","Categorical"],["performance","Performance"],["continuous","Continuous"],["trend","Trend"]];
const PURPOSE={sequential:"Single-hue ramp, light → dark. Ordered data, KPI emphasis, table heat.",tints:"11-step tint/shade scale (50–950) for fine UI theming and surface layering.",diverging:"Two-ended scale through a neutral center — above/below target, gap-to-goal, change.",categorical:"Distinct hues for unrelated groups. Three curated, source-independent sets.",performance:"Ordinal proficiency scale. Semantic = fixed good→needs-support; Source-tinted = monochrome intensity.",continuous:"Fine gradient for heatmaps and continuous fills (low → high).",trend:"Fixed semantic indicators — positive, negative, neutral."};
const DIVERGE_PAIR_={maroon:"teal",teal:"maroon",blue:"orange",orange:"blue",green:"violet",violet:"green",neutral:"maroon",gold:"teal",plum:"green",slate:"orange",emerald:"maroon"};
const COUNT={sequential:{min:3,max:9},continuous:{min:3,max:11},categorical:{min:3,max:10},diverging:{set:[5,7,9,11]}};

function sourceColor(){if(state.mode==="bases")return GCPS_BASE[state.baseKey];if(state.mode==="clusters")return CLUSTERS[state.cluster];return CLUSTERS[SCHOOL_CLUSTER[state.school]];}
function sourceName(){if(state.mode==="bases")return cap(state.baseKey);if(state.mode==="clusters")return state.cluster;return state.school+" · "+SCHOOL_CLUSTER[state.school];}
function divergeOther(){if(state.mode==="bases")return GCPS_BASE[DIVERGE_PAIR_[state.baseKey]];const [L,C,H]=T.hexToOklch(sourceColor());return T.oklchToHex(L,C,(H+180)%360);}
function catMax(){return state.catSet==="clusters"?CLUSTER_ORDER.length:COUNT.categorical.max;}
function currentPalette(){
  const hex=sourceColor();
  switch(state.type){
    case"sequential":return T.sequential(hex,state.counts.sequential);
    case"tints":return T.tints(hex);
    case"diverging":return T.diverging(hex,divergeOther(),state.counts.diverging);
    case"continuous":return T.continuous(hex,state.counts.continuous);
    case"trend":return T.trend();
    case"performance":return state.perfV==="semantic"?T.perfSemantic(state.perfN):T.perfBase(hex,state.perfN);
    case"categorical":return T.categorical(state.catSet,Math.min(state.counts.categorical,catMax()));
  }
}
function accentHex(){const o=T.accentOptions().find(a=>a.id===state.accent);return o?o.hex:"#660000";}
function fontDef(){return T.FONTS.find(f=>f.id===state.font);}
function surf(){return T.SURFACES[state.surface];}

/* ---------- TAB: palette ---------- */
function renderSource(){
  const body=$("#srcBody");
  $$("#srcSeg button").forEach(b=>b.setAttribute('aria-pressed',b.dataset.m===state.mode));
  if(state.mode==="bases"){
    body.innerHTML='<div class="chip-row" id="chips"></div>';const row=body.querySelector('#chips');
    BASE_ORDER.forEach(k=>{const b=document.createElement('button');b.className='chip';b.setAttribute('aria-pressed',k===state.baseKey);b.innerHTML=`<span class="dot" style="background:${GCPS_BASE[k]}"></span><span class="nm">${k}</span>`;b.onclick=()=>{state.baseKey=k;render();};row.appendChild(b);});
  }else if(state.mode==="clusters"){
    body.innerHTML='<div class="chip-row" id="chips"></div>';const row=body.querySelector('#chips');
    CLUSTER_ORDER.forEach(k=>{const b=document.createElement('button');b.className='chip';b.setAttribute('aria-pressed',k===state.cluster);b.innerHTML=`<span class="dot" style="background:${CLUSTERS[k]}"></span><span class="nm" style="text-transform:none">${k}</span>`;b.onclick=()=>{state.cluster=k;render();};row.appendChild(b);});
  }else{
    body.innerHTML='<div class="row"><select id="schoolSel"></select><span class="school-resolved" id="schoolRes"></span></div>';
    const sel=body.querySelector('#schoolSel');
    SCHOOL_ORDER.forEach(s=>{const o=document.createElement('option');o.value=s;o.textContent=s;if(s===state.school)o.selected=true;sel.appendChild(o);});
    sel.onchange=()=>{state.school=sel.value;render();};
    const cl=SCHOOL_CLUSTER[state.school];
    body.querySelector('#schoolRes').innerHTML=`<span class="dot" style="background:${CLUSTERS[cl]}"></span>Inherits <b>${cl}</b> · ${CLUSTERS[cl]}`;
  }
}
const isGrid=()=>["continuous","tints","categorical"].includes(state.type);
function gridCols(){if(state.type==="tints")return 11;if(state.type==="continuous")return Math.min(state.counts.continuous,11);if(state.type==="categorical")return Math.min(Math.min(state.counts.categorical,catMax()),7);return 7;}
function semLabel(item,i,len){
  if(item.sem!==undefined)return item.sem;
  if(["sequential","tints","continuous"].includes(state.type)){if(i===0)return"Lightest";if(i===len-1)return"Darkest";if(i===Math.floor(len/2))return"Mid";return"";}
  if(state.type==="diverging"){if(i===Math.floor(len/2))return"Center";return item.n<0?"Low pole":"High pole";}
  return"";
}
function renderCount(){
  const wrap=$("#countWidget");
  if(state.type==="diverging"){
    wrap.innerHTML='<div class="seg" id="divSeg"></div>';const seg=wrap.querySelector('#divSeg');
    COUNT.diverging.set.forEach(v=>{const b=document.createElement('button');b.textContent=v;b.setAttribute('aria-pressed',v===state.counts.diverging);b.onclick=()=>{state.counts.diverging=v;render();};seg.appendChild(b);});return;
  }
  const cfg=COUNT[state.type];if(!cfg)return;
  const max=state.type==="categorical"?catMax():cfg.max;
  let v=clamp(state.counts[state.type],cfg.min,max);state.counts[state.type]=v;
  wrap.innerHTML=`<div class="stepper"><button id="cMinus">−</button><span class="val">${v} color${v>1?'s':''}</span><button id="cPlus">+</button></div><span class="mono" style="font-size:11px;color:var(--text-3)">${cfg.min}–${max}</span>`;
  const minus=wrap.querySelector('#cMinus'),plus=wrap.querySelector('#cPlus');
  minus.disabled=v<=cfg.min;plus.disabled=v>=max;
  minus.onclick=()=>{state.counts[state.type]=v-1;render();};plus.onclick=()=>{state.counts[state.type]=v+1;render();};
}
function renderPalette(){
  renderSource();
  $$("#typeSeg button").forEach(b=>b.setAttribute('aria-pressed',b.dataset.t===state.type));
  $("#perfCtrls").classList.toggle('show',state.type==="performance");
  $("#catCtrls").classList.toggle('show',state.type==="categorical");
  const hasCount=["sequential","continuous","categorical","diverging"].includes(state.type);
  $("#countCtrls").classList.toggle('show',hasCount);if(hasCount)renderCount();
  $$("#catSetSeg button").forEach(b=>b.setAttribute('aria-pressed',b.dataset.s===state.catSet));

  $("#dTitle").textContent=(TYPES.find(t=>t[0]===state.type)[1])+" · "+sourceName();
  let purpose=PURPOSE[state.type];
  if(state.type==="categorical")purpose=T.CAT_SETS[state.catSet].desc+(state.catSet==="clusters"?" Swatches are labeled with the cluster name.":"");
  $("#dPurpose").textContent=purpose;

  const pal=currentPalette();
  const ramp=document.createElement('div');
  ramp.className=state.type==="trend"?"trend-row":(isGrid()?"ramp gridwrap":"ramp");
  if(isGrid())ramp.style.setProperty('--cols',gridCols());
  ramp.innerHTML=pal.map((item,i)=>{
    const sem=semLabel(item,i,pal.length);
    const num=(state.type==="performance")?("L"+item.n):(state.type==="diverging"?(item.n>0?"+"+item.n:item.n):item.n);
    return `<div class="sw" data-hex="${item.hex}"><div class="swatch" style="background:${item.hex}"><span class="cp">Copy</span></div><div class="lbl"><div class="num">${num}</div>${sem?`<div class="sem">${sem}</div>`:''}<div class="hex">${item.hex}</div></div></div>`;
  }).join('');
  const host=$("#dRamp");host.innerHTML='';host.appendChild(ramp);
  ramp.querySelectorAll('.sw').forEach(sw=>sw.onclick=()=>copy(sw.dataset.hex,'Copied '+sw.dataset.hex));

  const aa=pal.filter(p=>T.contrastWhite(p.hex)>=4.5).length;
  const extra=state.type==="categorical"?` · ${T.CAT_SETS[state.catSet].label}`:"";
  $("#dMeta").textContent=`${pal.length} stops · ${aa} meet AA on white · source ${sourceColor()}${extra}`;

  renderAccent();
}

/* ---------- Accent chip row (lives in Palette tab) ---------- */
function renderAccent(){
  const ar=$("#accentRow");if(!ar)return;ar.innerHTML='';
  T.accentOptions().forEach(a=>{const b=document.createElement('button');b.className='chip';b.setAttribute('aria-pressed',a.id===state.accent);b.innerHTML=`<span class="dot" style="background:${a.hex}"></span><span class="nm" style="text-transform:none">${a.label}</span>`;b.onclick=()=>{state.accent=a.id;render();};ar.appendChild(b);});
}

/* ---------- TAB: typography ---------- */
function renderType(){
  const grid=$("#fontGrid");grid.innerHTML='';
  T.FONTS.forEach(f=>{const b=document.createElement('button');b.className='fontcard';b.setAttribute('aria-pressed',f.id===state.font);b.innerHTML=`<span class="fn" style="font-family:${f.stack}">${f.label}</span><span class="fu">${f.use}</span>`;b.onclick=()=>{state.font=f.id;render();};grid.appendChild(b);});
  // ratio seg
  const rs=$("#ratioSeg");if(!rs.dataset.built){Object.entries(T.SCALE_RATIOS).forEach(([k,lbl])=>{const b=document.createElement('button');b.dataset.r=k;b.textContent=lbl;b.onclick=()=>{state.ratio=k;render();};rs.appendChild(b);});rs.dataset.built="1";}
  $$("#ratioSeg button").forEach(b=>b.setAttribute('aria-pressed',b.dataset.r===state.ratio));
  $$("#weightSeg button").forEach(b=>b.setAttribute('aria-pressed',+b.dataset.w===state.weight));
  $("#baseVal").textContent=state.baseSize+"px";
  const sc=T.typeScale(state.baseSize,state.ratio);
  const fam=fontDef().stack;
  const rows=[
    ["display",sc.display,state.weight,"-0.022em"],
    ["h1 · title",sc.h1,state.weight,"-0.018em"],
    ["h2 · section",sc.h2,state.weight,"-0.01em"],
    ["h3 · card",sc.h3,state.weight,"0"],
    ["body-lg",sc.bodyLg,400,"0"],
    ["body",sc.body,400,"0"],
    ["caption",sc.caption,600,"0.12em",true],
    ["micro",sc.micro,500,"0.04em"]
  ];
  const sample={ "display":"District Snapshot","h1 · title":"Palette Explorer","h2 · section":"Related palettes","h3 · card":"Teal — Sequential","body-lg":"Orientation copy that sits above a control group.","body":"Default UI text, table cells, field labels and helper sentences.","caption":"Typography Controls","micro":"#007C91 · contrast 4.8:1 AA"};
  $("#specimen").innerHTML=rows.map(([name,size,w,ls,upper])=>{
    const style=`font-family:${name==='micro'?'var(--mono)':fam};font-size:${size}px;line-height:1.2;font-weight:${w};letter-spacing:${ls};${upper?'text-transform:uppercase;color:var(--text-3);':''}`;
    return `<div class="type-row"><div class="meta"><b>${name}</b>${size}px · ${w}${ls!=='0'?'<br>'+ls:''}</div><div class="specimen" style="${style}">${sample[name]}</div></div>`;
  }).join('');
}

/* ---------- TAB: surfaces ---------- */
function renderSurfaces(){
  const grid=$("#surfGrid");grid.innerHTML='';
  Object.entries(T.SURFACES).forEach(([k,s])=>{
    const b=document.createElement('button');b.className='surf-card';b.setAttribute('aria-pressed',k===state.surface);
    b.innerHTML=`<div class="surf-prev"><span style="background:${s.canvas}"></span><span style="background:${s.surface}"></span><span style="background:${s.sunken}"></span><span style="background:${s.border}"></span><span style="background:${s.text}"></span></div><div class="surf-meta"><div class="sn">${s.label}</div><div class="snote">${s.note}</div></div>`;
    b.onclick=()=>{state.surface=k;render();};grid.appendChild(b);
  });
  const s=surf();
  const toks=[["canvas",s.canvas],["surface",s.surface],["sunken",s.sunken],["border",s.border],["border-strong",s.borderStrong],["text",s.text],["text-2",s.text2],["text-3",s.text3],["accent",accentHex()]];
  $("#tokenGrid").innerHTML=toks.map(([r,h])=>`<div class="token"><div class="chip" style="background:${h}"></div><div class="tb"><div class="role">${r}</div><div class="hx">${h.toUpperCase()}</div></div></div>`).join('');
  renderAccent();
  const SP=[["--s1","4px"],["--s2","8px"],["--s3","12px"],["--s4","16px"],["--s5","24px"],["--s6","32px"],["--s7","48px"],["--s8","64px"]];
  $("#spaceScale").innerHTML=SP.map(([n,v])=>`<div class="space-row"><span class="name">${n}</span><span class="val">${v}</span><div class="bar" style="width:${v}"></div></div>`).join('');
}

/* ---------- TAB: theme preview ----------
   Interactive dashboard preview: layout controls (canvas, header, sidebar, KPI,
   grid) + custom title/subtitle text drive a live, theme-styled dashboard that is
   the same uniform layout the Export tab emits. Layout state also feeds codeConfig(). */

// equal pixel split, ported from the Shiny calc_pixels() (proportions = null)
function pxSplit(total,gap,count){return (total-gap*(count-1))/count;}

// Build the inner HTML of the dashboard at full canvas dimensions.
function buildDashboardHtml(){
  const L=state.layout, c=L.content, h=L.header, sb=L.sidebar, cv=L.canvas;
  const ramp=currentPalette().map(p=>p.hex).slice(0,5);
  while(ramp.length<5)ramp.push(accentHex());
  const mainW=cv.width-sb.width, mainH=cv.height-h.height;
  const contentH=mainH-c.kpi_height-c.kpi_gap-c.padding*2;
  const pv=state.preview;

  // header
  const navBtns=Array.from({length:h.nav_button_count},(_,i)=>`<div class="dx-nav-btn${i===0?' active':''}"></div>`).join('');
  const logoStyle=`width:${h.logo_width}px;height:${h.logo_height}px;${h.logo_width<=0?'display:none;':''}`;
  const header=`<div class="dx-header" style="height:${h.height}px;padding:0 ${h.padding}px;">`+
    `<div class="dx-logo" style="${logoStyle}">${esc(pv.brand||'')}</div>`+
    `<div class="dx-title">${esc(pv.title||'')}${pv.subtitle?`<span class="dx-sub">${esc(pv.subtitle)}</span>`:''}</div>`+
    `<div class="dx-nav">${navBtns}</div></div>`;

  // sidebar
  const navItems=Array.from({length:sb.nav_item_count},(_,i)=>`<div class="dx-nav-item${i===0?' active':''}"><span class="dx-nav-ic"></span><span>Menu Item ${i+1}</span></div>`).join('');
  const sidebar=`<div class="dx-sidebar" style="top:${h.height}px;width:${sb.width}px;height:${mainH}px;padding:${sb.padding}px;">`+
    `<div class="dx-sb-title">Navigation</div>${navItems}</div>`;

  // KPI row
  const totalAvail=mainW-c.padding*2;
  const kpiW=pxSplit(totalAvail,c.kpi_gap,c.kpi_count);
  const swatches=ramp.map(hex=>`<span class="dx-kpi-sw" style="background:${hex}"></span>`).join('');
  let kpis="";
  for(let i=1;i<=c.kpi_count;i++){
    const val=1000+(i*1373)%9000;
    const chg=(1+((i*7)%14)+((i*3)%10)/10).toFixed(1);
    kpis+=`<div class="dx-kpi" style="flex:none;width:${Math.round(kpiW)}px;border-left:3px solid ${ramp[2]};">`+
      `<div class="dx-kpi-lbl">KPI Metric ${i}</div><div class="dx-kpi-val">${val.toLocaleString()}</div>`+
      `<div class="dx-kpi-chg">+${chg}%</div><div class="dx-kpi-sws">${swatches}</div></div>`;
  }

  // uniform grid (rows × cols) — absolute positioned, matching the Shiny preview
  const rows=c.grid_rows, cols=c.grid_cols;
  const rh=pxSplit(contentH,c.grid_gap,rows);
  const cw=pxSplit(mainW-c.padding*2,c.grid_gap,cols);
  let cards="",yOff=0,idx=1;
  for(let r=0;r<rows;r++){
    let xOff=0;
    for(let col=0;col<cols;col++){
      cards+=`<div class="dx-card" style="left:${Math.round(xOff)}px;top:${Math.round(yOff)}px;width:${Math.round(cw)}px;height:${Math.round(rh)}px;">`+
        `<div class="dx-card-hd"><span class="dx-card-tt">Chart ${idx}</span></div>`+
        `<div class="dx-card-bd">Visual Placeholder</div></div>`;
      xOff+=cw+c.grid_gap;idx++;
    }
    yOff+=rh+c.grid_gap;
  }
  const content=`<div class="dx-main" style="top:${h.height}px;left:${sb.width}px;width:${mainW}px;height:${mainH}px;padding:${c.padding}px;">`+
    `<div class="dx-kpis" style="gap:${c.kpi_gap}px;margin-bottom:${c.kpi_gap}px;height:${c.kpi_height}px;">${kpis}</div>`+
    `<div class="dx-grid" style="height:${contentH}px;">${cards}</div></div>`;

  return header+sidebar+content;
}

function esc(s){return String(s).replace(/[&<>"]/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[ch]));}

// numeric control: path is e.g. ["header","height"] inside state.layout
function numCtrl(label,path,min,max,step){
  const val=path.reduce((o,k)=>o[k],state.layout);
  const id="lc_"+path.join("_");
  return `<label class="lc"><span>${label}</span><input type="number" id="${id}" value="${val}" min="${min}" max="${max}" step="${step||1}" data-path="${path.join('.')}"></label>`;
}
function txtCtrl(label,key,ph){
  const val=state.preview[key]||"";
  return `<label class="lc lc-wide"><span>${label}</span><input type="text" id="pv_${key}" value="${esc(val)}" placeholder="${ph||''}" data-pv="${key}"></label>`;
}

function renderPreview(){
  const ctrls=$("#previewControls");
  ctrls.innerHTML=
    `<div class="lc-group"><div class="lc-gt">Content</div>`+
      txtCtrl("Brand","brand","REA")+txtCtrl("Title","title","District Snapshot")+txtCtrl("Subtitle","subtitle","")+
    `</div>`+
    `<div class="lc-group"><div class="lc-gt">Canvas</div>`+
      numCtrl("Width",["canvas","width"],400,3840,10)+numCtrl("Height",["canvas","height"],300,2160,10)+
    `</div>`+
    `<div class="lc-group"><div class="lc-gt">Header</div>`+
      numCtrl("Height",["header","height"],40,200)+numCtrl("Padding",["header","padding"],0,40)+
      numCtrl("Logo W",["header","logo_width"],0,300)+numCtrl("Logo H",["header","logo_height"],20,100)+
      numCtrl("Nav buttons",["header","nav_button_count"],0,8)+
    `</div>`+
    `<div class="lc-group"><div class="lc-gt">Sidebar</div>`+
      numCtrl("Width",["sidebar","width"],100,400)+numCtrl("Padding",["sidebar","padding"],0,32)+
      numCtrl("Nav items",["sidebar","nav_item_count"],1,15)+
    `</div>`+
    `<div class="lc-group"><div class="lc-gt">KPI cards</div>`+
      numCtrl("Count",["content","kpi_count"],1,8)+numCtrl("Height",["content","kpi_height"],60,150)+numCtrl("Gap",["content","kpi_gap"],0,40)+
    `</div>`+
    `<div class="lc-group"><div class="lc-gt">Content grid</div>`+
      numCtrl("Rows",["content","grid_rows"],1,10)+numCtrl("Columns",["content","grid_cols"],1,6)+numCtrl("Gap",["content","grid_gap"],0,40)+numCtrl("Padding",["content","padding"],0,40)+
    `</div>`;

  // wire numeric controls
  ctrls.querySelectorAll('input[data-path]').forEach(inp=>{
    inp.onchange=()=>{
      const parts=inp.dataset.path.split('.');
      let v=parseFloat(inp.value);if(isNaN(v))return;
      v=clamp(v,parseFloat(inp.min),parseFloat(inp.max));inp.value=v;
      let o=state.layout;for(let i=0;i<parts.length-1;i++)o=o[parts[i]];
      o[parts[parts.length-1]]=v;
      drawPreview();
    };
  });
  // wire text controls
  ctrls.querySelectorAll('input[data-pv]').forEach(inp=>{
    inp.oninput=()=>{state.preview[inp.dataset.pv]=inp.value;drawPreview();};
  });

  drawPreview();
}

function drawPreview(){
  const s=surf();const acc=accentHex();const f=fontDef();const sc=T.typeScale(state.baseSize,state.ratio);
  const stage=$("#tpStage");const dash=$("#tpDash");if(!dash)return;
  const cv=state.layout.canvas;
  dash.style.cssText=
    `--dx-bg:${s.canvas};--dx-card:${s.surface};--dx-border:${s.border};--dx-text:${s.text};`+
    `--dx-text2:${s.text2};--dx-accent:${acc};--dx-radius:8px;--dx-radius-lg:12px;`+
    `--dx-font:${f.stack};--dx-fw:${state.weight};--dx-fs:${state.baseSize}px;--dx-fh:${Math.round(sc.h3)}px;`+
    `width:${cv.width}px;height:${cv.height}px;`;
  dash.innerHTML=buildDashboardHtml();
  // scale to fit the stage width
  const avail=stage.clientWidth||stage.getBoundingClientRect().width||1000;
  const scale=Math.min(1, avail/cv.width);
  dash.style.transform=`scale(${scale})`;
  stage.style.height=(cv.height*scale)+"px";
}

/* ---------- TAB: accessibility ---------- */
function a11yCard(fg,bg,pair){
  const r=T.contrast(fg,bg);const rt=T.rating(r,false);
  return `<div class="a11y"><div class="demo" style="background:${bg};color:${fg}">Aa</div><div class="ab"><div class="meta"><div class="pair">${pair}</div><div class="ratio">${r.toFixed(2)}:1</div></div><span class="badge ${rt}">${rt==='AA-lg'?'AA Large':rt.toUpperCase()}</span></div></div>`;
}
function renderA11y(){
  const s=surf();const acc=accentHex();
  $("#a11yChrome").innerHTML=[
    a11yCard(s.text,s.surface,"text on surface"),
    a11yCard(s.text2,s.surface,"text-2 on surface"),
    a11yCard(s.text3,s.surface,"text-3 on surface"),
    a11yCard(s.text,s.canvas,"text on canvas"),
    a11yCard(acc,s.surface,"accent on surface"),
    a11yCard("#FFFFFF",acc,"white on accent")
  ].join('');
  const pal=currentPalette();
  $("#a11yPalette").innerHTML=pal.map(p=>a11yCard(p.hex,"#FFFFFF",(p.sem||("Stop "+p.n))+" on white")).join('');
}

/* ---------- Code generators (ported from the Shiny app's generate_*()) ----------
   These reproduce the Shiny Dashboard Architect exports client-side. The studio
   carries theme/type/palette; the dashboard layout (KPI count, grid, canvas) is
   controlled live from the Theme Preview tab via state.layout (uniform layout). */
function codeConfig(){
  const s=surf();const acc=accentHex();const f=fontDef();const sc=T.typeScale(state.baseSize,state.ratio);
  const ramp=currentPalette().map(p=>p.hex).slice(0,5);
  const L=state.layout;
  return {
    canvas:L.canvas, header:L.header, sidebar:L.sidebar,
    content:Object.assign({}, L.content, {layout_type:"uniform", kpi_proportions:null}),
    theme:{bg_page:s.canvas,bg_card:s.surface,border:s.border,text_primary:s.text,
           text_secondary:s.text2,accent:acc,radius:"8px",radius_lg:"12px"},
    typography:{font_family_name:(f.google||f.label),font_family:f.stack,font_weight:String(state.weight),
                font_size_base:state.baseSize,font_size_heading:Math.round(sc.h3)},
    palette:{base_name:sourceName(),base:acc,ramp:ramp}
  };
}
// equal 12-col split (proportions are always null with the default layout)
function props12(count){const base=Math.floor(12/count);let w=Array(count).fill(base);const rem=12-base*count;for(let i=0;i<rem;i++)w[i]++;return w;}
// equal pixel split
function calcPx(total,gap,count){return (total-gap*(count-1))/count;}
function rampAt(ramp,i,accent){return i<=ramp.length?ramp[i-1]:accent;}

function genDax(c){
  return [
    "// ============================================",
    "// Dashboard Layout DAX Measures",
    "// ============================================",
    "",
    "// Canvas Dimensions",
    `Canvas_Width = ${c.canvas.width}`,
    `Canvas_Height = ${c.canvas.height}`,
    "",
    "// Header Settings",
    `Header_Height = ${c.header.height}`,
    `Header_Padding = ${c.header.padding}`,
    `Logo_Width = ${c.header.logo_width}`,
    `Logo_Height = ${c.header.logo_height}`,
    "",
    "// Sidebar Settings",
    `Sidebar_Width = ${c.sidebar.width}`,
    `Sidebar_Padding = ${c.sidebar.padding}`,
    "",
    "// KPI Card Settings",
    `KPI_Height = ${c.content.kpi_height}`,
    `KPI_Count = ${c.content.kpi_count}`,
    `KPI_Gap = ${c.content.kpi_gap}`,
    "",
    "// Grid Settings",
    `Grid_Rows = ${c.content.grid_rows}`,
    `Grid_Cols = ${c.content.grid_cols}`,
    `Grid_Gap = ${c.content.grid_gap}`,
    "",
    "// Theme Colors",
    `Theme_BG_Page = "${c.theme.bg_page}"`,
    `Theme_BG_Card = "${c.theme.bg_card}"`,
    `Theme_Border = "${c.theme.border}"`,
    `Theme_Accent = "${c.theme.accent}"`,
    "",
    "// Layout HTML (copy from the Power BI Layout export)",
    'Layout HTML = "<style>...</style><div class=\'dashboard-container\'>...</div>"'
  ].join("\n");
}

function genCss(c){
  const mainH=c.canvas.height-c.header.height, mainW=c.canvas.width-c.sidebar.width;
  const contentH=mainH-c.content.kpi_height-c.content.kpi_gap-c.content.padding*2;
  const t=c.theme, ty=c.typography, p=c.palette.ramp;
  return `:root{--bg-page:${t.bg_page};--bg-card:${t.bg_card};--border:${t.border};--text-primary:${t.text_primary};--text-secondary:${t.text_secondary};--accent:${t.accent};--radius:${t.radius};--radius-lg:${t.radius_lg};--font-family:${ty.font_family};--font-weight:${ty.font_weight};--font-size-base:${Math.trunc(ty.font_size_base)}px;--font-size-heading:${Math.trunc(ty.font_size_heading)}px;--palette-base:${c.palette.base};--palette-1:${p[0]};--palette-2:${p[1]};--palette-3:${p[2]};--palette-4:${p[3]};--palette-5:${p[4]}}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:var(--font-family);font-weight:var(--font-weight);font-size:var(--font-size-base);background:var(--bg-page);color:var(--text-primary)}
.dashboard-container{position:relative;width:${c.canvas.width}px;height:${c.canvas.height}px;background:var(--bg-page);overflow:hidden}
.header{position:absolute;top:0;left:0;width:${c.canvas.width}px;height:${c.header.height}px;background:var(--bg-card);border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;padding:0 ${c.header.padding}px;z-index:100}
.header-logo{width:${c.header.logo_width}px;height:${c.header.logo_height}px;background:linear-gradient(135deg,var(--accent),#00796B);border-radius:var(--radius);display:flex;align-items:center;justify-content:center;color:white;font-weight:600;font-size:14px}
.header-nav{display:flex;gap:12px}
.header-nav-btn{width:36px;height:36px;background:var(--bg-page);border:1px solid var(--border);border-radius:var(--radius);display:flex;align-items:center;justify-content:center;color:var(--text-secondary);font-size:12px}
.header-nav-btn.active{background:var(--accent);border-color:var(--accent);color:white}
.sidebar{position:absolute;top:${c.header.height}px;left:0;width:${c.sidebar.width}px;height:${mainH}px;background:var(--bg-card);border-right:1px solid var(--border);padding:${c.sidebar.padding}px;overflow-y:auto}
.sidebar-section{margin-bottom:20px}
.sidebar-section-title{font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:12px}
.sidebar-nav-item{display:flex;align-items:center;gap:12px;padding:10px 12px;border-radius:var(--radius);color:var(--text-primary);font-size:14px;cursor:pointer;margin-bottom:4px}
.sidebar-nav-item:hover{background:var(--bg-page)}
.sidebar-nav-item.active{background:rgba(0,151,167,0.1);color:var(--accent);font-weight:500}
.sidebar-nav-icon{width:20px;height:20px;background:var(--bg-page);border-radius:4px;display:flex;align-items:center;justify-content:center;font-size:10px;color:var(--text-secondary)}
.sidebar-nav-item.active .sidebar-nav-icon{background:var(--accent);color:white}
.main-content{position:absolute;top:${c.header.height}px;left:${c.sidebar.width}px;width:${mainW}px;height:${mainH}px;padding:${c.content.padding}px;overflow:hidden}
.kpi-container{display:flex;gap:${c.content.kpi_gap}px;margin-bottom:${c.content.kpi_gap}px;height:${c.content.kpi_height}px}
.kpi-card{flex:1;background:var(--bg-card);border:1px solid var(--border);border-left:3px solid var(--palette-3);border-radius:var(--radius-lg);padding:16px;display:flex;flex-direction:column;justify-content:center;position:relative}
.kpi-swatches{position:absolute;bottom:8px;right:10px;display:flex;gap:3px;opacity:0.7}
.kpi-swatch{width:8px;height:8px;border-radius:2px}
.kpi-label{font-size:12px;color:var(--text-secondary);margin-bottom:4px}
.kpi-value{font-size:calc(var(--font-size-heading) * 1.5);font-weight:700;color:var(--text-primary)}
.kpi-change{font-size:12px;margin-top:4px}
.kpi-change.positive{color:#10B981}
.kpi-change.negative{color:#EF4444}
.content-grid{position:relative;height:${contentH}px}
.grid-card{background:var(--bg-card);border:1px solid var(--border);border-radius:var(--radius-lg);padding:16px;display:flex;flex-direction:column;position:absolute}
.grid-card-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}
.grid-card-title{font-size:var(--font-size-heading);font-weight:600;color:var(--text-primary)}
.grid-card-content{flex:1;background:var(--bg-page);border-radius:var(--radius);display:flex;align-items:center;justify-content:center;color:var(--text-secondary);font-size:12px}
.kpi-card,.grid-card,.header-logo,.sidebar-nav-item,.header-nav-btn{position:relative}`;
}
function genPbiLayoutHtml(c){
  const mainW=c.canvas.width-c.sidebar.width;
  const totalAvail=mainW-c.content.padding*2;
  const kpiW=calcPx(totalAvail,c.content.kpi_gap,c.content.kpi_count);
  let kpis="";
  for(let i=1;i<=c.content.kpi_count;i++){kpis+=`<div class="kpi-card" style="flex:none;width:${Math.round(kpiW)}px;"></div>`;}
  // uniform grid: grid_rows × grid_cols
  const contentH=(c.canvas.height-c.header.height)-c.content.kpi_height-c.content.kpi_gap-c.content.padding*2;
  const rows=c.content.grid_rows, cols=c.content.grid_cols;
  const rh=calcPx(contentH,c.content.grid_gap,rows);
  const cw=calcPx(mainW-c.content.padding*2,c.content.grid_gap,cols);
  let cards="",yOff=0;
  for(let r=0;r<rows;r++){let xOff=0;for(let col=0;col<cols;col++){cards+=`<div class="grid-card" style="position:absolute;left:${Math.round(xOff)}px;top:${Math.round(yOff)}px;width:${Math.round(cw)}px;height:${Math.round(rh)}px;"><div class="grid-card-content"></div></div>`;xOff+=cw+c.content.grid_gap;}yOff+=rh+c.content.grid_gap;}
  const navBtns=Array(c.header.nav_button_count).fill('<div class="header-nav-btn"></div>').join("");
  const navItems=Array(c.sidebar.nav_item_count).fill('<div class="sidebar-nav-item"><div class="sidebar-nav-icon"></div><span></span></div>').join("");
  const header=`<div class="header"><div class="header-logo"></div><div class="header-nav">${navBtns}</div></div>`;
  const sidebar=`<div class="sidebar"><div class="sidebar-section"><div class="sidebar-section-title">Navigation</div>${navItems}</div></div>`;
  const content=`<div class="main-content"><div class="kpi-container">${kpis}</div><div class="content-grid">${cards}</div></div>`;
  return `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Dashboard Layout</title><style>${genCss(c)}</style></head><body><div class="dashboard-container">${header}${sidebar}${content}</div></body></html>`;
}

function genShiny(c){
  const radius=c.theme.radius.replace(/px$/,"");
  const theme=[
    "theme <- bs_theme(",
    `  bg      = '${c.theme.bg_page}',`,
    `  fg      = '${c.theme.text_primary}',`,
    `  primary = '${c.theme.accent}'`,
    ") |> bs_add_variables(",
    `  'card-bg'      = '${c.theme.bg_card}',`,
    `  'border-color' = '${c.theme.border}',`,
    `  'border-radius' = '${radius}px'`,
    ")"
  ];
  const lw=c.header.logo_width;
  const title=[
    "  title = div(",
    "    img(src = 'logo.png', height = '40px', alt = 'Logo',",
    `        style = 'margin-right:12px; display:${lw>0?"inline-block":"none"};'),`,
    "    'My Dashboard'",
    "  ),"
  ];
  const nav=[];for(let i=1;i<=c.sidebar.nav_item_count;i++)nav.push(`    nav_item(actionLink('nav_${i}', 'Menu Item ${i}')),`);
  const sidebar=["  sidebar = sidebar(",`    width = ${c.sidebar.width},`,"    h4('Navigation'),",...nav,"  ),"];
  // KPI row
  let kpiLines=[];
  if(c.content.kpi_count>0){
    const cwk=props12(c.content.kpi_count);
    const vbox=[];for(let i=1;i<=c.content.kpi_count;i++)vbox.push(`    value_box(title = 'KPI ${i}', value = '...', showcase = bsicons::bs_icon('graph-up'))`);
    kpiLines=["  # KPI Row","  layout_columns(","    fill = FALSE,",`    col_widths = c(${cwk.join(", ")}),`,vbox.join(",\n"),"  ),"];
  }
  // uniform grid
  const cols=c.content.grid_cols, rows=c.content.grid_rows, nCards=rows*cols;
  const cwg=props12(cols);
  const cards=[];for(let i=1;i<=nCards;i++)cards.push(`    card(card_header('Chart ${i}'), card_body(plotOutput('plot_${i}')))`);
  const grid=["  # Main Grid (Uniform)","  layout_columns(",`    col_widths = c(${cwg.join(", ")}),`,"    fill = TRUE,",cards.join(",\n"),"  )"];
  const srv=[];for(let i=1;i<=nCards;i++)srv.push(`  output$plot_${i} <- renderPlot({ plot(cars, main = 'Chart ${i}') })`);
  const server=["server <- function(input, output, session) {",...srv,"}"];
  let code=[
    "# Generated by REA Theme Studio",
    "# Copy-paste into a new app.R file and run",
    "","library(shiny)","library(bslib)","library(bsicons)","",
    "# ── Theme ──",...theme,"",
    "# ── UI ──","ui <- page_sidebar(",...title,"  theme = theme,",...sidebar,""
  ];
  if(kpiLines.length)code=code.concat(kpiLines,[""]);
  code=code.concat(grid,[")"]);
  code=code.concat(["","# ── Server ──",...server,"","shinyApp(ui, server)"]);
  return code.join("\n");
}

function scssNote(c){
  return [
    "<!-- theme.scss ---------------------------------------------------",
    "/*-- scss:defaults --*/",
    `$primary:                 ${c.theme.accent};`,
    `$body-bg:                 ${c.theme.bg_page};`,
    `$card-bg:                 ${c.theme.bg_card};`,
    `$border-color:            ${c.theme.border};`,
    `$body-color:              ${c.theme.text_primary};`,
    `$font-family-sans-serif:  ${c.typography.font_family};`,
    "/*-- scss:rules --*/",
    ".card { border-radius: 10px; }",
    "--------------------------------------------------------------- -->"
  ].join("\n");
}
function genQuartoDash(c){
  const acc=c.theme.accent, fs=c.typography.font_size_base, ramp=c.palette.ramp;
  const yaml=["---",'title: "REA Dashboard"',"format:","  dashboard:","    theme: [cosmo, theme.scss]","    nav-buttons: []","    expandable: true","execute:","  echo: false","  warning: false","---",""].join("\n");
  const setup=["```{r setup}","#| label: setup","#| include: false","library(bslib)","library(ggplot2)","```",""].join("\n");
  let vbox="";
  if(c.content.kpi_count>0){
    const boxes=[];for(let i=1;i<=c.content.kpi_count;i++){const col=rampAt(ramp,i,acc);boxes.push(`::: {.valuebox icon="graph-up" color="${col}"}\nKPI ${i}\n\n\`—\`\n:::`);}
    vbox=['## Row {height="20%"}',"",boxes.join("\n\n"),""].join("\n");
  }
  let chart=[],idx=1;
  for(let r=0;r<c.content.grid_rows;r++){chart.push("## Row","");for(let cc=0;cc<c.content.grid_cols;cc++){chart.push(`### Chart ${idx}`,"","```{r}",`#| title: "Chart ${idx}"`,"ggplot(cars, aes(speed, dist)) +",`  geom_point(colour = "${acc}") +`,`  theme_minimal(base_size = ${fs})`,"```","");idx++;}}
  return [yaml,setup,vbox,chart.join("\n"),scssNote(c)].join("\n");
}
function genQuartoHtml(c){
  const acc=c.theme.accent, fs=c.typography.font_size_base, ramp=c.palette.ramp;
  const yaml=["---",'title: "REA Report"',"format:","  html:","    theme: [cosmo, theme.scss]","    page-layout: full","    toc: true","execute:","  echo: false","  warning: false","---",""].join("\n");
  const setup=["```{r setup}","#| label: setup","#| include: false","library(bslib)","library(ggplot2)","```",""].join("\n");
  let kpi="";
  if(c.content.kpi_count>0){
    const colW=Math.max(1,Math.floor(12/c.content.kpi_count));
    const vb=[];for(let i=1;i<=c.content.kpi_count;i++){const col=rampAt(ramp,i,acc);vb.push(`  value_box(\n    title = "KPI ${i}",\n    value = "—",\n    showcase = bsicons::bs_icon("graph-up"),\n    theme = value_box_theme(bg = "${col}")\n  )`);}
    kpi=["```{r kpi-row}","#| label: kpi-row","layout_columns(",`  col_widths = rep(${colW}L, ${c.content.kpi_count}L),`,vb.join(",\n"),")","```",""].join("\n");
  }
  let chart=[],idx=1;const colWc=Math.max(1,Math.floor(12/c.content.grid_cols));
  for(let r=1;r<=c.content.grid_rows;r++){
    const cards=[];for(let cc=0;cc<c.content.grid_cols;cc++){const ci=idx+cc;cards.push(`  card(\n    card_header("Chart ${ci}"),\n    card_body(\n      ggplot(cars, aes(speed, dist)) +\n        geom_point(colour = "${acc}") +\n        theme_minimal(base_size = ${fs})\n    )\n  )`);}
    chart.push(`\`\`\`{r chart-row-${r}}`,`#| label: chart-row-${r}`,"layout_columns(",`  col_widths = rep(${colWc}L, ${c.content.grid_cols}L),`,cards.join(",\n"),")","```","");
    idx+=c.content.grid_cols;
  }
  return [yaml,setup,kpi,chart.join("\n"),scssNote(c)].join("\n");
}
function genFlex(c){
  const acc=c.theme.accent, fs=c.typography.font_size_base, ramp=c.palette.ramp;
  const fontName=c.typography.font_family_name;
  const yaml=["---",'title: "REA Dashboard"',"output:","  flexdashboard::flex_dashboard:","    orientation: rows","    vertical_layout: fill","    theme:",`      bg: "${c.theme.bg_page}"`,`      fg: "${c.theme.text_primary}"`,`      primary: "${acc}"`,`      base_font: !expr bslib::font_google("${fontName}")`,"---",""].join("\n");
  const setup=["```{r setup, include=FALSE}","library(flexdashboard)","library(ggplot2)","library(bslib)","```",""].join("\n");
  let kpi="";
  if(c.content.kpi_count>0){
    const boxes=[];for(let i=1;i<=c.content.kpi_count;i++){const col=rampAt(ramp,i,acc);boxes.push([`### KPI ${i}`,"","```{r}",`valueBox("—", caption = "KPI ${i}",`,`  icon = "fa-chart-line", color = "${col}")`,"```"].join("\n"));}
    kpi=["## Row {data-height=150}","",boxes.join("\n\n"),""].join("\n");
  }
  let chart=[],idx=1;const colW=Math.max(200,Math.floor(600/Math.max(1,c.content.grid_cols)));
  for(let cc=0;cc<c.content.grid_cols;cc++){chart.push(`## Column {data-width=${colW}}`,"");for(let r=0;r<c.content.grid_rows;r++){chart.push(`### Chart ${idx}`,"","```{r}","ggplot(cars, aes(speed, dist)) +",`  geom_point(colour = "${acc}") +`,`  theme_minimal(base_size = ${fs})`,"```","");idx++;}}
  return [yaml,setup,kpi,chart.join("\n")].join("\n");
}

const FABRIC_STATIC = {"vite.config.ts": "import { defineConfig } from \"vite\";\nimport react from \"@vitejs/plugin-react\";\n\nexport default defineConfig({\n  plugins: [react()],\n});\n", "tsconfig.json": "{\n  \"compilerOptions\": {\n    \"target\": \"ES2020\",\n    \"useDefineForClassFields\": true,\n    \"lib\": [\"ES2020\", \"DOM\", \"DOM.Iterable\"],\n    \"module\": \"ESNext\",\n    \"skipLibCheck\": true,\n    \"moduleResolution\": \"bundler\",\n    \"allowImportingTsExtensions\": true,\n    \"resolveJsonModule\": true,\n    \"isolatedModules\": true,\n    \"noEmit\": true,\n    \"jsx\": \"react-jsx\",\n    \"strict\": true,\n    \"noUnusedLocals\": true,\n    \"noUnusedParameters\": true,\n    \"noFallthroughCasesInSwitch\": true,\n    \"experimentalDecorators\": true,\n    \"emitDecoratorMetadata\": true\n  },\n  \"include\": [\"src\"]\n}\n", "postcss.config.js": "export default {\n  plugins: {\n    tailwindcss: {},\n    autoprefixer: {},\n  },\n};\n", "tailwind.config.js": "export default {\n  content: [\n    \"./index.html\",\n    \"./src/**/*.{ts,tsx}\",\n  ],\n  theme: {\n    extend: {\n      colors: {\n        background: \"var(--background)\",\n        foreground: \"var(--foreground)\",\n        card: \"var(--card)\",\n        \"card-foreground\": \"var(--card-foreground)\",\n        primary: \"var(--primary)\",\n        \"primary-foreground\": \"var(--primary-foreground)\",\n        secondary: \"var(--secondary)\",\n        \"secondary-foreground\": \"var(--secondary-foreground)\",\n        muted: \"var(--muted)\",\n        \"muted-foreground\": \"var(--muted-foreground)\",\n        accent: \"var(--accent)\",\n        \"accent-foreground\": \"var(--accent-foreground)\",\n        border: \"var(--border)\",\n        ring: \"var(--ring)\",\n        success: \"var(--success)\",\n        warning: \"var(--warning)\",\n        danger: \"var(--danger)\",\n      },\n      borderRadius: {\n        sm: \"var(--radius-sm)\",\n        md: \"var(--radius-md)\",\n        lg: \"var(--radius-lg)\",\n        xl: \"var(--radius-xl)\",\n        full: \"var(--radius-full)\",\n      },\n      fontFamily: {\n        sans: \"var(--font-sans)\",\n        mono: \"var(--font-mono)\",\n      },\n    },\n  },\n  plugins: [],\n};\n", "rayfin/data/ThemeMetric.ts": "import { dateTime, entity, number, text, uuid } from \"@microsoft/rayfin\";\n\n@entity()\nexport class ThemeMetric {\n  @uuid()\n  id!: string;\n\n  @text()\n  label!: string;\n\n  @text()\n  category!: string;\n\n  @number()\n  value!: number;\n\n  @text({ optional: true })\n  unit?: string;\n\n  @text({ optional: true })\n  colorToken?: string;\n\n  @dateTime()\n  capturedAt!: Date;\n}\n", "rayfin/data/ThemeExport.ts": "import { dateTime, entity, text, uuid } from \"@microsoft/rayfin\";\n\n@entity()\nexport class ThemeExport {\n  @uuid()\n  id!: string;\n\n  @text()\n  name!: string;\n\n  @text()\n  exportType!: string;\n\n  @text({ optional: true })\n  description?: string;\n\n  @text({ optional: true })\n  themeJson?: string;\n\n  @dateTime()\n  createdAt!: Date;\n}\n", "rayfin/data/schema.ts": "import { ThemeExport } from \"./ThemeExport\";\nimport { ThemeMetric } from \"./ThemeMetric\";\n\nexport const schema = {\n  entities: [\n    ThemeExport,\n    ThemeMetric,\n  ],\n};\n", "src/types/theme.ts": "export type ThemeMetric = {\n  id: string;\n  label: string;\n  category: string;\n  value: number;\n  unit?: string;\n  colorToken?: string;\n  capturedAt: string;\n};\n\nexport type FabricThemeExport = {\n  name: string;\n  description?: string;\n  colors: {\n    background: string;\n    foreground: string;\n    card: string;\n    cardForeground: string;\n    primary: string;\n    primaryForeground: string;\n    secondary: string;\n    secondaryForeground: string;\n    muted: string;\n    mutedForeground: string;\n    accent: string;\n    accentForeground: string;\n    border: string;\n    ring: string;\n    success?: string;\n    warning?: string;\n    danger?: string;\n  };\n  radius: {\n    sm: string;\n    md: string;\n    lg: string;\n    xl: string;\n    full: string;\n  };\n  typography: {\n    fontSans: string;\n    fontMono?: string;\n    headingWeight?: string | number;\n    bodyWeight?: string | number;\n  };\n};\n", "src/data/sampleMetrics.ts": "import type { ThemeMetric } from \"../types/theme\";\n\nexport const sampleMetrics: ThemeMetric[] = [\n  {\n    id: \"theme-score\",\n    label: \"Theme Readiness\",\n    category: \"Quality\",\n    value: 92,\n    unit: \"%\",\n    colorToken: \"primary\",\n    capturedAt: new Date().toISOString(),\n  },\n  {\n    id: \"contrast-score\",\n    label: \"Contrast Coverage\",\n    category: \"Accessibility\",\n    value: 88,\n    unit: \"%\",\n    colorToken: \"success\",\n    capturedAt: new Date().toISOString(),\n  },\n  {\n    id: \"export-count\",\n    label: \"Export Options\",\n    category: \"Studio\",\n    value: 10,\n    unit: \"\",\n    colorToken: \"accent\",\n    capturedAt: new Date().toISOString(),\n  },\n  {\n    id: \"token-count\",\n    label: \"Theme Tokens\",\n    category: \"Design System\",\n    value: 34,\n    unit: \"\",\n    colorToken: \"warning\",\n    capturedAt: new Date().toISOString(),\n  },\n];\n", "src/hooks/useThemeMetrics.ts": "import { useEffect, useState } from \"react\";\nimport { sampleMetrics } from \"../data/sampleMetrics\";\nimport type { ThemeMetric } from \"../types/theme\";\n\nexport function useThemeMetrics() {\n  const [metrics, setMetrics] = useState<ThemeMetric[]>([]);\n  const [loading, setLoading] = useState(true);\n  const [error, setError] = useState<string | null>(null);\n\n  useEffect(() => {\n    try {\n      setLoading(true);\n\n      // Replace this sample data with a generated Rayfin/Fabric client query\n      // when the backend schema is deployed.\n      setMetrics(sampleMetrics);\n    } catch {\n      setError(\"Unable to load theme metrics.\");\n    } finally {\n      setLoading(false);\n    }\n  }, []);\n\n  return { metrics, loading, error };\n}\n", "src/lib/formatters.ts": "export function formatNumber(value: number) {\n  return new Intl.NumberFormat(\"en-US\").format(value);\n}\n\nexport function formatPercent(value: number) {\n  return new Intl.NumberFormat(\"en-US\", {\n    style: \"percent\",\n    maximumFractionDigits: 0,\n  }).format(value / 100);\n}\n", "src/components/KpiCard.tsx": "import type { ReactNode } from \"react\";\n\nexport type KpiCardProps = {\n  label: string;\n  value: string | number;\n  eyebrow?: string;\n  icon?: ReactNode;\n  tone?: \"primary\" | \"success\" | \"warning\" | \"danger\" | \"neutral\";\n};\n\nconst toneClasses: Record<NonNullable<KpiCardProps[\"tone\"]>, string> = {\n  primary: \"bg-primary/10 text-primary\",\n  success: \"bg-success/10 text-success\",\n  warning: \"bg-warning/10 text-warning\",\n  danger: \"bg-danger/10 text-danger\",\n  neutral: \"bg-muted text-muted-foreground\",\n};\n\nexport function KpiCard({ label, value, eyebrow, icon, tone = \"primary\" }: KpiCardProps) {\n  return (\n    <article className=\"rounded-xl border border-border bg-card p-5 text-card-foreground shadow-sm\">\n      <div className=\"flex items-start justify-between gap-4\">\n        <div>\n          {eyebrow ? <p className=\"text-sm font-medium text-muted-foreground\">{eyebrow}</p> : null}\n          <h3 className=\"mt-2 text-base font-semibold\">{label}</h3>\n        </div>\n        {icon ? (\n          <div className={`rounded-lg p-2 ${toneClasses[tone]}`}>\n            {icon}\n          </div>\n        ) : null}\n      </div>\n      <p className=\"mt-5 text-4xl font-bold tracking-tight\">{value}</p>\n    </article>\n  );\n}\n", "src/components/ThemeMetricBarChart.tsx": "import {\n  Bar,\n  BarChart,\n  CartesianGrid,\n  ResponsiveContainer,\n  Tooltip,\n  XAxis,\n  YAxis,\n} from \"recharts\";\nimport type { ThemeMetric } from \"../types/theme\";\n\nexport type ThemeMetricBarChartProps = {\n  data: ThemeMetric[];\n};\n\nexport function ThemeMetricBarChart({ data }: ThemeMetricBarChartProps) {\n  return (\n    <section className=\"rounded-xl border border-border bg-card p-6 text-card-foreground shadow-sm\">\n      <div className=\"mb-5\">\n        <h2 className=\"text-lg font-semibold\">Theme Studio Metrics</h2>\n        <p className=\"text-sm text-muted-foreground\">\n          Sample visual scaffold for a Fabric App frontend export.\n        </p>\n      </div>\n\n      <div className=\"h-80\">\n        <ResponsiveContainer width=\"100%\" height=\"100%\">\n          <BarChart data={data}>\n            <CartesianGrid vertical={false} strokeDasharray=\"3 3\" />\n            <XAxis dataKey=\"label\" tickLine={false} axisLine={false} />\n            <YAxis tickLine={false} axisLine={false} />\n            <Tooltip />\n            <Bar dataKey=\"value\" fill=\"var(--primary)\" radius={[8, 8, 0, 0]} />\n          </BarChart>\n        </ResponsiveContainer>\n      </div>\n    </section>\n  );\n}\n", "src/components/ThemePreviewPanel.tsx": "import { fabricTheme } from \"../lib/theme\";\n\nexport function ThemePreviewPanel() {\n  const swatches = Object.entries(fabricTheme.colors);\n\n  return (\n    <section className=\"rounded-xl border border-border bg-card p-6 text-card-foreground shadow-sm\">\n      <div className=\"mb-5\">\n        <h2 className=\"text-lg font-semibold\">Theme Preview</h2>\n        <p className=\"text-sm text-muted-foreground\">\n          Tokens exported from REA Theme Studio into a Fabric App sample.\n        </p>\n      </div>\n\n      <div className=\"grid gap-3 sm:grid-cols-2 lg:grid-cols-3\">\n        {swatches.map(([name, value]) => (\n          <div key={name} className=\"rounded-lg border border-border p-3\">\n            <div\n              className=\"mb-3 h-12 rounded-md border border-border\"\n              style={{ backgroundColor: value }}\n            />\n            <p className=\"text-sm font-medium\">{name}</p>\n            <p className=\"font-mono text-xs text-muted-foreground\">{value}</p>\n          </div>\n        ))}\n      </div>\n    </section>\n  );\n}\n", "src/components/AppShell.tsx": "import type { ReactNode } from \"react\";\n\nexport type AppShellProps = {\n  children: ReactNode;\n};\n\nexport function AppShell({ children }: AppShellProps) {\n  return (\n    <main className=\"min-h-screen bg-background text-foreground\">\n      <div className=\"mx-auto flex max-w-7xl flex-col gap-6 px-6 py-8\">\n        <header className=\"rounded-xl border border-border bg-card p-6 text-card-foreground shadow-sm\">\n          <p className=\"text-sm font-semibold text-primary\">REA Theme Studio Export</p>\n          <h1 className=\"mt-2 text-3xl font-bold tracking-tight\">\n            Microsoft Fabric App Sample\n          </h1>\n          <p className=\"mt-2 max-w-3xl text-sm text-muted-foreground\">\n            This sample demonstrates how a REA theme can be exported into a React + Tailwind frontend for Microsoft Fabric Apps.\n          </p>\n        </header>\n        {children}\n      </div>\n    </main>\n  );\n}\n", "src/components/ExportOptionCard.tsx": "export function ExportOptionCard() {\n  return (\n    <section className=\"rounded-xl border border-border bg-card p-6 text-card-foreground shadow-sm\">\n      <h2 className=\"text-lg font-semibold\">Export Integration</h2>\n      <p className=\"mt-2 text-sm text-muted-foreground\">\n        Add this sample as an export option inside REA Theme Studio so designers and developers can generate a themed Fabric App frontend scaffold.\n      </p>\n      <div className=\"mt-4 rounded-lg bg-muted p-4 text-sm text-muted-foreground\">\n        Suggested label: <span className=\"font-semibold text-foreground\">Microsoft Fabric App Sample</span>\n      </div>\n    </section>\n  );\n}\n", "src/components/LoadingState.tsx": "export function LoadingState() {\n  return (\n    <div className=\"rounded-xl border border-border bg-card p-6 text-card-foreground shadow-sm\">\n      <p className=\"text-sm text-muted-foreground\">Loading theme metrics...</p>\n    </div>\n  );\n}\n", "src/components/EmptyState.tsx": "export function EmptyState() {\n  return (\n    <div className=\"rounded-xl border border-border bg-card p-6 text-card-foreground shadow-sm\">\n      <h2 className=\"text-lg font-semibold\">No metrics available</h2>\n      <p className=\"mt-2 text-sm text-muted-foreground\">\n        Add sample data or connect this app to the generated Fabric backend.\n      </p>\n    </div>\n  );\n}\n", "src/App.tsx": "import { Activity, Boxes, Palette, ShieldCheck } from \"lucide-react\";\nimport { AppShell } from \"./components/AppShell\";\nimport { EmptyState } from \"./components/EmptyState\";\nimport { ExportOptionCard } from \"./components/ExportOptionCard\";\nimport { KpiCard } from \"./components/KpiCard\";\nimport { LoadingState } from \"./components/LoadingState\";\nimport { ThemeMetricBarChart } from \"./components/ThemeMetricBarChart\";\nimport { ThemePreviewPanel } from \"./components/ThemePreviewPanel\";\nimport { useThemeMetrics } from \"./hooks/useThemeMetrics\";\n\nexport default function App() {\n  const { metrics, loading, error } = useThemeMetrics();\n\n  if (loading) {\n    return (\n      <AppShell>\n        <LoadingState />\n      </AppShell>\n    );\n  }\n\n  if (error) {\n    return (\n      <AppShell>\n        <div className=\"rounded-xl border border-danger/30 bg-danger/10 p-6 text-danger\">\n          {error}\n        </div>\n      </AppShell>\n    );\n  }\n\n  if (!metrics.length) {\n    return (\n      <AppShell>\n        <EmptyState />\n      </AppShell>\n    );\n  }\n\n  const [readiness, contrast, exports, tokens] = metrics;\n\n  return (\n    <AppShell>\n      <section className=\"grid gap-4 md:grid-cols-2 xl:grid-cols-4\">\n        <KpiCard\n          label={readiness.label}\n          value={`${readiness.value}${readiness.unit ?? \"\"}`}\n          eyebrow={readiness.category}\n          icon={<Activity className=\"h-5 w-5\" />}\n          tone=\"primary\"\n        />\n        <KpiCard\n          label={contrast.label}\n          value={`${contrast.value}${contrast.unit ?? \"\"}`}\n          eyebrow={contrast.category}\n          icon={<ShieldCheck className=\"h-5 w-5\" />}\n          tone=\"success\"\n        />\n        <KpiCard\n          label={exports.label}\n          value={exports.value}\n          eyebrow={exports.category}\n          icon={<Boxes className=\"h-5 w-5\" />}\n          tone=\"warning\"\n        />\n        <KpiCard\n          label={tokens.label}\n          value={tokens.value}\n          eyebrow={tokens.category}\n          icon={<Palette className=\"h-5 w-5\" />}\n          tone=\"neutral\"\n        />\n      </section>\n\n      <div className=\"grid gap-6 xl:grid-cols-[1.4fr_1fr]\">\n        <ThemeMetricBarChart data={metrics} />\n        <ExportOptionCard />\n      </div>\n\n      <ThemePreviewPanel />\n    </AppShell>\n  );\n}\n", "src/main.tsx": "import React from \"react\";\nimport ReactDOM from \"react-dom/client\";\nimport App from \"./App\";\nimport \"./global.css\";\n\nReactDOM.createRoot(document.getElementById(\"root\")!).render(\n  <React.StrictMode>\n    <App />\n  </React.StrictMode>\n);\n", "package.json": "{\n  \"name\": \"rea-fabric-app-sample\",\n  \"private\": true,\n  \"version\": \"0.1.0\",\n  \"type\": \"module\",\n  \"scripts\": {\n    \"dev\": \"vite --host 0.0.0.0\",\n    \"build\": \"tsc -b && vite build\",\n    \"preview\": \"vite preview\"\n  },\n  \"dependencies\": {\n    \"react\": \"^18.3.1\",\n    \"react-dom\": \"^18.3.1\",\n    \"lucide-react\": \"^0.456.0\",\n    \"recharts\": \"^2.13.3\"\n  },\n  \"devDependencies\": {\n    \"@types/react\": \"^18.3.12\",\n    \"@types/react-dom\": \"^18.3.1\",\n    \"@vitejs/plugin-react\": \"^4.3.4\",\n    \"vite\": \"^5.4.11\",\n    \"typescript\": \"^5.6.3\",\n    \"tailwindcss\": \"^3.4.15\",\n    \"postcss\": \"^8.4.49\",\n    \"autoprefixer\": \"^10.4.20\"\n  }\n}\n", "rayfin/rayfin.yml": "name: rea-fabric-app-sample\nservices:\n  frontend:\n    path: .\n", "rayfin/data/.gitkeep": ""};

/* Map the live studio theme → the Fabric token shape (FabricThemeExport). */
function fabricThemeFromState(){
  const s=surf(); const acc=accentHex(); const f=fontDef();
  const onAcc = T.contrast(acc,"#FFFFFF") >= T.contrast(acc,s.text) ? "#FFFFFF" : s.text;
  return {
    name:`REA ${sourceName()} — ${state.type}`,
    description:"Generated from REA Theme Studio.",
    colors:{
      background:s.canvas, foreground:s.text,
      card:s.surface, cardForeground:s.text,
      primary:acc, primaryForeground:onAcc,
      secondary:s.sunken, secondaryForeground:s.text,
      muted:s.sunken, mutedForeground:s.text2,
      accent:T.accentTint(acc), accentForeground:T.accentHover(acc),
      border:s.border, ring:acc,
      success:(GCPS_BASE.green||"#5E8C31").toUpperCase(),
      warning:(GCPS_BASE.gold||"#C49A22").toUpperCase(),
      danger:"#B42318"
    },
    radius:{ sm:"0.375rem", md:"0.625rem", lg:"0.875rem", xl:"1rem", full:"9999px" },
    typography:{
      fontSans:f.stack,
      fontMono:"ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace",
      headingWeight:state.weight, bodyWeight:400
    }
  };
}

function fabricGlobalCss(tk){
  const c=tk.colors,r=tk.radius,t=tk.typography;
  return `@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --background: ${c.background};
  --foreground: ${c.foreground};
  --card: ${c.card};
  --card-foreground: ${c.cardForeground};
  --primary: ${c.primary};
  --primary-foreground: ${c.primaryForeground};
  --secondary: ${c.secondary};
  --secondary-foreground: ${c.secondaryForeground};
  --muted: ${c.muted};
  --muted-foreground: ${c.mutedForeground};
  --accent: ${c.accent};
  --accent-foreground: ${c.accentForeground};
  --border: ${c.border};
  --ring: ${c.ring};
  --success: ${c.success};
  --warning: ${c.warning};
  --danger: ${c.danger};
  --radius-sm: ${r.sm};
  --radius-md: ${r.md};
  --radius-lg: ${r.lg};
  --radius-xl: ${r.xl};
  --radius-full: ${r.full};
  --font-sans: ${t.fontSans};
  --font-mono: ${t.fontMono};
}

* {
  box-sizing: border-box;
}

html {
  background: var(--background);
}

body {
  margin: 0;
  background: var(--background);
  color: var(--foreground);
  font-family: var(--font-sans);
  font-weight: ${t.bodyWeight};
}

h1, h2, h3, h4 {
  font-weight: ${t.headingWeight};
}

button,
input,
select,
textarea {
  font: inherit;
}

:focus-visible {
  outline: 2px solid var(--ring);
  outline-offset: 2px;
}
`;
}

function fabricThemeLib(tk){
  return `import type { FabricThemeExport } from "../types/theme";

export const fabricTheme: FabricThemeExport = ${JSON.stringify(tk,null,2)};
`;
}

function fabricIndexHtml(tk){
  return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${esc(tk.name)} · Fabric App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
`;
}

function fabricReadme(tk){
  return `# REA Fabric App Sample

This project was generated from **REA Theme Studio** as a Microsoft Fabric App
frontend sample, themed with: **${tk.name}**.

## What is included

- React + TypeScript frontend (Vite)
- Tailwind CSS theme tokens generated from REA Theme Studio
- Sample visual dashboard (KPI cards, bar chart, theme preview)
- Rayfin / Fabric Apps data models
- Entity registration in \`rayfin/data/schema.ts\`

## Run locally

\`\`\`bash
npm install
npm run dev
\`\`\`

## Fabric Apps / Rayfin workflow

After configuring your Fabric workspace and Rayfin project settings:

\`\`\`bash
npx rayfin up db apply
npx rayfin up
npx rayfin up status
\`\`\`

## Data models

Generated models live in:

\`\`\`txt
rayfin/data/ThemeMetric.ts
rayfin/data/ThemeExport.ts
rayfin/data/schema.ts
\`\`\`

Every entity must be registered in \`rayfin/data/schema.ts\`.

## Next steps

1. Replace sample metrics in \`src/data/sampleMetrics.ts\` with generated client/API data.
2. Add real operational app entities in \`rayfin/data/\`.
3. Keep nullable fields marked with \`{ optional: true }\`.
4. Avoid direct many-to-many relationships; use explicit join entities.
5. Deploy with \`npx rayfin up\`.
`;
}

/* Assemble the full file set: live-theme dynamic files + static templates. */
function generateFabricAppFiles(){
  const tk=fabricThemeFromState();
  const files=[
    {path:"README.md", content:fabricReadme(tk)},
    {path:"index.html", content:fabricIndexHtml(tk)},
    {path:"src/global.css", content:fabricGlobalCss(tk)},
    {path:"src/lib/theme.ts", content:fabricThemeLib(tk)}
  ];
  Object.keys(FABRIC_STATIC).forEach(p=>files.push({path:p, content:FABRIC_STATIC[p]}));
  files.sort((a,b)=>a.path<b.path?-1:1);
  return files;
}

/* ---------- minimal store-only ZIP writer (no deps, no CDN) ---------- */
const CRC_TABLE=(()=>{const t=new Uint32Array(256);for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=(c&1)?(0xEDB88320^(c>>>1)):(c>>>1);t[n]=c>>>0;}return t;})();
function crc32(bytes){let c=0xFFFFFFFF;for(let i=0;i<bytes.length;i++)c=CRC_TABLE[(c^bytes[i])&0xFF]^(c>>>8);return (c^0xFFFFFFFF)>>>0;}
function strBytes(s){return new TextEncoder().encode(s);}
function u16(n){return [n&0xFF,(n>>>8)&0xFF];}
function u32(n){return [n&0xFF,(n>>>8)&0xFF,(n>>>16)&0xFF,(n>>>24)&0xFF];}
function zipFiles(files){
  // Deterministic DOS timestamp: 1980-01-01 00:00:00
  const dosTime=0, dosDate=(0<<9)|(1<<5)|1;
  const chunks=[]; const central=[]; let offset=0;
  files.forEach(f=>{
    const nameB=strBytes(f.path); const dataB=strBytes(f.content); const crc=crc32(dataB);
    const local=[].concat(
      u32(0x04034b50),u16(20),u16(0),u16(0),u16(dosTime),u16(dosDate),
      u32(crc),u32(dataB.length),u32(dataB.length),u16(nameB.length),u16(0)
    );
    const localHeader=new Uint8Array(local);
    chunks.push(localHeader,nameB,dataB);
    const cen=[].concat(
      u32(0x02014b50),u16(20),u16(20),u16(0),u16(0),u16(dosTime),u16(dosDate),
      u32(crc),u32(dataB.length),u32(dataB.length),u16(nameB.length),u16(0),u16(0),
      u16(0),u16(0),u32(0),u32(offset)
    );
    central.push(new Uint8Array(cen),nameB);
    offset+=localHeader.length+nameB.length+dataB.length;
  });
  let cenSize=0; central.forEach(c=>cenSize+=c.length);
  const cenOffset=offset;
  const end=new Uint8Array([].concat(
    u32(0x06054b50),u16(0),u16(0),u16(files.length),u16(files.length),
    u32(cenSize),u32(cenOffset),u16(0)
  ));
  return new Blob([...chunks,...central,end],{type:"application/zip"});
}

/* Readable preview for the <pre>: file tree + the two key themed files. */
function fabricPreview(){
  const files=generateFabricAppFiles();
  const tree=files.map(f=>"  "+f.path).join("\n");
  const css=files.find(f=>f.path==="src/global.css").content;
  const themeTs=files.find(f=>f.path==="src/lib/theme.ts").content;
  return `Microsoft Fabric App Sample — ${files.length} files\n`+
    `Download the .zip, then:  npm install  ·  npm run dev  ·  npx rayfin up\n`+
    `\n# Project tree\n${tree}\n`+
    `\n# src/global.css  (theme tokens from the current REA theme)\n${css}`+
    `\n# src/lib/theme.ts\n${themeTs}`;
}

// format registry: id -> {label, file, gen}
const CODE_FORMATS={
  dax:    {file:"rea_layout.dax",   gen:genDax},
  pbihtml:{file:"rea_layout.html",  gen:genPbiLayoutHtml},
  shiny:  {file:"app.R",             gen:genShiny},
  qdash:  {file:"dashboard.qmd",     gen:genQuartoDash},
  qhtml:  {file:"report.qmd",        gen:genQuartoHtml},
  flex:   {file:"flexdashboard.Rmd", gen:genFlex}
};

/* ---------- TAB: export ---------- */
function slug(){return `${sourceName().toLowerCase().replace(/[^a-z0-9]+/g,'_').replace(/^_|_$/g,'')}_${state.type}`;}
function buildExport(){
  // Microsoft Fabric App sample — themed React+Tailwind scaffold, downloaded as a .zip
  if(state.exp==="fabric"){
    $("#expFile").textContent="rea-fabric-app-sample.zip";
    return fabricPreview();
  }
  // Ported Shiny generators (DAX, Power BI layout, Shiny, Quarto, flexdashboard)
  if(CODE_FORMATS[state.exp]){
    const fmt=CODE_FORMATS[state.exp];
    $("#expFile").textContent=fmt.file;
    return fmt.gen(codeConfig());
  }
  const s=surf();const acc=accentHex();const f=fontDef();const sc=T.typeScale(state.baseSize,state.ratio);
  const pal=currentPalette();const hexes=pal.map(p=>p.hex);const sg=slug();
  const gradient=["sequential","continuous","tints","diverging"].includes(state.type);
  const hasSem=pal.some(p=>p.sem);
  if(state.exp==="css"){
    $("#expFile").textContent="rea_theme.css";
    return `:root{\n`+
`  /* surfaces */\n  --canvas:${s.canvas};\n  --surface:${s.surface};\n  --sunken:${s.sunken};\n  --border:${s.border};\n  --border-strong:${s.borderStrong};\n`+
`  /* text */\n  --text:${s.text};\n  --text-2:${s.text2};\n  --text-3:${s.text3};\n`+
`  /* accent */\n  --accent:${acc};\n  --accent-hover:${T.accentHover(acc)};\n  --accent-tint:${T.accentTint(acc)};\n`+
`  /* type */\n  --font-sans:${f.stack};\n  --fs-display:${sc.display}px; --fs-h1:${sc.h1}px; --fs-h2:${sc.h2}px; --fs-h3:${sc.h3}px;\n  --fs-body-lg:${sc.bodyLg}px; --fs-body:${sc.body}px; --fs-caption:${sc.caption}px; --fs-micro:${sc.micro}px;\n`+
`  /* spacing & radius */\n  --s1:4px; --s2:8px; --s3:12px; --s4:16px; --s5:24px; --s6:32px; --s7:48px; --s8:64px;\n  --r-sm:6px; --r-md:10px; --r-lg:14px;\n`+
`  /* data palette · ${sourceName()} ${state.type} */\n`+hexes.map((h,i)=>`  --rea-${sg}-${typeof pal[i].n==='number'?pal[i].n:i+1}: ${h};`).join('\n')+`\n}`;
  }
  if(state.exp==="json"){
    $("#expFile").textContent="rea_theme.json";
    const theme={name:`REA ${sourceName()} — ${state.type}`,dataColors:hexes,background:s.canvas,foreground:s.text,tableAccent:acc,
      textClasses:{label:{fontFace:f.label,color:s.text2},title:{fontFace:f.label,color:s.text},callout:{fontFace:f.label,color:s.text}}};
    return JSON.stringify(theme,null,2);
  }
  // R
  $("#expFile").textContent="rea_theme.R";
  let out=`# REA ${sourceName()} theme — generated by REA Theme Studio\nlibrary(ggplot2)\n\n`;
  out+=`rea_tokens <- list(\n  canvas = "${s.canvas}", surface = "${s.surface}", sunken = "${s.sunken}",\n  border = "${s.border}", text = "${s.text}", text_muted = "${s.text2}", accent = "${acc}"\n)\n\n`;
  if(hasSem){out+=`${sg} <- c(\n`+pal.map(p=>`  "${p.sem}" = "${p.hex}"`).join(",\n")+`\n)\n`;}
  else{out+=`${sg} <- c(${hexes.map(h=>`"${h}"`).join(", ")})\n`;}
  out+=`\n`;
  if(gradient){
    out+=`scale_fill_rea  <- function(...) scale_fill_gradientn(colours = ${sg}, ...)\n`;
    out+=`scale_color_rea <- function(...) scale_color_gradientn(colours = ${sg}, ...)\n\n`;
  }else{
    out+=`scale_fill_rea  <- function(...) scale_fill_manual(values = ${sg}, ...)\n`;
    out+=`scale_color_rea <- function(...) scale_color_manual(values = ${sg}, ...)\n\n`;
  }
  out+=`theme_rea <- function(base_size = ${state.baseSize}, base_family = "${f.label}") {\n`+
`  theme_minimal(base_size = base_size, base_family = base_family) +\n`+
`    theme(\n`+
`      plot.background  = element_rect(fill = rea_tokens$canvas, colour = NA),\n`+
`      panel.background = element_rect(fill = rea_tokens$surface, colour = NA),\n`+
`      panel.grid.minor = element_blank(),\n`+
`      panel.grid.major = element_line(colour = rea_tokens$border),\n`+
`      text             = element_text(colour = rea_tokens$text),\n`+
`      plot.title       = element_text(face = "bold", colour = rea_tokens$text),\n`+
`      axis.text        = element_text(colour = rea_tokens$text_muted)\n`+
`    )\n}`;
  return out;
}
function renderExport(){
  $$("#expSeg button").forEach(b=>b.setAttribute('aria-pressed',b.dataset.f===state.exp));
  $("#expCode").textContent=buildExport();
}

/* ---------- topbar ---------- */
function renderPill(){
  const acc=T.accentOptions().find(a=>a.id===state.accent);
  $("#themePill").textContent=`${acc.label} · ${fontDef().label} · ${state.baseSize}px`;
}

/* ---------- master ---------- */
function render(){
  renderPill();
  switch(state.tab){
    case"palette":renderPalette();break;
    case"type":renderType();break;
    case"surfaces":renderSurfaces();break;
    case"preview":renderPreview();break;
    case"a11y":renderA11y();break;
    case"export":renderExport();break;
  }

  // --- bridge to Shiny (no-op outside Shiny) ---
  // Pushes the CURRENT studio theme into input$ts_theme on every change so the
  // R side (Project Templates, build_config()) can bake it into exports.
  if (window.Shiny && Shiny.setInputValue) {
    const s = surf(); const acc = accentHex(); const f = fontDef();
    const sc = T.typeScale(state.baseSize, state.ratio);
    const pal = currentPalette();
    Shiny.setInputValue('ts_theme', {
      source:   sourceName(),
      type:     state.type,
      // surfaces
      canvas: s.canvas, surface: s.surface, sunken: s.sunken,
      border: s.border, border_strong: s.borderStrong,
      text: s.text, text_2: s.text2, text_3: s.text3, dark: !!s.dark,
      // accent
      accent: acc, accent_hover: T.accentHover(acc), accent_tint: T.accentTint(acc),
      // typography
      font_label: f.label, font_stack: f.stack, font_google: f.google || "",
      base_size: state.baseSize, ratio: state.ratio, heading_weight: state.weight,
      scale: sc,                                  // {micro,caption,body,bodyLg,h3,h2,h1,display}
      // data palette (current type) — names present for categorical/performance/trend
      palette: pal.map(p => ({ n: p.n, hex: p.hex, name: (p.sem || null) })),
      palette_hex: pal.map(p => p.hex)
    }, { priority: 'event' });
  }
}
function setTab(t){
  state.tab=t;
  $$("#tabs .tab").forEach(b=>b.setAttribute('aria-selected',b.dataset.tab===t));
  $$(".panel-tab").forEach(p=>p.classList.toggle('active',p.id==="tab-"+t));
  render();
}

/* rescale the live preview when the viewport changes */
let rsz;window.addEventListener('resize',()=>{if(state.tab!=="preview")return;clearTimeout(rsz);rsz=setTimeout(drawPreview,120);});

/* ---------- toast/copy ---------- */
let tt;function copy(text,msg){const f=()=>{const el=$("#toast");el.textContent=msg;el.classList.add('show');clearTimeout(tt);tt=setTimeout(()=>el.classList.remove('show'),1400);};if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(text).then(f,f);}else f();}

/* ---------- wire ---------- */
$$("#tabs .tab").forEach(b=>b.onclick=()=>setTab(b.dataset.tab));
$$("#srcSeg button").forEach(b=>b.onclick=()=>{state.mode=b.dataset.m;render();});
TYPES.forEach(([id,lbl])=>{const b=document.createElement('button');b.dataset.t=id;b.textContent=lbl;b.onclick=()=>{state.type=id;render();};$("#typeSeg").appendChild(b);});
Object.entries(T.CAT_SETS).forEach(([k,v])=>{const b=document.createElement('button');b.dataset.s=k;b.textContent=v.label;b.onclick=()=>{state.catSet=k;render();};$("#catSetSeg").appendChild(b);});
$("#semToggle").onchange=e=>document.querySelector('.ts-root').classList.toggle('semantic',e.target.checked);
$$("#perfLevels button").forEach(b=>b.onclick=()=>{state.perfN=+b.dataset.n;render();});
$$("#perfVariant button").forEach(b=>b.onclick=()=>{state.perfV=b.dataset.v;render();});
$("#baseSize").oninput=e=>{state.baseSize=parseFloat(e.target.value);render();};
$$("#weightSeg button").forEach(b=>b.onclick=()=>{state.weight=+b.dataset.w;render();});
$$("#expSeg button").forEach(b=>b.onclick=()=>{state.exp=b.dataset.f;renderExport();});
$("#expCopy").onclick=()=>copy($("#expCode").textContent,'Theme export copied');
const expDl=$("#expDownload");
if(expDl)expDl.onclick=()=>{
  const name=$("#expFile").textContent||"gcps_export.txt";
  const blob=(state.exp==="fabric")
    ? zipFiles(generateFabricAppFiles())
    : new Blob([$("#expCode").textContent],{type:"text/plain;charset=utf-8"});
  const url=URL.createObjectURL(blob);const a=document.createElement('a');
  a.href=url;a.download=name;document.body.appendChild(a);a.click();
  document.body.removeChild(a);setTimeout(()=>URL.revokeObjectURL(url),1000);
};

setTab("palette");
})();
