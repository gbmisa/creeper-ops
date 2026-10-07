// Spore Nests: surface enemy spawners that live in Blight zones (where turrets can't be built).
// Each nest breeds flying mites that defend a leash radius around it, attacking units,
// structures and the Operative. Nests die to unit fire or the Operative's rifle — never turrets.

import * as THREE from 'three';
import { THREATS } from '../core/config.js';
import { bus, log } from '../core/events.js';
import { sfx } from '../core/audio.js';
import { nestMesh } from './hazardMeshes.js';

const MITE_GEO = new THREE.SphereGeometry(0.32, 10, 8);
const MITE_MAT = new THREE.MeshStandardMaterial({ color: 0xa8ff5a, emissive: 0x4a9a10, emissiveIntensity: 1.4, roughness: 0.4 });
const tmp = new THREE.Vector3();

export class SporeNests {
  constructor(world, defs) {
    this.world = world;
    this.nests = defs.map((d) => this.makeNest(d));
    this.mites = [];
    this.prey = () => []; // injected: [{ pos, alive, hit(d), radius }]
    this.time = 0;
  }

  /** Everything units should shoot at. */
  get enemies() {
    return [...this.nests.filter((n) => n.alive).map((n) => n.enemy), ...this.mites.map((m) => m.enemy)];
  }

  makeNest(d) {
    const { grid, scene } = this.world;
    const c = grid.cellCenter(d.x, d.z);
    const mesh = nestMesh();
    mesh.position.set(c.x, grid.smoothY(c.x, c.z), c.z);
    scene.add(mesh);
    const nest = { ...d, mesh, pos: mesh.position.clone(), hp: THREATS.NEST_HP, alive: true, timer: Math.random() * 4, count: 0 };
    const hit = (dmg) => this.hitNest(nest, dmg);
    nest.target = { mesh, get alive() { return nest.alive; }, onHit: hit };
    nest.enemy = { pos: nest.pos.clone().setY(nest.pos.y + 0.8), radius: 1.4, get alive() { return nest.alive; }, hit, kind: 'nest' };
    this.world.targets.push(nest.target);
    this.world.markers.push({ pos: nest.enemy.pos, label: 'Spore Nest', color: '#a8ff5a', visible: () => nest.alive, minor: true });
    return nest;
  }

  hitNest(nest, dmg) {
    if (!nest.alive) return;
    nest.hp -= dmg;
    nest.mesh.userData.sac.scale.setScalar(1.25);
    if (nest.hp > 0) return;
    nest.alive = false;
    this.world.effects.burst(nest.enemy.pos, 0xa8ff5a, 6, 0.8);
    this.world.scene.remove(nest.mesh);
    this.world.removeTarget(nest.target);
    sfx('boom', nest.pos);
    log(`Spore Nest destroyed${nest.name ? ` (${nest.name})` : ''}.`, 'good');
    bus.emit('nestDestroyed', nest);
    if (this.nests.every((n) => !n.alive)) bus.emit('objectiveDone', 'nests');
  }

  spawnMite(nest) {
    const mesh = new THREE.Mesh(MITE_GEO, MITE_MAT);
    mesh.castShadow = true;
    mesh.position.copy(nest.enemy.pos).add(tmp.set(Math.random() - 0.5, 1, Math.random() - 0.5));
    this.world.scene.add(mesh);
    const m = { nest, mesh, hp: THREATS.SURFACE_MITE_HP, alive: true, phase: Math.random() * 6 };
    const hit = (dmg) => { m.hp -= dmg; if (m.hp <= 0) this.killMite(m); };
    m.target = { mesh, get alive() { return m.alive; }, onHit: hit };
    m.enemy = { pos: mesh.position, radius: 0.5, get alive() { return m.alive; }, hit, kind: 'mite' };
    this.world.targets.push(m.target);
    this.mites.push(m);
    nest.count++;
  }

  killMite(m) {
    if (!m.alive) return;
    m.alive = false;
    m.nest.count--;
    this.world.effects.burst(m.mesh.position, 0xa8ff5a, 0.9, 0.25);
    this.world.scene.remove(m.mesh);
    this.world.removeTarget(m.target);
    this.mites.splice(this.mites.indexOf(m), 1);
    sfx('pop', m.mesh.position);
  }

  update(dt) {
    this.time += dt;
    for (const n of this.nests) {
      if (!n.alive) continue;
      const sac = n.mesh.userData.sac;
      sac.scale.lerp(tmp.setScalar(1 + 0.08 * Math.sin(this.time * 3 + n.x)), 0.2);
      n.timer += dt;
      if (n.timer >= THREATS.NEST_SPAWN && n.count < THREATS.NEST_MAX) { n.timer = 0; this.spawnMite(n); }
    }
    const prey = this.prey();
    for (const m of [...this.mites]) this.updateMite(m, dt, prey);
  }

  updateMite(m, dt, prey) {
    const p = m.mesh.position, home = m.nest.enemy.pos;
    let target = null, bd = THREATS.NEST_AGGRO;
    for (const q of prey) {
      if (!q.alive || q.pos.distanceTo(home) > THREATS.NEST_LEASH) continue;
      const d = q.pos.distanceTo(p);
      if (d < bd) { bd = d; target = q; }
    }
    const goal = target ? tmp.copy(target.pos).setY(target.pos.y + 1) : tmp.copy(home).setY(home.y + 2.5 + Math.sin(this.time + m.phase) * 1.5)
      .add({ x: Math.cos(this.time * 0.7 + m.phase) * 4, y: 0, z: Math.sin(this.time * 0.7 + m.phase) * 4 });
    const dir = goal.sub(p);
    const dist = dir.length();
    if (target && dist < (target.radius ?? 0.5) + 0.9) {
      target.hit(THREATS.SURFACE_MITE_DPS * dt, 'mite');
    } else if (dist > 0.01) {
      p.addScaledVector(dir.normalize(), Math.min(dist, 5.2 * dt));
    }
    p.y = Math.max(p.y, this.world.grid.smoothY(p.x, p.z) + 0.6) + Math.sin(this.time * 6 + m.phase) * dt;
  }
}
