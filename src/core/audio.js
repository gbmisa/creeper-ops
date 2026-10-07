// Procedural sound effects (WebAudio, no asset files). sfx(name, pos?) plays a short synth
// voice; per-name throttling stops 20 blasters turning into noise, and `pos` attenuates by
// distance from the listener (camera). Call unlockAudio() from any user gesture.

let ctx = null, master = null, noiseBuf = null;
const listener = { x: 0, y: 0, z: 0 };
const last = new Map();
let muted = false;

export function unlockAudio() {
  if (typeof AudioContext === 'undefined') return;
  if (!ctx) {
    ctx = new AudioContext();
    master = ctx.createGain();
    master.gain.value = 0.35;
    master.connect(ctx.destination);
    noiseBuf = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
    const d = noiseBuf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  }
  if (ctx.state === 'suspended') ctx.resume();
}

export function setListener(p) { listener.x = p.x; listener.y = p.y; listener.z = p.z; }
export function toggleMute() { muted = !muted; if (master) master.gain.value = muted ? 0 : 0.35; return muted; }

// name: [min seconds between plays, falloff distance (m), builder]
const VOICES = {
  blaster: [0.07, 70, (g, t) => tone(g, t, 'square', 1400, 500, 0.06, 0.12)],
  mortar: [0.15, 90, (g, t) => tone(g, t, 'sine', 160, 60, 0.2, 0.5)],
  boom: [0.1, 110, (g, t) => noise(g, t, 0.45, 600, 0.6)],
  rifle: [0.04, 0, (g, t) => { tone(g, t, 'sawtooth', 900, 120, 0.09, 0.3); noise(g, t, 0.06, 3000, 0.25); }],
  spray: [0.12, 0, (g, t) => noise(g, t, 0.14, 1800, 0.12)],
  hit: [0.05, 0, (g, t) => tone(g, t, 'triangle', 1800, 1200, 0.05, 0.25)],
  hurt: [0.25, 0, (g, t) => tone(g, t, 'sawtooth', 220, 90, 0.18, 0.3)],
  sizzle: [0.3, 0, (g, t) => noise(g, t, 0.3, 4000, 0.15)],
  build: [0.2, 120, (g, t) => { tone(g, t, 'sine', 520, 520, 0.08, 0.2); tone(g, t + 0.08, 'sine', 780, 780, 0.12, 0.2); }],
  lost: [0.3, 200, (g, t) => { tone(g, t, 'square', 330, 160, 0.3, 0.25); noise(g, t, 0.3, 800, 0.3); }],
  alarm: [2.5, 0, (g, t) => { tone(g, t, 'square', 880, 880, 0.12, 0.18); tone(g, t + 0.2, 'square', 660, 660, 0.12, 0.18); }],
  teleport: [0.5, 0, (g, t) => tone(g, t, 'sine', 200, 1600, 0.6, 0.35)],
  good: [0.4, 0, (g, t) => [523, 659, 784].forEach((f, i) => tone(g, t + i * 0.09, 'triangle', f, f, 0.25, 0.25))],
  click: [0.03, 0, (g, t) => tone(g, t, 'sine', 900, 700, 0.03, 0.15)],
  deny: [0.15, 0, (g, t) => tone(g, t, 'square', 180, 150, 0.12, 0.2)],
  unit: [0.1, 0, (g, t) => tone(g, t, 'triangle', 600, 900, 0.08, 0.2)],
  pop: [0.05, 60, (g, t) => tone(g, t, 'sine', 700, 200, 0.1, 0.3)],
};

export function sfx(name, pos) {
  if (!ctx || muted || ctx.state !== 'running') return;
  const v = VOICES[name];
  if (!v) return;
  const now = ctx.currentTime;
  if (now - (last.get(name) ?? -1) < v[0]) return;
  let vol = 1;
  if (pos && v[1] > 0) {
    const d = Math.hypot(pos.x - listener.x, pos.y - listener.y, pos.z - listener.z);
    vol = Math.max(0, 1 - d / v[1]);
    if (vol < 0.05) return;
  }
  last.set(name, now);
  const g = ctx.createGain();
  g.gain.value = vol;
  g.connect(master);
  v[2](g, now);
}

function tone(out, t, type, f0, f1, dur, vol) {
  const o = ctx.createOscillator(), g = ctx.createGain();
  o.type = type;
  o.frequency.setValueAtTime(f0, t);
  o.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + dur);
  g.gain.setValueAtTime(vol, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + dur);
  o.connect(g).connect(out);
  o.start(t);
  o.stop(t + dur + 0.02);
}

function noise(out, t, dur, cutoff, vol) {
  const s = ctx.createBufferSource(), f = ctx.createBiquadFilter(), g = ctx.createGain();
  s.buffer = noiseBuf;
  f.type = 'lowpass';
  f.frequency.value = cutoff;
  g.gain.setValueAtTime(vol, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + dur);
  s.connect(f).connect(g).connect(out);
  s.start(t, Math.random() * 0.5);
  s.stop(t + dur + 0.02);
}
