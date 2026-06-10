// store.jsx — App/Play Store marketing screenshots, Ink & Paper.
// Reuses B_* screens (directionB.jsx + inkpaper-extra.jsx) inside device bezels.
const { createRoot: createStoreRoot } = ReactDOM;
const SB = window.B; // ink & paper palette

function DeviceShot({ children, scale = 0.66, top = 0 }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'center' }}>
      <div style={{ transform: `scale(${scale})`, transformOrigin: 'top center', marginTop: top,
        padding: 7, background: '#0E0C0A', borderRadius: 52,
        boxShadow: '0 24px 50px rgba(20,15,10,0.35)' }}>
        <div style={{ borderRadius: 45, overflow: 'hidden' }}>{children}</div>
      </div>
    </div>
  );
}

function StorePanel({ bg, headline, sub, accent, children, scale, top }) {
  const onDark = bg === SB.ink || bg === SB.seal;
  const headColor = onDark ? '#F3EEE2' : SB.ink;
  const subColor = onDark ? 'rgba(243,238,226,0.7)' : SB.muted;
  return (
    <div style={{ width: 320, height: 692, background: bg, borderRadius: 14, overflow: 'hidden',
      position: 'relative', boxShadow: '0 1px 0 rgba(255,255,255,0.04) inset' }}>
      {/* faint lattice texture */}
      <div style={{ position: 'absolute', inset: 0, opacity: onDark ? 0.06 : 0.05,
        backgroundImage: latticeURL(onDark ? 'rgba(243,238,226,0.5)' : 'rgba(27,23,18,0.5)', 1),
        backgroundSize: '70px 70px' }} />
      <div style={{ position: 'relative', padding: '40px 30px 0', textAlign: 'center',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
        <div style={{ width: 34, height: 3, background: accent || SB.seal, marginBottom: 4 }} />
        <h2 style={{ fontFamily: SB.serif, fontStyle: 'italic', fontWeight: 400, fontSize: 26,
          lineHeight: 1.14, color: headColor, margin: 0, maxWidth: 256 }}>{headline}</h2>
        {sub && <p style={{ fontFamily: SB.serif, fontSize: 14, color: subColor, margin: 0, maxWidth: 240, lineHeight: 1.45 }}>{sub}</p>}
      </div>
      <DeviceShot scale={scale} top={top}>{children}</DeviceShot>
    </div>
  );
}

function StoreNote() {
  return (
    <div style={{ maxWidth: 760, padding: '8px 4px 4px', fontFamily: '"Space Grotesk", sans-serif', color: '#2a251e' }}>
      <div style={{ fontSize: 13, letterSpacing: '0.22em', textTransform: 'uppercase', color: 'rgba(60,50,40,0.5)' }}>Alaif · M5 store prep</div>
      <h1 style={{ margin: '8px 0 10px', fontSize: 32, fontWeight: 700 }}>Store screenshots</h1>
      <p style={{ margin: 0, fontSize: 15, lineHeight: 1.6, color: 'rgba(40,33,26,0.78)' }}>
        Five marketing panels for the App Store / Play listing — caption + framed device, in the Ink &amp; Paper
        language. Each is a 320×692 display proxy; for submission, re-render the phone at the store's required
        portrait size (e.g. 1290×2796 for iPhone 6.7″, 1242×2208 for older) and export at 1×/2×. Copy is a
        starting point — tune for ASO.
      </p>
    </div>
  );
}

function StoreApp() {
  return (
    <DesignCanvas>
      <DCSection id="m5" title="Marketing">
        <DCArtboard id="note" label="Read me" width={800} height={210}><StoreNote /></DCArtboard>
      </DCSection>
      <DCSection id="panels" title="Store panels" subtitle="Caption + device · alternating paper / ink / seal grounds">
        <DCArtboard id="p1" label="1 · Hero" width={320} height={692}>
          <StorePanel bg={SB.paper} headline="Slice the falling script."
            sub="A calligrapher's blade game. Pure reflex, no rules to read." scale={0.62} top={26}>
            <B_Menu /></StorePanel>
        </DCArtboard>
        <DCArtboard id="p2" label="2 · Combo" width={320} height={692}>
          <StorePanel bg={SB.ink} headline="One swipe. Many letters."
            sub="Chain three or more in a single stroke for the gold." accent={SB.goldDust} scale={0.62} top={26}>
            <B_Game /></StorePanel>
        </DCArtboard>
        <DCArtboard id="p3" label="3 · How to play" width={320} height={692}>
          <StorePanel bg={SB.paper} headline="Easy to learn. Hard to master."
            sub="Swipe, combo, and keep your three lives." scale={0.62} top={26}>
            <B_HowTo /></StorePanel>
        </DCArtboard>
        <DCArtboard id="p4" label="4 · Bombs" width={320} height={692}>
          <StorePanel bg={SB.seal} headline="Mind the bombs."
            sub="One wrong cut and a life is gone." accent="#F3EEE2" scale={0.62} top={26}>
            <B_Over /></StorePanel>
        </DCArtboard>
        <DCArtboard id="p5" label="5 · Offline" width={320} height={692}>
          <StorePanel bg={SB.ink} headline="Beautifully offline."
            sub="No accounts, no ads, no network. Just ink and paper." accent={SB.goldDust} scale={0.62} top={26}>
            <B_Settings /></StorePanel>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

createStoreRoot(document.getElementById('root')).render(<StoreApp />);
