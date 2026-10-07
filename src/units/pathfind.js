// A* over the terrain grid (8-way, no corner cutting). Movement limits come from the unit def:
// `climb` (max rise between neighbours) and `drop` (max fall). Creeper adds cost so units route
// around pools when they can. Returns world-space waypoints, string-pulled where walkable.

import { WORLD } from '../core/config.js';

const DIRS = [[1, 0, 1], [-1, 0, 1], [0, 1, 1], [0, -1, 1], [1, 1, 1.414], [1, -1, 1.414], [-1, 1, 1.414], [-1, -1, 1.414]];

class Heap {
  constructor() { this.a = []; }
  push(n, f) {
    const a = this.a; a.push([f, n]);
    let i = a.length - 1;
    while (i > 0) { const p = (i - 1) >> 1; if (a[p][0] <= a[i][0]) break; [a[p], a[i]] = [a[i], a[p]]; i = p; }
  }
  pop() {
    const a = this.a, top = a[0], last = a.pop();
    if (a.length) {
      a[0] = last;
      let i = 0;
      for (;;) {
        const l = i * 2 + 1, r = l + 1;
        let m = i;
        if (l < a.length && a[l][0] < a[m][0]) m = l;
        if (r < a.length && a[r][0] < a[m][0]) m = r;
        if (m === i) break;
        [a[m], a[i]] = [a[i], a[m]]; i = m;
      }
    }
    return top[1];
  }
  get size() { return this.a.length; }
}

export function stepOk(grid, ax, az, bx, bz, def) {
  if (!grid.inBounds(bx, bz)) return false;
  const d = grid.heightAt(bx, bz) - grid.heightAt(ax, az);
  return d <= def.climb && -d <= def.drop;
}

/** Nearest reachable-looking cell to (x, z) if the goal itself is a wall. */
function nearestOpen(grid, x, z, from, def) {
  if (grid.inBounds(x, z) && Math.abs(grid.heightAt(x, z) - grid.heightAt(from.x, from.z)) < 30) return { x, z };
  return { x: Math.max(0, Math.min(grid.w - 1, x)), z: Math.max(0, Math.min(grid.h - 1, z)) };
}

export function findPath(grid, creeper, start, goal, def, maxNodes = 6000) {
  goal = nearestOpen(grid, goal.x, goal.z, start, def);
  const W = grid.w, n = W * grid.h;
  const g = new Float32Array(n).fill(Infinity);
  const came = new Int32Array(n).fill(-1);
  const s = start.z * W + start.x, t = goal.z * W + goal.x;
  const h = (i) => Math.hypot((i % W) - goal.x, Math.floor(i / W) - goal.z);
  const open = new Heap();
  g[s] = 0;
  open.push(s, h(s));
  let best = s, bestH = h(s), visited = 0;

  while (open.size && visited++ < maxNodes) {
    const cur = open.pop();
    if (cur === t) { best = t; break; }
    const cx = cur % W, cz = Math.floor(cur / W);
    for (const [dx, dz, cost] of DIRS) {
      const nx = cx + dx, nz = cz + dz;
      if (!stepOk(grid, cx, cz, nx, nz, def)) continue;
      if (dx && dz && (!stepOk(grid, cx, cz, cx + dx, cz, def) || !stepOk(grid, cx, cz, cx, cz + dz, def))) continue;
      const j = nz * W + nx;
      const ng = g[cur] + cost + creeper.depth[j] * 4;
      if (ng >= g[j]) continue;
      g[j] = ng;
      came[j] = cur;
      const hj = h(j);
      if (hj < bestH) { bestH = hj; best = j; }
      open.push(j, ng + hj);
    }
  }
  // Walk back from the goal (or the closest point we reached).
  const cells = [];
  for (let i = best; i !== -1; i = came[i]) cells.push(i);
  cells.reverse();
  return smooth(grid, cells, def).map((i) => {
    const x = i % W, z = Math.floor(i / W);
    return { x: (x + 0.5) * WORLD.CELL, z: (z + 0.5) * WORLD.CELL };
  });
}

/** Drop intermediate cells when a straight walk between kept points is legal. */
function smooth(grid, cells, def) {
  if (cells.length < 3) return cells.slice(1);
  const W = grid.w, out = [];
  let anchor = 0;
  for (let i = 2; i < cells.length; i++) {
    if (!lineWalkable(grid, cells[anchor], cells[i], W, def)) { out.push(cells[i - 1]); anchor = i - 1; }
  }
  out.push(cells[cells.length - 1]);
  return out;
}

function lineWalkable(grid, a, b, W, def) {
  let x = a % W, z = Math.floor(a / W);
  const bx = b % W, bz = Math.floor(b / W);
  const steps = Math.max(Math.abs(bx - x), Math.abs(bz - z));
  for (let k = 1; k <= steps; k++) {
    const nx = Math.round((a % W) + ((bx - (a % W)) * k) / steps);
    const nz = Math.round(Math.floor(a / W) + ((bz - Math.floor(a / W)) * k) / steps);
    if (!stepOk(grid, x, z, nx, nz, def)) return false;
    x = nx; z = nz;
  }
  return true;
}
