// Soldiers and Crawlers on the surface: spawning from barracks, selection, move orders
// (A* paths, spread into a formation), auto-targeting enemies, clearing creeper, and creeper
// damage. Units deliberately have no way to trigger objectives (see unitDefs.js).

import * as THREE from 'three';
import { UNIT_DEFS, UNIT_CREEPER } from './unitDefs.js';
import { findPath } from './pathfind.js';
import { soldierMesh, crawlerMesh, selectionRing } from './unitMeshes.js';
import { Bar } from '../world/Bars.js';
import { CREEPER, WORLD } from '../core/config.js';
import { bus, log } from '../core/events.js';
import { sfx } from '../core/audio.js';

const MESHES = { soldier: soldierMesh, crawler: crawlerMesh };
const tmp = new THREE.Vector3(), tmp2 = new THREE.Vector3();

export class UnitManager {
  constructor(world) {
    this.world = world;
    this.list = [];
    this.selected = new Set();
    bus.on('unitTrained', ({ type, barracks }) => this.spawnAt(type, barracks));
  }

  spawnAt(type, barracks) {
    const c = barracks.pos;
    const u = this.spawn(type, c.x + (Math.random() - 0.5) * 2, c.z + 4.2);
    const rally = barracks.rally ?? { x: c.x + (Math.random() - 0.5) * 6, z: c.z + 9 };
    this.order([u], rally);
    log(`${u.def.label} ready.`, 'good');
  }

  spawn(type, x, z) {
    const def = UNIT_DEFS[type];
    const mesh = MESHES[type]();
    const ring = selectionRing(def.radius);
    mesh.add(ring);
    const anchor = new THREE.Group();
    this.world.scene.add(mesh, anchor);
    const u = {
      type, def, mesh, ring, anchor, hp: def.hp, alive: true, path: [], heading: 0,
      pos: new THREE.Vector3(x, this.world.grid.smoothY(x, z), z), gunCd: 0, clearCd: 0, hurt: 0,
    };
    u.bar = new Bar(anchor, type === 'crawler' ? 2.2 : 2.0, type === 'crawler' ? 1.8 : 1.1);
    // Shootable by enemies: same shape as other targets.
    u.target = { pos: u.pos, radius: def.radius, get alive() { return u.alive; }, hit: (d) => this.damage(u, d), kind: 'unit' };
    this.list.push(u);
    this.sync(u);
    return u;
  }

  /** Move order for a group: spread destinations in a spiral so they don't stack. */
  order(units, dest) {
    const { grid, creeper } = this.world;
    units.forEach((u, i) => {
      const a = i * 2.4, r = i === 0 ? 0 : 1.4 * Math.sqrt(i);
      const gx = dest.x + Math.cos(a) * r, gz = dest.z + Math.sin(a) * r;
      const from = grid.worldToCell(u.pos.x, u.pos.z), to = grid.worldToCell(gx, gz);
      u.path = findPath(grid, creeper, from, to, u.def);
      if (u.path.length) u.path[u.path.length - 1] = { x: gx, z: gz };
    });
    if (units.length) sfx('click');
  }

  damage(u, amount) {
    if (!u.alive) return;
    u.hp -= amount;
    u.hurt = 0.2;
    if (u.hp <= 0) this.kill(u);
  }

  kill(u) {
    u.alive = false;
    this.world.effects.burst(tmp.copy(u.pos).setY(u.pos.y + 1), 0xff7744, 2, 0.4);
    this.world.scene.remove(u.mesh, u.anchor);
    u.bar.dispose();
    this.selected.delete(u);
    this.list.splice(this.list.indexOf(u), 1);
    sfx('lost', u.pos);
    log(`${u.def.label} lost.`, 'bad');
  }

  select(units, additive = false) {
    if (!additive) this.selected.clear();
    for (const u of units) this.selected.add(u);
    for (const u of this.list) u.ring.visible = this.selected.has(u);
  }

  update(dt, enemies) {
    for (const u of [...this.list]) {
      this.move(u, dt);
      this.creeperDamage(u, dt);
      if (!u.alive) continue;
      this.fight(u, dt, enemies);
      this.sync(u);
    }
  }

