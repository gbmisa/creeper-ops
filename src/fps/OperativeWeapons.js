// Operative loadout: hitscan Pulse Rifle and the creeper-evaporating Null Sprayer.

import * as THREE from 'three';
import { WEAPONS, OPERATIVE, WORLD } from '../core/config.js';
import { sfx } from '../core/audio.js';

const gunMat = (color, emissive = 0) => new THREE.MeshStandardMaterial({ color, emissive, emissiveIntensity: 1.5, metalness: 0.6, roughness: 0.35 });

export class OperativeWeapons {
  constructor(camera) {
    this.camera = camera;
    this.current = 'rifle';
    this.cooldown = 0;
    this.tank = OPERATIVE.TANK_MAX;
    this.spraying = false;
    this.hitMarker = 0;
    this.raycaster = new THREE.Raycaster();
    this.raycaster.far = WEAPONS.rifle.range;

    // view-model
    this.gun = new THREE.Group();
    const body = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.09, 0.42), gunMat(0x5a6878));
    const barrel = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.022, 0.3, 8), gunMat(0x2a2f36));
    barrel.rotation.x = Math.PI / 2;
    barrel.position.set(0, 0.015, -0.33);
    this.coil = new THREE.Mesh(new THREE.BoxGeometry(0.075, 0.03, 0.2), gunMat(0x7fe0ff, 0x2a9fd0));
    this.coil.position.set(0, 0.055, -0.02);
    const grip = new THREE.Mesh(new THREE.BoxGeometry(0.05, 0.12, 0.06), gunMat(0x2a2f36));
    grip.position.set(0, -0.09, 0.1);
    grip.rotation.x = 0.3;
    this.gun.add(body, barrel, this.coil, grip);
    this.gun.scale.setScalar(0.6);
    this.gun.position.set(0.21, -0.19, -0.62);
    camera.add(this.gun);

    const cone = new THREE.ConeGeometry(1.8, WEAPONS.sprayer.range * 0.8, 16, 1, true);
    cone.rotateX(Math.PI / 2);
    cone.translate(0, 0, -WEAPONS.sprayer.range * 0.4 - 0.3);
    this.cone = new THREE.Mesh(cone, new THREE.MeshBasicMaterial({ color: 0x9ff6ff, transparent: true, opacity: 0.16, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending }));
    this.cone.visible = false;
    camera.add(this.cone);
  }

  get name() { return `[${this.current === 'rifle' ? 1 : 2}] ${WEAPONS[this.current].name}`; }

  update(dt, input, world, feet) {
    if (input.wasPressed('Digit1')) this.current = 'rifle';
    if (input.wasPressed('Digit2')) this.current = 'sprayer';
    this.coil.material.color.setHex(this.current === 'rifle' ? 0x7fe0ff : 0x9dff7a);
    this.coil.material.emissive.setHex(this.current === 'rifle' ? 0x2a9fd0 : 0x3faa22);
    this.cooldown -= dt;
    this.hitMarker = Math.max(0, this.hitMarker - dt);
    this.gun.position.z += (-0.62 - this.gun.position.z) * Math.min(1, dt * 18); // recoil recovery

    this.spraying = this.current === 'sprayer' && input.mouse.left && this.tank > 0;
    this.cone.visible = this.spraying;
    if (this.spraying) this.spray(dt, world, feet);
    else this.tank = Math.min(OPERATIVE.TANK_MAX, this.tank + OPERATIVE.TANK_REGEN * dt);

    if (this.current === 'rifle' && input.mouse.left && this.cooldown <= 0) {
      this.cooldown = WEAPONS.rifle.cooldown;
      this.fireRifle(world);
    }
  }

  fireRifle(world) {
    const cam = this.camera;
    cam.updateMatrixWorld();
    this.raycaster.setFromCamera(new THREE.Vector2(0, 0), cam);
    const owner = new Map();
    for (const t of world.targets) if (t.alive) owner.set(t.mesh, t);
    const hits = this.raycaster.intersectObjects([...owner.keys()], true);
    const ground = world.raycastGround(this.raycaster.ray, WEAPONS.rifle.range);
    const groundDist = ground ? ground.distanceTo(this.raycaster.ray.origin) : Infinity;

    const start = new THREE.Vector3(0.21, -0.17, -0.85).applyMatrix4(cam.matrixWorld);
    let end = this.raycaster.ray.at(WEAPONS.rifle.range, new THREE.Vector3());
    const h = hits[0];
    if (h && h.distance < groundDist) {
      end = h.point;
      let o = h.object;
      while (o && !owner.has(o)) o = o.parent; // climb to the registered target root
      if (o) { owner.get(o).onHit(WEAPONS.rifle.damage, h.point, 'operative'); this.hitMarker = 0.15; sfx('hit'); }
    } else if (ground) {
      end = ground;
      world.effects.burst(ground, 0xffffaa, 0.3, 0.12);
    }
    world.effects.beam(start, end, 0x9ff6ff, 0.06, 0.025);
    sfx('rifle');
    this.gun.position.z = -0.56; // recoil kick
  }

  spray(dt, world, feet) {
    const cfg = WEAPONS.sprayer;
    this.tank = Math.max(0, this.tank - cfg.tankPerSec * dt);
    sfx('spray');
    const { grid, creeper } = world;
    const fwd = new THREE.Vector3();
    this.camera.getWorldDirection(fwd);
    fwd.y = 0;
    fwd.normalize();
    const here = grid.worldToCell(feet.x, feet.z);
    const rangeCells = cfg.range / WORLD.CELL;
    const cos = Math.cos(cfg.halfAngle);
    grid.forEachInRadius(here.x, here.z, rangeCells, (x, z, dist) => {
      const c = grid.cellCenter(x, z);
      const dx = c.x - feet.x, dz = c.z - feet.z;
      const len = Math.hypot(dx, dz);
      const inCone = len < WORLD.CELL * 0.9 || (dx * fwd.x + dz * fwd.z) / len >= cos;
      if (inCone) creeper.remove(x, z, cfg.removePerSec * dt * (1 - 0.5 * dist / rangeCells));
    });
  }
}
