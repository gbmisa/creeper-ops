// Heightfield fluid automaton (Creeper World style).
// Each cell holds a creeper depth. Every tick, creeper flows toward neighbours whose
// (terrain + creeper) "head" is lower, so it pools in basins and spills over ridges.

import { CREEPER } from '../core/config.js';

const NEIGHBOURS = [[1, 0], [-1, 0], [0, 1], [0, -1]];

export class CreeperSim {
  constructor(grid) {
    this.grid = grid;
    const n = grid.w * grid.h;
    this.depth = new Float32Array(n);
    this.delta = new Float32Array(n);
    this.sources = [];
    this.acc = 0;
    this.ticks = 0;
  }

  /** source: { x, z, amount, interval, active, cap? } (amount per pulse, interval seconds, optional max depth) */
  addSource(src) {
    const s = { timer: 0, active: true, ...src };
    this.sources.push(s);
    return s;
  }

  update(dt) {
    this.acc += dt;
    while (this.acc >= CREEPER.TICK) {
      this.acc -= CREEPER.TICK;
      this.emit(CREEPER.TICK);
      this.flow();
      this.ticks++;
    }
  }

  emit(dt) {
    for (const s of this.sources) {
      if (!s.active) continue;
      if (s.cap !== undefined && this.depthAt(s.x, s.z) >= s.cap) continue; // pressure-limited source
      s.timer += dt;
      if (s.timer >= s.interval) {
        s.timer -= s.interval;
        this.add(s.x, s.z, s.amount);
      }
    }
  }

  flow() {
    const { w, h, height } = this.grid;
    const depth = this.depth, delta = this.delta;
    delta.fill(0);
    const out = [0, 0, 0, 0];

    for (let z = 0; z < h; z++) {
      for (let x = 0; x < w; x++) {
        const i = z * w + x;
        const d = depth[i];
        if (d < 0.0005) continue;
        const head = height[i] + d;
        let total = 0;
        for (let k = 0; k < 4; k++) {
          const nx = x + NEIGHBOURS[k][0], nz = z + NEIGHBOURS[k][1];
          out[k] = 0;
          if (nx < 0 || nz < 0 || nx >= w || nz >= h) continue;
          const j = nz * w + nx;
          const diff = head - (height[j] + depth[j]);
          if (diff > 0) { out[k] = diff * CREEPER.FLOW_RATE; total += out[k]; }
        }
        if (total <= 0) continue;
        const scale = total > d ? d / total : 1;
        for (let k = 0; k < 4; k++) {
          if (out[k] <= 0) continue;
          const j = (z + NEIGHBOURS[k][1]) * w + (x + NEIGHBOURS[k][0]);
          const amt = out[k] * scale;
          delta[i] -= amt;
          delta[j] += amt;
        }
      }
    }

    for (let i = 0; i < depth.length; i++) {
      const v = depth[i] + delta[i];
      depth[i] = v < 0.0005 ? 0 : Math.min(v, CREEPER.MAX_DEPTH);
    }
  }

  depthAt(x, z) {
    if (!this.grid.inBounds(x, z)) return 0;
    return this.depth[this.grid.idx(x, z)];
  }

  add(x, z, amount) {
    if (!this.grid.inBounds(x, z)) return;
    const i = this.grid.idx(x, z);
    this.depth[i] = Math.min(this.depth[i] + amount, CREEPER.MAX_DEPTH);
  }

  /** Remove up to `amount` from one cell. Returns the amount actually removed. */
  remove(x, z, amount) {
    if (!this.grid.inBounds(x, z)) return 0;
    const i = this.grid.idx(x, z);
    const r = Math.min(this.depth[i], amount);
    this.depth[i] -= r;
    return r;
  }

  /** Remove creeper in a radius with linear falloff. */
  removeRadius(cx, cz, r, amount) {
    let removed = 0;
    this.grid.forEachInRadius(cx, cz, r, (x, z, dist) => {
      removed += this.remove(x, z, amount * (1 - dist / (r + 1)));
    });
    return removed;
  }

  /** Find the nearest wet cell within range; returns {x, z, d} or null. */
  nearestWet(cx, cz, range) {
    let best = null, bestDist = Infinity;
    this.grid.forEachInRadius(cx, cz, range, (x, z, dist) => {
      const d = this.depth[this.grid.idx(x, z)];
      if (d > CREEPER.MIN_DEPTH * 2 && dist < bestDist) { best = { x, z, d }; bestDist = dist; }
    });
    return best;
  }

  /** Deepest cell within range (mortars prefer big pools). */
  deepestWet(cx, cz, range) {
    let best = null;
    this.grid.forEachInRadius(cx, cz, range, (x, z) => {
      const d = this.depth[this.grid.idx(x, z)];
      if (d > CREEPER.MIN_DEPTH * 2 && (!best || d > best.d)) best = { x, z, d };
    });
    return best;
  }

  coverage() {
    let wet = 0;
    for (let i = 0; i < this.depth.length; i++) if (this.depth[i] > CREEPER.MIN_DEPTH) wet++;
    return wet / this.depth.length;
  }
}
