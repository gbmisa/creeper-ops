// Short-lived visual effects: beams, lobbed projectiles (with trails), bursts. One instance per World.

import * as THREE from 'three';

const UP = new THREE.Vector3(0, 1, 0);
const additive = (color, opacity = 1) => new THREE.MeshBasicMaterial({
  color, transparent: true, opacity, depthWrite: false, blending: THREE.AdditiveBlending, fog: false,
});

export class Effects {
  constructor(scene) {
    this.scene = scene;
    this.items = [];
    this.sphereGeo = new THREE.SphereGeometry(1, 12, 8);
    this.beamGeo = new THREE.CylinderGeometry(1, 1, 1, 6, 1, true);
    this.beamGeo.translate(0, 0.5, 0); // pivot at one end
  }

  /** Glowing beam from a to b (Vector3) that fades over `life` seconds. */
  beam(a, b, color = 0xfff27a, life = 0.08, radius = 0.05) {
    const len = a.distanceTo(b);
    const m = new THREE.Mesh(this.beamGeo, additive(color, 0.95));
    m.position.copy(a);
    m.quaternion.setFromUnitVectors(UP, b.clone().sub(a).normalize());
    m.scale.set(radius, len, radius);
    this.scene.add(m);
    this.items.push({ obj: m, t: 0, life, kind: 'fade', base: 0.95 });
  }

  /** Expanding, fading sphere. */
  burst(pos, color = 0xffaa33, radius = 1.5, life = 0.35) {
    const m = new THREE.Mesh(this.sphereGeo, additive(color, 0.8));
    m.position.copy(pos);
    m.scale.setScalar(0.2);
    this.scene.add(m);
    this.items.push({ obj: m, t: 0, life, kind: 'burst', radius });
  }

  /** Lobbed projectile along a parabola; calls onArrive() when it lands. */
  lob(from, to, { color = 0xffcc55, size = 0.35, time = 0.9, arc = 8, trail = false, onArrive } = {}) {
    const m = new THREE.Mesh(this.sphereGeo, additive(color, 1));
    m.scale.setScalar(size);
    m.position.copy(from);
    this.scene.add(m);
    this.items.push({ obj: m, t: 0, life: time, kind: 'lob', from: from.clone(), to: to.clone(), arc, onArrive, trail, color, size, puff: 0 });
  }

  update(dt) {
    for (let i = this.items.length - 1; i >= 0; i--) {
      const it = this.items[i];
      it.t += dt;
      const k = Math.min(1, it.t / it.life);
      if (it.kind === 'fade') {
        it.obj.material.opacity = it.base * (1 - k);
      } else if (it.kind === 'burst') {
        it.obj.scale.setScalar(0.2 + it.radius * k);
        it.obj.material.opacity = 0.8 * (1 - k) * (1 - k);
      } else if (it.kind === 'lob') {
        it.obj.position.lerpVectors(it.from, it.to, k);
        it.obj.position.y += Math.sin(Math.PI * k) * it.arc;
        if (it.trail && (it.puff -= dt) <= 0) { it.puff = 0.04; this.burst(it.obj.position, it.color, it.size * 1.5, 0.4); }
      }
      if (k >= 1) {
        if (it.kind === 'lob') it.onArrive?.();
        this.scene.remove(it.obj);
        it.obj.material.dispose();
        this.items.splice(i, 1);
      }
    }
  }
}
