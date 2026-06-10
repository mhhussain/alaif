// directionA.jsx — "Girih Noir": cool, surgical, white-hot glyphs on near-black.
const A = {
  bg: '#0B0D12', panel: '#11141C',
  cyan: '#5BD7EA', cyanDim: 'rgba(91,215,234,0.55)',
  text: '#E8EEF7', muted: '#7A8494', faint: 'rgba(232,238,247,0.10)',
  danger: '#E5484D',
  glyphGlow: 'drop-shadow(0 0 16px rgba(91,215,234,0.45)) drop-shadow(0 0 3px rgba(255,255,255,0.7))',
  ui: '"Space Grotesk", system-ui, sans-serif',
};
const aMono = { fontFamily: A.ui, fontVariantNumeric: 'tabular-nums' };

function ALife({ on }) {
  return <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
    <path d="M19 7c-2.5-3-7-1.5-7 1.5C12 5.5 7.5 4 5 7c-2 2.4-1 5.6 1.4 7.8L12 19l5.6-4.2C20 12.6 21 9.4 19 7z"
      stroke={on ? A.cyan : 'rgba(122,132,148,0.5)'} strokeWidth="1.6"
      fill={on ? 'rgba(91,215,234,0.15)' : 'none'} />
  </svg>;
}

function A_Menu() {
  return (
    <PhoneFrame bg={A.bg} statusTone="light">
      <Lattice stroke="rgba(91,215,234,0.07)" sw={1} opacity={0.9} />
      <div style={{ position: 'absolute', inset: 0, background:
        'radial-gradient(120% 80% at 50% 18%, rgba(91,215,234,0.10), transparent 55%)' }} />
      {/* faint background glyph */}
      <div style={{ position: 'absolute', right: -36, top: 250, opacity: 0.06 }}>
        <Glyph letter="ع" size={300} fill={A.cyan} />
      </div>

      <div style={{ position: 'absolute', inset: 0, padding: '72px 34px 40px',
        display: 'flex', flexDirection: 'column', color: A.text }}>
        <div style={{ ...aMono, fontSize: 12, letterSpacing: '0.42em', color: A.muted, textTransform: 'uppercase' }}>Slice the script</div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'flex-start', marginTop: -20 }}>
          <Glyph letter="ا" size={150} fill={A.text} glow={A.glyphGlow} style={{ marginBottom: 4, marginLeft: 6 }} />
          <h1 style={{ ...aMono, margin: 0, fontSize: 76, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 0.9 }}>ALAIF</h1>
          <div style={{ ...aMono, fontSize: 13, letterSpacing: '0.34em', color: A.cyan, marginTop: 14, textTransform: 'uppercase' }}>الألِف</div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10, ...aMono, fontSize: 13, color: A.muted, marginBottom: 18 }}>
          <span style={{ letterSpacing: '0.18em' }}>BEST</span>
          <span style={{ flex: 1, height: 1, background: A.faint }} />
          <span style={{ color: A.text, fontSize: 18, fontWeight: 600 }}>14,820</span>
        </div>

        <button style={{ ...aMono, width: '100%', padding: '20px', border: 'none', borderRadius: 16,
          background: A.cyan, color: '#04222A', fontSize: 19, fontWeight: 700, letterSpacing: '0.16em',
          boxShadow: '0 0 28px rgba(91,215,234,0.4)', cursor: 'pointer' }}>PLAY</button>

        <div style={{ display: 'flex', gap: 12, marginTop: 14 }}>
          {['HOW TO PLAY', 'SOUND'].map((t) => (
            <div key={t} style={{ ...aMono, flex: 1, textAlign: 'center', padding: '14px',
              borderRadius: 14, border: `1px solid ${A.faint}`, color: A.muted, fontSize: 12, letterSpacing: '0.14em' }}>{t}</div>
          ))}
        </div>
      </div>
    </PhoneFrame>
  );
}

