// inkpaper-app.jsx — the full Ink & Paper reference canvas.
const { createRoot: createInkRoot } = ReactDOM;

function InkNote() {
  return (
    <div style={{ maxWidth: 780, padding: '8px 4px 4px', fontFamily: '"Space Grotesk", sans-serif', color: '#2a251e' }}>
      <div style={{ fontSize: 13, letterSpacing: '0.22em', textTransform: 'uppercase', color: 'rgba(60,50,40,0.5)' }}>Alaif · chosen direction</div>
      <h1 style={{ margin: '8px 0 10px', fontSize: 34, fontWeight: 700, letterSpacing: '-0.01em' }}>Ink &amp; Paper — full screen set</h1>
      <p style={{ margin: 0, fontSize: 15.5, lineHeight: 1.62, color: 'rgba(40,33,26,0.78)' }}>
        Black calligraphy on warm paper, a vermillion seal as the brand mark, ink-splatter cuts and gold-dust
        combos. <b>Spectral</b> for UI, <b>Aref Ruqaa</b> for the hero glyphs. This is the reference for M4
        (menus &amp; settings) and the look M3's juice should serve. The background flips from the current dark
        purple to paper — the glyphs become <b>ink</b>, the blade trail becomes a dark brush-stroke, cuts throw
        ink; combos sparkle gold. Tokens, theme, and the implementation spec ship alongside as Dart + Markdown.
      </p>
    </div>
  );
}

const PW = 340, PH = 736;
const AB = (id, label, node) => <DCArtboard id={id} label={label} width={PW} height={PH}>{node}</DCArtboard>;

function InkApp() {
  return (
    <DesignCanvas>
      <DCSection id="brief" title="Direction">
        <DCArtboard id="note" label="Read me" width={820} height={250}><InkNote /></DCArtboard>
        <DCArtboard id="tokens" label="Tokens" width={560} height={560}><B_Tokens /></DCArtboard>
      </DCSection>

      <DCSection id="flow" title="Screens" subtitle="Every surface M4 needs, plus the in-game HUD M3 dresses">
        {AB('s-menu', 'Main menu', <B_Menu />)}
        {AB('s-howto', 'How to play', <B_HowTo />)}
        {AB('s-game', 'In-game · the slice', <B_Game />)}
        {AB('s-pause', 'Pause', <B_Pause />)}
        {AB('s-over', 'Game over', <B_Over />)}
        {AB('s-settings', 'Settings', <B_Settings />)}
      </DCSection>

      <DCSection id="icons" title="App icon" subtitle="Three takes for the adaptive icon — pick one for M5">
        <DCArtboard id="ic1" label="alif + cut" width={236} height={260}>
          <div style={{ width: '100%', height: '100%', display: 'grid', placeItems: 'center' }}><B_IconStroke /></div></DCArtboard>
        <DCArtboard id="ic2" label="ink ground" width={236} height={260}>
          <div style={{ width: '100%', height: '100%', display: 'grid', placeItems: 'center' }}><B_IconSeal /></div></DCArtboard>
        <DCArtboard id="ic3" label="seal" width={236} height={260}>
          <div style={{ width: '100%', height: '100%', display: 'grid', placeItems: 'center' }}><B_IconSealMark /></div></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

createInkRoot(document.getElementById('root')).render(<InkApp />);
