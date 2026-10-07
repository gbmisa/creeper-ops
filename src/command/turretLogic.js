// Per-type active behaviour for built, connected weapon structures.
// Every shot spends one round of ammo; ammo only arrives as packets over the network.

import * as THREE from 'three';
import { WORLD } from '../core/config.js';
import { sfx } from '../core/audio.js';

const tmpA = new THREE.Vector3();
const tmpB = new THREE.Vector3();

function cellWorld(grid, x, z, out, yOffset = 0) {
  const c = grid.cellCenter(x, z);
  return out.set(c.x, c.y + yOffset, c.z);
}

function fireBlaster(s, world) {
  const { creeper, grid, effects } = world;
  const t = creeper.nearestWet(s.x, s.z, s.def.range);
  if (!t) return false;
  creeper.remove(t.x, t.z, s.def.power);
  tmpA.copy(s.pos).y += 0.9;
  cellWorld(grid, t.x, t.z, tmpB, t.d * WORLD.LEVEL_H);
  effects.beam(tmpA, tmpB, 0xfff27a, 0.09, 0.07);
  effects.burst(tmpB, 0xfff6b0, 0.6, 0.12);
  const turret = s.mesh.userData.turret;
  if (turret) turret.rotation.y = Math.atan2(-(tmpB.z - tmpA.z), tmpB.x - tmpA.x);
  sfx('blaster', s.pos);
  return true;
}

function fireMortar(s, world) {
  const { creeper, grid, effects } = world;
  const t = creeper.deepestWet(s.x, s.z, s.def.range);
  if (!t) return false;
  tmpA.copy(s.pos).y += 1.4;
  cellWorld(grid, t.x, t.z, tmpB, t.d * WORLD.LEVEL_H);
  const landing = tmpB.clone();
  effects.lob(tmpA, landing, {
    color: 0xffb347, time: 1.0, arc: 10, trail: true,
    onArrive: () => {
      creeper.removeRadius(t.x, t.z, s.def.splash, s.def.power);
      effects.burst(landing, 0xffaa33, s.def.splash * WORLD.CELL * 0.7, 0.45);
      sfx('boom', landing);
    },
  });
  sfx('mortar', s.pos);
  return true;
}

const FIRE = { blaster: fireBlaster, mortar: fireMortar };

/** Weapon structures: count down cooldown and fire when ready and loaded. */
export function updateWeapon(s, dt, world) {
  const fire = FIRE[s.type];
  if (!fire) return;
  s.cooldown -= dt;
  if (s.cooldown > 0 || s.ammo < 1) return;
  // Only reset the cooldown when a shot actually happens, so idle turrets react instantly.
  if (fire(s, world)) { s.ammo -= 1; s.cooldown = s.def.fireRate; }
}
