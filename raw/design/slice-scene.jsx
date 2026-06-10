// slice-scene.jsx — animated "slice in motion" reference for M3 juice.
// Drives off useTime(); every phase is annotated with the AlaifMotion token
// it maps to. Reuses Glyph from frame.jsx (window). Loads after animations.jsx.

const INK_GRAD = 'linear-gradient(180deg, #2C2720 0%, #14110B 100%)';
const PAPER = '#EDE7D8', INK = '#1B1712', SEAL = '#B23A2B', GOLD = '#A8842F', GOLD_DUST = '#C9A24B', MUTED = '#867C6C';
const { easeOutQuad, easeInQuad, easeOutCubic, easeOutBack } = Easing;

// deterministic rng
function rng(seed) { let s = seed >>> 0; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }

// ---- arc + half kinematics --------------------------------------------------
const G = 900; // px/s^2, scene gravity (visual only)

function arcPos(L, t) {
  const x = interpolate([0, 2.6], [L.x0, L.x0 + L.drift])(t);
  const y = interpolate([0, L.apexT, 2.8], [820, L.apexY, 900], [easeOutQuad, easeInQuad])(t);
  return { x, y };
}

// ---- particles --------------------------------------------------------------
function makeBurst(cx, cy, cut, opts) {
  const r = rng(opts.seed);
  const out = [];
  for (let i = 0; i < opts.count; i++) {
    const ang = opts.angBase + (r() - 0.5) * opts.spread;
    out.push({
      cx, cy, cut, ang,
      spd: opts.spdMin + r() * (opts.spdMax - opts.spdMin),
      size: opts.sizeMin + r() * (opts.sizeMax - opts.sizeMin),
      life: opts.life * (0.7 + r() * 0.5),
      grav: opts.grav, kind: opts.kind,
    });
  }
  return out;
}
function Particle({ p, t }) {
  const dt = t - p.cut;
  if (dt < 0 || dt > p.life) return null;
  const x = p.cx + Math.cos(p.ang) * p.spd * dt;
  const y = p.cy + Math.sin(p.ang) * p.spd * dt + 0.5 * p.grav * dt * dt;
  const op = Math.max(0, 1 - dt / p.life);
  const isGold = p.kind === 'gold';
  return <div style={{
    position: 'absolute', left: x, top: y, width: p.size, height: p.size, borderRadius: '50%',
    background: isGold ? GOLD_DUST : INK,
    opacity: isGold ? op : op * 0.9,
    filter: isGold ? `drop-shadow(0 0 ${p.size}px rgba(201,162,75,0.8))` : 'none',
    transform: 'translate(-50%,-50%)',
  }} />;
}

// ---- a glyph half (clipped + transformed) -----------------------------------
function Half({ ch, size, x, y, rot, op, which }) {
  const clip = which === 'top'
    ? 'polygon(-40% -40%, 140% -40%, -40% 140%)'
    : 'polygon(140% -40%, 140% 140%, -40% 140%)';
  return (
    <div style={{ position: 'absolute', left: x, top: y, width: size, height: size,
      transform: `translate(-50%,-50%) rotate(${rot}deg)`, opacity: op,
      clipPath: clip, display: 'grid', placeItems: 'center', pointerEvents: 'none' }}>
      <Glyph letter={ch} size={size * 0.92} gradient={INK_GRAD} font='"Aref Ruqaa", serif' />
    </div>
  );
}

