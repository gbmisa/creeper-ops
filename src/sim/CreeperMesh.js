// Renders a CreeperSim as a deforming translucent sheet with depth-based colour.
// Vertex (x, z) sits at the centre of cell (x, z), so vertex index == grid index.

import * as THREE from 'three';
import { WORLD, CREEPER } from '../core/config.js';

const SHALLOW = new THREE.Color(0x10257a);
const DEEP = new THREE.Color(0x2f7fe0);
const FOAM = new THREE.Color(0x081040);
const GLOW = new THREE.Color(0x6fe6ff);

export class CreeperMesh {
  constructor(sim) {
    this.sim = sim;
    const { w, h } = sim.grid;
    const geo = new THREE.PlaneGeometry((w - 1) * WORLD.CELL, (h - 1) * WORLD.CELL, w - 1, h - 1);
    geo.rotateX(-Math.PI / 2); // row index now increases with +z, matching grid.idx
    geo.translate((w * WORLD.CELL) / 2, 0, (h * WORLD.CELL) / 2);
    geo.setAttribute('color', new THREE.BufferAttribute(new Float32Array(w * h * 3), 3));

    const mat = new THREE.MeshStandardMaterial({
      vertexColors: true, transparent: true, opacity: 0.93, roughness: 0.22, metalness: 0.35,
      emissive: 0x0a1a66, emissiveIntensity: 0.7, side: THREE.DoubleSide,
    });
    this.mesh = new THREE.Mesh(geo, mat);
    this.mesh.name = 'creeper';
    this.mesh.renderOrder = 1;
    this.mesh.receiveShadow = true;
    this.frame = 0;

    // Where a dry vertex hides: below the lowest neighbouring ground, so triangles that
    // span a cliff never poke through the lower terrain's top face.
    const g = sim.grid;
    this.dryY = new Float32Array(w * h);
    for (let z = 0; z < h; z++) {
      for (let x = 0; x < w; x++) {
        let lo = g.heightAt(x, z);
        for (const [dx, dz] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          if (g.inBounds(x + dx, z + dz)) lo = Math.min(lo, g.heightAt(x + dx, z + dz));
        }
        this.dryY[g.idx(x, z)] = lo * WORLD.LEVEL_H - 0.4;
      }
    }
  }

  update() {
    const { grid, depth } = this.sim;
    const pos = this.mesh.geometry.attributes.position;
    const col = this.mesh.geometry.attributes.color;
    const c = new THREE.Color();
    const t = performance.now() / 1000, w = grid.w;

    for (let i = 0; i < depth.length; i++) {
      const d = depth[i];
      const ground = grid.height[i] * WORLD.LEVEL_H;
      if (d > CREEPER.MIN_DEPTH) {
        // slow viscous swell + glowing veins that crawl across the surface
        const x = i % w, z = (i - x) / w;
        const wave = Math.sin(x * 0.9 + t * 1.3) * Math.cos(z * 0.8 - t * 1.1);
        pos.setY(i, ground + d * WORLD.LEVEL_H + 0.03 + wave * 0.06 * Math.min(1, d));
        if (d < 0.4) c.copy(FOAM).lerp(SHALLOW, d / 0.4);
        else c.copy(SHALLOW).lerp(DEEP, Math.min(1, (d - 0.4) / 5));
        const vein = Math.max(0, Math.sin(x * 0.55 + z * 0.35 + t * 0.9 + wave * 1.5));
        c.lerp(GLOW, vein ** 6 * 0.45 * Math.min(1, d));
      } else {
        pos.setY(i, this.dryY[i]); // tuck under terrain when dry
        c.copy(SHALLOW);
      }
      col.setXYZ(i, c.r, c.g, c.b);
    }
    pos.needsUpdate = true;
    col.needsUpdate = true;
    // Normals are the expensive part; refresh every other frame.
    if (this.frame++ % 2 === 0) this.mesh.geometry.computeVertexNormals();
  }
}
