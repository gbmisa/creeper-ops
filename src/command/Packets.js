// Packet dispatcher (the heart of Creeper World's economy). Every build, every turret reload
// and every trained unit is paid for in 1-energy packets that the ship launches at a limited
// rate and that physically travel the relay network. Starve the network and turrets go dry.

import * as THREE from 'three';
import { ECONOMY } from '../core/config.js';

const MAX_VISIBLE = 600;
const COLORS = { build: new THREE.Color(0xe8fbff), ammo: new THREE.Color(0xffb13b), unit: new THREE.Color(0x9dff7a) };

export class Packets {
  constructor(scene, network, economy) {
    this.network = network;
    this.economy = economy;
    this.flying = [];
    this.acc = 0;
    this.cursor = 0; // round-robin position so one hungry structure can't hog the ship
    this.mesh = new THREE.InstancedMesh(
      new THREE.OctahedronGeometry(0.28),
      new THREE.MeshBasicMaterial({ color: 0xffffff, fog: false }),
      MAX_VISIBLE,
    );
    this.mesh.count = 0;
    this.mesh.frustumCulled = false;
    this.mesh.renderOrder = 4;
    scene.add(this.mesh);
    this.tmp = new THREE.Matrix4();
  }

  /**
   * What a structure still needs delivered. Returns 'ammo' | 'build' | 'unit' | null.
   * Counts packets already in flight so we never over-send.
   */
  static need(s) {
    if (!s.connected || s.def.dropPod) return null;
    if (s.built < 1) return s.delivered + s.inFlight < s.def.cost ? 'build' : null;
    const a = s.def.ammo;
    if (a && s.ammo + s.inFlight * a.perPacket <= a.max - a.perPacket) return 'ammo';
    const q = s.queue?.[0];
    if (q && q.delivered + s.inFlight < q.cost) return 'unit';
    return null;
  }

  update(dt, list) {
    this.dispatch(dt, list);
    this.fly(dt);
  }

  dispatch(dt, list) {
    this.acc = Math.min(this.acc + ECONOMY.PACKET_RATE * dt, ECONOMY.PACKET_RATE * 0.5);
    if (!list.length) return;
    // Ammo first (keep the line alive), then construction and training.
    for (const pass of ['ammo', 'other']) {
      let tries = 0;
      while (this.acc >= 1 && tries < list.length) {
        const s = list[this.cursor++ % list.length];
        tries++;
        const kind = Packets.need(s);
        if (!kind || (pass === 'ammo') !== (kind === 'ammo')) continue;
        if (this.economy.energy < 1) return;
        const route = this.network.route(s);
        if (!route) continue;
        this.economy.energy -= 1;
        this.acc -= 1;
        s.inFlight++;
        this.flying.push({ s, kind, route, seg: 0, t: 0, pos: route[0].clone() });
        tries = 0;
      }
    }
  }

  fly(dt) {
    let n = 0;
    for (let i = this.flying.length - 1; i >= 0; i--) {
      const p = this.flying[i];
      let move = ECONOMY.PACKET_SPEED * dt;
      while (move > 0 && p.seg < p.route.length - 1) {
        const a = p.route[p.seg], b = p.route[p.seg + 1];
        const len = Math.max(0.001, a.distanceTo(b));
        const left = (1 - p.t) * len;
        if (move >= left) { move -= left; p.seg++; p.t = 0; } else { p.t += move / len; move = 0; }
      }
      if (p.seg >= p.route.length - 1) { this.arrive(p); this.flying.splice(i, 1); continue; }
      p.pos.lerpVectors(p.route[p.seg], p.route[p.seg + 1], p.t);
      if (n < MAX_VISIBLE) {
        this.tmp.makeTranslation(p.pos.x, p.pos.y, p.pos.z);
        this.mesh.setMatrixAt(n, this.tmp);
        this.mesh.setColorAt(n, COLORS[p.kind]);
        n++;
      }
    }
    this.mesh.count = n;
    this.mesh.instanceMatrix.needsUpdate = true;
    if (this.mesh.instanceColor) this.mesh.instanceColor.needsUpdate = true;
  }

  arrive(p) {
    const s = p.s;
    s.inFlight = Math.max(0, s.inFlight - 1);
    if (s.dead) return; // destroyed while the packet was en route: energy lost
    if (p.kind === 'build') s.delivered++;
    else if (p.kind === 'ammo') s.ammo = Math.min(s.def.ammo.max, s.ammo + s.def.ammo.perPacket);
    else if (p.kind === 'unit' && s.queue[0]) s.queue[0].delivered++;
  }

  /** Packets in the air, for the HUD. */
  get count() { return this.flying.length; }
}
