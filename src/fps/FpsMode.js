// Operative mode: wraps movement + weapons + suit + interaction + recall.
// Works in any World (surface or cave); Game decides which World it's in.

import * as THREE from 'three';
import { OPERATIVE, WORLD } from '../core/config.js';
import { bus } from '../core/events.js';
import { sfx, setListener } from '../core/audio.js';
import { PlayerController } from './PlayerController.js';
import { OperativeWeapons } from './OperativeWeapons.js';

export class FpsMode {
  constructor() {
    this.camera = new THREE.PerspectiveCamera(75, innerWidth / innerHeight, 0.05, 1200);
    this.controller = new PlayerController(this.camera);
    this.weapons = new OperativeWeapons(this.camera);
    this.suit = OPERATIVE.SUIT_MAX;
    this.recallHold = 0;
    this.world = null;
    this.prompt = '';
    this.inCreeper = false;
    this.creeperDepth = 0;
    this.hurtFlash = 0;
    this.sinceHurt = 99;
    this.beacons = () => []; // injected: returns built beacons when on the surface
    // What enemies (surface mites) see: same shape as unit/structure prey.
    const self = this;
    this.asPrey = { pos: this.controller.pos, radius: 0.5, get alive() { return !!self.world; }, hit: (d) => self.damage(d) };
  }

  enter(world, cell, { mites = null } = {}) {
    this.leave();
    this.world = world;
    this.mites = mites;
    world.scene.add(this.camera); // so the view-model renders
    this.controller.spawn(world.grid, cell.x, cell.z, cell.yaw ?? 0);
    this.recallHold = 0;
    if (mites) {
      mites.target = this.controller.pos;
      mites.onPlayerHit = (d) => this.damage(d);
    }
    sfx('teleport');
  }

  leave() {
    if (!this.world) return;
    this.world.scene.remove(this.camera);
    if (this.mites) this.mites.target = null;
    this.world = null;
    this.mites = null;
  }

  resetSuit() { this.suit = OPERATIVE.SUIT_MAX; this.weapons.tank = OPERATIVE.TANK_MAX; }

  damage(amount) {
    this.suit -= amount;
    this.hurtFlash = 0.3;
    this.sinceHurt = 0;
    sfx('hurt');
  }

  update(dt, input) {
    const world = this.world;
    const { grid, creeper } = world;
    const feet = this.controller.pos;
    const cell = grid.worldToCell(feet.x, feet.z);
    const depth = creeper.depthAt(cell.x, cell.z);
    const surfaceY = grid.heightAt(cell.x, cell.z) * WORLD.LEVEL_H + depth * WORLD.LEVEL_H;
    this.inCreeper = depth > 0.04 && feet.y < surfaceY + 0.15;
    this.creeperDepth = this.inCreeper ? depth : 0;

    this.controller.update(dt, input, grid, this.inCreeper ? OPERATIVE.CREEPER_SLOW : 1);
    this.weapons.update(dt, input, world, feet);
    setListener(this.camera.position);

    // suit integrity: creeper burns, faster the deeper you wade
    this.sinceHurt += dt;
    if (this.inCreeper) {
      this.suit -= (OPERATIVE.CREEPER_BASE_DPS + depth * OPERATIVE.CREEPER_DPS) * dt;
      this.sinceHurt = 0;
      sfx('sizzle');
    } else if (this.sinceHurt > OPERATIVE.REGEN_DELAY) {
      this.suit = Math.min(OPERATIVE.SUIT_MAX, this.suit + OPERATIVE.SUIT_REGEN * dt);
    }
    this.hurtFlash = Math.max(0, this.hurtFlash - dt);
    if (this.suit <= 0) { bus.emit('operativeDown'); return; }

    this.updateInteraction(input);
    this.updateRecall(dt, input);
  }

  updateInteraction(input) {
    const feet = this.controller.pos;
    let best = null, bd = Infinity;
    const candidates = [...this.world.interactables, ...this.beaconInteractables()];
    for (const it of candidates) {
      const d = Math.hypot(it.position.x - feet.x, it.position.z - feet.z);
      if (d <= it.radius && d < bd && it.prompt()) { best = it; bd = d; }
    }
    this.prompt = best ? best.prompt() : '';
    if (best && input.wasPressed('KeyE')) best.use();
  }

  beaconInteractables() {
    return this.beacons(this.world).map((b) => ({
      position: b.pos, radius: 1.8,
      prompt: () => '[E] Teleport back to the ship (free)',
      use: () => bus.emit('recall', { cost: 0 }),
    }));
  }

  updateRecall(dt, input) {
    if (input.down('KeyR')) {
      this.recallHold += dt;
      if (this.recallHold >= OPERATIVE.RECALL_HOLD) {
        this.recallHold = 0;
        bus.emit('recall', { cost: OPERATIVE.RECALL_COST });
      }
    } else {
      this.recallHold = 0;
    }
  }

  resize() {
    this.camera.aspect = innerWidth / innerHeight;
    this.camera.updateProjectionMatrix();
  }
}
