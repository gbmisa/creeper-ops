// Billboard status bars (HP / construction / ammo) for structures, units and enemies.
// Bars.faceCamera(camera) once per frame turns every live bar toward the viewer.

import * as THREE from 'three';

const live = new Set();
const PLANE = new THREE.PlaneGeometry(1, 1);
PLANE.translate(0.5, 0, 0); // grow from the left edge
const BG = new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.6, depthTest: false, fog: false });

export class Bar {
  /** parent: Object3D to ride on (must not rotate), y: height above its origin. */
  constructor(parent, y, width = 1.6, color = 0x6ee39a) {
    this.group = new THREE.Group();
    this.group.position.y = y;
    this.width = width;
    this.bg = new THREE.Mesh(PLANE, BG);
    this.bg.scale.set(width + 0.1, 0.24, 1);
    this.bg.position.x = -(width + 0.1) / 2;
    this.fill = new THREE.Mesh(PLANE, new THREE.MeshBasicMaterial({ color, transparent: true, depthTest: false, fog: false }));
    this.fill.scale.set(width, 0.14, 1);
    this.fill.position.set(-width / 2, 0, 0.01);
    // both transparent so renderOrder decides: background first, then fill on top
    this.bg.renderOrder = 10;
    this.fill.renderOrder = 11;
    this.group.add(this.bg, this.fill);
    parent.add(this.group);
    live.add(this);
  }

  set(frac, color) {
    const f = Math.max(0, Math.min(1, frac));
    this.fill.scale.x = Math.max(0.001, this.width * f);
    if (color !== undefined) this.fill.material.color.setHex(color);
  }

  set visible(v) { this.group.visible = v; }
  get visible() { return this.group.visible; }

  dispose() {
    this.group.removeFromParent();
    this.fill.material.dispose();
    live.delete(this);
  }

  /** HP colour ramp: green → yellow → red. */
  static hpColor(f) { return f > 0.6 ? 0x6ee39a : f > 0.3 ? 0xffc857 : 0xff5a5a; }

  static faceCamera(camera) {
    for (const b of live) if (b.group.visible) b.group.quaternion.copy(camera.quaternion);
  }
}
