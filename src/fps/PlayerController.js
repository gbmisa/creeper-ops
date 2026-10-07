// First-person movement on a heightfield Grid: mouse look, walk/sprint/jump, smooth ground
// that matches the rendered terrain, cliffs (cell rise > CLIMB) that block unless you jump
// high enough, gravity, per-axis sliding, and a little head bob.

import * as THREE from 'three';
import { OPERATIVE } from '../core/config.js';

const SENSITIVITY = 0.0022;

export class PlayerController {
  constructor(camera) {
    this.camera = camera;
    this.pos = new THREE.Vector3();   // feet position
    this.velY = 0;
    this.yaw = 0;
    this.pitch = 0;
    this.onGround = false;
    this.bob = 0;
    this.moving = false;
    camera.rotation.order = 'YXZ';
  }

  spawn(grid, x, z, yaw = Math.PI) {
    const c = grid.cellCenter(x, z);
    this.pos.set(c.x, grid.smoothY(c.x, c.z), c.z);
    this.velY = 0;
    this.yaw = yaw;
    this.pitch = 0;
    this.syncCamera();
  }

  /** Can the body (a small square) stand at (x, z) given the current height? */
  canOccupy(grid, x, z) {
    const r = OPERATIVE.RADIUS;
    const reach = Math.max(this.pos.y, grid.groundY(this.pos.x, this.pos.z)) + OPERATIVE.CLIMB;
    for (const [ox, oz] of [[-r, -r], [r, -r], [-r, r], [r, r]]) {
      const c = grid.worldToCell(x + ox, z + oz);
      if (!grid.inBounds(c.x, c.z) || grid.heightAt(c.x, c.z) > reach) return false;
    }
    return true;
  }

  forward(out = new THREE.Vector3()) {
    return out.set(-Math.sin(this.yaw), 0, -Math.cos(this.yaw));
  }

  update(dt, input, grid, speedFactor = 1) {
    this.yaw -= input.mouse.dx * SENSITIVITY;
    this.pitch -= input.mouse.dy * SENSITIVITY;
    this.pitch = Math.max(-1.5, Math.min(1.5, this.pitch));

    let mx = 0, mz = 0;
    if (input.down('KeyW')) mz -= 1;
    if (input.down('KeyS')) mz += 1;
    if (input.down('KeyA')) mx -= 1;
    if (input.down('KeyD')) mx += 1;
    const len = Math.hypot(mx, mz);
    this.moving = len > 0;
    if (len > 0) {
      const sprint = input.down('ShiftLeft') || input.down('ShiftRight');
      const speed = (sprint ? OPERATIVE.SPRINT : OPERATIVE.WALK) * speedFactor;
      mx /= len; mz /= len;
      const sin = Math.sin(this.yaw), cos = Math.cos(this.yaw);
      const dx = (mx * cos + mz * sin) * speed * dt;
      const dz = (-mx * sin + mz * cos) * speed * dt;
      // per-axis so you slide along cliffs instead of sticking
      if (this.canOccupy(grid, this.pos.x + dx, this.pos.z)) this.pos.x += dx;
      if (this.canOccupy(grid, this.pos.x, this.pos.z + dz)) this.pos.z += dz;
      if (this.onGround) this.bob += dt * speed * 1.6;
    }

    if (this.onGround && input.wasPressed('Space')) {
      this.velY = OPERATIVE.JUMP_V;
      this.onGround = false;
    }
    this.velY -= OPERATIVE.GRAVITY * dt;
    this.pos.y += this.velY * dt;
    const ground = grid.smoothY(this.pos.x, this.pos.z);
    if (this.pos.y <= ground) {
      this.pos.y = ground;
      this.velY = 0;
      this.onGround = true;
    } else if (this.onGround && this.velY <= 0 && this.pos.y - ground < 0.5) {
      this.pos.y = ground; // stick to slopes when walking downhill
      this.velY = 0;
    } else {
      this.onGround = false;
    }
    this.syncCamera();
  }

  syncCamera() {
    const bob = this.moving && this.onGround ? Math.sin(this.bob) * 0.05 : 0;
    this.camera.position.set(this.pos.x, this.pos.y + OPERATIVE.EYE + bob, this.pos.z);
    this.camera.rotation.set(this.pitch, this.yaw, 0);
  }
}
