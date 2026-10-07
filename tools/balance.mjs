// Headless creeper balance check (no browser): node tools/balance.mjs "$(pwd)" [seconds]
// Prints coverage / key-cell depths over time plus an ASCII flood map (S = ship, # = Blight).
// No turrets: this is the "do nothing" pressure curve the player is racing against.
const root = process.argv[2];
const secs = Number(process.argv[3] ?? 900);
const { buildLevel01 } = await import(root + '/src/level/level01.js');
const { buildCave01 } = await import(root + '/src/level/cave01.js');
const { CreeperSim } = await import(root + '/src/sim/CreeperSim.js');
const L = buildLevel01(); const sim = new CreeperSim(L.grid);
for (const e of [...L.emitters, ...L.vents]) sim.addSource(e);
const g = L.grid;
const near = (p, r) => { let m = 0; g.forEachInRadius(p.x, p.z, r, (x, z) => { m = Math.max(m, sim.depthAt(x, z)); }); return m; };
const t0 = Date.now();
let shipWet = null;
for (let t = 0; t <= secs; t += 1) {
  sim.update(1);
  if (shipWet === null && near(L.ship, 1.5) > 0.06) shipWet = t;
  if (t % 120 === 0) console.log(`t=${t}s cov=${(sim.coverage() * 100).toFixed(0)}% ship=${near(L.ship, 1.5).toFixed(2)} ` +
    `rift=${near(L.rift, 1).toFixed(2)} spireRamp=${sim.depthAt(61, 34).toFixed(2)} ventSW=${near(L.vents[1], 3).toFixed(2)}`);
}
console.log(`ship first wet at t=${shipWet ?? 'never'}s; sim ms`, Date.now() - t0);
const ch = (x, z) => {
  if (Math.abs(x - L.ship.x) <= 1 && Math.abs(z - L.ship.z) <= 1) return 'S';
  const d = sim.depthAt(x, z);
  if (d > 3) return '@'; if (d > 1) return 'O'; if (d > 0.05) return 'o';
  return g.zone[g.idx(x, z)] ? '#' : String(Math.min(9, Math.round(g.heightAt(x, z))));
};
for (let z = 0; z < g.h; z += 2) { let r = ''; for (let x = 0; x < g.w; x++) r += ch(x, z); console.log(r); }

const C = buildCave01(); const cs = new CreeperSim(C.grid);
const src = cs.addSource({ ...C.core, ...C.coreSource, cap: C.coreSource.baseCap });
for (let t = 0; t <= 900; t++) {
  src.cap = C.coreSource.baseCap + t * C.coreSource.capGrowth;
  cs.update(1);
  if (t % 300 === 0) console.log(`cave t=${t} cov=${(cs.coverage() * 100).toFixed(0)}% pad=${cs.depthAt(C.pad.x, C.pad.z).toFixed(2)}`);
}
