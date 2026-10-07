// Decorative scatter: boulders, alien crystal clusters in Blight zones, shrubs.
// Instanced for cost. Deterministic per seed so screenshots are stable.

import * as THREE from 'three';
import { WORLD } from '../core/config.js';
import { ZONE } from './Grid.js';

function rng(seed) {
  let s = seed >>> 0;
  return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296);
}

function instanced(geo, mat, items) {
  const mesh = new THREE.InstancedMesh(geo, mat, Math.max(1, items.length));
  const m = new THREE.Matrix4(), q = new THREE.Quaternion(), e = new THREE.Euler();
  items.forEach((it, i) => {
    e.set(it.tilt, it.rot, it.tilt * 0.5);
    mesh.setMatrixAt(i, m.compose(it.pos, q.setFromEuler(e), it.scale));
  });
  mesh.count = items.length;
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  return mesh;
}

/** keepClear(x, z) -> true for cells where nothing decorative should sit (hazards, pads). */
export function scatterProps(grid, { cave = false, seed = 3, keepClear = () => false } = {}) {
  const r = rng(seed);
  const rocks = [], crystals = [], stalks = [];
  const V = (x, y, z) => new THREE.Vector3(x, y, z);

  for (let z = 0; z < grid.h; z++) {
    for (let x = 0; x < grid.w; x++) {
      if (keepClear(x, z) || grid.blocked[grid.idx(x, z)]) continue;
      const h = grid.heightAt(x, z);
      let steep = 0;
      for (const [dx, dz] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) steep = Math.max(steep, Math.abs(grid.heightAt(x + dx, z + dz) - h));
      if (steep > 20) steep = 0; // map edge
      const blight = grid.zone[grid.idx(x, z)] === ZONE.BLIGHT;
      const wx = (x + r()) * WORLD.CELL, wz = (z + r()) * WORLD.CELL;
      const y = grid.smoothY(wx, wz);

      if (r() < (steep > 1.5 ? 0.35 : 0.035)) {
        const s = 0.25 + r() * (steep > 1.5 ? 1.1 : 0.5);
        rocks.push({ pos: V(wx, y - s * 0.3, wz), rot: r() * 6, tilt: r() * 0.5, scale: V(s * (1 + r()), s * (0.6 + r() * 0.5), s * (1 + r())) });
      }
      if ((blight && r() < 0.22) || (cave && steep > 1.5 && r() < 0.12)) {
        const s = 0.4 + r() * 0.9;
        crystals.push({ pos: V(wx, y - 0.2, wz), rot: r() * 6, tilt: (r() - 0.5) * 0.7, scale: V(s * 0.5, s * (1.5 + r() * 2), s * 0.5) });
      }
      if (!cave && !blight && steep < 0.6 && r() < 0.06) {
        const s = 0.6 + r() * 0.8;
        stalks.push({ pos: V(wx, y, wz), rot: r() * 6, tilt: (r() - 0.5) * 0.3, scale: V(s, s * (1 + r()), s) });
      }
    }
  }

  const group = new THREE.Group();
  group.name = 'props';
  const rockMat = new THREE.MeshStandardMaterial({ color: cave ? 0x4a4152 : 0x6b665e, roughness: 0.95, flatShading: true });
  group.add(instanced(new THREE.DodecahedronGeometry(1, 0), rockMat, rocks));
  const crystalGeo = new THREE.OctahedronGeometry(0.6, 0);
  crystalGeo.translate(0, 0.6, 0);
  group.add(instanced(crystalGeo, new THREE.MeshStandardMaterial({ color: 0xb06cff, emissive: 0x5a1a9a, emissiveIntensity: 1.2, roughness: 0.3, flatShading: true }), crystals));
  const shrubGeo = new THREE.IcosahedronGeometry(0.45, 0);
  shrubGeo.scale(1, 0.6, 1);
  shrubGeo.translate(0, 0.15, 0);
  group.add(instanced(shrubGeo, new THREE.MeshStandardMaterial({ color: 0x4f5f2c, roughness: 0.9, flatShading: true }), stalks));
  return group;
}
