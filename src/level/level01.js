// Level 01 "Hollow Ridge" — surface layout. See docs/LEVEL01_DESIGN.md for the intent.
// Everything here is data + a few shaping helpers so new levels can copy this file.
// Designed for BOTH modes: turret-reachable lowlands, plus Blight zones (no building) that
// only the Operative and barracks units can enter.

import { Grid, ZONE } from '../world/Grid.js';
import { makeNoise } from '../world/noise.js';

const W = 80, H = 80;

// ---- shaping helpers -------------------------------------------------------
function disc(grid, cx, cz, r, fn) { grid.forEachInRadius(cx, cz, r, (x, z, d) => fn(x, z, d)); }
function rect(grid, x0, z0, x1, z1, fn) {
  for (let z = z0; z <= z1; z++) for (let x = x0; x <= x1; x++) if (grid.inBounds(x, z)) fn(x, z);
}
const smoothstep = (a, b, t) => { const k = Math.max(0, Math.min(1, (t - a) / (b - a))); return k * k * (3 - 2 * k); };
function blight(grid, cx, cz, r) { disc(grid, cx, cz, r, (x, z) => { grid.zone[grid.idx(x, z)] = ZONE.BLIGHT; }); }
/** Bowl: floor at `floor` inside r0, blending back to existing ground by r1. */
function bowl(grid, cx, cz, r0, r1, floor) {
  disc(grid, cx, cz, r1, (x, z, d) => grid.setHeight(x, z, floor + (grid.heightAt(x, z) - floor) * smoothstep(r0, r1, d)));
}
function mesa(grid, cx, cz, r0, r1, top) {
  disc(grid, cx, cz, r1, (x, z, d) => grid.setHeight(x, z, Math.max(grid.heightAt(x, z), top - (top - grid.heightAt(x, z)) * smoothstep(r0, r1, d))));
}

export function buildLevel01() {
  const grid = new Grid(W, H);
  const noise = makeNoise(7);

  // Rolling lowland (continuous heights, ~1..3.5) with a shallow valley snaking west->east.
  for (let z = 0; z < H; z++) {
    for (let x = 0; x < W; x++) {
      const n = noise(x / 16, z / 16, 4);
      const valley = Math.exp(-(((z - 30 - Math.sin(x / 9) * 4) / 6) ** 2)) * 1.6;
      grid.setHeight(x, z, Math.max(0.3, 1.1 + n * 2.6 - valley));
    }
  }

  // Command ship mesa (south centre) with a long gentle ramp north for vehicles.
  mesa(grid, 40, 66, 6.5, 11, 3.5);
  rect(grid, 38, 50, 42, 58, (x, z) => grid.setHeight(x, z, Math.max(grid.heightAt(x, z), 2 + (z - 50) * 0.25)));

  // West ridge shields the mesa from the Rift basin; gap at x 27-29 makes a choke.
  rect(grid, 12, 52, 34, 53, (x, z) => { if (x < 27 || x > 29) grid.setHeight(x, z, 4.2 + noise(x / 3, z) * 0.8); });

  // NW emitter basin.
  bowl(grid, 14, 12, 4, 9, 0);

  // Rift hollow (cave mouth) — west. The Rift sits on a small rock so it floods last.
  bowl(grid, 14, 42, 3.5, 8, 0.2);
  disc(grid, 14, 42, 1.6, (x, z) => grid.setHeight(x, z, 2.2));
  blight(grid, 12, 41, 7);

  // NE "Spire Heights": sheer plateau, Blight on top, one 0.5/cell ramp heading south.
  rect(grid, 54, 3, 73, 19, (x, z) => {
    const edge = Math.min(x - 54, 73 - x, z - 3, 19 - z);
    grid.setHeight(x, z, edge < 1 ? 6 + noise(x, z) * 2 : 9 + noise(x / 4, z / 4) * 0.6);
  });
  rect(grid, 60, 17, 62, 19, (x, z) => grid.setHeight(x, z, 9)); // ramp cuts through the rim
  for (let z = 20; z <= 34; z++) {
    const h = 9 - (z - 19) * 0.5; // walkable for Soldiers, Crawlers and the Operative
    rect(grid, 60, z, 62, z, (x) => grid.setHeight(x, z, Math.max(h, grid.heightAt(x, z))));
    for (const x of [59, 63]) grid.setHeight(x, z, Math.min(grid.heightAt(x, z), Math.max(1, h - 3)));
  }
  rect(grid, 54, 3, 73, 19, (x, z) => { grid.zone[grid.idx(x, z)] = ZONE.BLIGHT; });

  // Central Blight knoll with a nest: overlooks the valley, units' first real fight.
  mesa(grid, 40, 24, 3, 7, 4.5);
  blight(grid, 40, 24, 5);

  // East emitter shelf.
  mesa(grid, 68, 50, 4, 7, 3);

  const level = {
    name: 'Hollow Ridge',
    grid,
    ship: { x: 40, z: 66 },
    emitters: [
      { id: 'e1', name: 'Emitter NW', x: 14, z: 12, amount: 4, interval: 1.5 },
      { id: 'e2', name: 'Emitter East', x: 68, z: 50, amount: 4, interval: 1.5, shieldedBy: 'core',
        shieldHint: 'Its shield is powered from underground: send the Operative into the Rift and destroy the Deep Core.' },
    ],
    vents: [ // fed by the Deep Core, shut off when it dies
      { x: 24, z: 36, amount: 1.6, interval: 3 },
      { x: 18, z: 58, amount: 1.4, interval: 3 },
    ],
    nests: [
      { name: 'Rift', x: 9, z: 38 },
      { name: 'Spire Heights', x: 59, z: 13 },
      { name: 'Central knoll', x: 40, z: 23 },
    ],
    spire: { x: 66, z: 9 },
    rift: { x: 14, z: 42 },
    intro: [
      ['Ops: Command ship on station over Hollow Ridge. Creeper is surfacing everywhere.', 'radio'],
      ['Ops: Everything runs on energy packets. Collectors (1) claim land; Relays (2) carry packets to the front.', 'radio'],
      ['Ops: Blasters (5) need ammo packets to fire. Cut the network and they go silent.', 'radio'],
      ['Ops: Purple Blight can\'t be built on. Train units at a Barracks (7) or drop the Operative (Beacon 8, then T).', 'radio'],
    ],
  };

  // Keep hazard cells clear of construction
  for (const p of [...level.emitters, ...level.vents, level.spire, level.rift, ...level.nests]) {
    disc(grid, p.x, p.z, 1.5, (x, z) => { grid.blocked[grid.idx(x, z)] = 1; });
  }
  level.keepClear = (x, z) => Math.hypot(x - level.ship.x, z - level.ship.z) < 4;
  return level;
}
