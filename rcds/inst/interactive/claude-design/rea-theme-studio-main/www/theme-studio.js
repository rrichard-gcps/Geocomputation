// ============================================================================
// theme-studio.js — GCPS Theme Studio engine (pure logic + data)
// Depends on palette-data.js (GCPS_BASE, CLUSTERS, SCHOOL_CLUSTER, GCPS_QUALITATIVE…)
// Exposes everything on window so the HTML can wire it up.
// No runtime CDN, deterministic. Mirrors what the Shiny port must reproduce in R.
// ============================================================================
(function (G) {
  /* ---------- sRGB <-> OKLCH ---------- */
  const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
  const lerp = (a, b, t) => a + (b - a) * t;
  function hexToRgb(h){h=h.replace('#','');if(h.length===3)h=h.split('').map(c=>c+c).join('');return [parseInt(h.slice(0,2),16),parseInt(h.slice(2,4),16),parseInt(h.slice(4,6),16)];}
  function rgbToHex(r,g,b){const f=v=>('0'+Math.round(clamp(v,0,255)).toString(16)).slice(-2);return ('#'+f(r)+f(g)+f(b)).toUpperCase();}
  const s2l = c => c <= 0.04045 ? c/12.92 : Math.pow((c+0.055)/1.055, 2.4);
  const l2s = c => c <= 0.0031308 ? 12.92*c : 1.055*Math.pow(c,1/2.4)-0.055;
  function hexToOklch(hex){
    let [r,g,b]=hexToRgb(hex).map(v=>s2l(v/255));
    const l=0.4122214708*r+0.5363325363*g+0.0514459929*b, m=0.2119034982*r+0.6806995451*g+0.1073969566*b, s=0.0883024619*r+0.2817188376*g+0.6299787005*b;
    const l_=Math.cbrt(l),m_=Math.cbrt(m),s_=Math.cbrt(s);
    const L=0.2104542553*l_+0.7936177850*m_-0.0040720468*s_, A=1.9779984951*l_-2.4285922050*m_+0.4505937099*s_, B=0.0259040371*l_+0.7827717662*m_-0.8086757660*s_;
    let H=Math.atan2(B,A)*180/Math.PI; if(H<0)H+=360;
    return [L,Math.sqrt(A*A+B*B),H];
  }
  function oklchToHex(L,C,H){
    const hr=H*Math.PI/180,A=C*Math.cos(hr),B=C*Math.sin(hr);
    const l_=L+0.3963377774*A+0.2158037573*B,m_=L-0.1055613458*A-0.0638541728*B,s_=L-0.0894841775*A-1.2914855480*B;
    const l=l_**3,m=m_**3,s=s_**3;
    return rgbToHex(l2s(4.0767416621*l-3.3077115913*m+0.2309699292*s)*255, l2s(-1.2684380046*l+2.6097574011*m-0.3413193965*s)*255, l2s(-0.0041960863*l-0.7034186147*m+1.7076147010*s)*255);
  }
  /* ---------- WCAG contrast ---------- */
  function relLum(hex){const [r,g,b]=hexToRgb(hex).map(v=>s2l(v/255));return 0.2126*r+0.7152*g+0.0722*b;}
  function contrast(h1,h2){const a=relLum(h1),b=relLum(h2);const hi=Math.max(a,b),lo=Math.min(a,b);return (hi+0.05)/(lo+0.05);}
  const contrastWhite = hex => contrast(hex,'#FFFFFF');
  function rating(ratio,large){ // text rating
    if(large) return ratio>=4.5?'AAA':ratio>=3?'AA':'fail';
    return ratio>=7?'AAA':ratio>=4.5?'AA':ratio>=3?'AA-lg':'fail';
  }

  /* ---------- Palette generators ---------- */
  function sequential(hex,n=5){const [L,C,H]=hexToOklch(hex);return Array.from({length:n},(_,i)=>{const t=i/(n-1);return {n:Math.round(lerp(100,900,t)/100)*100, hex:oklchToHex(lerp(0.95,L*0.80,t),C*lerp(0.30,0.98,t),H)};});}
  function tints(hex){const [L,C,H]=hexToOklch(hex);const labels=[50,100,200,300,400,500,600,700,800,900,950];return labels.map((lb,i)=>{const t=i/(labels.length-1);return {n:lb,hex:oklchToHex(lerp(0.975,L*0.78,t),C*lerp(0.16,1.0,t),H)};});}
  function continuous(hex,n=9){const [L,C,H]=hexToOklch(hex);return Array.from({length:n},(_,i)=>{const t=i/(n-1);return {n:i+1,hex:oklchToHex(lerp(0.975,L*0.80,t),C*lerp(0.18,1.0,t),H)};});}
  function diverging(hex,otherHex,n=7){const [La,Ca,Ha]=hexToOklch(hex),[Lb,Cb,Hb]=hexToOklch(otherHex);const half=(n-1)/2,out=[];
    for(let i=0;i<n;i++){if(i<half){const t=i/half;out.push({n:i-half,hex:oklchToHex(lerp(La*0.85,0.94,t),lerp(Ca,Ca*0.18,t),Ha)});}
      else if(i===half){out.push({n:0,hex:"#F3F4F6"});}
      else{const t=(i-half)/half;out.push({n:i-half,hex:oklchToHex(lerp(0.94,Lb*0.85,t),lerp(Cb*0.18,Cb,t),Hb)});}}return out;}

  const BRAND_CAT=["#2F5FB3","#D96A1D","#007C91","#5E8C31","#6A4CC3","#660000","#7A828C"];
  const CAT_SETS={
    brand:   {label:"GCPS Brand",  colors:BRAND_CAT,           names:null, desc:"The seven GCPS analytics bases, ordered for maximum adjacent contrast."},
    curated: {label:"GCPS Curated",colors:GCPS_QUALITATIVE,  names:null, desc:"Nine hand-tuned qualitative hues repurposed from the GCPS Tableau library."},
    clusters:{label:"All Clusters",colors:CLUSTER_ORDER.map(k=>CLUSTERS[k]), names:CLUSTER_ORDER, desc:"High-school cluster brand colors, labeled by cluster."}
  };
  function extendCat(colors,n){
    if(n<=colors.length)return colors.slice(0,n);
    const out=colors.slice();let i=0;
    while(out.length<n){const base=colors[i%colors.length];const step=Math.floor(i/colors.length)+1;const [L,C,H]=hexToOklch(base);const dir=(out.length%2===0)?1:-1;out.push(oklchToHex(clamp(L+dir*0.15*step,0.28,0.9),C*0.92,H));i++;}
    return out;
  }
  function categorical(setKey,n){const set=CAT_SETS[setKey];const cols=extendCat(set.colors,n);return cols.map((hex,i)=>({n:i+1,hex,sem:set.names?(set.names[i]||("Series "+(i+1))):("Series "+(i+1))}));}

  const PERF_NAMES={4:["Beginning","Developing","Proficient","Distinguished"],5:["Beginning","Developing","Approaching","Proficient","Distinguished"],6:["Entering","Beginning","Developing","Expanding","Bridging","Reaching"]};
  function perfSemantic(n){return Array.from({length:n},(_,i)=>{const t=i/(n-1);return {n:i+1,hex:oklchToHex(lerp(0.60,0.66,t),lerp(0.15,0.13,t),lerp(28,150,t)),sem:PERF_NAMES[n][i]};});}
  function perfBase(hex,n){const [L,C,H]=hexToOklch(hex);return Array.from({length:n},(_,i)=>{const t=i/(n-1);return {n:i+1,hex:oklchToHex(lerp(0.86,L*0.82,t),C*lerp(0.4,1.0,t),H),sem:PERF_NAMES[n][i]};});}
  function trend(){return [{n:"+",hex:GCPS_BASE.green.toUpperCase(),sem:"Positive · improvement"},{n:"\u2013",hex:"#B42318",sem:"Negative · decline"},{n:"=",hex:GCPS_BASE.neutral.toUpperCase(),sem:"Neutral · no change"}];}

  /* ---------- Typography ---------- */
  // Fonts curated for K-12 dashboards exported to Power BI / R / Quarto.
  const FONTS=[
    {id:"segoe",   label:"Segoe UI",      stack:"'Segoe UI',system-ui,-apple-system,sans-serif", google:null, use:"Power BI native — themes match the host app out of the box."},
    {id:"sourcesans",label:"Source Sans 3",stack:"'Source Sans 3',system-ui,sans-serif", google:"Source+Sans+3:wght@400;500;600;700", use:"Neutral, legible workhorse. Safe default for dense dashboards."},
    {id:"lexend",  label:"Lexend",        stack:"'Lexend',system-ui,sans-serif", google:"Lexend:wght@300;400;500;600;700", use:"Readability-tuned. Calm, executive tone for board reports."},
    {id:"plex",    label:"IBM Plex Sans", stack:"'IBM Plex Sans',system-ui,sans-serif", google:"IBM+Plex+Sans:wght@400;500;600;700", use:"Technical and distinctive; pairs with IBM Plex Mono for figures."},
    {id:"spectral",label:"Spectral",      stack:"'Spectral',Georgia,serif", google:"Spectral:wght@400;500;600;700", use:"Editorial serif for narrative, board-facing PDFs."}
  ];
  const SCALE_RATIOS={ "1.125":"Major second (1.125)","1.2":"Minor third (1.2)","1.25":"Major third (1.25)" };
  // Compute an 8-step scale from a base size + ratio.
  function typeScale(base, ratio){
    const r=parseFloat(ratio);
    const round=x=>Math.round(x*10)/10;
    return {
      micro:   round(base/(r*r)),
      caption: round(base/r),
      body:    round(base),
      bodyLg:  round(base*r*0.92),
      h3:      round(base*r),
      h2:      round(base*r*r),
      h1:      round(base*r*r*r),
      display: round(base*r*r*r*r)
    };
  }

  /* ---------- Surfaces (theme chrome tokens) ---------- */
  const SURFACES={
    paper: {label:"Warm Paper", canvas:"#F7F6F3",surface:"#FFFFFF",sunken:"#F1EFEA",border:"#E4E1D9",borderStrong:"#CFCBC0",text:"#1F2120",text2:"#5C5A54",text3:"#8A8780",dark:false,
            note:"Editorial, executive. The current GCPS direction."},
    cool:  {label:"Cool Slate", canvas:"#F5F6F8",surface:"#FFFFFF",sunken:"#EEF0F3",border:"#E1E4EA",borderStrong:"#C7CCD6",text:"#1B1F26",text2:"#545A66",text3:"#858B97",dark:false,
            note:"Crisp, neutral-cool. Reads modern on screens and in Power BI."},
    neutral:{label:"Pure Neutral",canvas:"#F6F6F6",surface:"#FFFFFF",sunken:"#EFEFEF",border:"#E3E3E3",borderStrong:"#C9C9C9",text:"#1A1A1A",text2:"#555555",text3:"#888888",dark:false,
            note:"True gray. Maximum chart-color fidelity, zero tint bias."},
    slate: {label:"Slate Dark", canvas:"#16181C",surface:"#1E2127",sunken:"#23262D",border:"#2C3038",borderStrong:"#3A3F49",text:"#F2F3F5",text2:"#B7BCC6",text3:"#838996",dark:true,
            note:"Dark mode for control rooms / always-on displays."}
  };
  // Accent options: maroon (district) + the 7 analytics bases.
  function accentOptions(){
    return BASE_ORDER.map(k=>({id:k,label:k.charAt(0).toUpperCase()+k.slice(1),hex:GCPS_BASE[k]}));
  }
  function accentTint(hex){const [L,C,H]=hexToOklch(hex);return oklchToHex(lerp(L,0.97,0.86),C*0.22,H);}
  function accentHover(hex){const [L,C,H]=hexToOklch(hex);return oklchToHex(L*0.82,C,H);}

  G.TS = {
    hexToRgb,rgbToHex,hexToOklch,oklchToHex,relLum,contrast,contrastWhite,rating,
    sequential,tints,continuous,diverging,categorical,perfSemantic,perfBase,trend,
    CAT_SETS,extendCat,PERF_NAMES,
    FONTS,SCALE_RATIOS,typeScale,
    SURFACES,accentOptions,accentTint,accentHover
  };
})(window);
