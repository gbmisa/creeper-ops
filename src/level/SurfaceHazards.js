// Surface threats: emitters (one shielded by the Deep Core, with a visible power link),
// core-fed vents, the armored Spore Spire (Operative-only kill), Spore Nests, and the Rift.
// Every objective gets an on-screen marker so the player always knows what to do and how.

import * as THREE from 'three';
import { THREATS, WORLD } from '../core/config.js';
import { bus, log } from '../core/events.js';
import { sfx } from '../core/audio.js';
import { emitterMesh, shieldMesh, shieldLink, ventMesh, spireMesh, riftMesh } from './hazardMeshes.js';
import { SporeNests } from './SporeNests.js';

export class SurfaceHazards {
  constructor(world, level, structures) {
    this.world = world;
    this.structures = structures;
    this.coreAlive = true;
    this.time = 0;

    this.rift = this.makeRift(level.rift);
    this.emitters = level.emitters.map((e) => this.makeEmitter(e));
    this.vents = level.vents.map((v) => this.makeVent(v));
    this.spire = this.makeSpire(level.spire);
    this.nests = new SporeNests(world, level.nests ?? []);
    world.updaters.push((dt) => this.update(dt));
  }

  place(obj, x, z) {
    const g = this.world.grid, c = g.cellCenter(x, z);
    const y = g.smoothY(c.x, c.z);
    obj.position.set(c.x, y, c.z);
    this.world.scene.add(obj);
    return new THREE.Vector3(c.x, y, c.z);
  }

  marker(pos, label, color, visible) {
    this.world.markers.push({ pos, label, color, visible });
  }

  makeEmitter(e) {
    const mesh = emitterMesh();
    const pos = this.place(mesh, e.x, e.z);
    const source = this.world.creeper.addSource({ x: e.x, z: e.z, amount: e.amount, interval: e.interval });
    const em = { ...e, mesh, pos, source, shield: null, link: null, alive: true };
    if (e.shieldedBy) {
      em.shield = shieldMesh(3.4);
      em.shield.position.y = 1.6;
      mesh.add(em.shield);
      em.link = shieldLink(this.rift.pos.clone().setY(this.rift.pos.y + 1), pos.clone().setY(pos.y + 2));
      this.world.scene.add(em.link);
    }
    this.marker(pos.clone().setY(pos.y + 4), () => (this.isShielded(em) ? `${e.name}: SHIELDED (kill the Deep Core)` : `${e.name}: Nullify`),
      e.shieldedBy ? '#d38cff' : '#7fb0ff', () => em.alive);
    return em;
  }

  makeVent(v) {
    const mesh = ventMesh();
    this.place(mesh, v.x, v.z);
    const source = this.world.creeper.addSource({ x: v.x, z: v.z, amount: v.amount, interval: v.interval });
    return { ...v, mesh, source };
  }

  makeSpire(sp) {
    const mesh = spireMesh();
    const pos = this.place(mesh, sp.x, sp.z);
    const spire = { ...sp, mesh, pos, alive: true, timer: 0, interval: THREATS.SPIRE_INTERVAL, fuse: -1 };
    this.world.interactables.push({
      position: pos, radius: 3.6,
      prompt: () => (!spire.alive ? null : spire.fuse >= 0 ? 'Charge armed. Get clear!' : '[E] Plant demolition charge'),
      use: () => {
        if (!spire.alive || spire.fuse >= 0) return;
        spire.fuse = THREATS.CHARGE_FUSE;
        sfx('alarm');
        log('Charge planted on the Spore Spire. 3 seconds!', 'warn');
      },
    });
    this.marker(pos.clone().setY(pos.y + 10), 'Spore Spire: Operative plants charge [E]', '#ffc857', () => spire.alive);
    return spire;
  }

  makeRift(r) {
    const mesh = riftMesh();
    const pos = this.place(mesh, r.x, r.z);
    this.world.interactables.push({
      position: pos, radius: 2.8,
      prompt: () => '[E] Descend into the Rift',
      use: () => bus.emit('enterCave'),
    });
    this.marker(pos.clone().setY(pos.y + 4), () => (this.coreAlive ? 'Rift: Operative descends [E]' : 'Rift (Core destroyed)'), '#b48cff', () => true);
    return { ...r, mesh, pos };
  }

