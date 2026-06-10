// directionB.jsx — "Ink & Paper": black calligraphy on warm paper, seal-red accent.
const B = {
  paper: '#EDE7D8', paper2: '#E4DCC8',
  ink: '#1B1712', text: '#2A251E', muted: '#867C6C',
  seal: '#B23A2B', gold: '#A8842F', hair: 'rgba(27,23,18,0.14)',
  serif: '"Spectral", Georgia, serif',
  inkGlow: 'drop-shadow(0 2px 1px rgba(27,23,18,0.18))',
};

function BSeal({ size = 58, letter = 'ا' }) {
  return (
    <div style={{ width: size, height: size, borderRadius: size * 0.22, background: B.seal,
      display: 'grid', placeItems: 'center', boxShadow: '0 2px 8px rgba(178,58,43,0.3)',
      position: 'relative' }}>
      <Glyph letter={letter} size={size * 0.74} fill={B.paper} font='"Aref Ruqaa", serif' />
    </div>
  );
}
function BLife({ on }) {
  return <div style={{ width: 14, height: 14, borderRadius: '50%',
    background: on ? B.ink : 'transparent', border: `1.5px solid ${on ? B.ink : 'rgba(27,23,18,0.3)'}` }} />;
}

function PaperBG() {
  return <>
    <div style={{ position: 'absolute', inset: 0, background:
      `radial-gradient(120% 90% at 50% 0%, ${B.paper}, ${B.paper2})` }} />
    <Lattice stroke="rgba(27,23,18,0.05)" sw={1} opacity={0.8} />
    <div style={{ position: 'absolute', inset: 0, boxShadow: 'inset 0 0 80px rgba(27,23,18,0.07)' }} />
  </>;
}

function B_Menu() {
  return (
    <PhoneFrame bg={B.paper} statusTone="dark">
      <PaperBG />
      {/* faint giant glyph watermark */}
      <div style={{ position: 'absolute', right: -50, bottom: 120, opacity: 0.05 }}>
        <Glyph letter="ل" size={360} fill={B.ink} />
      </div>
      <div style={{ position: 'absolute', inset: 0, padding: '74px 38px 40px', display: 'flex',
        flexDirection: 'column', color: B.text, fontFamily: B.serif }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <BSeal size={56} />
          <div>
            <div style={{ fontSize: 12, letterSpacing: '0.34em', color: B.muted, textTransform: 'uppercase' }}>A slicing game</div>
            <div style={{ fontSize: 13, color: B.seal, letterSpacing: '0.1em', marginTop: 2 }}>الألِف</div>
          </div>
        </div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
          <h1 style={{ margin: 0, fontSize: 92, fontWeight: 400, fontStyle: 'italic', letterSpacing: '-0.02em',
            lineHeight: 0.9, color: B.ink }}>Alaif</h1>
          <div style={{ width: 64, height: 2, background: B.seal, marginTop: 22 }} />
          <p style={{ fontSize: 16, color: B.muted, lineHeight: 1.5, marginTop: 18, maxWidth: 230 }}>
            Swipe to slice the falling letters. Mind the bombs.</p>
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 18 }}>
          <span style={{ fontSize: 12, letterSpacing: '0.24em', color: B.muted, textTransform: 'uppercase' }}>Best</span>
          <span style={{ fontSize: 26, color: B.ink, fontVariantNumeric: 'tabular-nums' }}>14,820</span>
        </div>

        <button style={{ width: '100%', padding: 20, border: 'none', borderRadius: 4, background: B.ink,
          color: B.paper, fontFamily: B.serif, fontSize: 19, fontStyle: 'italic', letterSpacing: '0.08em', cursor: 'pointer' }}>Play</button>
        <div style={{ display: 'flex', gap: 26, justifyContent: 'center', marginTop: 18 }}>
          {['How to play', 'Sound'].map((t) => (
            <span key={t} style={{ fontSize: 14, color: B.muted, borderBottom: `1px solid ${B.hair}`, paddingBottom: 2 }}>{t}</span>
          ))}
        </div>
      </div>
    </PhoneFrame>
  );
}