function A_Game() {
  return (
    <PhoneFrame bg={A.bg} statusTone="light" notch={false}>
      <Lattice stroke="rgba(91,215,234,0.05)" sw={1} />
      {/* HUD */}
      <div style={{ position: 'absolute', top: 60, left: 28, right: 28, zIndex: 30,
        display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <div>
          <div style={{ ...aMono, color: A.muted, fontSize: 11, letterSpacing: '0.28em' }}>SCORE</div>
          <div style={{ ...aMono, color: A.text, fontSize: 38, fontWeight: 700, lineHeight: 1 }}>8,640</div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <ALife on /><ALife on /><ALife on={false} />
        </div>
      </div>

      {/* combo callout */}
      <div style={{ position: 'absolute', top: 150, left: 0, right: 0, textAlign: 'center', zIndex: 30 }}>
        <span style={{ ...aMono, fontSize: 15, fontWeight: 700, letterSpacing: '0.2em', color: A.cyan,
          filter: 'drop-shadow(0 0 10px rgba(91,215,234,0.5))' }}>×4 COMBO</span>
      </div>

      {/* flying whole glyph (upper) */}
      <div style={{ position: 'absolute', left: 44, top: 220, transform: 'rotate(-14deg)' }}>
        <Glyph letter="ن" size={104} fill={A.text} glow={A.glyphGlow} />
      </div>

      {/* sliced hero glyph */}
      <div style={{ position: 'absolute', left: '50%', top: '52%', transform: 'translate(-50%,-50%)' }}>
        <SlicedGlyph letter="ع" size={190} fill={A.text} glow={A.glyphGlow} particles="cyan"
          blade={{ thickness: 5, streak: 'linear-gradient(90deg, transparent, rgba(91,215,234,0.7) 30%, #fff 50%, rgba(91,215,234,0.7) 70%, transparent)',
                   glow: 'drop-shadow(0 0 12px rgba(91,215,234,0.9))' }} />
      </div>

      {/* bomb */}
      <div style={{ position: 'absolute', right: 40, bottom: 210 }}>
        <div style={{ width: 78, height: 78, borderRadius: '50%', position: 'relative',
          background: 'radial-gradient(circle at 35% 30%, #2a2f3a, #0c0e14 70%)',
          boxShadow: `0 0 0 2px ${A.danger}, 0 0 22px rgba(229,72,77,0.45)` }}>
          <div style={{ position: 'absolute', top: -12, left: '50%', width: 3, height: 16,
            background: A.danger, transform: 'translateX(-50%) rotate(18deg)' }} />
          <div style={{ position: 'absolute', top: -16, left: '58%', width: 7, height: 7, borderRadius: '50%',
            background: '#FFB020', boxShadow: '0 0 12px #FFB020' }} />
          <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center',
            ...aMono, color: A.danger, fontSize: 26, fontWeight: 700 }}>!</div>
        </div>
      </div>

      {/* swipe trail */}
      <svg style={{ position: 'absolute', inset: 0 }} width="100%" height="100%">
        <defs><linearGradient id="aTrail" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#fff" stopOpacity="0"/><stop offset="0.7" stopColor="#fff" stopOpacity="0.9"/>
          <stop offset="1" stopColor={A.cyan} stopOpacity="0"/></linearGradient></defs>
        <path d="M70 560 Q 180 470 250 360" fill="none" stroke="url(#aTrail)" strokeWidth="6"
          strokeLinecap="round" style={{ filter: 'drop-shadow(0 0 8px rgba(91,215,234,0.8))' }} />
      </svg>
    </PhoneFrame>
  );
}

function A_Over() {
  return (
    <PhoneFrame bg={A.bg} statusTone="light">
      <Lattice stroke="rgba(91,215,234,0.06)" sw={1} />
      <div style={{ position: 'absolute', inset: 0, background:
        'radial-gradient(110% 70% at 50% 40%, rgba(229,72,77,0.10), transparent 60%)' }} />
      <div style={{ position: 'absolute', left: '50%', top: 150, transform: 'translateX(-50%)', opacity: 0.5 }}>
        <SlicedGlyph letter="ف" size={150} fill={A.text} glow={A.glyphGlow} angle={-18} particles="cyan"
          blade={{ thickness: 4, streak: 'linear-gradient(90deg, transparent, rgba(91,215,234,0.6), transparent)', glow: 'none' }} />
      </div>
      <div style={{ position: 'absolute', inset: 0, padding: '0 34px', display: 'flex',
        flexDirection: 'column', justifyContent: 'flex-end', paddingBottom: 48, color: A.text }}>
        <div style={{ ...aMono, fontSize: 13, letterSpacing: '0.4em', color: A.danger, textTransform: 'uppercase', marginBottom: 6 }}>Run ended</div>
        <div style={{ ...aMono, fontSize: 17, color: A.muted, letterSpacing: '0.2em' }}>SCORE</div>
        <div style={{ ...aMono, fontSize: 70, fontWeight: 700, lineHeight: 0.95, marginBottom: 18 }}>11,205</div>
        <div style={{ display: 'flex', gap: 12, marginBottom: 26 }}>
          {[['BEST', '14,820'], ['BEST COMBO', '×9']].map(([k, v]) => (
            <div key={k} style={{ flex: 1, padding: '14px 16px', borderRadius: 14, border: `1px solid ${A.faint}`, background: A.panel }}>
              <div style={{ ...aMono, fontSize: 10, letterSpacing: '0.2em', color: A.muted }}>{k}</div>
              <div style={{ ...aMono, fontSize: 22, fontWeight: 600, marginTop: 4 }}>{v}</div>
            </div>
          ))}
        </div>
        <button style={{ ...aMono, width: '100%', padding: 19, border: 'none', borderRadius: 16, background: A.cyan,
          color: '#04222A', fontSize: 18, fontWeight: 700, letterSpacing: '0.16em', boxShadow: '0 0 26px rgba(91,215,234,0.4)' }}>REPLAY</button>
        <button style={{ ...aMono, width: '100%', padding: 17, marginTop: 12, borderRadius: 16,
          background: 'transparent', border: `1px solid ${A.faint}`, color: A.muted, fontSize: 14, letterSpacing: '0.16em' }}>MAIN MENU</button>
      </div>
    </PhoneFrame>
  );
}

function A_Icon() {
  return (
    <IconTile size={168} bg="#0B0D12" label="A · Girih Noir">
      <div style={{ position: 'absolute', inset: 0 }}>
        <Lattice stroke="rgba(91,215,234,0.12)" size={60} sw={1} />
      </div>
      <div style={{ position: 'absolute', inset: 0, background:
        'radial-gradient(90% 90% at 50% 40%, rgba(91,215,234,0.18), transparent 60%)' }} />
      <Glyph letter="ا" size={120} fill="#EAF6FA" glow="drop-shadow(0 0 14px rgba(91,215,234,0.8))" />
      <div style={{ position: 'absolute', left: '14%', right: '14%', top: '54%', height: 3,
        background: 'linear-gradient(90deg, transparent, #fff, transparent)', transform: 'rotate(-18deg)',
        filter: 'drop-shadow(0 0 6px rgba(91,215,234,0.9))' }} />
    </IconTile>
  );
}

Object.assign(window, { A_Menu, A_Game, A_Over, A_Icon });
