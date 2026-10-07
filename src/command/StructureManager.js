// Owns every structure on the surface: placement rules, lifecycle, creeper damage, and the
// per-frame tick. Network graph, packet delivery, land claim and per-type behaviour live in
// Network / Packets / CollectorField / structureBehaviors.

import * as THREE from 'three';
import { DEFS } from './structureDefs.js';
import { makeStructureMesh } from './structureMeshes.js';
import { Network } from './Network.js';
import { Packets } from './Packets.js';
import { CollectorField } from './CollectorField.js';
import { BEHAVIORS } from './structureBehaviors.js';
import { updateWeapon } from './turretLogic.js';
import { Bar } from '../world/Bars.js';
import { ZONE } from '../world/Grid.js';
import { CREEPER, ECONOMY, THREATS } from '../core/config.js';
import { bus, log } from '../core/events.js';
import { sfx } from '../core/audio.js';

let nextId = 1;
const DROP_POD_TIME = 3;

export class StructureManager {
  constructor(world, economy) {
    this.world = world;
    this.economy = economy;
    this.list = [];
    this.occupied = new Map(); // grid idx -> structure
    this.hazards = null;       // set by Game (nullifier + validation hooks)
    this.selectedBeacon = null;
    this.dirty = true;
    this.network = new Network(world.scene);
    this.packets = new Packets(world.scene, this.network, economy);
    this.field = new CollectorField(world);
  }

  get ship() { return this.list.find((s) => s.type === 'ship'); }
  get beacons() { return this.list.filter((s) => s.type === 'beacon' && s.built >= 1); }

  // ---- placement ------------------------------------------------------------
  footprintCells(type, x, z) {
    const r = DEFS[type].footprint, cells = [];
    for (let dz = -r; dz <= r; dz++) for (let dx = -r; dx <= r; dx++) cells.push([x + dx, z + dz]);
    return cells;
  }

  canPlace(type, x, z) {
    const def = DEFS[type];
    const { grid, creeper } = this.world;
    const cells = this.footprintCells(type, x, z);
    const h0 = grid.heightAt(x, z);
    for (const [cx, cz] of cells) {
      if (!grid.inBounds(cx, cz)) return { ok: false, reason: 'Out of bounds' };
      const i = grid.idx(cx, cz);
      if (grid.zone[i] === ZONE.BLIGHT) return { ok: false, reason: 'Blight zone: nothing can be built here. Send the Operative or units.' };
      if (grid.blocked[i]) return { ok: false, reason: 'Too close to a hazard' };
      if (this.occupied.has(i)) return { ok: false, reason: 'Cell occupied' };
      if (Math.abs(grid.heightAt(cx, cz) - h0) > 1.01) return { ok: false, reason: 'Ground too steep' };
      if (!def.buildOnCreeper && creeper.depthAt(cx, cz) > 0.1) return { ok: false, reason: 'Cannot build on creeper' };
    }
    if (def.dropPod && !this.economy.canAfford(def.cost)) return { ok: false, reason: `Drop pod needs ${def.cost} energy up front` };
    if (def.needsNetwork !== false && !this.network.inRange(this.list, x, z, def.link)) {
      return { ok: false, reason: 'Out of network range: build a Relay or Collector closer' };
    }
    if (type === 'nullifier') {
      const e = this.hazards?.emitterNear(x, z, THREATS.NULLIFY_RANGE);
      if (!e) return { ok: false, reason: `Nullifier must be within ${THREATS.NULLIFY_RANGE} cells of an emitter` };
      if (this.hazards.isShielded(e)) return { ok: false, reason: `${e.name} is SHIELDED. ${e.shieldHint}` };
    }
    return { ok: true };
  }

  place(type, x, z, { instant = false } = {}) {
    const def = DEFS[type];
    if (def.dropPod && !instant && !this.economy.spend(def.cost)) return null;
    const { grid } = this.world;
    const c = grid.cellCenter(x, z);
    const y = grid.smoothY(c.x, c.z);
    const mesh = makeStructureMesh(type);
    mesh.position.set(c.x, y, c.z);
    const anchor = new THREE.Group();
    anchor.position.set(c.x, y, c.z);
    this.world.scene.add(mesh, anchor);

    const s = {
      id: nextId++, type, def, x, z, mesh, anchor,
      pos: new THREE.Vector3(c.x, y, c.z),
      hp: def.hp, built: instant ? 1 : 0, delivered: instant ? def.cost : 0, inFlight: 0,
      connected: false, cooldown: 0, charge: 0, ammo: def.ammo ? (instant ? def.ammo.max : 0) : 0,
      queue: type === 'barracks' ? [] : null, dead: false, wet: 0,
    };
    s.hpBar = new Bar(anchor, def.linkY + (def.footprint ? 3 : 1.3), def.footprint ? 3 : 1.6);
    if (def.ammo) s.ammoBar = new Bar(anchor, def.linkY + 1.05, 1.6, 0xffb13b);
    for (const [fx, fz] of this.footprintCells(type, x, z)) this.occupied.set(grid.idx(fx, fz), s);
    if (!instant) mesh.scale.y = 0.15;
    this.list.push(s);
    this.dirty = true;
    if (type === 'beacon' && !instant) this.selectedBeacon = s;
    return s;
  }

