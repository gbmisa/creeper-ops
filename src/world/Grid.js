// Heightfield grid shared by terrain rendering, creeper sim, structures, units and the operative.
// Cell (x, z) has its centre at world ((x + .5) * CELL, height * LEVEL_H, (z + .5) * CELL).
// The rendered terrain passes through every cell centre, so smoothY() matches what you see.

import { WORLD } from '../core/config.js';

export const ZONE = { NONE: 0, BLIGHT: 1 }; // BLIGHT = agent-only: nothing can be built there

export class Grid {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.height = new Float32Array(w * h);  // terrain level per cell (fractional is fine)
    this.blocked = new Uint8Array(w * h);   // 1 = no building here (hazard footprint)
    this.zone = new Uint8Array(w * h);      // ZONE.* per cell
  }

  idx(x, z) { return z * this.w + x; }
  inBounds(x, z) { return x >= 0 && z >= 0 && x < this.w && z < this.h; }

  heightAt(x, z) {
    if (!this.inBounds(x, z)) return 99; // map edge acts as a wall
    return this.height[this.idx(x, z)];
  }

  setHeight(x, z, v) { if (this.inBounds(x, z)) this.height[this.idx(x, z)] = v; }
  zoneAt(x, z) { return this.inBounds(x, z) ? this.zone[this.idx(x, z)] : ZONE.NONE; }

  worldToCell(wx, wz) {
    return { x: Math.floor(wx / WORLD.CELL), z: Math.floor(wz / WORLD.CELL) };
  }

  cellCenter(x, z) {
    return {
      x: (x + 0.5) * WORLD.CELL,
      y: this.heightAt(x, z) * WORLD.LEVEL_H,
      z: (z + 0.5) * WORLD.CELL,
    };
  }

  /** Clamped cell height (no wall at the edge) for interpolation. */
  hClamped(x, z) {
    x = Math.max(0, Math.min(this.w - 1, x));
    z = Math.max(0, Math.min(this.h - 1, z));
    return this.height[z * this.w + x];
  }

  /** Smooth ground height in world units: bilinear between cell centres (matches the mesh). */
  smoothY(wx, wz) {
    const fx = wx / WORLD.CELL - 0.5, fz = wz / WORLD.CELL - 0.5;
    const x0 = Math.floor(fx), z0 = Math.floor(fz);
    const tx = fx - x0, tz = fz - z0;
    const a = this.hClamped(x0, z0), b = this.hClamped(x0 + 1, z0);
    const c = this.hClamped(x0, z0 + 1), d = this.hClamped(x0 + 1, z0 + 1);
    return ((a + (b - a) * tx) * (1 - tz) + (c + (d - c) * tx) * tz) * WORLD.LEVEL_H;
  }

  /** Stepped ground height (cell under the point). */
  groundY(wx, wz) {
    const c = this.worldToCell(wx, wz);
    return this.heightAt(c.x, c.z) * WORLD.LEVEL_H;
  }

  /** Iterate cells within a radius (in cells) of a centre cell. */
  forEachInRadius(cx, cz, r, fn) {
    const r2 = r * r;
    const ri = Math.ceil(r);
    for (let dz = -ri; dz <= ri; dz++) {
      for (let dx = -ri; dx <= ri; dx++) {
        const d2 = dx * dx + dz * dz;
        if (d2 > r2) continue;
        const x = cx + dx, z = cz + dz;
        if (this.inBounds(x, z)) fn(x, z, Math.sqrt(d2));
      }
    }
  }

  get worldWidth() { return this.w * WORLD.CELL; }
  get worldDepth() { return this.h * WORLD.CELL; }
}
