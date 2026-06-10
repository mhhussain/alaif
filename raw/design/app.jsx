// app.jsx — assemble the three directions on the design canvas.
const { createRoot } = ReactDOM;

function Note() {
  return (
    <div style={{ maxWidth: 760, padding: '8px 4px 4px', fontFamily: '"Space Grotesk", sans-serif', color: '#2b2620' }}>
      <div style={{ fontSize: 13, letterSpacing: '0.22em', textTransform: 'uppercase', color: 'rgba(60,50,40,0.5)' }}>Alaif · visual language</div>
      <h1 style={{ margin: '8px 0 10px', fontSize: 34, fontWeight: 700, letterSpacing: '-0.01em' }}>Three directions to slice into</h1>
      <p style={{ margin: 0, fontSize: 15.5, lineHeight: 1.62, color: 'rgba(40,33,26,0.78)' }}>
        All three share the brief's DNA: a flowing calligraphic hero glyph (<b>Aref Ruqaa</b>), a clean geometric
        girih lattice, white-hot blade trails, and the three cut/combo feedbacks you picked — <b>ink-splatter cuts,
        gold-dust bursts, white-hot fringe</b>. Each screen is real, portrait, and offline-friendly (cheap CSS
        gradients + cached glyphs, no per-frame blur). Pick one — or hybridise — and I'll generate the
        <b> design_tokens.dart</b> file plus a short spec for the repo.
      </p>
      <div style={{ display: 'flex', gap: 22, marginTop: 16, flexWrap: 'wrap', fontSize: 13.5, color: 'rgba(40,33,26,0.72)' }}>
        <span><b style={{ color: '#0B0D12' }}>A · Girih Noir</b> — cool, surgical, esports-clean. White glyphs, cyan glow.</span>
        <span><b style={{ color: '#B23A2B' }}>B · Ink &amp; Paper</b> — light, minimal, gallery-like. Black ink, seal-red.</span>
        <span><b style={{ color: '#C9881C' }}>C · Molten Manuscript</b> — warm premium. Molten-gold glyphs, gold frame.</span>
      </div>
    </div>
  );
}

const PHONE_W = 340, PHONE_H = 736;

function Direction({ id, title, subtitle, screens, icon }) {
  return (
    <DCSection id={id} title={title} subtitle={subtitle}>
      <DCArtboard id={`${id}-menu`} label="Main menu" width={PHONE_W} height={PHONE_H}>{screens.menu}</DCArtboard>
      <DCArtboard id={`${id}-game`} label="In-game · the slice" width={PHONE_W} height={PHONE_H}>{screens.game}</DCArtboard>
      <DCArtboard id={`${id}-over`} label="Game over" width={PHONE_W} height={PHONE_H}>{screens.over}</DCArtboard>
      <DCArtboard id={`${id}-icon`} label="App icon" width={236} height={260}>
        <div style={{ width: '100%', height: '100%', display: 'grid', placeItems: 'center' }}>{icon}</div>
      </DCArtboard>
    </DCSection>
  );
}

function App() {
  return (
    <DesignCanvas>
      <DCSection id="intro" title="Brief">
        <DCArtboard id="note" label="Read me" width={800} height={290}><Note /></DCArtboard>
      </DCSection>
      <Direction id="A" title="A · Girih Noir" subtitle="Cool & surgical — white-hot glyphs, cyan glow, geometric lattice"
        screens={{ menu: <A_Menu />, game: <A_Game />, over: <A_Over /> }} icon={<A_Icon />} />
      <Direction id="B" title="B · Ink & Paper" subtitle="Light & minimal — black calligraphy on warm paper, seal-red accent"
        screens={{ menu: <B_Menu />, game: <B_Game />, over: <B_Over /> }} icon={<B_Icon />} />
      <Direction id="C" title="C · Molten Manuscript" subtitle="Warm & premium — molten-gold glyphs, thin gold framing, teal accent"
        screens={{ menu: <C_Menu />, game: <C_Game />, over: <C_Over /> }} icon={<C_Icon />} />
    </DesignCanvas>
  );
}

createRoot(document.getElementById('root')).render(<App />);
