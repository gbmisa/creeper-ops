// A self-contained playable space: scene + grid + creeper + effects + gameplay hooks.
// The surface and the cave are both Worlds; the simulation ticks for every World every frame,
// but only the active one is rendered.

import * as THREE from 'three';
import { buildTerrainMesh, raycastGround } from './TerrainMesh.js';
import { skyDome, caveCeiling } from './Sky.js';
import { scatterProps } from './Props.js';
import { CreeperSim } from '../sim/CreeperSim.js';
import { CreeperMesh } from '../sim/CreeperMesh.js';
import { Effects } from './Effects.js';

export class World {
  constructor(name, grid, { cave = false, keepClear } = {}) {
    this.name = name;
    this.grid = grid;
    this.cave = cave;
    this.scene = new THREE.Scene();

    this.terrain = buildTerrainMesh(grid, { cave });
    this.scene.add(this.terrain);
    this.scene.add(scatterProps(grid, { cave, seed: cave ? 11 : 3, keepClear }));

    this.creeper = new CreeperSim(grid);
    this.creeperMesh = new CreeperMesh(this.creeper);
    this.scene.add(this.creeperMesh.mesh);

    this.effects = new Effects(this.scene);

    /** Shootable things: { mesh, alive, onHit(damage, point, source) } */
    this.targets = [];
    /** Things the operative can use: { position: Vector3, radius, prompt() -> string|null, use() } */
    this.interactables = [];
    /** Per-frame hooks for world-specific logic: fn(dt) */
    this.updaters = [];
    /** On-screen objective markers: { pos: Vector3, label, color, visible() -> bool } */
    this.markers = [];

    this.setupLighting();
  }

  setupLighting() {
    const g = this.grid;
    if (this.cave) {
      this.scene.background = new THREE.Color(0x120b1c);
      this.scene.fog = new THREE.FogExp2(0x120b1c, 0.018);
      this.scene.add(new THREE.HemisphereLight(0xa08cd0, 0x2a1830, 2.4));
      this.scene.add(new THREE.AmbientLight(0x3a2c50, 1.2));
      this.scene.add(caveCeiling(g, 8.5));
      return;
    }
    const sunDir = new THREE.Vector3(-0.45, 0.62, 0.35).normalize();
    this.scene.add(skyDome({ sunDir }));
    this.scene.fog = new THREE.Fog(0x6f6a80, 120, 420);
    this.scene.add(new THREE.HemisphereLight(0xc6d8ff, 0x3a3020, 1.0));
    const sun = new THREE.DirectionalLight(0xfff0d8, 2.2);
    const c = new THREE.Vector3(g.worldWidth / 2, 0, g.worldDepth / 2);
    sun.position.copy(c).addScaledVector(sunDir, 160);
    sun.target.position.copy(c);
    sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    const half = Math.max(g.worldWidth, g.worldDepth) * 0.62;
    Object.assign(sun.shadow.camera, { left: -half, right: half, top: half, bottom: -half, near: 10, far: 400 });
    sun.shadow.bias = -0.0008;
    sun.shadow.normalBias = 0.4;
    this.scene.add(sun, sun.target);
  }

  /** Cheap terrain pick: march the heightfield instead of raycasting 100k triangles. */
  raycastGround(ray, maxDist) { return raycastGround(this.grid, ray, maxDist); }

  removeTarget(t) {
    const i = this.targets.indexOf(t);
    if (i >= 0) this.targets.splice(i, 1);
  }

  update(dt) {
    this.creeper.update(dt);
    for (const fn of this.updaters) fn(dt);
    this.effects.update(dt);
  }

  /** Visual refresh — only needed for the world being rendered. */
  refreshVisuals() {
    this.creeperMesh.update();
  }
}
