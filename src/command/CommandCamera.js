// RTS camera for command mode: WASD/arrows pan (relative to view), Q/E rotate,
// wheel zoom (pitch flattens as you zoom in so the terrain reads as 3D), screen-edge pan.

import * as THREE from 'three';

export class CommandCamera {
  constructor(grid) {
    this.grid = grid;
    this.camera = new THREE.PerspectiveCamera(50, innerWidth / innerHeight, 0.5, 1500);
    this.target = new THREE.Vector3();
    this.dist = 70;
    this.yaw = 0;        // radians around Y; 0 = looking north
    this.edgePan = true;
  }

  focus(pos) { this.target.set(pos.x, 0, pos.z); }

  update(dt, input) {
    const speed = this.dist * 0.9 * dt;
    let fx = 0, fz = 0;
    if (input.down('KeyW') || input.down('ArrowUp')) fz -= 1;
    if (input.down('KeyS') || input.down('ArrowDown')) fz += 1;
    if (input.down('KeyA') || input.down('ArrowLeft')) fx -= 1;
    if (input.down('KeyD') || input.down('ArrowRight')) fx += 1;
    if (this.edgePan && document.hasFocus()) {
      const m = 6, { x, y } = input.mouse;
      if (x > 0 && x < m) fx -= 1; else if (x > innerWidth - m) fx += 1;
      if (y > 0 && y < m) fz -= 1; else if (y > innerHeight - m) fz += 1;
    }
    if (input.down('KeyQ')) this.yaw += dt * 1.6;
    if (input.down('KeyE')) this.yaw -= dt * 1.6;
    const s = Math.sin(this.yaw), c = Math.cos(this.yaw);
    this.target.x += (fx * c + fz * s) * speed;
    this.target.z += (-fx * s + fz * c) * speed;
    this.dist = THREE.MathUtils.clamp(this.dist * (1 + input.mouse.wheel * 0.1), 14, 190);
    this.target.x = THREE.MathUtils.clamp(this.target.x, 0, this.grid.worldWidth);
    this.target.z = THREE.MathUtils.clamp(this.target.z, 0, this.grid.worldDepth);
    this.target.y = this.grid.smoothY(this.target.x, this.target.z);
    this.apply();
  }

  apply() {
    const pitch = THREE.MathUtils.mapLinear(this.dist, 14, 190, 0.62, 1.15);
    const h = Math.cos(pitch) * this.dist;
    this.camera.position.set(
      this.target.x + Math.sin(this.yaw) * h,
      this.target.y + Math.sin(pitch) * this.dist,
      this.target.z + Math.cos(this.yaw) * h,
    );
    this.camera.lookAt(this.target);
  }

  resize() {
    this.camera.aspect = innerWidth / innerHeight;
    this.camera.updateProjectionMatrix();
  }
}
