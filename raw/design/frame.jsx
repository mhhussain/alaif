// frame.jsx — shared primitives for Alaif visual directions
// PhoneFrame, StatusBar, SlicedGlyph, FlyingGlyph, Particles, Lattice, IconTile
// Exported to window at bottom.

const { useId } = React;

// ---- Portrait phone shell ---------------------------------------------------
function PhoneFrame({ children, bg, statusTone = 'light', notch = true, width = 340, height = 736 }) {
  const tone = statusTone === 'light' ? 'rgba(255,255,255,0.92)' : 'rgba(20,16,12,0.85)';
  return (
    <div style={{
      width, height, borderRadius: 44, background: bg, position: 'relative',
      overflow: 'hidden', boxShadow: '0 1px 0 rgba(255,255,255,0.06) inset',
      fontFamily: '"Space Grotesk", system-ui, sans-serif',
    }}>
      {/* status bar */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 52, zIndex: 40,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '0 30px', color: tone, fontSize: 15, fontWeight: 600,
        fontVariantNumeric: 'tabular-nums', letterSpacing: '0.02em',
      }}>
        <span>9:41</span>
        {notch && (
          <div style={{
            position: 'absolute', left: '50%', top: 11, transform: 'translateX(-50%)',
            width: 104, height: 30, borderRadius: 18, background: 'rgba(0,0,0,0.55)',
          }} />
        )}
        <span style={{ display: 'flex', gap: 6, alignItems: 'center', opacity: 0.95 }}>
          <Bars tone={tone} /><Wifi tone={tone} /><Batt tone={tone} />
        </span>
      </div>
      {children}
    </div>
  );
}
const Bars = ({ tone }) => (
  <svg width="18" height="12" viewBox="0 0 18 12" fill={tone}><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5" width="3" height="7" rx="1"/><rect x="10" y="2.5" width="3" height="9.5" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg>
);
const Wifi = ({ tone }) => (
  <svg width="17" height="12" viewBox="0 0 17 12" fill={tone}><path d="M8.5 2.2c2.6 0 5 1 6.8 2.7l-1.3 1.4A7.6 7.6 0 0 0 8.5 4.1 7.6 7.6 0 0 0 2.7 6.3L1.4 4.9A9.6 9.6 0 0 1 8.5 2.2zm0 3.6c1.6 0 3 .6 4.1 1.6l-1.4 1.5A3.9 3.9 0 0 0 8.5 9.4a3.9 3.9 0 0 0-2.7 1L4.4 9C5.5 8 6.9 7.4 8.5 7.4zm0 3.4 1.6 1.7H6.9z"/></svg>
);
const Batt = ({ tone }) => (
  <svg width="26" height="13" viewBox="0 0 26 13"><rect x="0.5" y="0.5" width="22" height="12" rx="3.5" fill="none" stroke={tone} strokeOpacity="0.5"/><rect x="2.5" y="2.5" width="16" height="8" rx="1.5" fill={tone}/><rect x="24" y="4" width="2" height="5" rx="1" fill={tone} fillOpacity="0.5"/></svg>
);

// ---- Sliced-glyph hero ------------------------------------------------------
// Renders a calligraphic letter cleanly OR split along a diagonal with a
// blade streak + particles. `mode`: 'whole' | 'sliced'.
function Glyph({ letter, size = 200, font = '"Aref Ruqaa", serif',
                 fill, gradient, glow, weight = 700, style = {} }) {
  const base = {
    fontFamily: font, fontSize: size, fontWeight: weight, lineHeight: 1,
    userSelect: 'none', WebkitFontSmoothing: 'antialiased',
  };
  if (gradient) {
    return <span style={{ ...base, background: gradient, WebkitBackgroundClip: 'text',
      backgroundClip: 'text', color: 'transparent', filter: glow, ...style }}>{letter}</span>;
  }
  return <span style={{ ...base, color: fill, filter: glow, textShadow: glow ? undefined : 'none', ...style }}>{letter}</span>;
}

