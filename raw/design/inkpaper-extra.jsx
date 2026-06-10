// inkpaper-extra.jsx — remaining Ink & Paper screens + token board.
const B = window.B, BSeal = window.BSeal, BLife = window.BLife, PaperBG = window.PaperBG;

// ---- A thin ink toggle ------------------------------------------------------
function InkToggle({ on }) {
  return (
    <div style={{ width: 50, height: 28, borderRadius: 999, padding: 3,
      background: on ? B.ink : 'transparent', border: `1.5px solid ${on ? B.ink : 'rgba(27,23,18,0.3)'}`,
      display: 'flex', justifyContent: on ? 'flex-end' : 'flex-start', alignItems: 'center', transition: 'all .2s' }}>
      <div style={{ width: 20, height: 20, borderRadius: '50%', background: on ? B.paper : B.muted }} />
    </div>
  );
}

function SettingRow({ label, sub, control, last }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '20px 0', borderBottom: last ? 'none' : `1px solid ${B.hair}` }}>
      <div>
        <div style={{ fontFamily: B.serif, fontSize: 18, color: B.ink }}>{label}</div>
        {sub && <div style={{ fontFamily: B.serif, fontSize: 13, color: B.muted, marginTop: 2 }}>{sub}</div>}
      </div>
      {control}
    </div>
  );
}

// ---- How to play ------------------------------------------------------------
function HowToRow({ icon, title, body, last }) {
  return (
    <div style={{ display: 'flex', gap: 18, alignItems: 'flex-start',
      padding: '22px 0', borderBottom: last ? 'none' : `1px solid ${B.hair}` }}>
      <div style={{ width: 56, height: 56, flex: '0 0 auto', borderRadius: 6, border: `1px solid ${B.hair}`,
        display: 'grid', placeItems: 'center', background: 'rgba(27,23,18,0.02)' }}>{icon}</div>
      <div>
        <div style={{ fontFamily: B.serif, fontSize: 19, fontStyle: 'italic', color: B.ink }}>{title}</div>
        <div style={{ fontFamily: B.serif, fontSize: 14.5, color: B.muted, lineHeight: 1.5, marginTop: 3 }}>{body}</div>
      </div>
    </div>
  );
}
const SwipeIcon = () => (
  <svg width="34" height="34" viewBox="0 0 34 34" fill="none">
    <path d="M5 25 Q16 6 29 13" stroke={B.ink} strokeWidth="2.2" strokeLinecap="round" />
    <path d="M29 13 l-1.5 -6 M29 13 l-6 1.5" stroke={B.ink} strokeWidth="2.2" strokeLinecap="round" />
  </svg>
);
const BombIcon = () => (
  <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
    <circle cx="15" cy="20" r="9" fill={B.ink} />
    <path d="M22 11 l3 -4" stroke={B.ink} strokeWidth="2" strokeLinecap="round" />
    <circle cx="26" cy="6" r="2.4" fill={B.seal} />
  </svg>
);
const ComboIcon = () => (
  <svg width="34" height="22" viewBox="0 0 34 22" fill="none">
    <circle cx="6" cy="11" r="3.2" fill={B.ink} /><circle cx="17" cy="11" r="3.2" fill={B.ink} /><circle cx="28" cy="11" r="3.2" fill={B.ink} />
    <circle cx="11" cy="4" r="1.6" fill={B.gold} /><circle cx="23" cy="18" r="1.6" fill={B.gold} /><circle cx="30" cy="3" r="1.3" fill={B.gold} />
  </svg>
);

