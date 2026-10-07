// Spore mites: small flying chasers spawned by the Deep Core. Shootable, pop on contact.

import * as THREE from 'three';
import { THREATS } from '../core/config.js';

const GEO = new THREE.SphereGeometry(0.3, 8, 6);

export class Mites {
  constructor(world, spawnPos) {
    this.world = world;
    this.spawnPos = spawnPos.clone();
    this.list = [];
    this.timer = 0;
    this.enabled = true;
    this.target = null; // operative position (Vector3) when the operative is in this world
    this.onPlayerHit = null;
  }

  spawn() {
    const mesh = new THREE.Mesh(GEO, new THREE.MeshLambertMaterial({ color: 0x99ff66, emissive: 0x335511 }));
    mesh.position.copy(this.spawnPos).add(new THREE.Vector3((Math.random() - 0.5) * 3, 1.5, (Math.random() - 0.5) * 3));
    this.world.scene.add(mesh);
    const mite = { mesh, hp: 2, alive: true, phase: Math.random() * 6 };
    mite.target = {
      mesh, get alive() { return mite.alive; },
      onHit: (dmg) => { mite.hp -= dmg; if (mite.hp <= 0) this.kill(mite); },
    };
    this.world.targets.push(mite.target);
    this.list.push(mite);
  }

  kill(mite) {
    if (!mite.alive) return;
    mite.alive = false;
    this.world.effects.burst(mite.mesh.position, 0x99ff66, 0.8, 0.25);
    this.world.scene.remove(mite.mesh);
    this.world.removeTarget(mite.target);
    this.list.splice(this.list.indexOf(mite), 1);
  }

  killAll() { for (const m of [...this.list]) this.kill(m); }

  update(dt, time) {
    // Only hunt (and only spawn) while the operative is down here.
    if (!this.target) return;
    if (this.enabled) {
      this.timer += dt;
      if (this.timer >= THREATS.MITE_SPAWN && this.list.length < THREATS.MITE_MAX) {
        this.timer = 0;
        this.spawn();
      }
    }
    const dir = new THREE.Vector3();
    for (const m of [...this.list]) {
      dir.subVectors(this.target, m.mesh.position);
      const dist = dir.length();
      if (dist < 0.8) {
        this.onPlayerHit?.(THREATS.MITE_DAMAGE);
        this.kill(m);
        continue;
      }
      dir.normalize().multiplyScalar(THREATS.MITE_SPEED * dt);
      dir.y += Math.sin(time * 5 + m.phase) * dt * 1.5; // bobbing
      m.mesh.position.add(dir);
    }
  }
}
