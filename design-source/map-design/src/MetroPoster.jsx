import { useEffect, useRef, useState } from 'react';

const CANVAS_W = 1620;
const CANVAS_H = 1080;

// Hand-placed leader-line / label anchors for the 3 highlighted districts.
// cx/cy (the dot, on the district centroid) come from mapdata.json; the rest
// is tuned placement so each label lands in open space, clear of fills and
// the numbered side districts.
const CALLOUT_CONFIG = [
  { geoid: '1302550', lx: 632, ly: 286, tx: 614, ty: 236, anchor: 'middle', l1: 'Gwinnett County', l2: 'Public Schools' },
  { geoid: '1300120', lx: 430, ly: 472, tx: 332, ty: 452, anchor: 'middle', l1: 'Atlanta', l2: 'Public Schools' },
  { geoid: '1302820', lx: 668, ly: 768, tx: 722, ty: 812, anchor: 'middle', l1: 'Henry County', l2: 'Schools' },
];

const DISTRICTS_OF_INTEREST = [
  'Gwinnett County Public Schools',
  'Atlanta Public Schools',
  'Henry County Schools',
];

export default function MetroPoster({ theme: t }) {
  const [data, setData] = useState(null);
  const [scale, setScale] = useState(0.62);
  const wrapRef = useRef(null);

  useEffect(() => {
    let cancelled = false;
    fetch('/data/mapdata.json')
      .then((res) => res.json())
      .then((json) => {
        if (!cancelled) setData(json);
      })
      .catch((err) => console.error('mapdata load failed', err));
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const fit = () => {
      const w = el.clientWidth;
      if (!w) return;
      const s = w / CANVAS_W;
      setScale((prev) => (Math.abs(s - prev) > 0.002 ? s : prev));
    };
    const ro = new ResizeObserver(fit);
    ro.observe(el);
    fit();
    return () => ro.disconnect();
  }, []);

  const all = data?.main.districts ?? [];
  const nonHi = all
    .filter((x) => !x.isHi)
    .slice()
    .sort((a, b) => a.short.localeCompare(b.short))
    .map((x, i) => ({ ...x, n: i + 1 }));
  const hi = all.filter((x) => x.isHi);
  const col1 = nonHi.slice(0, 13);
  const col2 = nonHi.slice(13);

  const callouts = CALLOUT_CONFIG.map((c) => {
    const district = all.find((x) => x.geoid === c.geoid);
    return { ...c, cx: district?.cx ?? 0, cy: district?.cy ?? 0 };
  });

  const insetAll = data?.inset.allPath ?? '';
  const insetHi = data?.inset.hi ?? [];
  const ring = data?.inset.ring ?? { cx: 0, cy: 0, r: 0 };

  return (
    <div
      ref={wrapRef}
      style={{
        width: '100%',
        height: Math.round(CANVAS_H * scale),
        position: 'relative',
        overflow: 'hidden',
        background: t.bg,
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: CANVAS_W,
          height: CANVAS_H,
          transform: `scale(${scale})`,
          transformOrigin: '0 0',
          background: t.bg,
          color: t.ink,
          fontFamily: t.bodyFont,
        }}
      >
        {/* Title */}
        <div style={{ position: 'absolute', left: 60, top: 46, width: 1480 }}>
          <div
            style={{
              fontFamily: t.titleFont,
              fontWeight: t.titleWeight,
              fontSize: t.titleSize,
              lineHeight: 1.0,
              letterSpacing: t.titleSpacing,
              textTransform: t.titleTransform,
              color: t.header,
            }}
          >
            Metro Atlanta School Districts
          </div>
          <div
            style={{
              width: 88,
              height: 4,
              background: t.accent,
              margin: '15px 0 13px',
              borderRadius: 2,
            }}
          />
          <div
            style={{
              fontFamily: t.bodyFont,
              fontSize: 22,
              color: t.sub,
              maxWidth: 1180,
              lineHeight: 1.25,
            }}
          >
            Location map highlighting Gwinnett County, Atlanta Public Schools &amp; Henry
            County
          </div>
        </div>

        {/* Left column */}
        <div
          style={{
            position: 'absolute',
            left: 60,
            top: 212,
            width: 414,
            height: 816,
            display: 'flex',
            flexDirection: 'column',
            gap: 14,
          }}
        >
          <div>
            <SectionLabel t={t}>Location within Georgia</SectionLabel>
            <div style={{ marginTop: 14 }}>
              <svg
                viewBox="0 0 320 364"
                width={252}
                height={287}
                style={{ display: 'block', overflow: 'visible' }}
              >
                <path
                  d={insetAll}
                  fill={t.insetFill}
                  stroke={t.insetStroke}
                  strokeWidth={0.5}
                  strokeLinejoin="round"
                />
                {insetHi.map((h, i) => (
                  <path key={i} d={h.d} fill={t.accent} stroke={t.accentDark} strokeWidth={0.6} />
                ))}
                <circle
                  cx={ring.cx}
                  cy={ring.cy}
                  r={ring.r}
                  fill="none"
                  stroke={t.accentDark}
                  strokeWidth={1.5}
                />
                <text
                  x={ring.cx + ring.r + 5}
                  y={ring.cy + 3}
                  fontSize={11}
                  fill={t.sub}
                  fontWeight={600}
                  style={{ fontFamily: t.bodyFont }}
                >
                  Metro Atlanta
                </text>
              </svg>
            </div>
          </div>

          <div>
            <SectionLabel t={t}>Districts of interest</SectionLabel>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 13 }}>
              {DISTRICTS_OF_INTEREST.map((name) => (
                <div key={name} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <span
                    style={{
                      width: 18,
                      height: 18,
                      borderRadius: 4,
                      background: t.accent,
                      border: `1px solid ${t.accentDark}`,
                      flex: 'none',
                    }}
                  />
                  <span
                    style={{
                      fontFamily: t.bodyFont,
                      fontSize: 15.5,
                      fontWeight: 600,
                      color: t.ink,
                    }}
                  >
                    {name}
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div>
            <SectionLabel t={t}>Other metro school systems</SectionLabel>
            <div style={{ display: 'flex', gap: 22, marginTop: 13 }}>
              <DistrictColumn t={t} items={col1} />
              <DistrictColumn t={t} items={col2} />
            </div>
          </div>

          <div
            style={{
              marginTop: 'auto',
              paddingTop: 16,
              borderTop: `1px solid ${t.distStroke}`,
              fontFamily: t.monoFont,
              fontSize: 11,
              lineHeight: 1.7,
              color: t.faint,
            }}
          >
            <div style={{ color: t.sub, fontWeight: 500 }}>
              Created by GCPS Research, Evaluation &amp; Analytics (REA)
            </div>
            <div>Data: U.S. Census Bureau TIGER/Line Shapefiles</div>
          </div>
        </div>

        {/* Main map */}
        <div
          style={{
            position: 'absolute',
            left: 500,
            top: 168,
            width: 1062,
            height: 884,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: t.panel,
            border: `1px solid ${t.panelEdge}`,
            borderRadius: 14,
            boxShadow: t.shadow,
          }}
        >
          <svg viewBox="0 0 1000 881" width={1000} height={881} style={{ display: 'block', overflow: 'visible' }}>
            <g>
              {nonHi.map((d) => (
                <path
                  key={d.geoid}
                  d={d.d}
                  fill={t.distFill}
                  stroke={t.distStroke}
                  strokeWidth={t.distSW}
                  fillRule="evenodd"
                  strokeLinejoin="round"
                />
              ))}
            </g>
            <g>
              {hi.map((d) => (
                <path
                  key={d.geoid}
                  d={d.d}
                  fill={t.accent}
                  stroke={t.accentDark}
                  strokeWidth={t.hiSW}
                  fillRule="evenodd"
                  strokeLinejoin="round"
                />
              ))}
            </g>
            <g>
              {nonHi.map((d) => (
                <text
                  key={d.geoid}
                  x={d.cx}
                  y={d.cy}
                  textAnchor="middle"
                  dominantBaseline="central"
                  paintOrder="stroke"
                  stroke={t.numHalo}
                  strokeWidth={3}
                  fill={t.num}
                  fontSize={13}
                  fontWeight={600}
                  style={{ fontFamily: t.bodyFont }}
                >
                  {d.n}
                </text>
              ))}
            </g>
            <g>
              {callouts.map((c) => (
                <g key={c.geoid}>
                  <line
                    x1={c.cx}
                    y1={c.cy}
                    x2={c.lx}
                    y2={c.ly}
                    stroke={t.accentDark}
                    strokeWidth={1.5}
                    strokeLinecap="round"
                  />
                  <circle cx={c.cx} cy={c.cy} r={4.5} fill={t.accent} stroke={t.numHalo} strokeWidth={1.6} />
                  <text
                    x={c.tx}
                    y={c.ty}
                    textAnchor={c.anchor}
                    paintOrder="stroke"
                    stroke={t.hiHalo}
                    strokeWidth={5.5}
                    fill={t.hiLabel}
                    fontSize={22}
                    fontWeight={700}
                    letterSpacing={0.2}
                    style={{ fontFamily: t.bodyFont }}
                  >
                    <tspan x={c.tx} dy={0}>{c.l1}</tspan>
                    <tspan x={c.tx} dy={23}>{c.l2}</tspan>
                  </text>
                </g>
              ))}
            </g>
          </svg>
        </div>
      </div>
    </div>
  );
}

function SectionLabel({ t, children }) {
  return (
    <div
      style={{
        fontFamily: t.bodyFont,
        fontSize: 12.5,
        fontWeight: 700,
        letterSpacing: '1.6px',
        textTransform: 'uppercase',
        color: t.faint,
        paddingBottom: 7,
        borderBottom: `1px solid ${t.distStroke}`,
      }}
    >
      {children}
    </div>
  );
}

function DistrictColumn({ t, items }) {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 5 }}>
      {items.map((d) => (
        <div key={d.geoid} style={{ display: 'flex', gap: 9, alignItems: 'baseline' }}>
          <span
            style={{
              fontFamily: t.monoFont,
              fontSize: 12,
              color: t.accent,
              minWidth: 17,
              textAlign: 'right',
              flex: 'none',
            }}
          >
            {d.n}
          </span>
          <span style={{ fontFamily: t.bodyFont, fontSize: 14, color: t.sub, lineHeight: 1.2 }}>
            {d.short}
          </span>
        </div>
      ))}
    </div>
  );
}