function B_HowTo() {
  return (
    <PhoneFrame bg={B.paper} statusTone="dark">
      <PaperBG />
      <div style={{ position: 'absolute', inset: 0, padding: '72px 38px 36px', display: 'flex',
        flexDirection: 'column', fontFamily: B.serif, color: B.text }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <BSeal size={42} />
          <h2 style={{ margin: 0, fontSize: 34, fontWeight: 400, fontStyle: 'italic', color: B.ink }}>How to play</h2>
        </div>
        <div style={{ marginTop: 14 }}>
          <HowToRow icon={<SwipeIcon />} title="Swipe to slice"
            body="Drag across a flying letter to cut it clean in two." />
          <HowToRow icon={<ComboIcon />} title="Chain combos"
            body="Slice three or more in one stroke for bonus points." />
          <HowToRow icon={<BombIcon />} title="Avoid the bombs"
            body="A sliced bomb costs a life. Three letters missed ends the run." last />
        </div>
        <div style={{ flex: 1 }} />
        <button style={{ width: '100%', padding: 19, border: 'none', borderRadius: 4, background: B.ink,
          color: B.paper, fontFamily: B.serif, fontStyle: 'italic', fontSize: 19, letterSpacing: '0.06em' }}>Got it</button>
      </div>
    </PhoneFrame>
  );
}

// ---- Pause ------------------------------------------------------------------
function B_Pause() {
  return (
    <PhoneFrame bg={B.paper} statusTone="dark" notch={false}>
      <PaperBG />
      {/* faint game still behind */}
      <div style={{ position: 'absolute', left: 44, top: 150, opacity: 0.12 }}>
        <Glyph letter="ع" size={120} fill={B.ink} />
      </div>
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(237,231,216,0.78)' }} />
      <div style={{ position: 'absolute', inset: 0, padding: '0 44px', display: 'flex', flexDirection: 'column',
        justifyContent: 'center', alignItems: 'center', fontFamily: B.serif, color: B.text }}>
        <div style={{ fontSize: 13, letterSpacing: '0.32em', color: B.muted, textTransform: 'uppercase' }}>Paused</div>
        <div style={{ fontSize: 70, fontStyle: 'italic', color: B.ink, lineHeight: 1, margin: '6px 0 4px' }}>8,640</div>
        <div style={{ fontSize: 12, letterSpacing: '0.2em', color: B.muted, textTransform: 'uppercase', marginBottom: 36 }}>Current score</div>
        <button style={{ width: '100%', padding: 19, border: 'none', borderRadius: 4, background: B.ink, color: B.paper,
          fontFamily: B.serif, fontStyle: 'italic', fontSize: 19, letterSpacing: '0.06em' }}>Resume</button>
        <div style={{ display: 'flex', gap: 12, width: '100%', marginTop: 12 }}>
          {['Restart', 'Settings'].map((t) => (
            <button key={t} style={{ flex: 1, padding: 16, borderRadius: 4, background: 'transparent',
              border: `1px solid ${B.hair}`, color: B.ink, fontFamily: B.serif, fontSize: 16 }}>{t}</button>
          ))}
        </div>
        <button style={{ background: 'none', border: 'none', color: B.muted, fontFamily: B.serif, fontSize: 15,
          marginTop: 22, borderBottom: `1px solid ${B.hair}`, paddingBottom: 2 }}>Quit to menu</button>
      </div>
    </PhoneFrame>
  );
}

// ---- Settings ---------------------------------------------------------------
function B_Settings() {
  return (
    <PhoneFrame bg={B.paper} statusTone="dark">
      <PaperBG />
      <div style={{ position: 'absolute', inset: 0, padding: '72px 38px 36px', display: 'flex',
        flexDirection: 'column', fontFamily: B.serif, color: B.text }}>
        <h2 style={{ margin: 0, fontSize: 34, fontWeight: 400, fontStyle: 'italic', color: B.ink }}>Settings</h2>
        <div style={{ width: 56, height: 2, background: B.seal, margin: '14px 0 6px' }} />
        <div>
          <SettingRow label="Sound effects" sub="Slices, bombs, combos" control={<InkToggle on />} />
          <SettingRow label="Music" sub="Ambient oud loop" control={<InkToggle on={false} />} />
          <SettingRow label="Haptics" sub="Vibrate on slice & miss" control={<InkToggle on />} last />
        </div>
        <div style={{ marginTop: 30, padding: '18px 20px', borderRadius: 4, border: `1px solid ${B.hair}`,
          background: 'rgba(27,23,18,0.02)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontSize: 13, letterSpacing: '0.2em', color: B.muted, textTransform: 'uppercase' }}>Best score</span>
          <span style={{ fontSize: 26, color: B.ink }}>14,820</span>
        </div>
        <div style={{ flex: 1 }} />
        <div style={{ textAlign: 'center', fontSize: 12, color: B.muted, letterSpacing: '0.1em' }}>Alaif · v1.0 · made offline</div>
        <button style={{ width: '100%', padding: 18, border: 'none', borderRadius: 4, background: B.ink, color: B.paper,
          fontFamily: B.serif, fontStyle: 'italic', fontSize: 18, marginTop: 16 }}>Done</button>
      </div>
    </PhoneFrame>
  );
}

// ---- Alt app icons ----------------------------------------------------------
function B_IconStroke() {
  return (
    <IconTile size={168} bg="#EDE7D8" label="Icon · alif + cut">
      <Lattice stroke="rgba(27,23,18,0.06)" size={56} sw={1} />
      <Glyph letter="ا" size={128} fill="#1B1712" font='"Aref Ruqaa", serif' />
      <div style={{ position: 'absolute', left: '16%', right: '16%', top: '52%', height: 5,
        background: 'linear-gradient(90deg, transparent, #1B1712, transparent)', transform: 'rotate(-16deg)', borderRadius: 4 }} />
    </IconTile>
  );
}
function B_IconSeal() {
  return (
    <IconTile size={168} bg="#1B1712" label="Icon · ink ground">
      <Lattice stroke="rgba(237,231,216,0.07)" size={56} sw={1} />
      <Glyph letter="ا" size={128} fill="#EDE7D8" font='"Aref Ruqaa", serif' />
      <div style={{ position: 'absolute', right: 24, bottom: 24, width: 30, height: 30, borderRadius: 7,
        background: '#B23A2B', display: 'grid', placeItems: 'center' }}>
        <Glyph letter="✦" size={18} fill="#EDE7D8" />
      </div>
    </IconTile>
  );
}
function B_IconSealMark() {
  return (
    <IconTile size={168} bg="#B23A2B" label="Icon · seal">
      <div style={{ position: 'absolute', inset: 14, borderRadius: 22, border: '2px solid rgba(237,231,216,0.45)' }} />
      <Glyph letter="ا" size={120} fill="#EDE7D8" font='"Aref Ruqaa", serif' />
    </IconTile>
  );
}

// ---- Token board ------------------------------------------------------------
function Swatch({ name, hex, dark }) {
  return (
    <div style={{ width: 124 }}>
      <div style={{ height: 64, borderRadius: 6, background: hex, border: `1px solid ${B.hair}` }} />
      <div style={{ fontFamily: '"Space Grotesk", sans-serif', fontSize: 12, color: B.ink, marginTop: 7 }}>{name}</div>
      <div style={{ fontFamily: '"Space Grotesk", monospace', fontSize: 11, color: B.muted, letterSpacing: '0.04em' }}>{hex}</div>
    </div>
  );
}
function TypeRow({ role, spec, children }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 24, padding: '14px 0', borderBottom: `1px solid ${B.hair}` }}>
      <div style={{ width: 150, flex: '0 0 auto' }}>
        <div style={{ fontFamily: '"Space Grotesk", sans-serif', fontSize: 13, color: B.ink }}>{role}</div>
        <div style={{ fontFamily: '"Space Grotesk", monospace', fontSize: 11, color: B.muted }}>{spec}</div>
      </div>
      <div style={{ color: B.ink }}>{children}</div>
    </div>
  );
}
function B_Tokens() {
  return (
    <div style={{ width: '100%', minHeight: '100%', background: B.paper, padding: '34px 40px',
      display: 'flex', flexDirection: 'column', gap: 26 }}>
      <div>
        <div style={{ fontFamily: '"Space Grotesk", sans-serif', fontSize: 12, letterSpacing: '0.24em',
          textTransform: 'uppercase', color: B.muted }}>Ink &amp; Paper · tokens</div>
        <div style={{ fontFamily: B.serif, fontSize: 30, fontStyle: 'italic', color: B.ink, marginTop: 4 }}>Palette &amp; type</div>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 18 }}>
        <Swatch name="paper" hex="#EDE7D8" />
        <Swatch name="paperDeep" hex="#E4DCC8" />
        <Swatch name="ink" hex="#1B1712" />
        <Swatch name="inkSoft" hex="#2A251E" />
        <Swatch name="inkMuted" hex="#867C6C" />
        <Swatch name="seal" hex="#B23A2B" />
        <Swatch name="gold" hex="#A8842F" />
        <Swatch name="goldDust" hex="#C9A24B" />
      </div>
      <div>
        <TypeRow role="Display / title" spec="Spectral italic · 64">
          <span style={{ fontFamily: B.serif, fontStyle: 'italic', fontSize: 40 }}>Alaif</span></TypeRow>
        <TypeRow role="Glyph (Flame)" spec="Aref Ruqaa · 220">
          <span style={{ fontFamily: '"Aref Ruqaa", serif', fontSize: 46 }}>ع ل ف</span></TypeRow>
        <TypeRow role="Overlay heading" spec="Spectral italic · 32 / 500">
          <span style={{ fontFamily: B.serif, fontStyle: 'italic', fontSize: 26 }}>How to play</span></TypeRow>
        <TypeRow role="Score" spec="Spectral · 40 tabular">
          <span style={{ fontFamily: B.serif, fontSize: 32, fontVariantNumeric: 'tabular-nums' }}>14,820</span></TypeRow>
        <TypeRow role="Label / caption" spec="Spectral · 12 · 0.24em caps">
          <span style={{ fontFamily: B.serif, fontSize: 13, letterSpacing: '0.24em', textTransform: 'uppercase', color: B.muted }}>Best score</span></TypeRow>
        <TypeRow role="Combo callout" spec="Spectral italic · 20 · seal">
          <span style={{ fontFamily: B.serif, fontStyle: 'italic', fontSize: 20, color: B.seal }}>four in a row</span></TypeRow>
      </div>
    </div>
  );
}

Object.assign(window, { B_HowTo, B_Pause, B_Settings, B_IconStroke, B_IconSeal, B_IconSealMark, B_Tokens });
