// The Deep Core set piece: 3 Shield Pylons -> vulnerable Core -> kill.
// Also owns the flooding source (pressure cap rises over time), the recall pad, and the
// on-screen markers that tell the player exactly what to shoot.

import * as THREE from 'three';
import { bus, log } from '../core/events.js';
import { coreMesh, pylonMesh, padMesh, shieldMesh } from '../level/hazardMeshes.js';
import { sfx } from '../core/audio.js';
import { Mites } from './Mites.js';

const PYLON_HP = 8;
const CORE_HP = 30;

export class CaveHazards {
  constructor(world, cave) {
    this.world = world;
    this.cave = cave;
    this.time = 0;

    this.padPos = this.placeAt(padMesh(), cave.pad.x, cave.pad.z);
    world.interactables.push({
      position: this.padPos, radius: 2,
      prompt: () => '[E] Return to the surface',
      use: () => bus.emit('exitCave'),
    });
    world.markers.push({ pos: this.padPos.clone().setY(this.padPos.y + 2.5), label: 'Exit pad [E]', color: '#7fa0ff', visible: () => true, minor: true });

    this.buildCore();
    this.conduits = cave.pylons.map((c) => this.buildConduit(c));
    this.mites = new Mites(world, this.core.pos);
    this.addLights();
    world.updaters.push((dt) => this.update(dt));
  }

  placeAt(obj, x, z) {
    const g = this.world.grid, c = g.cellCenter(x, z);
    const y = g.smoothY(c.x, c.z);
    obj.position.set(c.x, y, c.z);
    this.world.scene.add(obj);
    return new THREE.Vector3(c.x, y, c.z);
  }

  buildCore() {
    const { cave, world } = this;
    const mesh = coreMesh();
    const pos = this.placeAt(mesh, cave.core.x, cave.core.z);
    const shield = shieldMesh(2.6);
    shield.position.y = 2.6;
    mesh.add(shield);
    const src = cave.coreSource;
    const source = world.creeper.addSource({ x: cave.core.x, z: cave.core.z, amount: src.amount, interval: src.interval, cap: src.baseCap });
    const core = { mesh, pos, shield, source, hp: CORE_HP, alive: true };
    core.target = {
      mesh: mesh.userData.heart, get alive() { return core.alive; },
      onHit: (dmg, point) => this.hitCore(dmg, point),
    };
    world.targets.push(core.target);
    world.markers.push({
      pos: pos.clone().setY(pos.y + 5.5), color: '#ff5577', visible: () => core.alive,
      label: () => (core.shield ? `Deep Core: SHIELDED (${this.conduitsLeft} pylons left)` : 'Deep Core: SHOOT IT'),
    });
    this.core = core;
  }

  buildConduit(c) {
    const mesh = pylonMesh();
    const pos = this.placeAt(mesh, c.x, c.z);
    const conduit = { mesh, pos, hp: PYLON_HP, alive: true };
    this.world.markers.push({ pos: pos.clone().setY(pos.y + 5), label: 'Shield Pylon: SHOOT', color: '#d38cff', visible: () => conduit.alive });
    conduit.target = {
      mesh, get alive() { return conduit.alive; },
      onHit: (dmg) => {
        conduit.hp -= dmg;
        sfx('hit');
        mesh.userData.crystal.material.emissive.setHex(0xffffff);
        setTimeout(() => conduit.alive && mesh.userData.crystal.material.emissive.setHex(0x8833cc), 60);
        if (conduit.hp <= 0) this.destroyConduit(conduit);
      },
    };
    this.world.targets.push(conduit.target);
    return conduit;
  }

  addLights() {
    const coreLight = new THREE.PointLight(0xff3355, 160, 45, 1.2);
    coreLight.position.copy(this.core.pos).y += 4;
    const padLight = new THREE.PointLight(0x6688ff, 60, 22, 1.2);
    padLight.position.copy(this.padPos).y += 3;
    this.world.scene.add(coreLight, padLight);
    this.coreLight = coreLight;
    for (const c of this.conduits) {
      const l = new THREE.PointLight(0xc070ff, 50, 20, 1.2);
      l.position.copy(c.pos).y += 3.5;
      this.world.scene.add(l);
      c.light = l;
    }
  }

  get conduitsLeft() { return this.conduits.filter((c) => c.alive).length; }

  destroyConduit(c) {
    c.alive = false;
    this.world.effects.burst(c.pos.clone().setY(c.pos.y + 3), 0xd38cff, 3, 0.5);
    this.world.scene.remove(c.mesh, c.light);
    this.world.removeTarget(c.target);
    const left = this.conduitsLeft;
    sfx('boom', c.pos);
    if (left > 0) log(`Shield Pylon down. ${left} remaining.`, 'good');
    else {
      this.core.mesh.remove(this.core.shield);
      this.core.shield = null;
      sfx('good');
      log('Core shield collapsed! Shoot the Core!', 'good');
    }
  }

  hitCore(dmg, point) {
    const core = this.core;
    if (core.shield) {
      this.world.effects.burst(point, 0xc070ff, 0.6, 0.15);
      return;
    }
    core.hp -= dmg;
    sfx('hit');
    core.mesh.userData.heart.material.emissive.setHex(0xffffff);
    setTimeout(() => core.alive && core.mesh.userData.heart.material.emissive.setHex(0x880022), 60);
    if (core.hp <= 0) this.destroyCore();
  }

  destroyCore() {
    const core = this.core;
    core.alive = false;
    core.source.active = false;
    this.world.effects.burst(core.pos.clone().setY(core.pos.y + 2.6), 0xff3355, 10, 1.2);
    this.world.scene.remove(core.mesh);
    this.world.removeTarget(core.target);
    this.coreLight.color.setHex(0x334466);
    this.mites.enabled = false;
    this.mites.killAll();
    sfx('good');
    log('DEEP CORE DESTROYED. Get back to the pad or recall (hold R).', 'good');
    bus.emit('objectiveDone', 'core');
    bus.emit('coreDestroyed');
  }

  update(dt) {
    this.time += dt;
    const core = this.core;
    if (core.alive) {
      // Flood pressure grows the longer you leave it.
      const src = this.cave.coreSource;
      core.source.cap = src.baseCap + this.time * src.capGrowth;
      const s = 1 + 0.08 * Math.sin(this.time * (core.shield ? 3 : 8));
      core.mesh.userData.heart.scale.setScalar(s);
      core.mesh.userData.heart.rotation.y += dt * 0.6;
    }
    for (const c of this.conduits) if (c.alive) c.mesh.userData.crystal.rotation.y += dt * 2;
    this.mites.update(dt, this.time);
  }
}
