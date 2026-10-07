// On-screen objective markers. Projects world.markers through the active camera; off-screen
// markers clamp to the screen edge with an arrow so you can always find the next objective.
// `minor` markers (e.g. nests) only show when near, to keep the view uncluttered.

import * as THREE from 'three';

const v = new THREE.Vector3();
const MINOR_RANGE = 45;

export class Markers {
  constructor() {
    this.root = document.getElementById('markers');
    this.els = new Map(); // marker -> element
  }

  /** Remove elements for markers that aren't in the given world. */
  sync(world) {
    for (const [m, el] of this.els) if (!world.markers.includes(m)) { el.remove(); this.els.delete(m); }
    for (const m of world.markers) {
      if (this.els.has(m)) continue;
      const el = document.createElement('div');
      el.className = `marker${m.minor ? ' minor' : ''}`;
      el.innerHTML = '<i></i><span></span><small></small>';
      el.style.setProperty('--c', m.color);
      this.root.appendChild(el);
      this.els.set(m, el);
    }
  }

  update(world, camera, { fps }) {
    this.sync(world);
    const W = innerWidth, H = innerHeight, pad = 40, padX = 110; // padX keeps labels on screen
    for (const [m, el] of this.els) {
      const dist = camera.position.distanceTo(m.pos);
      const show = m.visible() && (!m.minor || dist < MINOR_RANGE || !fps);
      el.style.display = show ? '' : 'none';
      if (!show) continue;
      v.copy(m.pos).project(camera);
      const behind = v.z > 1;
      let x = (v.x + 1) / 2 * W, y = (1 - v.y) / 2 * H;
      if (behind) { x = W - x; y = H - pad; }
      const off = behind || x < pad || x > W - pad || y < pad || y > H - pad;
      if (off && !fps) { el.style.display = 'none'; continue; } // command view: on-screen only
      x = Math.max(padX, Math.min(W - padX, x));
      y = Math.max(pad, Math.min(H - pad, y));
      el.style.transform = `translate(${x}px, ${y}px)`;
      el.classList.toggle('off', off);
      const label = typeof m.label === 'function' ? m.label() : m.label;
      const span = el.children[1], small = el.children[2];
      if (span.textContent !== label) span.textContent = label;
      small.textContent = fps ? `${Math.round(dist)} m` : '';
      if (off) {
        const ang = Math.atan2(y - H / 2, x - W / 2);
        el.firstChild.style.transform = `rotate(${ang}rad)`;
      }
    }
  }
}
