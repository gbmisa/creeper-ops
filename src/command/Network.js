// Energy network graph (Creeper World style). Relaying nodes (ship, relays, collectors) chain
// together within link range; every other structure hangs off its nearest connected node.
// Packets follow the BFS tree from the ship, so a cut relay starves everything behind it.

import * as THREE from 'three';

export class Network {
  constructor(scene) {
    this.parent = new Map(); // structure -> upstream structure (null for the ship)
    this.lines = new THREE.LineSegments(
      new THREE.BufferGeometry(),
      new THREE.LineBasicMaterial({ color: 0x7fe0ff, transparent: true, opacity: 0.55 }),
    );
    this.lines.renderOrder = 3;
    scene.add(this.lines);
  }

  static linked(a, b) {
    return Math.hypot(a.x - b.x, a.z - b.z) <= Math.max(a.def.link, b.def.link);
  }

  /** Recompute connectivity for every structure in `list`. */
  rebuild(list) {
    this.parent.clear();
    for (const s of list) s.connected = false;
    const ship = list.find((s) => s.type === 'ship');
    const pts = [];
    if (ship) {
      ship.connected = true;
      this.parent.set(ship, null);
      // relaying nodes: BFS (only finished relays pass packets on)
      const relays = list.filter((s) => s.def.relays && s !== ship);
      const queue = [ship];
      while (queue.length) {
        const a = queue.shift();
        for (const b of relays) {
          if (b.connected || !Network.linked(a, b)) continue;
          b.connected = true;
          this.parent.set(b, a);
          if (b.built >= 1) queue.push(b);
          pts.push(a.pos.x, a.pos.y + a.def.linkY, a.pos.z, b.pos.x, b.pos.y + b.def.linkY, b.pos.z);
        }
      }
      // leaves: attach to the nearest finished, connected relaying node in range
      for (const s of list) {
        if (s.connected || s.def.link <= 0) continue;
        let best = null, bd = Infinity;
        for (const n of list) {
          if (!n.connected || !n.def.relays || n.built < 1) continue;
          const d = Math.hypot(n.x - s.x, n.z - s.z);
          if (d <= Math.max(n.def.link, s.def.link) && d < bd) { bd = d; best = n; }
        }
        if (!best) continue;
        s.connected = true;
        this.parent.set(s, best);
        pts.push(best.pos.x, best.pos.y + best.def.linkY, best.pos.z, s.pos.x, s.pos.y + s.def.linkY, s.pos.z);
      }
    }
    for (const s of list) if (s.def.needsNetwork === false) s.connected = true;
    this.lines.geometry.dispose();
    this.lines.geometry = new THREE.BufferGeometry();
    this.lines.geometry.setAttribute('position', new THREE.Float32BufferAttribute(pts, 3));
  }

  /** Points a packet visits from the ship to `s` (inclusive), or null if unreachable. */
  route(s) {
    if (!this.parent.has(s)) return null;
    const chain = [];
    for (let n = s; n; n = this.parent.get(n)) chain.push(n);
    return chain.reverse().map((n) => n.pos.clone().setY(n.pos.y + n.def.linkY));
  }

  /** Can a new structure at (x, z) with this link radius join the network? */
  inRange(list, x, z, link) {
    return list.some((n) => n.connected && n.def.relays && n.built >= 1 &&
      Math.hypot(n.x - x, n.z - z) <= Math.max(n.def.link, link));
  }
}
