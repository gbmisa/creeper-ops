// Per-type behaviour for built, connected structures (weapons live in turretLogic.js).
// Each entry: fn(structure, dt, manager, time).

import { THREATS } from '../core/config.js';
import { bus, log } from '../core/events.js';
import { sfx } from '../core/audio.js';
import { UNIT_DEFS } from '../units/unitDefs.js';

const spin = (speed) => (s, dt) => { const m = s.mesh.userData.spin; if (m) m.rotation.y += dt * speed; };

export const BEHAVIORS = {
  collector: spin(1.5),
  relay: spin(2),
  reactor(s, dt) { s.mesh.userData.spin.rotation.z += dt * 3; },
  beacon(s, dt, mgr, time) {
    const glow = s.mesh.userData.glow;
    const sel = s === mgr.selectedBeacon;
    if (!glow.userData.own) { glow.material = glow.material.clone(); glow.userData.own = true; }
    glow.material.emissive.setHex(sel ? 0x66ffcc : 0x116644);
    glow.scale.y = sel ? 1 + 0.15 * Math.sin(time * 6) : 1;
  },
  nullifier(s, dt, mgr) {
    const e = mgr.hazards?.emitterNear(s.x, s.z, THREATS.NULLIFY_RANGE);
    if (!e) return;
    if (mgr.hazards.isShielded(e)) {
      if (!s.warned) { s.warned = true; log(`Nullifier ready but ${e.name} is shielded. ${e.shieldHint}`, 'warn'); }
      return;
    }
    s.charge = Math.min(THREATS.NULLIFY_TIME, s.charge + dt);
    const core = s.mesh.userData.core;
    core.rotation.y += dt * (1 + s.charge * 2);
    core.scale.setScalar(1 + (s.charge / THREATS.NULLIFY_TIME) * 0.8);
    if (s.charge < THREATS.NULLIFY_TIME) return;
    if (mgr.hazards.tryNullify(s.x, s.z) === 'destroyed') mgr.remove(s, 'spent');
  },
  barracks(s, dt, mgr) {
    spin(4)(s, dt);
    const q = s.queue[0];
    if (!q || q.delivered < q.cost) return;
    q.train = (q.train ?? 0) + dt;
    if (q.train < UNIT_DEFS[q.type].trainTime) return;
    s.queue.shift();
    sfx('unit', s.pos);
    bus.emit('unitTrained', { type: q.type, barracks: s });
  },
};

/** Queue a unit at a barracks (paid for by packets as they arrive). */
export function queueUnit(barracks, type) {
  if (barracks.queue.length >= 5) { log('Barracks queue is full (5).', 'warn'); return false; }
  barracks.queue.push({ type, cost: UNIT_DEFS[type].cost, delivered: 0 });
  return true;
}