  // ---- queries used by StructureManager ------------------------------------
  emitterNear(x, z, r) {
    return this.emitters.find((e) => e.alive && Math.hypot(e.x - x, e.z - z) <= r) ?? null;
  }

  isShielded(e) { return !!e.shieldedBy && this.coreAlive; }

  tryNullify(x, z) {
    const e = this.emitterNear(x, z, THREATS.NULLIFY_RANGE);
    if (!e) return 'none';
    if (this.isShielded(e)) return 'shielded';
    e.alive = false;
    e.source.active = false;
    this.world.effects.burst(e.pos.clone().setY(e.pos.y + 1.5), 0xd38cff, 8, 0.9);
    this.world.scene.remove(e.mesh);
    sfx('good');
    log(`${e.name} nullified!`, 'good');
    bus.emit('objectiveDone', e.id);
    return 'destroyed';
  }

  onCoreDestroyed() {
    this.coreAlive = false;
    for (const v of this.vents) { v.source.active = false; v.mesh.visible = false; }
    for (const e of this.emitters) {
      if (e.shield) { e.mesh.remove(e.shield); e.shield = null; }
      if (e.link) { this.world.scene.remove(e.link); e.link = null; }
    }
    log('Vents have gone quiet. Emitter East\'s shield is DOWN. Build a Nullifier (9) next to it!', 'good');
  }

  // ---- per frame ------------------------------------------------------------
  update(dt) {
    this.time += dt;
    for (const e of this.emitters) {
      if (!e.alive) continue;
      e.mesh.userData.orb.scale.setScalar(1 + 0.15 * Math.sin(this.time * 4 + e.x));
      if (e.shield) e.shield.material.opacity = 0.22 + 0.1 * Math.sin(this.time * 3);
      if (e.link) e.link.material.opacity = 0.35 + 0.25 * Math.sin(this.time * 5);
    }
    for (const v of this.vents) v.mesh.userData.ring.rotation.z += dt;
    this.rift.mesh.userData.marker.rotation.y += dt * 2;
    this.nests.update(dt);
    this.updateSpire(dt);
  }

  updateSpire(dt) {
    const sp = this.spire;
    if (!sp.alive) return;
    sp.mesh.userData.sac.scale.setScalar(0.8 + (sp.timer / sp.interval) * 0.7);
    if (sp.fuse >= 0) {
      sp.fuse -= dt;
      if (sp.fuse < 0) this.destroySpire();
      return;
    }
    sp.timer += dt;
    if (sp.timer < sp.interval) return;
    sp.timer = 0;
    sp.interval = Math.max(THREATS.SPIRE_MIN_INTERVAL, sp.interval * THREATS.SPIRE_SPEEDUP);
    this.fireSpore();
  }

  fireSpore() {
    const sp = this.spire;
    const target = this.structures.nearestTo(sp.x, sp.z, (s) => s.type !== 'beacon') ?? this.structures.ship;
    if (!target) return;
    const from = sp.pos.clone().setY(sp.pos.y + 7.5);
    const to = target.pos.clone();
    log(`Spore volley incoming at your ${target.def.label}!`, 'warn');
    this.world.effects.lob(from, to, {
      color: 0x88ff55, size: 0.8, time: 2.4, arc: 28, trail: true,
      onArrive: () => {
        this.world.creeper.add(target.x, target.z, THREATS.SPORE_AMOUNT);
        this.world.effects.burst(to, 0x88ff55, 3 * WORLD.CELL, 0.6);
        sfx('boom', to);
        if (!target.dead) this.structures.damage(target, 15);
      },
    });
  }

  destroySpire() {
    const sp = this.spire;
    sp.alive = false;
    this.world.effects.burst(sp.pos.clone().setY(sp.pos.y + 4), 0xff8844, 10, 1.2);
    this.world.scene.remove(sp.mesh);
    sfx('boom', sp.pos);
    log('Spore Spire destroyed. No more volleys.', 'good');
    bus.emit('objectiveDone', 'spire');
  }
}
