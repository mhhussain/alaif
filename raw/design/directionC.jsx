// directionC.jsx — "Molten Manuscript": molten-gold glyphs on indigo, gold framing.
const C = {
  bg: '#100A1B', bg2: '#1A1230', panel: 'rgba(255,255,255,0.04)',
  gold: '#E9C36A', goldDeep: '#C9881C',
  glyphGrad: 'linear-gradient(155deg, #FFEFC2 0%, #F3A33C 52%, #C9621C 100%)',
  teal: '#46B6A4', text: '#F3E9D6', muted: '#9A8B73', danger: '#E5562F',
  serif: '"Cormorant Garamond", Georgia, serif',
  kufi: '"Reem Kufi", sans-serif',
  glow: 'drop-shadow(0 0 16px rgba(233,195,106,0.5)) drop-shadow(0 0 3px rgba(255,235,180,0.6))',
};

function CFrame() {
  return <>
    <div style={{ position: 'absolute', inset: 0, background:
      `radial-gradient(120% 80% at 50% 22%, #241640 0%, ${C.bg} 60%)` }} />
    <Lattice stroke="rgba(233,195,106,0.07)" sw={1} opacity={0.9} />
    {/* thin gold inner frame */}
    <div style={{ position: 'absolute', inset: 22, borderRadius: 26,
      border: `1px solid rgba(233,195,106,0.30)` }} />
    {/* corner diamonds */}
    {[[28, 28], [28, 'auto'], ['auto', 28], ['auto', 'auto']].map(([t, l], i) => (
      <div key={i} style={{ position: 'absolute',
        top: t === 'auto' ? 'auto' : t, bottom: t === 'auto' ? 28 : 'auto',
        left: l === 'auto' ? 'auto' : l, right: l === 'auto' ? 28 : 'auto',
        width: 8, height: 8, background: C.gold, transform: 'rotate(45deg)', opacity: 0.7 }} />
    ))}
  </>;
}
function CLife({ on }) {
  return <svg width="22" height="22" viewBox="0 0 24 24">
    <path d="M17 5a7 7 0 1 0 2.5 5.4A5.6 5.6 0 1 1 17 5z" fill={on ? C.gold : 'none'}
      stroke={on ? C.gold : 'rgba(154,139,115,0.5)'} strokeWidth="1.4" />
  </svg>;
}
function CDivider() {
  return <div style={{ display: 'flex', alignItems: 'center', gap: 10, color: C.gold, opacity: 0.7 }}>
    <span style={{ flex: 1, height: 1, background: 'linear-gradient(90deg, transparent, rgba(233,195,106,0.5))' }} />
    <span style={{ width: 6, height: 6, background: C.gold, transform: 'rotate(45deg)' }} />
    <span style={{ flex: 1, height: 1, background: 'linear-gradient(90deg, rgba(233,195,106,0.5), transparent)' }} />
  </div>;
}

