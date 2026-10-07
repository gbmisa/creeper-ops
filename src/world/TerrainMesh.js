// Smooth heightfield terrain. Vertices interpolate the gameplay grid (Grid.smoothY) at
// WORLD.DETAIL vertices per cell, plus a decorative mountain rim beyond the playable edge.
// Colour comes from height, slope and zone, with a tiling grain texture for surface detail.

import * as THREE from 'three';
import { WORLD } from '../core/config.js';
import { makeNoise } from './noise.js';
import { ZONE } from './Grid.js';

const MARGIN = 14; // decorative cells beyond each edge

const PALETTES = {
  surface: {
    low: new THREE.Color(0x3d4a2c), mid: new THREE.Color(0x5d6b3a), high: new THREE.Color(0x8b8566),
    peak: new THREE.Color(0xb9b2a0), rock: new THREE.Color(0x5a5550), blight: new THREE.Color(0x4a2a5c),
  },
  cave: {
    low: new THREE.Color(0x2c2633), mid: new THREE.Color(0x3a3244), high: new THREE.Color(0x4a3f55),
    peak: new THREE.Color(0x4a3f55), rock: new THREE.Color(0x3a3440), blight: new THREE.Color(0x46205a),
  },
};

let grainTex = null;
function grainTexture() {
  if (grainTex) return grainTex;
  const size = 256, cvs = document.createElement('canvas');
  cvs.width = cvs.height = size;
  const ctx = cvs.getContext('2d');
  const img = ctx.createImageData(size, size);
  const n = makeNoise(99);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const v = 0.78 + 0.22 * n(x / 9, y / 9, 3) + (Math.random() - 0.5) * 0.08;
      const i = (y * size + x) * 4;
      img.data[i] = img.data[i + 1] = img.data[i + 2] = Math.min(255, v * 255);
      img.data[i + 3] = 255;
    }
  }
  ctx.putImageData(img, 0, 0);
  grainTex = new THREE.CanvasTexture(cvs);
  grainTex.wrapS = grainTex.wrapT = THREE.RepeatWrapping;
  grainTex.colorSpace = THREE.SRGBColorSpace;
  return grainTex;
}

/** Height (world units) for any world position, including the decorative rim. */
function sampleHeight(grid, wx, wz, noise, cave) {
  const W = grid.worldWidth, D = grid.worldDepth;
  const cx = Math.max(0, Math.min(W, wx)), cz = Math.max(0, Math.min(D, wz));
  let y = grid.smoothY(cx, cz);
  const out = Math.hypot(wx - cx, wz - cz) / WORLD.CELL; // cells outside the map
  if (out > 0) y = Math.max(y, 0) + out * (cave ? 2.2 : 1.4) + noise(wx / 18, wz / 18, 3) * out * (cave ? 1 : 0.9);
  // gentle visual roughness; kept tiny so shallow creeper still shows
  return y + (noise(wx / 3.1, wz / 3.1, 2) - 0.5) * 0.14;
}

export function buildTerrainMesh(grid, { cave = false } = {}) {
  const noise = makeNoise(cave ? 41 : 17);
  const pal = PALETTES[cave ? 'cave' : 'surface'];
  const step = WORLD.CELL / WORLD.DETAIL;
  const nx = (grid.w + MARGIN * 2) * WORLD.DETAIL + 1;
  const nz = (grid.h + MARGIN * 2) * WORLD.DETAIL + 1;
  const x0 = -MARGIN * WORLD.CELL, z0 = -MARGIN * WORLD.CELL;

  const pos = new Float32Array(nx * nz * 3);
  const uv = new Float32Array(nx * nz * 2);
  for (let j = 0; j < nz; j++) {
    for (let i = 0; i < nx; i++) {
      const wx = x0 + i * step, wz = z0 + j * step, k = j * nx + i;
      pos[k * 3] = wx; pos[k * 3 + 1] = sampleHeight(grid, wx, wz, noise, cave); pos[k * 3 + 2] = wz;
      uv[k * 2] = wx / 6; uv[k * 2 + 1] = wz / 6;
    }
  }
  const index = [];
  for (let j = 0; j < nz - 1; j++) {
    for (let i = 0; i < nx - 1; i++) {
      const a = j * nx + i, b = a + 1, c = a + nx, d = c + 1;
      index.push(a, c, b, b, c, d);
    }
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  geo.setIndex(index);
  geo.computeVertexNormals();
  geo.setAttribute('color', new THREE.BufferAttribute(colourise(grid, geo, pal, noise), 3));

  const mat = new THREE.MeshStandardMaterial({ vertexColors: true, map: grainTexture(), roughness: 0.93, metalness: 0.02 });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.name = 'terrain';
  mesh.receiveShadow = true;
  return mesh;
}

function colourise(grid, geo, pal, noise) {
  const pos = geo.attributes.position, nrm = geo.attributes.normal;
  const col = new Float32Array(pos.count * 3);
  const c = new THREE.Color(), tmp = new THREE.Color();
  for (let k = 0; k < pos.count; k++) {
    const wx = pos.getX(k), y = pos.getY(k), wz = pos.getZ(k);
    const t = Math.max(0, Math.min(1, y / 9));
    if (t < 0.35) c.copy(pal.low).lerp(pal.mid, t / 0.35);
    else if (t < 0.75) c.copy(pal.mid).lerp(pal.high, (t - 0.35) / 0.4);
    else c.copy(pal.high).lerp(pal.peak, (t - 0.75) / 0.25);
    // patchy variation so flat ground isn't one flat colour
    c.multiplyScalar(0.85 + 0.3 * noise(wx / 11, wz / 11, 2));
    // steep faces read as bare rock
    const steep = 1 - nrm.getY(k);
    if (steep > 0.18) c.lerp(tmp.copy(pal.rock).multiplyScalar(0.8 + 0.4 * noise(wx / 2, y / 2)), Math.min(1, (steep - 0.18) * 3));
    const cell = grid.worldToCell(wx, wz);
    if (grid.zoneAt(cell.x, cell.z) === ZONE.BLIGHT) c.lerp(pal.blight, 0.55);
    col[k * 3] = c.r; col[k * 3 + 1] = c.g; col[k * 3 + 2] = c.b;
  }
  return col;
}

/** March a ray across the heightfield; returns the world hit point or null. Much cheaper than mesh raycasts. */
export function raycastGround(grid, ray, maxDist = 400) {
  const p = new THREE.Vector3();
  let prev = 0;
  for (let t = 0; t < maxDist; t += 0.5) {
    ray.at(t, p);
    if (p.x < 0 || p.z < 0 || p.x > grid.worldWidth || p.z > grid.worldDepth) { if (t > 40 && p.y < -5) break; prev = t; continue; }
    if (p.y <= grid.smoothY(p.x, p.z)) {
      let lo = prev, hi = t; // refine
      for (let i = 0; i < 8; i++) {
        const mid = (lo + hi) / 2;
        ray.at(mid, p);
        if (p.y <= grid.smoothY(p.x, p.z)) hi = mid; else lo = mid;
      }
      return ray.at(hi, p);
    }
    prev = t;
  }
  return null;
}
