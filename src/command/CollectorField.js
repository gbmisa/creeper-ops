// Collector land claim (Creeper World's green field). Each dry, non-Blight cell within
// COLLECT_RADIUS of a collector belongs to the nearest collector and yields energy.
// Overlapping collectors therefore share land, which rewards spreading out.

import * as THREE from 'three';
import { ECONOMY, CREEPER, WORLD } from '../core/config.js';
import { ZONE } from '../world/Grid.js';

const REFRESH = 0.5; // seconds between recounts

export class CollectorField {
  constructor(world) {
    this.world = world;
    this.timer = 0;
    this.income = 0;
    this.cells = 0;
    const { w, h } = world.grid;
    const geo = new THREE.PlaneGeometry(WORLD.CELL * 0.92, WORLD.CELL * 0.92);
    geo.rotateX(-Math.PI / 2);
    this.mesh = new THREE.InstancedMesh(
      geo,
      new THREE.MeshBasicMaterial({ color: 0x5dff8a, transparent: true, opacity: 0.22, depthWrite: false }),
      w * h,
    );
    this.mesh.count = 0;
    this.mesh.renderOrder = 2;
    this.mesh.frustumCulled = false;
    world.scene.add(this.mesh);
    this.m = new THREE.Matrix4();
  }

  update(dt, collectors) {
    this.timer -= dt;
    if (this.timer > 0) return;
    this.timer = REFRESH;
    const { grid, creeper } = this.world;
    const owner = new Map(); // idx -> distance to its closest collector
    for (const c of collectors) {
      grid.forEachInRadius(c.x, c.z, ECONOMY.COLLECT_RADIUS, (x, z, d) => {
        const i = grid.idx(x, z);
        if (!owner.has(i) || d < owner.get(i)) owner.set(i, d);
      });
    }
    let n = 0;
    for (const i of owner.keys()) {
      if (grid.zone[i] === ZONE.BLIGHT || creeper.depth[i] > CREEPER.MIN_DEPTH) continue;
      const x = i % grid.w, z = Math.floor(i / grid.w);
      const c = grid.cellCenter(x, z);
      this.m.makeTranslation(c.x, grid.smoothY(c.x, c.z) + 0.12, c.z);
      this.mesh.setMatrixAt(n++, this.m);
    }
    this.mesh.count = n;
    this.mesh.instanceMatrix.needsUpdate = true;
    this.cells = n;
    this.income = n * ECONOMY.COLLECT_PER_CELL;
  }
}