// A letter sliced in two along a diagonal — two clipped copies pushed apart.
function SlicedGlyph({ letter, size = 210, font, fill, gradient, glow,
                       angle = -22, gap = 13, blade, particles = 'gold' }) {
  const upper = `polygon(-30% -30%, 130% -30%, ${50 - 80}% 130%, -30% 130%)`;
  // diagonal cut: top-left piece vs bottom-right piece
  const cutTop = 'polygon(-40% -40%, 140% -40%, -40% 140%)';
  const cutBot = 'polygon(140% -40%, 140% 140%, -40% 140%)';
  const g = (clip, dx, dy, rot) => (
    <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center',
      clipPath: clip, transform: `translate(${dx}px, ${dy}px) rotate(${rot}deg)`,
      transformOrigin: 'center' }}>
      <Glyph letter={letter} size={size} font={font} fill={fill} gradient={gradient} glow={glow} />
    </div>
  );
  return (
    <div style={{ position: 'relative', width: size * 1.1, height: size * 1.25,
      transform: `rotate(${angle}deg)` }}>
      {g(cutTop, -gap * 0.5, -gap * 0.7, -3)}
      {g(cutBot, gap * 0.5, gap * 0.7, 3)}
      {/* blade streak across the cut */}
      <div style={{ position: 'absolute', left: '-12%', right: '-12%', top: '50%',
        height: blade?.thickness || 5, transform: 'translateY(-50%)',
        background: blade?.streak || 'linear-gradient(90deg, transparent, #fff 45%, #fff 55%, transparent)',
        filter: blade?.glow || 'drop-shadow(0 0 10px rgba(255,255,255,0.9))',
        borderRadius: 6 }} />
      <CutParticles kind={particles} />
    </div>
  );
}

function CutParticles({ kind }) {
  const palette = kind === 'ink'
    ? ['#16130E', '#2b2620', '#3a342b']
    : kind === 'cyan'
    ? ['#bdeefb', '#6fd9ec', '#ffffff']
    : ['#ffe6a8', '#f3b24c', '#fff3d6'];
  const dots = [];
  for (let i = 0; i < 16; i++) {
    const t = (i / 16) * Math.PI * 2;
    const r = 30 + (i % 4) * 26 + (i * 7 % 18);
    const x = 50 + Math.cos(t) * r * 0.16;
    const y = 50 + Math.sin(t) * r * 0.10;
    const s = 2 + (i % 5);
    dots.push(<span key={i} style={{ position: 'absolute', left: `${x}%`, top: `${y}%`,
      width: s, height: s, borderRadius: '50%', background: palette[i % palette.length],
      opacity: 0.85 - (i % 5) * 0.1,
      filter: kind === 'ink' ? 'none' : `drop-shadow(0 0 4px ${palette[0]})` }} />);
  }
  return <>{dots}</>;
}

// ---- Geometric lattice background (cheap CSS data-URI tile) -----------------
// Two overlapped squares = 8-point girih star, stroked, tiled.
function latticeURL(stroke, sw = 1) {
  const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='84' height='84' viewBox='0 0 84 84'>
    <g fill='none' stroke='${stroke}' stroke-width='${sw}'>
      <rect x='17' y='17' width='50' height='50'/>
      <path d='M42 7 L77 42 L42 77 L7 42 Z'/>
      <path d='M42 7 L42 77 M7 42 L77 42'/>
    </g></svg>`;
  return `url("data:image/svg+xml,${encodeURIComponent(svg)}")`;
}

function Lattice({ stroke, size = 84, sw = 1, opacity = 1, style = {} }) {
  return <div style={{ position: 'absolute', inset: 0, backgroundImage: latticeURL(stroke, sw),
    backgroundSize: `${size}px ${size}px`, opacity, ...style }} />;
}

// ---- App icon tile ----------------------------------------------------------
function IconTile({ size = 168, radius = 0.224, children, bg, label }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
      <div style={{ width: size, height: size, borderRadius: size * radius, background: bg,
        position: 'relative', overflow: 'hidden', display: 'grid', placeItems: 'center',
        boxShadow: '0 10px 30px rgba(0,0,0,0.28)' }}>{children}</div>
      <div style={{ fontFamily: '"Space Grotesk", sans-serif', fontSize: 12, letterSpacing: '0.08em',
        textTransform: 'uppercase', color: 'rgba(60,50,40,0.55)' }}>{label}</div>
    </div>
  );
}

// ---- small UI helpers -------------------------------------------------------
function Pill({ children, style }) {
  return <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8,
    padding: '9px 18px', borderRadius: 999, ...style }}>{children}</div>;
}

Object.assign(window, { PhoneFrame, Glyph, SlicedGlyph, CutParticles, Lattice, latticeURL, IconTile, Pill });