function B_Game() {
  const inkBlade = { thickness: 6,
    streak: 'linear-gradient(90deg, transparent, rgba(27,23,18,0.65) 35%, #1B1712 50%, rgba(27,23,18,0.65) 65%, transparent)',
    glow: 'drop-shadow(0 1px 2px rgba(27,23,18,0.4))' };
  return (
    <PhoneFrame bg={B.paper} statusTone="dark" notch={false}>
      <PaperBG />
      {/* HUD */}
      <div style={{ position: 'absolute', top: 62, left: 32, right: 32, zIndex: 30, display: 'flex',
        justifyContent: 'space-between', alignItems: 'flex-start', fontFamily: B.serif }}>
        <div>
          <div style={{ fontSize: 11, letterSpacing: '0.26em', color: B.muted, textTransform: 'uppercase' }}>Score</div>
          <div style={{ fontSize: 40, color: B.ink, lineHeight: 1, fontVariantNumeric: 'tabular-nums' }}>8,640</div>
        </div>
        <div style={{ display: 'flex', gap: 7, marginTop: 8 }}><BLife on /><BLife on /><BLife on={false} /></div>
      </div>
      <div style={{ position: 'absolute', top: 156, left: 0, right: 0, textAlign: 'center', zIndex: 30 }}>
        <span style={{ fontFamily: B.serif, fontStyle: 'italic', fontSize: 20, color: B.seal }}>four in a row</span>
      </div>

      {/* upper whole glyph */}
      <div style={{ position: 'absolute', left: 40, top: 226, transform: 'rotate(-12deg)' }}>
        <Glyph letter="ص" size={96} fill={B.ink} glow={B.inkGlow} />
      </div>

      {/* sliced hero */}
      <div style={{ position: 'absolute', left: '50%', top: '52%', transform: 'translate(-50%,-50%)' }}>
        <SlicedGlyph letter="ه" size={188} fill={B.ink} glow={B.inkGlow} particles="ink" blade={inkBlade} angle={-20} />
      </div>

      {/* bomb */}
      <div style={{ position: 'absolute', right: 44, bottom: 220 }}>
        <div style={{ width: 74, height: 74, borderRadius: '50%', background:
          'radial-gradient(circle at 36% 30%, #3a342b, #14110c 72%)', position: 'relative',
          boxShadow: `0 0 0 2px ${B.seal}` }}>
          <div style={{ position: 'absolute', top: -10, left: '52%', width: 3, height: 14, background: B.ink, transform: 'rotate(16deg)' }} />
          <div style={{ position: 'absolute', top: -14, left: '58%', width: 6, height: 6, borderRadius: '50%', background: B.gold, boxShadow: `0 0 8px ${B.gold}` }} />
          <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', color: B.seal, fontFamily: B.serif, fontSize: 28, fontWeight: 700 }}>!</div>
        </div>
      </div>

      {/* ink swipe trail */}
      <svg style={{ position: 'absolute', inset: 0 }} width="100%" height="100%">
        <defs><linearGradient id="bTrail" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#1B1712" stopOpacity="0"/><stop offset="0.7" stopColor="#1B1712" stopOpacity="0.7"/>
          <stop offset="1" stopColor="#1B1712" stopOpacity="0"/></linearGradient></defs>
        <path d="M64 558 Q 180 472 252 360" fill="none" stroke="url(#bTrail)" strokeWidth="7" strokeLinecap="round" />
      </svg>
    </PhoneFrame>
  );
}

function B_Over() {
  return (
    <PhoneFrame bg={B.paper} statusTone="dark">
      <PaperBG />
      <div style={{ position: 'absolute', left: '50%', top: 140, transform: 'translateX(-50%)', opacity: 0.85 }}>
        <SlicedGlyph letter="م" size={140} fill={B.ink} glow={B.inkGlow} particles="ink" angle={-16}
          blade={{ thickness: 4, streak: 'linear-gradient(90deg, transparent, rgba(27,23,18,0.5), transparent)', glow: 'none' }} />
      </div>
      <div style={{ position: 'absolute', inset: 0, padding: '0 40px', display: 'flex', flexDirection: 'column',
        justifyContent: 'flex-end', paddingBottom: 50, fontFamily: B.serif, color: B.text }}>
        <div style={{ fontSize: 14, fontStyle: 'italic', color: B.seal, marginBottom: 4 }}>The blade rests</div>
        <div style={{ fontSize: 12, letterSpacing: '0.24em', color: B.muted, textTransform: 'uppercase' }}>Final score</div>
        <div style={{ fontSize: 76, color: B.ink, lineHeight: 0.95, fontVariantNumeric: 'tabular-nums', marginBottom: 22 }}>11,205</div>
        <div style={{ display: 'flex', gap: 0, marginBottom: 28 }}>
          {[['Best', '14,820'], ['Best combo', '×9']].map(([k, v], i) => (
            <div key={k} style={{ flex: 1, paddingLeft: i ? 22 : 0, borderLeft: i ? `1px solid ${B.hair}` : 'none' }}>
              <div style={{ fontSize: 11, letterSpacing: '0.18em', color: B.muted, textTransform: 'uppercase' }}>{k}</div>
              <div style={{ fontSize: 26, color: B.ink, marginTop: 4 }}>{v}</div>
            </div>
          ))}
        </div>
        <button style={{ width: '100%', padding: 20, border: 'none', borderRadius: 4, background: B.ink, color: B.paper,
          fontFamily: B.serif, fontStyle: 'italic', fontSize: 19, letterSpacing: '0.06em' }}>Play again</button>
        <button style={{ width: '100%', padding: 16, marginTop: 12, borderRadius: 4, background: 'transparent',
          border: `1px solid ${B.hair}`, color: B.muted, fontFamily: B.serif, fontSize: 15 }}>Main menu</button>
      </div>
    </PhoneFrame>
  );
}

function B_Icon() {
  return (
    <IconTile size={168} bg="#EDE7D8" label="B · Ink & Paper">
      <Lattice stroke="rgba(27,23,18,0.06)" size={56} sw={1} />
      <Glyph letter="ا" size={128} fill="#1B1712" font='"Aref Ruqaa", serif' />
      <div style={{ position: 'absolute', right: 26, bottom: 26 }}>
        <BSeal size={40} letter="✦" />
      </div>
      <div style={{ position: 'absolute', left: '16%', right: '16%', top: '52%', height: 5,
        background: 'linear-gradient(90deg, transparent, #1B1712, transparent)', transform: 'rotate(-16deg)', borderRadius: 4 }} />
    </IconTile>
  );
}

Object.assign(window, { B_Menu, B_Game, B_Over, B_Icon, B, BSeal, BLife, PaperBG });