  move(u, dt) {
    const { grid } = this.world;
    let vx = 0, vz = 0;
    const wp = u.path[0];
    if (wp) {
      const dx = wp.x - u.pos.x, dz = wp.z - u.pos.z, d = Math.hypot(dx, dz);
      if (d < 0.5) u.path.shift();
      else { vx = dx / d; vz = dz / d; u.heading = Math.atan2(-dz, dx); }
    }
    // separation so groups don't clump into one mesh
    for (const o of this.list) {
      if (o === u) continue;
      const dx = u.pos.x - o.pos.x, dz = u.pos.z - o.pos.z, d = Math.hypot(dx, dz);
      const min = u.def.radius + o.def.radius + 0.3;
      if (d > 0.001 && d < min) { vx += (dx / d) * (min - d) * 2; vz += (dz / d) * (min - d) * 2; }
    }
    const depth = this.depthAt(u);
    const speed = u.def.speed * (depth > CREEPER.DAMAGE_DEPTH ? 0.6 : 1) * dt;
    const nx = u.pos.x + vx * speed, nz = u.pos.z + vz * speed;
    const a = grid.worldToCell(u.pos.x, u.pos.z), b = grid.worldToCell(nx, nz);
    const rise = grid.heightAt(b.x, b.z) - grid.heightAt(a.x, a.z);
    if (grid.inBounds(b.x, b.z) && rise <= u.def.climb && -rise <= u.def.drop) { u.pos.x = nx; u.pos.z = nz; }
    u.pos.y = grid.smoothY(u.pos.x, u.pos.z);
  }

  depthAt(u) {
    const c = this.world.grid.worldToCell(u.pos.x, u.pos.z);
    return this.world.creeper.depthAt(c.x, c.z);
  }

  creeperDamage(u, dt) {
    const d = this.depthAt(u);
    if (d > CREEPER.DAMAGE_DEPTH) this.damage(u, (UNIT_CREEPER.BASE_DPS + d * UNIT_CREEPER.DPS) * u.def.creeperMult * dt);
  }

  fight(u, dt, enemies) {
    u.gunCd -= dt;
    u.clearCd -= dt;
    const { gun, clear } = u.def;
    let best = null, bd = gun.range;
    for (const e of enemies) {
      if (!e.alive) continue;
      const d = e.pos.distanceTo(u.pos);
      if (d < bd) { bd = d; best = e; }
    }
    const muzzle = tmp.copy(u.pos).setY(u.pos.y + (u.type === 'crawler' ? 1.3 : 1.0));
    if (best) {
      if (!u.path.length) u.heading = Math.atan2(-(best.pos.z - u.pos.z), best.pos.x - u.pos.x);
      if (u.gunCd <= 0) {
        u.gunCd = gun.rate;
        best.hit(gun.damage, 'unit');
        this.world.effects.beam(muzzle, tmp2.copy(best.pos).setY(best.pos.y + 0.6), u.type === 'crawler' ? 0xffc06a : 0xbfffa0, 0.07, 0.04);
        sfx('rifle', u.pos);
      }
      return;
    }
    if (u.clearCd > 0) return;
    const { grid, creeper, effects } = this.world;
    const c = grid.worldToCell(u.pos.x, u.pos.z);
    const t = creeper.nearestWet(c.x, c.z, clear.range);
    if (!t) return;
    u.clearCd = clear.rate;
    if (clear.splash) creeper.removeRadius(t.x, t.z, clear.splash, clear.power);
    else creeper.remove(t.x, t.z, clear.power);
    const p = grid.cellCenter(t.x, t.z);
    tmp2.set(p.x, p.y + t.d * WORLD.LEVEL_H, p.z);
    if (u.path.length === 0) u.heading = Math.atan2(-(p.z - u.pos.z), p.x - u.pos.x);
    effects.beam(muzzle, tmp2, 0x9dff7a, 0.1, u.type === 'crawler' ? 0.12 : 0.04);
  }

  sync(u) {
    u.mesh.position.copy(u.pos);
    u.mesh.rotation.y = u.heading;
    u.anchor.position.copy(u.pos);
    const f = u.hp / u.def.hp;
    u.bar.visible = f < 0.999 || this.selected.has(u);
    u.hurt = Math.max(0, u.hurt - 1 / 60);
    u.bar.set(f, u.hurt > 0 ? 0xffffff : Bar.hpColor(f));
  }

  /** Units near a world point (for click-select). */
  nearest(p, maxDist = 1.6) {
    let best = null, bd = maxDist;
    for (const u of this.list) { const d = Math.hypot(u.pos.x - p.x, u.pos.z - p.z); if (d < bd) { bd = d; best = u; } }
    return best;
  }
}