// ---- the letters ------------------------------------------------------------
const LETTERS = [
  { ch: 'ع', x0: 150, drift: 30, apexT: 1.18, apexY: 320, cut: 1.18, seed: 7 },
  { ch: 'ل', x0: 256, drift: -26, apexT: 1.30, apexY: 300, cut: 1.32, seed: 23 },
];
// precompute bursts at each cut position
const SCENE = LETTERS.map((L) => {
  const p = arcPos(L, L.cut);
  return {
    L, cx: p.x, cy: p.y,
    ink: makeBurst(p.x, p.y, L.cut, { count: 14, kind: 'ink', angBase: -Math.PI / 2,
      spread: Math.PI * 1.6, spdMin: 120, spdMax: 360, sizeMin: 3, sizeMax: 8, life: 0.52, grav: G, seed: L.seed }),
  };
});
const COMBO_AT = LETTERS[1].cut;
const GOLD_BURST = makeBurst(SCENE[1].cx, SCENE[1].cy - 10, COMBO_AT, {
  count: 18, kind: 'gold', angBase: -Math.PI / 2, spread: Math.PI * 1.8,
  spdMin: 90, spdMax: 300, sizeMin: 2, sizeMax: 5, life: 0.6, grav: G * 0.5, seed: 99 });

// ---- phase caption ----------------------------------------------------------
function phaseFor(t) {
  if (t < 1.0) return ['00 · launch', 'letters rise on a gravity arc · GlyphAtlas textures'];
  if (t < LETTERS[0].cut) return ['01 · swipe', 'brush-ink blade · bladeRetentionMs 110 · bladeWidth 7→1.5'];
  if (t < COMBO_AT + 0.05) return ['02 · cut', 'ink splatter · cutInkParticles 14 · life 520ms'];
  if (t < COMBO_AT + 0.6) return ['03 · combo', '×2 in one swipe · comboDustParticles 18 · flash 600ms · +score pop 220ms'];
  return ['04 · settle', 'halves tumble off · cutHalfTumbleMs 900'];
}