  remove(s, reason) {
    const i = this.list.indexOf(s);
    if (i < 0) return;
    this.list.splice(i, 1);
    s.dead = true;
    this.world.scene.remove(s.mesh, s.anchor);
    s.hpBar.dispose();
    s.ammoBar?.dispose();
    for (const [k, v] of this.occupied) if (v === s) this.occupied.delete(k);
    if (this.selectedBeacon === s) this.selectedBeacon = null;
    this.dirty = true;
    if (reason) this.world.effects.burst(s.pos.clone().setY(s.pos.y + 1), 0xff5533, 2.5);
    if (reason === 'destroyed') {
      sfx('lost', s.pos);
      if (s.type === 'ship') bus.emit('shipDestroyed');
      else log(`${s.def.label} destroyed`, 'bad');
    }
    bus.emit('structureRemoved', s);
  }

  /** Recycle: give back part of what was delivered. */
  recycle(s) {
    if (s.type === 'ship') return;
    this.economy.add(Math.floor(s.delivered * ECONOMY.RECYCLE_REFUND));
    this.world.effects.burst(s.pos.clone().setY(s.pos.y + 1), 0x7fe0ff, 2, 0.3);
    this.remove(s, 'recycled');
  }

  damage(s, amount) {
    if (s.dead) return;
    s.hp -= amount;
    s.hurt = 0.25;
    if (s.type === 'ship') bus.emit('shipHit');
    if (s.hp <= 0) this.remove(s, 'destroyed');
  }

  structureAt(x, z) { return this.occupied.get(this.world.grid.idx(x, z)) ?? null; }

  nearestTo(x, z, filter = () => true) {
    let best = null, bd = Infinity;
    for (const s of this.list) {
      if (!filter(s)) continue;
      const d = Math.hypot(s.x - x, s.z - z);
      if (d < bd) { bd = d; best = s; }
    }
    return best;
  }

  /** Deepest creeper across a structure's footprint. */
  wetDepth(s) {
    const { creeper } = this.world;
    let d = 0;
    for (const [x, z] of this.footprintCells(s.type, s.x, s.z)) d = Math.max(d, creeper.depthAt(x, z));
    return d;
  }

  // ---- per frame ------------------------------------------------------------
  update(dt, time) {
    if (this.dirty) { this.network.rebuild(this.list); this.dirty = false; }
    this.packets.update(dt, this.list);
    const totals = { reactorIncome: 0, storage: 0 };
    const collectors = [];

    for (const s of [...this.list]) {
      s.wet = this.wetDepth(s);
      if (s.wet > CREEPER.DAMAGE_DEPTH) {
        const dps = (CREEPER.STRUCT_BASE_DPS + s.wet * CREEPER.STRUCT_DPS) * (1 - (s.def.creeperResist ?? 0));
        this.damage(s, dps * dt);
        if (s.dead) continue;
      } else if (s.connected) {
        s.hp = Math.min(s.def.hp, s.hp + ECONOMY.REPAIR_PER_SEC * dt);
      }
      this.updateConstruction(s, dt);
      this.updateBars(s, time);
      if (s.built < 1 || !s.connected) continue;

      if (s.type === 'collector') collectors.push(s);
      if (s.def.income) totals.reactorIncome += s.def.income;
      if (s.def.storage) totals.storage += s.def.storage;
      updateWeapon(s, dt, this.world);
      BEHAVIORS[s.type]?.(s, dt, this, time);
    }
    this.field.update(dt, collectors);
    this.economy.tick(dt, { shipAlive: !!this.ship, fieldIncome: this.field.income, fieldCells: this.field.cells, ...totals });
  }

  updateConstruction(s, dt) {
    if (s.built >= 1) return;
    if (s.def.dropPod) s.built = Math.min(1, s.built + dt / DROP_POD_TIME);
    else s.built = Math.min(1, s.delivered / s.def.cost);
    s.mesh.scale.y = 0.15 + 0.85 * s.built;
    if (s.built >= 1) {
      this.dirty = true; // a finished relay may connect new nodes
      sfx('build', s.pos);
      bus.emit('structureBuilt', s);
    }
  }

  updateBars(s, time) {
    const hpF = s.hp / s.def.hp;
    if (s.built < 1) {
      s.hpBar.visible = true;
      s.hpBar.set(s.built, 0x5fd4ff);
    } else {
      s.hpBar.visible = hpF < 0.999 || s.type === 'ship';
      s.hpBar.set(hpF, s.hurt > 0 && Math.sin(time * 40) > 0 ? 0xffffff : Bar.hpColor(hpF));
    }
    s.hurt = Math.max(0, (s.hurt ?? 0) - 1 / 60);
    if (s.ammoBar) {
      s.ammoBar.visible = s.built >= 1;
      s.ammoBar.set(s.ammo / s.def.ammo.max, s.ammo < 1 && Math.sin(time * 8) > 0 ? 0xff3030 : 0xffb13b);
    }
  }
}