function C_Menu() {
  return (
    <PhoneFrame bg={C.bg} statusTone="light">
      <CFrame />
      <div style={{ position: 'absolute', inset: 0, padding: '78px 44px 46px', display: 'flex',
        flexDirection: 'column', alignItems: 'center', color: C.text }}>
        <div style={{ fontFamily: C.kufi, fontSize: 11, letterSpacing: '0.4em', color: C.muted, textTransform: 'uppercase' }}>Slice the script</div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
          <Glyph letter="ا" size={160} gradient={C.glyphGrad} glow={C.glow} font='"Aref Ruqaa", serif' style={{ marginBottom: 6 }} />
          <h1 style={{ fontFamily: C.serif, margin: 0, fontSize: 78, fontWeight: 500, letterSpacing: '0.14em',
            background: C.glyphGrad, WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent' }}>ALAIF</h1>
          <div style={{ fontFamily: C.kufi, fontSize: 18, color: C.gold, letterSpacing: '0.1em', marginTop: 4 }}>الألِف</div>
        </div>

        <div style={{ width: '100%', marginBottom: 18 }}><CDivider /></div>
        <div style={{ width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 20 }}>
          <span style={{ fontFamily: C.kufi, fontSize: 11, letterSpacing: '0.22em', color: C.muted, textTransform: 'uppercase' }}>Best</span>
          <span style={{ fontFamily: C.serif, fontSize: 28, color: C.gold }}>14,820</span>
        </div>

        <button style={{ width: '100%', padding: 19, border: 'none', borderRadius: 14, fontFamily: C.serif,
          background: 'linear-gradient(180deg, #F6CE7B, #D89A36)', color: '#3A2207', fontSize: 22, fontWeight: 600,
          letterSpacing: '0.12em', boxShadow: '0 6px 22px rgba(216,154,54,0.4)', cursor: 'pointer' }}>Play</button>
        <div style={{ display: 'flex', gap: 12, marginTop: 14, width: '100%' }}>
          {['How to play', 'Sound'].map((t) => (
            <div key={t} style={{ flex: 1, textAlign: 'center', padding: 13, borderRadius: 12,
              border: '1px solid rgba(233,195,106,0.22)', color: C.muted, fontFamily: C.serif, fontSize: 15 }}>{t}</div>
          ))}
        </div>
      </div>
    </PhoneFrame>
  );
}

function C_Game() {
  const goldBlade = { thickness: 5,
    streak: 'linear-gradient(90deg, transparent, rgba(233,195,106,0.7) 28%, #fff 50%, rgba(233,195,106,0.7) 72%, transparent)',
    glow: 'drop-shadow(0 0 12px rgba(233,195,106,0.9))' };
  return (
    <PhoneFrame bg={C.bg} statusTone="light" notch={false}>
      <div style={{ position: 'absolute', inset: 0, background: `radial-gradient(120% 80% at 50% 30%, #1E1438, ${C.bg} 62%)` }} />
      <Lattice stroke="rgba(233,195,106,0.05)" sw={1} />
      {/* HUD */}
      <div style={{ position: 'absolute', top: 60, left: 30, right: 30, zIndex: 30, display: 'flex',
        justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontFamily: C.kufi, fontSize: 10, letterSpacing: '0.28em', color: C.muted, textTransform: 'uppercase' }}>Score</div>
          <div style={{ fontFamily: C.serif, fontSize: 42, color: C.gold, lineHeight: 1 }}>8,640</div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}><CLife on /><CLife on /><CLife on={false} /></div>
      </div>
      <div style={{ position: 'absolute', top: 152, left: 0, right: 0, textAlign: 'center', zIndex: 30 }}>
        <span style={{ fontFamily: C.serif, fontSize: 24, fontWeight: 600, color: C.teal,
          letterSpacing: '0.06em', filter: 'drop-shadow(0 0 8px rgba(70,182,164,0.5))' }}>×4 combo</span>
      </div>

      <div style={{ position: 'absolute', left: 44, top: 224, transform: 'rotate(-14deg)' }}>
        <Glyph letter="و" size={100} gradient={C.glyphGrad} glow={C.glow} font='"Aref Ruqaa", serif' />
      </div>
      <div style={{ position: 'absolute', left: '50%', top: '52%', transform: 'translate(-50%,-50%)' }}>
        <SlicedGlyph letter="ج" size={196} gradient={C.glyphGrad} glow={C.glow} particles="gold" blade={goldBlade} angle={-20} />
      </div>

      {/* bomb */}
      <div style={{ position: 'absolute', right: 42, bottom: 216 }}>
        <div style={{ width: 78, height: 78, borderRadius: '50%', position: 'relative',
          background: 'radial-gradient(circle at 35% 30%, #2c2440, #0c0814 72%)',
          boxShadow: `0 0 0 2px ${C.danger}, 0 0 20px rgba(229,86,47,0.45)` }}>
          <div style={{ position: 'absolute', top: -12, left: '52%', width: 3, height: 15, background: C.goldDeep, transform: 'rotate(16deg)' }} />
          <div style={{ position: 'absolute', top: -16, left: '58%', width: 7, height: 7, borderRadius: '50%', background: '#FFB020', boxShadow: '0 0 12px #FFB020' }} />
          <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', color: C.danger, fontFamily: C.serif, fontSize: 30, fontWeight: 700 }}>!</div>
        </div>
      </div>

      <svg style={{ position: 'absolute', inset: 0 }} width="100%" height="100%">
        <defs><linearGradient id="cTrail" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#fff" stopOpacity="0"/><stop offset="0.7" stopColor="#fff" stopOpacity="0.95"/>
          <stop offset="1" stopColor={C.gold} stopOpacity="0"/></linearGradient></defs>
        <path d="M68 560 Q 182 470 252 358" fill="none" stroke="url(#cTrail)" strokeWidth="6" strokeLinecap="round"
          style={{ filter: 'drop-shadow(0 0 8px rgba(233,195,106,0.8))' }} />
      </svg>
    </PhoneFrame>
  );
}

function C_Over() {
  return (
    <PhoneFrame bg={C.bg} statusTone="light">
      <CFrame />
      <div style={{ position: 'absolute', left: '50%', top: 132, transform: 'translateX(-50%)', opacity: 0.7 }}>
        <SlicedGlyph letter="ك" size={140} gradient={C.glyphGrad} glow={C.glow} particles="gold" angle={-16}
          blade={{ thickness: 4, streak: 'linear-gradient(90deg, transparent, rgba(233,195,106,0.6), transparent)', glow: 'none' }} />
      </div>
      <div style={{ position: 'absolute', inset: 0, padding: '0 44px', display: 'flex', flexDirection: 'column',
        justifyContent: 'flex-end', paddingBottom: 50, color: C.text, alignItems: 'center' }}>
        <div style={{ fontFamily: C.serif, fontStyle: 'italic', fontSize: 20, color: C.teal, marginBottom: 14, lineHeight: 1 }}>the blade rests</div>
        <div style={{ fontFamily: C.kufi, fontSize: 11, letterSpacing: '0.26em', color: C.muted, textTransform: 'uppercase' }}>Final score</div>
        <div style={{ fontFamily: C.serif, fontSize: 78, color: C.gold, lineHeight: 0.95, marginBottom: 14 }}>11,205</div>
        <div style={{ width: '100%', marginBottom: 18 }}><CDivider /></div>
        <div style={{ display: 'flex', gap: 12, marginBottom: 26, width: '100%' }}>
          {[['Best', '14,820'], ['Best combo', '×9']].map(([k, v]) => (
            <div key={k} style={{ flex: 1, padding: '14px 16px', borderRadius: 12, background: C.panel,
              border: '1px solid rgba(233,195,106,0.2)', textAlign: 'center' }}>
              <div style={{ fontFamily: C.kufi, fontSize: 9, letterSpacing: '0.18em', color: C.muted, textTransform: 'uppercase' }}>{k}</div>
              <div style={{ fontFamily: C.serif, fontSize: 26, color: C.gold, marginTop: 3 }}>{v}</div>
            </div>
          ))}
        </div>
        <button style={{ width: '100%', padding: 19, border: 'none', borderRadius: 14, fontFamily: C.serif,
          background: 'linear-gradient(180deg, #F6CE7B, #D89A36)', color: '#3A2207', fontSize: 21, fontWeight: 600,
          letterSpacing: '0.1em', boxShadow: '0 6px 22px rgba(216,154,54,0.4)' }}>Play again</button>
        <button style={{ width: '100%', padding: 15, marginTop: 12, borderRadius: 14, background: 'transparent',
          border: '1px solid rgba(233,195,106,0.22)', color: C.muted, fontFamily: C.serif, fontSize: 16 }}>Main menu</button>
      </div>
    </PhoneFrame>
  );
}

function C_Icon() {
  return (
    <IconTile size={168} bg="#100A1B" label="C · Molten Manuscript">
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(90% 90% at 50% 38%, #241640, #100A1B 65%)' }} />
      <Lattice stroke="rgba(233,195,106,0.14)" size={56} sw={1} />
      <div style={{ position: 'absolute', inset: 16, borderRadius: 22, border: '1px solid rgba(233,195,106,0.4)' }} />
      <Glyph letter="ا" size={120} gradient="linear-gradient(155deg, #FFEFC2, #F3A33C 55%, #C9621C)"
        glow="drop-shadow(0 0 14px rgba(233,195,106,0.8))" font='"Aref Ruqaa", serif' />
      <div style={{ position: 'absolute', left: '15%', right: '15%', top: '53%', height: 3,
        background: 'linear-gradient(90deg, transparent, #fff, transparent)', transform: 'rotate(-17deg)',
        filter: 'drop-shadow(0 0 6px rgba(233,195,106,0.9))' }} />
    </IconTile>
  );
}

Object.assign(window, { C_Menu, C_Game, C_Over, C_Icon });