// ---- the scene --------------------------------------------------------------
function SliceScene() {
  const t = useTime();

  // blade swipe path reveal 1.0 → 1.35, fade 1.4 → 1.7
  const reveal = animate({ from: 0, to: 1, start: 1.0, end: 1.36, ease: easeOutQuad })(t);
  const bladeFade = animate({ from: 1, to: 0, start: 1.4, end: 1.75, ease: easeOutQuad })(t);
  const DASH = 760;

  // combo callout + score pop
  const comboIn = animate({ from: 0, to: 1, start: COMBO_AT, end: COMBO_AT + 0.18, ease: easeOutBack })(t);
  const comboOut = animate({ from: 1, to: 0, start: COMBO_AT + 0.45, end: COMBO_AT + 0.6, ease: easeOutQuad })(t);
  const comboOp = Math.min(comboIn, comboOut);
  const popY = animate({ from: 0, to: -54, start: COMBO_AT, end: COMBO_AT + 0.7, ease: easeOutCubic })(t);
  const popOp = animate({ from: 0, to: 1, start: COMBO_AT, end: COMBO_AT + 0.22 })(t)
              * animate({ from: 1, to: 0, start: COMBO_AT + 0.45, end: COMBO_AT + 0.7 })(t);
  const score = t >= COMBO_AT ? '8,640' : (t >= LETTERS[0].cut ? '8,620' : '8,600');

  const [ph, phSub] = phaseFor(t);

  return (
    <div style={{ position: 'absolute', inset: 0, background:
      `radial-gradient(120% 90% at 50% 12%, ${PAPER}, #E4DCC8)`, overflow: 'hidden' }}>
      {/* lattice */}
      <div style={{ position: 'absolute', inset: 0, opacity: 0.8,
        backgroundImage: latticeURL('rgba(27,23,18,0.05)', 1), backgroundSize: '74px 74px' }} />

      {/* HUD */}
      <div style={{ position: 'absolute', top: 30, left: 28, right: 28, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontFamily: 'Spectral, serif', fontSize: 11, letterSpacing: '0.26em', color: MUTED, textTransform: 'uppercase' }}>Score</div>
          <div style={{ fontFamily: 'Spectral, serif', fontSize: 40, color: INK, lineHeight: 1, fontVariantNumeric: 'tabular-nums' }}>{score}</div>
        </div>
        <div style={{ display: 'flex', gap: 7, marginTop: 8 }}>
          {[1, 1, 0].map((on, i) => <div key={i} style={{ width: 14, height: 14, borderRadius: '50%',
            background: on ? INK : 'transparent', border: `1.5px solid ${on ? INK : 'rgba(27,23,18,0.3)'}` }} />)}
        </div>
      </div>

      {/* phase caption */}
      <div style={{ position: 'absolute', left: 28, bottom: 26, fontFamily: 'ui-monospace, monospace' }}>
        <div style={{ fontSize: 12, letterSpacing: '0.18em', color: SEAL, textTransform: 'uppercase' }}>{ph}</div>
        <div style={{ fontSize: 11, color: MUTED, marginTop: 3, maxWidth: 320 }}>{phSub}</div>
      </div>

      {/* whole letters (pre-cut) */}
      {LETTERS.map((L, i) => {
        if (t >= L.cut) return null;
        const p = arcPos(L, t);
        const rot = interpolate([0, 2.6], [L.x0 > 200 ? 16 : -14, L.x0 > 200 ? -10 : 22])(t);
        return <div key={i} style={{ position: 'absolute', left: p.x, top: p.y, transform: `translate(-50%,-50%) rotate(${rot}deg)` }}>
          <Glyph letter={L.ch} size={112} gradient={INK_GRAD} font='"Aref Ruqaa", serif'
            glow="drop-shadow(0 2px 1px rgba(27,23,18,0.18))" />
        </div>;
      })}

      {/* halves (post-cut) */}
      {SCENE.map(({ L, cx, cy }, i) => {
        if (t < L.cut) return null;
        const dt = t - L.cut;
        const op = Math.max(0, 1 - dt / 0.9);
        const yTop = cy - 70 * dt + 0.5 * G * dt * dt;
        const yBot = cy - 40 * dt + 0.5 * G * dt * dt;
        return <React.Fragment key={i}>
          <Half ch={L.ch} size={112} x={cx - 60 * dt} y={yTop} rot={-160 * dt} op={op} which="top" />
          <Half ch={L.ch} size={112} x={cx + 70 * dt} y={yBot} rot={150 * dt} op={op} which="bot" />
        </React.Fragment>;
      })}

      {/* ink splatter */}
      {SCENE.flatMap((s, i) => s.ink.map((p, j) => <Particle key={`ink${i}-${j}`} p={p} t={t} />))}
      {/* gold dust (combo) */}
      {GOLD_BURST.map((p, j) => <Particle key={`g${j}`} p={p} t={t} />)}

      {/* blade swipe */}
      <svg style={{ position: 'absolute', inset: 0 }} width="100%" height="100%">
        <defs>
          <linearGradient id="sBlade" x1="0" y1="1" x2="1" y2="0">
            <stop offset="0" stopColor={INK} stopOpacity="0" />
            <stop offset="0.55" stopColor={INK} stopOpacity="0.85" />
            <stop offset="1" stopColor={INK} stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d="M40 520 Q 200 360 350 280" fill="none" stroke="url(#sBlade)" strokeWidth="8"
          strokeLinecap="round" opacity={bladeFade}
          strokeDasharray={DASH} strokeDashoffset={DASH * (1 - reveal)}
          style={{ filter: 'drop-shadow(0 1px 2px rgba(27,23,18,0.35))' }} />
      </svg>

      {/* combo callout + score pop */}
      {comboOp > 0.01 && (
        <div style={{ position: 'absolute', left: 0, right: 0, top: 150, textAlign: 'center',
          opacity: comboOp, transform: `scale(${0.9 + comboIn * 0.1})` }}>
          <span style={{ fontFamily: 'Spectral, serif', fontStyle: 'italic', fontSize: 30, color: SEAL }}>×2 — twice over</span>
        </div>
      )}
      {popOp > 0.01 && (
        <div style={{ position: 'absolute', left: SCENE[1].cx, top: SCENE[1].cy - 70,
          transform: `translate(-50%, ${popY}px)`, opacity: popOp,
          fontFamily: 'Spectral, serif', fontStyle: 'italic', fontSize: 26, color: GOLD }}>+40</div>
      )}
    </div>
  );
}

Object.assign(window, { SliceScene });
