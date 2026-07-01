import { useState } from 'react';
import MetroPoster from './MetroPoster.jsx';
import { themes } from './themes.js';

export default function App() {
  const [activeId, setActiveId] = useState(themes[0].id);
  const active = themes.find((t) => t.id === activeId) ?? themes[0];

  return (
    <div style={{ minHeight: '100svh', display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '32px 24px' }}>
      <div
        role="tablist"
        aria-label="Poster theme"
        style={{ display: 'flex', gap: 10, marginBottom: 24, flexWrap: 'wrap', justifyContent: 'center' }}
      >
        {themes.map((t) => {
          const isActive = t.id === activeId;
          return (
            <button
              key={t.id}
              role="tab"
              aria-selected={isActive}
              type="button"
              onClick={() => setActiveId(t.id)}
              style={{
                display: 'flex',
                alignItems: 'baseline',
                gap: 8,
                padding: '8px 14px',
                borderRadius: 8,
                border: isActive ? '1px solid #2a78d6' : '1px solid rgba(0,0,0,.12)',
                background: isActive ? '#2a78d6' : '#fff',
                color: isActive ? '#fff' : '#1a1a1a',
                cursor: 'pointer',
                font: '500 13px/1.3 system-ui, sans-serif',
              }}
            >
              <span
                style={{
                  font: '600 10.5px ui-monospace, Menlo, monospace',
                  padding: '2px 6px',
                  borderRadius: 5,
                  background: isActive ? 'rgba(255,255,255,.2)' : 'rgba(0,0,0,.08)',
                }}
              >
                {t.label}
              </span>
              {t.name} &mdash; {t.blurb}
            </button>
          );
        })}
      </div>

      <div
        style={{
          width: '100%',
          maxWidth: 1240,
          border: '1px solid rgba(0,0,0,.1)',
          borderRadius: 10,
          boxShadow: '0 2px 10px rgba(0,0,0,.07)',
          overflow: 'hidden',
        }}
      >
        <MetroPoster theme={active} />
      </div>
    </div>
  );
}
